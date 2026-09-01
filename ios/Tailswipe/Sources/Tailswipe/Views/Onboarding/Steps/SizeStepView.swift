import SwiftUI

/// 3 icons — Small / Medium / Large — sized to visually communicate scale. "Large"
/// bundles `.xlarge` under the hood so giant-breed pets stay in the results without
/// needing a 4th icon.
struct SizeStepView: View {
    @Binding var selected: [Pet.Size]

    private let tiers: [(size: Pet.Size, label: String, iconSize: CGFloat)] = [
        (.small, "Small", 22),
        (.medium, "Medium", 34),
        (.large, "Large", 46)
    ]

    var body: some View {
        WizardStepScaffold(
            title: "What size?",
            subtitle: "Pick as many as you'd like. Large includes extra-large pets too."
        ) {
            HStack(spacing: 20) {
                ForEach(tiers, id: \.size) { tier in
                    IconOptionButton(
                        systemImage: "pawprint.fill",
                        label: tier.label,
                        isSelected: selected.contains(tier.size),
                        iconSize: tier.iconSize
                    ) {
                        toggle(tier.size)
                    }
                }
            }
        }
    }

    private func toggle(_ size: Pet.Size) {
        let bundle: [Pet.Size] = size == .large ? [.large, .xlarge] : [size]
        if selected.contains(size) {
            selected.removeAll { bundle.contains($0) }
        } else {
            for value in bundle where !selected.contains(value) {
                selected.append(value)
            }
        }
    }
}
