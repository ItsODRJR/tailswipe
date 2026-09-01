import Foundation

enum RepositoryError: LocalizedError {
    case notFound
    case notAuthenticated
    case invalidCredentials
    case emailAlreadyInUse

    var errorDescription: String? {
        switch self {
        case .notFound: return "That pet could not be found."
        case .notAuthenticated: return "You need to be signed in to do that."
        case .invalidCredentials: return "Incorrect email or password."
        case .emailAlreadyInUse: return "An account with that email already exists."
        }
    }
}
