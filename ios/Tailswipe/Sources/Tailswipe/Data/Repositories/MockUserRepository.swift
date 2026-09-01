import Foundation

final class MockUserRepository: UserRepository {
    let store: MockDataStore

    init(store: MockDataStore = .shared) {
        self.store = store
    }

    func currentUser() async -> User? {
        guard let id = store.currentUserID else { return nil }
        return store.users[id]
    }

    func signUp(email: String, password: String, displayName: String) async throws -> AuthOutcome {
        let normalizedEmail = email.lowercased()
        guard store.credentials[normalizedEmail] == nil else {
            throw RepositoryError.emailAlreadyInUse
        }
        let user = User(id: UUID(), email: normalizedEmail, displayName: displayName, location: nil, createdAt: Date())
        store.users[user.id] = user
        store.credentials[normalizedEmail] = password
        store.preferences[user.id] = .default
        store.currentUserID = user.id
        return .success(user)
    }

    func signIn(email: String, password: String) async throws -> AuthOutcome {
        let normalizedEmail = email.lowercased()
        guard store.credentials[normalizedEmail] == password,
              let user = store.users.values.first(where: { $0.email == normalizedEmail }) else {
            throw RepositoryError.invalidCredentials
        }
        store.currentUserID = user.id
        return .success(user)
    }

    func signOut() async {
        store.currentUserID = nil
    }

    func fetchPreferences(for userID: UUID) async throws -> AdoptionPreferences {
        store.preferences[userID] ?? .default
    }

    func updatePreferences(_ preferences: AdoptionPreferences, for userID: UUID) async throws {
        store.preferences[userID] = preferences
    }

    func updateProfile(_ user: User) async throws -> User {
        store.users[user.id] = user
        return user
    }
}
