import SwiftUI

struct PreferencesSetupView: View {
    enum Mode {
        case onboarding
        case edit
    }

    private enum Step: Hashable {
        case species, breed, age, size, medical, location
    }

    let mode: Mode

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @State private var draft: AdoptionPreferences
    @State private var currentStep: Step = .species

    init(mode: Mode, initialPreferences: AdoptionPreferences = .default) {
        self.mode = mode
        _draft = State(initialValue: initialPreferences)
    }

    /// Breed step only appears when a species with a known breed catalog is selected.
    private var steps: [Step] {
        var result: [Step] = [.species]
        if draft.species.contains(.dog) || draft.species.contains(.cat) {
            result.append(.breed)
        }
        result.append(contentsOf: [.age, .size, .medical, .location])
        return result
    }

    private var currentIndex: Int {
        steps.firstIndex(of: currentStep) ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            stepContent
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(currentStep)
            footer
        }
        .navigationTitle(mode == .onboarding ? "Your Preferences" : "Edit Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if mode == .edit {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            if mode == .onboarding && currentStep == .species {
                Text("Let's find the right pet for you. You can change these anytime from your profile.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            HStack(spacing: 6) {
                ForEach(steps.indices, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentIndex ? Color.accentColor : Color(.systemGray4))
                        .frame(height: 5)
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .species:
            SpeciesStepView(selected: $draft.species)
        case .breed:
            BreedStepView(species: draft.species, selected: breedsBinding)
        case .age:
            AgeStepView(selected: $draft.ageCategories)
        case .size:
            SizeStepView(selected: $draft.sizes)
        case .medical:
            MedicalConditionsStepView(openToMedicalConditions: $draft.openToMedicalConditions)
        case .location:
            LocationRadiusStepView(maxDistanceMiles: $draft.maxDistanceMiles, locationService: environment.locationService)
        }
    }

    private var breedsBinding: Binding<[String]> {
        Binding(
            get: { draft.breeds ?? [] },
            set: { draft.breeds = $0.isEmpty ? nil : $0 }
        )
    }

    private var footer: some View {
        HStack(spacing: 16) {
            if currentIndex > 0 {
                Button("Back") { goBack() }
                    .buttonStyle(.bordered)
            }
            Button(isLastStep ? (mode == .onboarding ? "Start Swiping" : "Save Preferences") : "Next") {
                goNext()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canAdvance)
            .frame(maxWidth: .infinity)
        }
        .padding()
    }

    private var isLastStep: Bool {
        currentIndex == steps.count - 1
    }

    private var canAdvance: Bool {
        switch currentStep {
        case .species: return !draft.species.isEmpty
        case .breed: return true
        case .age: return !draft.ageCategories.isEmpty
        case .size: return !draft.sizes.isEmpty
        case .medical: return true
        case .location: return true
        }
    }

    private func goNext() {
        if isLastStep {
            Task { await save() }
            return
        }
        let ordered = steps
        guard let index = ordered.firstIndex(of: currentStep), index + 1 < ordered.count else { return }
        withAnimation(.easeInOut) {
            currentStep = ordered[index + 1]
        }
    }

    private func goBack() {
        let ordered = steps
        guard let index = ordered.firstIndex(of: currentStep), index > 0 else { return }
        withAnimation(.easeInOut) {
            currentStep = ordered[index - 1]
        }
    }

    private func save() async {
        switch mode {
        case .onboarding:
            await appState.completeOnboarding(with: draft)
        case .edit:
            await appState.updatePreferences(draft)
            dismiss()
        }
    }
}
