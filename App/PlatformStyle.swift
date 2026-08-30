import SwiftUI
import FinelloKit

/// How each Platform looks. Presentation only — the Kit has no idea what
/// colour Instagram is.
extension Platform {
    var symbolName: String {
        switch self {
        case .instagram: "camera.fill"
        case .tiktok: "music.note"
        case .youtube: "play.rectangle.fill"
        case .snapchat: "bolt.fill"
        case .linkedin: "briefcase.fill"
        }
    }

    var tint: Color {
        switch self {
        case .instagram: Color(red: 0.85, green: 0.24, blue: 0.53)
        case .tiktok: Color(red: 0.03, green: 0.72, blue: 0.71)
        case .youtube: Color(red: 0.90, green: 0.16, blue: 0.16)
        case .snapchat: Color(red: 0.95, green: 0.76, blue: 0.06)
        case .linkedin: Color(red: 0.06, green: 0.44, blue: 0.70)
        }
    }
}

struct PlatformBadge: View {
    let platform: Platform
    var isDone: Bool = false
    var size: CGFloat = 15

    var body: some View {
        Image(systemName: platform.symbolName)
            .font(.system(size: size * 0.58, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(platform.tint.opacity(isDone ? 1.0 : 0.55), in: .circle)
            .overlay {
                if isDone {
                    Circle().strokeBorder(.white.opacity(0.9), lineWidth: 1)
                }
            }
            .help(platform.displayName + (isDone ? " — done" : ""))
    }
}

/// How progress reads on screen. Collected here so the day cell, its tiles and
/// anything later all agree.
extension DoneState {
    /// For a tile too small to carry the `2/3` pill.
    var dotColour: Color {
        switch self {
        case .all: .green
        case .some: .yellow
        case .none: .black.opacity(0.35)
        }
    }

    var pillBackground: AnyShapeStyle {
        switch self {
        case .all: AnyShapeStyle(.green)
        case .some: AnyShapeStyle(.yellow.opacity(0.85))
        case .none: AnyShapeStyle(.thinMaterial)
        }
    }

    var pillForeground: Color {
        self == .all ? .white : .primary
    }
}
