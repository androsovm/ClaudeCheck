import Foundation

enum IncidentImpact: String, Codable {
    case none
    case minor
    case major
    case critical
    case maintenance
}

struct Incident: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let status: String        // "investigating", "identified", "monitoring", "resolved", "postmortem"
    let impact: IncidentImpact
    let shortlink: String?
    let componentIds: [String]?
    let components: [Component]?

    /// Union of component IDs this incident affects.
    var affectedComponentIds: Set<String> {
        if let ids = componentIds, !ids.isEmpty { return Set(ids) }
        return Set((components ?? []).map(\.id))
    }
}
