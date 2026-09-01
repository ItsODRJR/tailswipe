import Foundation

final class APIUserRepository: UserRepository {
    private let client: APIClient
    private var cachedUser: User?

    init(client: APIClient) {
        self.client = client
    }

    func currentUser() async -> User? {
        cachedUser
    }

    func signUp(email: String, password: String, displayName: String) async throws -> AuthOutcome {
        struct Body: Encodable { let email, password, displayName: String }
        struct Response: Decodable { let needsVerification: Bool; let email: String }
        let response: Response = try await client.post(.signUp, body: Body(email: email, password: password, displayName: displayName))
        return .needsVerification(email: response.email)
    }

    func signIn(email: String, password: String) async throws -> AuthOutcome {
        struct Body: Encodable { let email, password: String }
        struct SuccessResponse: Decodable { let token: String; let user: User }
        struct VerificationResponse: Decodable { let needsVerification: Bool; let email: String }
        do {
            let response: SuccessResponse = try await client.post(.signIn, body: Body(email: email, password: password))
            client.authToken = response.token
            cachedUser = response.user
            return .success(response.user)
        } catch APIError.server(let statusCode, let message) where statusCode == 403 {
            // The backend responds 403 (not 2xx) for an unverified account, so this never
            // reaches the normal decode path above — the verification payload has to be
            // pulled back out of the error's raw message instead.
            if let data = message?.data(using: .utf8),
               let verification = try? JSONDecoder().decode(VerificationResponse.self, from: data) {
                return .needsVerification(email: verification.email)
            }
            throw APIError.server(statusCode: statusCode, message: message)
        }
    }

    func verifyEmail(email: String, code: String) async throws -> User {
        struct Body: Encodable { let email, code: String }
        struct Response: Decodable { let token: String; let user: User }
        let response: Response = try await client.post(.verifyEmail, body: Body(email: email, code: code))
        client.authToken = response.token
        cachedUser = response.user
        return response.user
    }

    func resendVerification(email: String) async throws {
        struct Body: Encodable { let email: String }
        let _: EmptyResponse? = try? await client.post(.resendVerification, body: Body(email: email))
    }

    func signOut() async {
        client.authToken = nil
        cachedUser = nil
    }

    func fetchPreferences(for userID: UUID) async throws -> AdoptionPreferences {
        try await client.get(.preferences)
    }

    func updatePreferences(_ preferences: AdoptionPreferences, for userID: UUID) async throws {
        let _: AdoptionPreferences = try await client.patch(.preferences, body: preferences)
    }

    func updateProfile(_ user: User) async throws -> User {
        let updated: User = try await client.patch(.profile, body: user)
        cachedUser = updated
        return updated
    }

    func registerDeviceToken(_ token: String) async {
        struct Body: Encodable { let deviceToken: String }
        let _: EmptyResponse? = try? await client.post(.deviceToken, body: Body(deviceToken: token))
    }
}

private struct EmptyResponse: Decodable {}
