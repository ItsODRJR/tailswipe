import Foundation

/// Created when an adopter swipes right on a pet. Stays `.pending` until the pet's
/// lister reviews the adopter's profile on the Requests tab and accepts or declines —
/// only an `.accepted` request unlocks the chat thread between the two users.
struct AdoptionRequest: Identifiable, Codable, Equatable {
    enum Status: String, Codable {
        case pending, accepted, declined
    }

    var id: String
    var petID: UUID
    var adopterID: UUID
    var listerID: UUID
    var status: Status
    var isSuper: Bool = false
    var createdAt: Date

    static func key(petID: UUID, adopterID: UUID) -> String {
        "\(petID.uuidString)-\(adopterID.uuidString)"
    }
}

/// Denormalized view of a pending request for the lister's Requests tab: the adopter's
/// profile alongside the pet they're interested in, ready to render as a swipeable card.
struct AdoptionRequestInfo: Identifiable, Codable, Equatable {
    var id: String
    var pet: Pet
    var adopter: User
    var isSuper: Bool = false
    var createdAt: Date
}
