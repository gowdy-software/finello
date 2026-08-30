import Foundation

/// One of the five places she publishes. Fixed set, and deliberately persisted
/// as its `rawValue` string rather than as a database enum, so that adding a
/// sixth Platform later is a code change with no schema migration.
public enum Platform: String, CaseIterable, Codable, Sendable, Identifiable, Comparable {
    case instagram
    case tiktok
    case youtube
    case snapchat
    case linkedin

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .instagram: "Instagram"
        case .tiktok: "TikTok"
        case .youtube: "YouTube"
        case .snapchat: "Snapchat"
        case .linkedin: "LinkedIn"
        }
    }

    /// Declaration order. Variants are always presented in this order so the
    /// tabs never reshuffle under her.
    public var sortOrder: Int {
        Platform.allCases.firstIndex(of: self) ?? 0
    }

    public static func < (lhs: Platform, rhs: Platform) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
