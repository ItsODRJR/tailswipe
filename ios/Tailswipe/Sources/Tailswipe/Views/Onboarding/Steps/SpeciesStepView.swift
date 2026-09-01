import SwiftUI

struct SpeciesStepView: View {
    @Binding var selected: [Pet.Species]

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 20)]

    var body: some View {
        WizardStepScaffold(
            title: "What kind of pet?",
            subtitle: "Pick as many as you'd like — you can change this later."
        ) {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(Pet.Species.allCases) { species in
                    IconOptionButton(
                        systemImage: icon(for: species),
                        label: species.displayName,
                        isSelected: selected.contains(species)
                    ) {
                        toggle(species)
                    }
                }
            }
        }
    }

    private func icon(for species: Pet.Species) -> String {
        switch species {
        case .dog: return "dog.fill"
        case .cat: return "cat.fill"
        case .other: return "lizard.fill"
        }
    }

    private func toggle(_ species: Pet.Species) {
        if selected.contains(species) {
            selected.removeAll { $0 == species }
        } else {
            selected.append(species)
        }
    }
}
