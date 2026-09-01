import Foundation

/// Writes picked photo data into the app's Documents directory. Backs `LocalImageUploadService`
/// for mock-data mode, where there's no real server to upload to — photos are just local
/// files referenced by a `file://` URL, which works fine with `AsyncImage`.
enum ImageStorage {
    @discardableResult
    static func save(_ data: Data) -> URL? {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = directory.appendingPathComponent(UUID().uuidString + ".jpg")
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
}
