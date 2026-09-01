import SwiftUI

/// A diagonal light band that sweeps across the view on a loop — the standard "content is
/// loading" shimmer effect, applied to plain gray placeholder shapes instead of a spinner.
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { proxy in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.45), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: proxy.size.width * 0.6)
                    .offset(x: phase * proxy.size.width * 1.6 - proxy.size.width * 0.3)
                }
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

/// Loading placeholder shaped like `PetCardView`/`AdopterProfileCardView` — used while the
/// swipe deck or requests deck is fetching its first page.
struct SkeletonCardView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color(.tertiarySystemFill))
            .shimmering()
    }
}

/// Loading placeholder shaped like `InterestRowView` — used while list-style screens
/// (Interests, My Listings) are fetching.
struct SkeletonRowView: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 140, height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 90, height: 12)
            }
            Spacer()
        }
        .shimmering()
        .padding(.vertical, 8)
    }
}

struct SkeletonListView: View {
    var rowCount = 6

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<rowCount, id: \.self) { _ in
                SkeletonRowView()
                Divider()
            }
        }
        .padding(.horizontal)
    }
}
