import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var displayName = ""
    @Published var errorMessage: String?
    @Published private(set) var isSubmitting = false

    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    func signIn() async -> AuthOutcome? {
        await submit { [userRepository, email, password] in
            try await userRepository.signIn(email: email, password: password)
        }
    }

    func signUp() async -> AuthOutcome? {
        await submit { [userRepository, email, password, displayName] in
            try await userRepository.signUp(email: email, password: password, displayName: displayName)
        }
    }

    func verifyEmail(email: String, code: String) async -> User? {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            return try await userRepository.verifyEmail(email: email, code: code)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    @discardableResult
    func resendVerification(email: String) async -> Bool {
        do {
            try await userRepository.resendVerification(email: email)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func submit(_ action: @escaping () async throws -> AuthOutcome) async -> AuthOutcome? {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            return try await action()
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
