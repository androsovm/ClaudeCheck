import Foundation

/// Raw component status string as reported by statuspage.io.
enum ComponentStatus: String, Codable {
    case operational
    case degradedPerformance = "degraded_performance"
    case partialOutage = "partial_outage"
    case majorOutage = "major_outage"
    case underMaintenance = "under_maintenance"

    var severity: Severity {
        switch self {
        case .operational:         return .ok
        case .degradedPerformance: return .degraded
        case .partialOutage:       return .partial
        case .majorOutage:         return .down
        case .underMaintenance:    return .maintenance
        }
    }

    var displayName: String {
        switch self {
        case .operational:         return "Operational"
        case .degradedPerformance: return "Degraded Performance"
        case .partialOutage:       return "Partial Outage"
        case .majorOutage:         return "Major Outage"
        case .underMaintenance:    return "Under Maintenance"
        }
    }
}

struct Component: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let status: ComponentStatus
    let position: Int?
}
