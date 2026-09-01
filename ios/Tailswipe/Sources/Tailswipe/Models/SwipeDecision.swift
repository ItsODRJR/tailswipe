import Foundation

enum SwipeDecision: String, Codable {
    case interested
    /// Stronger signal than a plain right swipe — bumps the request to the top of the
    /// lister's Requests queue.
    case superInterested
    case passed
}

struct SwipeRecord: Identifiable, Codable, Equatable {
    var id: UUID
    var petID: UUID
    var decision: SwipeDecision
    var decidedAt: Date
}
