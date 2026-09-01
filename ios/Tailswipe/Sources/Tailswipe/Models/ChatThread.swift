import Foundation

struct ChatThread: Identifiable, Codable, Equatable {
    var id: UUID
    var petID: UUID
    var participantUserID: UUID
    var listerID: UUID
    var createdAt: Date
    var lastMessagePreview: String?
    var lastMessageAt: Date?
}
