import Foundation

/// Turns picked photo bytes into a URL string usable in `Pet.photoURLs` /
/// `User.avatarImagePath`. Mock mode just writes to disk; live mode uploads to the backend.
protocol ImageUploadService {
    func upload(_ data: Data) async throws -> String
}

final class LocalImageUploadService: ImageUploadService {
    func upload(_ data: Data) async throws -> String {
        guard let url = ImageStorage.save(data) else { throw RepositoryError.notFound }
        return url.absoluteString
    }
}

final class RemoteImageUploadService: ImageUploadService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func upload(_ data: Data) async throws -> String {
        try await client.uploadImage(data)
    }
}
