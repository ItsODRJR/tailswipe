import SwiftUI

/// Generic Tinder-style stack: renders the top few `items` with a slight scale/offset
/// cascade and only lets the front card receive drag gestures. Backs both the pet
/// discovery deck and the lister's incoming-requests deck.
struct CardStackContainer<Item: Identifiable, CardContent: View>: View {
    let items: [Item]
    let onSwipe: (Item, SwipeDecision) -> Void
    @ViewBuilder let card: (Item) -> CardContent

    private let maxVisible = 3

    var body: some View {
        // GeometryReader always reports back exactly the size it was proposed (unlike a
        // plain ZStack, whose reported size grows to match its largest child). Without this,
        // an AsyncImage's aspect-fill photo can report a huge ideal size once it loads —
        // ballooning the whole card stack — because nothing here otherwise constrains it.
        GeometryReader { proxy in
            ZStack {
                ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                    card(item)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .swipeableCard { decision in onSwipe(item, decision) }
                        .scaleEffect(scale(for: index))
                        .offset(y: yOffset(for: index))
                        .zIndex(Double(maxVisible - index))
                        .allowsHitTesting(index == 0)
                }
            }
            // Without this, the moment a front card is removed the next card's scale/offset
            // (driven by its now-changed index) jumps straight to its new value instead of
            // growing into place.
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: visibleItems.map(\.id))
        }
    }

    private var visibleItems: [Item] {
        Array(items.prefix(maxVisible))
    }

    private func scale(for index: Int) -> CGFloat {
        1.0 - (CGFloat(index) * 0.04)
    }

    private func yOffset(for index: Int) -> CGFloat {
        CGFloat(index) * 8
    }
}
