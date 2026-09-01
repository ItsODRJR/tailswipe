import Foundation

struct User: Identifiable, Codable, Equatable {
    var id: UUID
    var email: String
    var displayName: String
    var location: Location?
    var bio: String? = nil
    /// Local file:// path to a picked profile photo. There's no real upload backend yet,
    /// so this just points at a file written into the app's Documents directory.
    var avatarImagePath: String? = nil
    var createdAt: Date
}
