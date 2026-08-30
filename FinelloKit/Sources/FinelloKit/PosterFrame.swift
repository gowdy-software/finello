import Foundation

/// Where in a video to grab the still that represents it in the calendar.
///
/// Frame zero is the wrong answer: leading frames are very often black, a fade
/// in, or a slate, which would give a grid of black rectangles for exactly the
/// media type she uses most.
public enum PosterFrame {
    /// How far in we would like to be, when the clip is long enough to allow it.
    public static let nominalOffset: TimeInterval = 1.0

    /// Never seeks past the end: for a clip shorter than twice the nominal
    /// offset this lands at the midpoint instead.
    public static func offset(forDuration duration: TimeInterval) -> TimeInterval {
        guard duration.isFinite, duration > 0 else { return 0 }
        return min(nominalOffset, duration / 2)
    }
}
