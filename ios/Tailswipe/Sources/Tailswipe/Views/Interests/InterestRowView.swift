import SwiftUI

struct InterestRowView: View {
    enum Trailing {
        case chatIcon
        case pendingBadge
        case matchedBadge
        case adoptedBadge
    }

    let pet: Pet
    var trailing: Trailing = .chatIcon

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: pet.photoURLs.first.flatMap(URL.init)) { phase in
                if case .success(let image) = phase {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Rectangle().fill(Color(.tertiarySystemFill))
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(pet.name).font(.headline)
                Text(pet.breedDisplay).font(.subheadline).foregroundStyle(.secondary)
                if let badge = pet.source.badgeText {
                    Text(badge).font(.caption).foregroundStyle(.secondary)
                }
            }

            Spacer()

            trailingView
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var trailingView: some View {
        switch trailing {
        case .chatIcon:
            Image(systemName: "bubble.left.and.bubble.right")
                .foregroundStyle(.secondary)
        case .pendingBadge:
            Label("Pending", systemImage: "clock")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        case .matchedBadge:
            Label("Matched", systemImage: "bubble.left.and.bubble.right.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.green)
        case .adoptedBadge:
            Label("Adopted", systemImage: "party.popper.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.purple)
        }
    }
}
