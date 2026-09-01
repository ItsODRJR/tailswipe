import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    var id: UUID
    var threadID: UUID
    var senderID: UUID
    var body: String
    var sentAt: Date
}
