import Foundation

/// Mock mode never requires verification (no real email to send a code to), so signUp/signIn
/// there always resolve `.success` immediately. Live mode's backend won't issue a token to an
/// unverified account — signUp always returns `.needsVerification`, and signIn does too if the
/// account hasn't completed it yet.
enum AuthOutcome {
    case success(User)
    case needsVerification(email: String)
}

protocol UserRepository {
    func currentUser() async -> User?
    func signUp(email: String, password: String, displayName: String) async throws -> AuthOutcome
    func signIn(email: String, password: String) async throws -> AuthOutcome
    func verifyEmail(email: String, code: String) async throws -> User
    func resendVerification(email: String) async throws
    func signOut() async
    func fetchPreferences(for userID: UUID) async throws -> AdoptionPreferences
    func updatePreferences(_ preferences: AdoptionPreferences, for userID: UUID) async throws
    func updateProfile(_ user: User) async throws -> User
    func registerDeviceToken(_ token: String) async
}

extension UserRepository {
    /// Default no-op — mock mode has no push backend to register a device token with.
    func registerDeviceToken(_ token: String) async {}
    // Default no-op/throwing implementations — mock mode never returns `.needsVerification`,
    // so these are never actually called there.
    func verifyEmail(email: String, code: String) async throws -> User { throw RepositoryError.notFound }
    func resendVerification(email: String) async throws {}
}
