import SwiftUI

struct MedicalConditionsStepView: View {
    @Binding var openToMedicalConditions: Bool

    var body: some View {
        WizardStepScaffold(
            title: "Medical needs",
            subtitle: "Some pets have an ongoing condition (like diabetes or arthritis) noted on their listing."
        ) {
            VStack(spacing: 16) {
                optionCard(
                    title: "I'm open to pets with medical conditions",
                    systemImage: "heart.text.square.fill",
                    isSelected: openToMedicalConditions
                ) {
                    openToMedicalConditions = true
                }
                optionCard(
                    title: "Only show pets with no known conditions",
                    systemImage: "checkmark.shield.fill",
                    isSelected: !openToMedicalConditions
                ) {
                    openToMedicalConditions = false
                }
            }
        }
    }

    private func optionCard(title: String, systemImage: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .frame(width: 32)
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .multilineTextAlignment(.leading)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(16)
            .background(
                isSelected ? Color.accentColor.opacity(0.12) : Color(.secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }
}
