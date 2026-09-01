import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case server(statusCode: Int, message: String?)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid request URL."
        case .invalidResponse: return "Received an unexpected response from the server."
        case .server(let statusCode, let message): return message ?? "Server error (\(statusCode))."
        case .decoding: return "Couldn't read the server's response."
        }
    }
}
