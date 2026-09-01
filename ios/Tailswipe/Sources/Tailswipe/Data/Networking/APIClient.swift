import Foundation

/// Thin URLSession wrapper used only by the API* repositories once the app is switched
/// to `.live` mode. Not exercised by the MVP build — see docs/BACKEND_SPEC.md for the
/// contract this is built against.
final class APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    var authToken: String?

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    func get<Response: Decodable>(_ endpoint: APIEndpoint) async throws -> Response {
        try await send(endpoint: endpoint, method: "GET", body: Optional<EmptyBody>.none)
    }

    func post<Response: Decodable>(_ endpoint: APIEndpoint) async throws -> Response {
        try await send(endpoint: endpoint, method: "POST", body: Optional<EmptyBody>.none)
    }

    func post<Body: Encodable, Response: Decodable>(_ endpoint: APIEndpoint, body: Body) async throws -> Response {
        try await send(endpoint: endpoint, method: "POST", body: body)
    }

    func patch<Body: Encodable, Response: Decodable>(_ endpoint: APIEndpoint, body: Body) async throws -> Response {
        try await send(endpoint: endpoint, method: "PATCH", body: body)
    }

    /// Uploads raw image bytes as multipart/form-data (field name "photo") and returns the
    /// public URL the server stored it at.
    func uploadImage(_ data: Data, filename: String = "photo.jpg") async throws -> String {
        guard let url = URL(string: APIEndpoint.uploads.path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (responseData, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.server(statusCode: httpResponse.statusCode, message: String(data: responseData, encoding: .utf8))
        }
        struct UploadResponse: Decodable { let url: String }
        do {
            return try decoder.decode(UploadResponse.self, from: responseData).url
        } catch {
            throw APIError.decoding(error)
        }
    }

    private func send<Body: Encodable, Response: Decodable>(
        endpoint: APIEndpoint,
        method: String,
        body: Body?
    ) async throws -> Response {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidURL
        }
        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }
        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.server(statusCode: httpResponse.statusCode, message: String(data: data, encoding: .utf8))
        }
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}

private struct EmptyBody: Encodable {}
