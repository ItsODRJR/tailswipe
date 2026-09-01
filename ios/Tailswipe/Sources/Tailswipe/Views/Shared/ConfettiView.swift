import SwiftUI

/// Hand-rolled confetti burst (no third-party dependencies) for the match celebration
/// screen: a handful of small rectangles fall from the top with randomized color,
/// rotation, and timing, then fade out.
struct ConfettiView: View {
    private struct Piece: Identifiable {
        let id = UUID()
        let color: Color
        let xOffset: CGFloat
        let delay: Double
        let rotation: Double
        let size: CGFloat
    }

    @State private var animate = false
    private let pieces: [Piece]

    init(count: Int = 40) {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        pieces = (0..<count).map { _ in
            Piece(
                color: colors.randomElement() ?? .white,
                xOffset: CGFloat.random(in: -160...160),
                delay: Double.random(in: 0...0.4),
                rotation: Double.random(in: 0...360),
                size: CGFloat.random(in: 6...12)
            )
        }
    }

    var body: some View {
        ZStack {
            ForEach(pieces) { piece in
                RoundedRectangle(cornerRadius: 2)
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size * 0.4)
                    .rotationEffect(.degrees(animate ? piece.rotation + 360 : piece.rotation))
                    .offset(x: piece.xOffset, y: animate ? 520 : -40)
                    .opacity(animate ? 0 : 1)
                    .animation(.easeIn(duration: 1.8).delay(piece.delay), value: animate)
            }
        }
        .allowsHitTesting(false)
        .onAppear { animate = true }
    }
}
