import SwiftUI

/// A tappable icon tile with a label underneath, used for the wizard's multi-select
/// steps (species, age, size). Highlights in the accent color when selected.
struct IconOptionButton: View {
    let systemImage: String
    let label: String
    let isSelected: Bool
    var iconSize: CGFloat = 34
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: iconSize))
                    .frame(width: 88, height: 88)
                    .background(
                        isSelected ? Color.accentColor : Color(.secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                    )
                    .foregroundStyle(isSelected ? .white : .primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isSelected ? Color.accentColor : .primary)
            }
        }
        .buttonStyle(.plain)
    }
}
