import SwiftUI

/// Handles the drag-to-swipe interaction for a single card: offset, rotation, and a
/// LIKE/PASS/SUPER stamp that fades in with drag distance, then either commits (flies off
/// screen and reports the decision) or springs back to center. `CardStackContainer`
/// only enables hit-testing on the topmost card, so cards underneath simply never
/// receive the touches that would start this gesture. A mostly-vertical upward drag
/// commits `.superInterested` instead of the usual left/right `.passed`/`.interested`.
struct SwipeableCardModifier: ViewModifier {
    let onDecision: (SwipeDecision) -> Void

    @State private var translation: CGSize = .zero

    private let swipeThreshold: CGFloat = 120
    private let verticalThreshold: CGFloat = 120
    private let rotationFactor: Double = 0.06

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(Double(translation.width) * rotationFactor))
            .offset(translation)
            .overlay(alignment: .topLeading) {
                stampLabel(text: "INTERESTED", color: .green)
                    .opacity(likeOpacity)
                    .padding(24)
            }
            .overlay(alignment: .topTrailing) {
                stampLabel(text: "PASS", color: .red)
                    .opacity(passOpacity)
                    .padding(24)
            }
            .overlay(alignment: .top) {
                stampLabel(text: "SUPER", color: .blue)
                    .opacity(superOpacity)
                    .padding(.top, 24)
            }
            .gesture(dragGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                translation = value.translation
            }
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                if vertical < -verticalThreshold && abs(horizontal) < abs(vertical) {
                    commit(.superInterested, offset: CGSize(width: horizontal, height: -900))
                } else if horizontal > swipeThreshold {
                    commit(.interested, offset: CGSize(width: 600, height: vertical))
                } else if horizontal < -swipeThreshold {
                    commit(.passed, offset: CGSize(width: -600, height: vertical))
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        translation = .zero
                    }
                }
            }
    }

    private func commit(_ decision: SwipeDecision, offset: CGSize) {
        Haptics.swipeCommitted(decision)
        withAnimation(.easeOut(duration: 0.3)) {
            translation = offset
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDecision(decision)
        }
    }

    private var likeOpacity: Double {
        Double(max(0, min(1, translation.width / swipeThreshold)))
    }

    private var passOpacity: Double {
        Double(max(0, min(1, -translation.width / swipeThreshold)))
    }

    private var superOpacity: Double {
        Double(max(0, min(1, -translation.height / verticalThreshold)))
    }

    private func stampLabel(text: String, color: Color) -> some View {
        Text(text)
            .font(.headline.bold())
            .padding(8)
            .foregroundStyle(color)
            .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(color, lineWidth: 3))
            .rotationEffect(.degrees(text == "PASS" ? 15 : (text == "SUPER" ? 0 : -15)))
    }
}

extension View {
    func swipeableCard(onDecision: @escaping (SwipeDecision) -> Void) -> some View {
        modifier(SwipeableCardModifier(onDecision: onDecision))
    }
}
