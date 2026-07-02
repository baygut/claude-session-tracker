import Foundation

// MARK: - claude.ai usage API models
// Mirrors the response of GET https://claude.ai/api/organizations/{id}/usage
// (the same private endpoint the claude.ai Settings > Usage panel calls).
// This is not a documented/public API and may change without notice.

struct Organization: Decodable {
    let uuid: String
    let name: String
}

struct UsageModelScope: Decodable {
    let id: String?
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
    }
}

struct UsageScope: Decodable {
    let model: UsageModelScope?
    let surface: String?
}

struct UsageLimit: Decodable, Identifiable {
    let kind: String
    let group: String
    let percent: Int
    let severity: String
    let resetsAt: Date?
    let scope: UsageScope?
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case kind, group, percent, severity, scope
        case resetsAt = "resets_at"
        case isActive = "is_active"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decode(String.self, forKey: .kind)
        group = try c.decode(String.self, forKey: .group)
        // The API has returned this as a plain int in practice; decode
        // defensively in case it's ever a float instead.
        if let intVal = try? c.decode(Int.self, forKey: .percent) {
            percent = intVal
        } else {
            percent = Int((try c.decode(Double.self, forKey: .percent)).rounded())
        }
        severity = (try? c.decode(String.self, forKey: .severity)) ?? "normal"
        resetsAt = try? c.decode(Date.self, forKey: .resetsAt)
        scope = try? c.decode(UsageScope.self, forKey: .scope)
        isActive = (try? c.decode(Bool.self, forKey: .isActive)) ?? false
    }

    var id: String { kind + (scope?.model?.displayName ?? "") }

    /// Human label matching what claude.ai shows: "Current session" for the
    /// 5-hour window, the scoped model's name for per-model weekly limits,
    /// or "All models" for the general weekly limit.
    var displayName: String {
        if group == "session" { return "Current session" }
        if let name = scope?.model?.displayName, !name.isEmpty { return name }
        return "All models"
    }

    var resetsInText: String {
        guard let resetsAt else { return "—" }
        let remaining = resetsAt.timeIntervalSinceNow
        guard remaining > 0 else { return "resetting…" }
        let days = Int(remaining) / 86400
        let hours = (Int(remaining) % 86400) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

struct UsageResponse: Decodable {
    let limits: [UsageLimit]

    var session: UsageLimit? { limits.first { $0.group == "session" } }
    var weekly: [UsageLimit] { limits.filter { $0.group == "weekly" } }
}
