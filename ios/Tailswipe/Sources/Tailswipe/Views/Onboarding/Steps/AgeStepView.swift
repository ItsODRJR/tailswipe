import SwiftUI

struct AgeStepView: View {
    @Binding var selected: [Pet.AgeCategory]

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 20)]

    var body: some View {
        WizardStepScaffold(
            title: "How old?",
            subtitle: "Pick as many as you'd like."
        ) {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(Pet.AgeCategory.allCases) { age in
                    IconOptionButton(
                        systemImage: icon(for: age),
                        label: age.displayName,
                        isSelected: selected.contains(age)
                    ) {
                        toggle(age)
                    }
                }
            }
        }
    }

    private func icon(for age: Pet.AgeCategory) -> String {
        switch age {
        case .baby: return "leaf.fill"
        case .young: return "hare.fill"
        case .adult: return "pawprint.fill"
        case .senior: return "tortoise.fill"
        }
    }

    private func toggle(_ age: Pet.AgeCategory) {
        if selected.contains(age) {
            selected.removeAll { $0 == age }
        } else {
            selected.append(age)
        }
    }
}
