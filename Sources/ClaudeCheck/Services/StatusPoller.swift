import Foundation
import Combine

/// Polls the Claude status page on a timer and exposes the derived
/// severity we care about (max of Claude API + Claude Code).
///
/// All state mutations happen on the main actor so @Published updates
/// flow straight into SwiftUI views without hopping threads.
@MainActor
final class StatusPoller: ObservableObject {
    static let summaryURL = URL(string: "https://status.claude.com/api/v2/summary.json")!

    /// Components whose status actually drives our icon color and alerts.
    /// Matched against `Component.name` case-insensitively so minor
    /// rebrands don't silently break us.
    static let monitoredNames: [String] = ["Claude API", "Claude Code"]

    /// When true, skip real polling and cycle `severity` through every
    /// case every 5s so you can eyeball the tinted menu-bar logo in each
    /// state without waiting for a real outage. Flip off before shipping.
    static let debugCycleSeverities = false

    /// When true, skip real polling and pin the app to a fake "Claude is
    /// down" state with both monitored components marked as major outage
    /// plus a synthetic incident — for screenshots. Flip off before shipping.
    static let debugForceDown = false

    @Published private(set) var summary: StatusSummary?
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var lastError: String?
    @Published private(set) var isFetching = false
    @Published private(set) var severity: Severity = .unknown

    private var pollTask: Task<Void, Never>?
    private var currentInterval: TimeInterval = 60

    func start(interval: TimeInterval) {
        currentInterval = interval
        pollTask?.cancel()
        if Self.debugCycleSeverities {
            pollTask = Task { [weak self] in
                let states: [Severity] = [.ok, .degraded, .partial, .down, .maintenance, .unknown]
                var i = 0
                while !Task.isCancelled {
                    self?.severity = states[i % states.count]
                    self?.lastUpdated = Date()
                    i += 1
                    try? await Task.sleep(for: .seconds(5))
                }
            }
            return
        }
        if Self.debugForceDown {
            self.summary = Self.fakeDownSummary()
            self.severity = .down
            self.lastUpdated = Date()
            self.lastError = nil
            return
        }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.fetchOnce()
                // Task inherits @MainActor from the enclosing method,
                // so we can read currentInterval directly before sleeping.
                let seconds = self?.currentInterval ?? 60
                try? await Task.sleep(for: .seconds(seconds))
            }
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
    }

    /// Change the polling cadence without dropping the current in-flight fetch.
    func setInterval(_ interval: TimeInterval) {
        guard interval != currentInterval else { return }
        currentInterval = interval
        // Restart so the new interval takes effect on the next tick.
        start(interval: interval)
    }

    func refresh() {
        Task { await fetchOnce() }
    }

    /// True iff the component's name starts with one of our monitored prefixes.
    /// Prefix match (not exact) so that e.g. "Claude API (api.anthropic.com)"
    /// still matches the "Claude API" prefix — statuspage component labels
    /// occasionally pick up trailing clarifications.
    private static func isMonitored(_ component: Component) -> Bool {
        let name = component.name.lowercased()
        return monitoredNames.contains { name.hasPrefix($0.lowercased()) }
    }

    /// Components that drive the signal.
    var monitoredComponents: [Component] {
        guard let components = summary?.components else { return [] }
        return components
            .filter(Self.isMonitored)
            .sorted { $0.name < $1.name }
    }

    /// Everything else — shown as info-only under "Other services".
    var otherComponents: [Component] {
        guard let components = summary?.components else { return [] }
        return components
            .filter { !Self.isMonitored($0) }
            .sorted { ($0.position ?? .max) < ($1.position ?? .max) }
    }

    /// Incidents touching at least one monitored component.
    var relevantIncidents: [Incident] {
        guard let incidents = summary?.incidents else { return [] }
        let wantedIds = Set(monitoredComponents.map(\.id))
        return incidents.filter { !wantedIds.isDisjoint(with: $0.affectedComponentIds) }
    }

    // MARK: - Fetch

    private func fetchOnce() async {
        isFetching = true
        defer { isFetching = false }

        do {
            var request = URLRequest(url: Self.summaryURL)
            request.timeoutInterval = 15
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.setValue("ClaudeCheck/1.0", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let newSummary = try decoder.decode(StatusSummary.self, from: data)

            self.summary = newSummary
            self.lastUpdated = Date()
            self.lastError = nil
            self.severity = computeSeverity(from: newSummary)
        } catch {
            self.lastError = error.localizedDescription
            // Only reset to .unknown if we have no prior successful data —
            // otherwise keep showing the last known state during blips.
            if summary == nil {
                self.severity = .unknown
            }
        }
    }

    private func computeSeverity(from summary: StatusSummary) -> Severity {
        let monitored = summary.components.filter(Self.isMonitored)
        guard !monitored.isEmpty else {
            // Fall back to the page-wide indicator if our names drifted.
            return Self.severity(fromIndicator: summary.status.indicator)
        }
        return monitored.map(\.status.severity).max() ?? .ok
    }

    private static func fakeDownSummary() -> StatusSummary {
        let components = [
            Component(id: "fake-api", name: "Claude API", status: .majorOutage, position: 1),
            Component(id: "fake-code", name: "Claude Code", status: .majorOutage, position: 2)
        ]
        let incident = Incident(
            id: "fake-incident",
            name: "Elevated errors on Claude API and Claude Code",
            status: "investigating",
            impact: .critical,
            shortlink: "https://status.claude.com",
            componentIds: ["fake-api", "fake-code"],
            components: nil
        )
        return StatusSummary(
            page: .init(id: "fake", name: "Anthropic", url: "https://status.claude.com", updatedAt: ""),
            components: components,
            incidents: [incident],
            scheduledMaintenances: [],
            status: .init(indicator: "critical", description: "Major System Outage")
        )
    }

    static func severity(fromIndicator indicator: String) -> Severity {
        switch indicator {
        case "none":        return .ok
        case "minor":       return .degraded
        case "major":       return .partial
        case "critical":    return .down
        case "maintenance": return .maintenance
        default:            return .unknown
        }
    }
}
