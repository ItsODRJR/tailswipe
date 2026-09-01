import Foundation

/// Route definitions matching the contract in docs/BACKEND_SPEC.md. Not wired to a real
/// server yet — the API* repositories build requests from these once `AppEnvironment`
/// is switched to `.live`.
enum APIEndpoint {
    case signUp
    case signIn
    case verifyEmail
    case resendVerification
    case feed(query: [URLQueryItem])
    case pet(id: UUID)
    case createPet
    case swipe(petID: UUID)
    case myInterests
    case myListings
    case preferences
    case profile
    case threads
    case messages(threadID: UUID)
    case requestStatus(petID: UUID, adopterID: UUID)
    case incomingRequests
    case respondToRequest(petID: UUID)
    case uploads
    case deviceToken

    var path: String {
        switch self {
        case .signUp: return "/auth/signup"
        case .signIn: return "/auth/signin"
        case .verifyEmail: return "/auth/verify-email"
        case .resendVerification: return "/auth/resend-verification"
        case .feed: return "/pets"
        case .pet(let id): return "/pets/\(id.uuidString)"
        case .createPet: return "/pets"
        case .swipe(let id): return "/pets/\(id.uuidString)/swipe"
        case .myInterests: return "/me/interests"
        case .myListings: return "/me/listings"
        case .preferences: return "/me/preferences"
        case .profile: return "/me/profile"
        case .threads: return "/threads"
        case .messages(let threadID): return "/threads/\(threadID.uuidString)/messages"
        case .requestStatus(let petID, let adopterID): return "/pets/\(petID.uuidString)/requests/\(adopterID.uuidString)"
        case .incomingRequests: return "/me/requests"
        case .respondToRequest(let petID): return "/pets/\(petID.uuidString)/requests/respond"
        case .uploads: return "/uploads"
        case .deviceToken: return "/me/device-token"
        }
    }

    var queryItems: [URLQueryItem] {
        if case .feed(let query) = self { return query }
        return []
    }
}
