import Foundation

/// App-wide session state: who's signed in, their preferences, and whether they've
/// finished the first-run onboarding flow. Owned at the root and injected via
/// `.environmentObject` so any screen can react to sign-in/sign-out.
@MainActor
final class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var preferences: AdoptionPreferences = .default
    @Published var hasCompletedOnboarding = false
    @Published var isLoading = true

    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    func bootstrap() async {
        isLoading = true
        defer { isLoading = false }
        guard let user = await userRepository.currentUser() else { return }
        await setCurrentUser(user)
    }

    func setCurrentUser(_ user: User) async {
        currentUser = user
        preferences = (try? await userRepository.fetchPreferences(for: user.id)) ?? .default
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Self.onboardingKey(for: user.id))
    }

    func completeOnboarding(with preferences: AdoptionPreferences) async {
        guard let user = currentUser else { return }
        self.preferences = preferences
        try? await userRepository.updatePreferences(preferences, for: user.id)
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: Self.onboardingKey(for: user.id))
    }

    func updatePreferences(_ preferences: AdoptionPreferences) async {
        guard let user = currentUser else { return }
        self.preferences = preferences
        try? await userRepository.updatePreferences(preferences, for: user.id)
    }

    func updateProfile(_ user: User) async {
        currentUser = user
        try? await userRepository.updateProfile(user)
    }

    func signOut() async {
        await userRepository.signOut()
        currentUser = nil
        hasCompletedOnboarding = false
        preferences = .default
    }

    private static func onboardingKey(for userID: UUID) -> String {
        "hasCompletedOnboarding.\(userID.uuidString)"
    }
}
