import Foundation

/// Decodes https://status.claude.com/api/v2/summary.json
struct StatusSummary: Codable {
    struct Page: Codable {
        let id: String
        let name: String
        let url: String
        let updatedAt: String
    }

    /// Page-wide aggregate. We don't drive our icon from this — we compute
    /// severity from the monitored components instead — but it's exposed
    /// in case we ever need to fall back.
    struct Status: Codable {
        /// "none", "minor", "major", "critical", "maintenance"
        let indicator: String
        let description: String
    }

    let page: Page
    let components: [Component]
    let incidents: [Incident]
    let scheduledMaintenances: [Incident]
    let status: Status
}
