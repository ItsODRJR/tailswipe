import SwiftUI

struct BreedStepView: View {
    let species: [Pet.Species]
    @Binding var selected: [String]

    var body: some View {
        WizardStepScaffold(
            title: "Any breed preferences?",
            subtitle: "Optional — leave everything unselected for any breed."
        ) {
            VStack(alignment: .leading, spacing: 28) {
                if species.contains(.dog) {
                    breedSection(title: "Dog Breeds", breeds: BreedCatalog.dog)
                }
                if species.contains(.cat) {
                    breedSection(title: "Cat Breeds", breeds: BreedCatalog.cat)
                }
            }
        }
    }

    private func breedSection(title: String, breeds: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            FlowLayout(spacing: 8) {
                ForEach(breeds, id: \.self) { breed in
                    breedChip(breed)
                }
            }
        }
    }

    private func breedChip(_ breed: String) -> some View {
        let isSelected = selected.contains(breed)
        return Button {
            toggle(breed)
        } label: {
            Text(breed)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.accentColor : Color(.secondarySystemBackground),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ breed: String) {
        if selected.contains(breed) {
            selected.removeAll { $0 == breed }
        } else {
            selected.append(breed)
        }
    }
}
