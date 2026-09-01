import UIKit

/// Tiny wrapper around UIKit's feedback generators so call sites don't need to import
/// UIKit directly or juggle generator instances themselves.
enum Haptics {
    static func swipeCommitted(_ decision: SwipeDecision) {
        switch decision {
        case .interested:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .superInterested:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .passed:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    static func match() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
