import Foundation

/// Everything the app needs from "pets" as a data source. `MockPetRepository` backs this
/// with in-memory data today; `APIPetRepository` will back it with the real server later —
/// see docs/BACKEND_SPEC.md for the wire contract. ViewModels only ever depend on this
/// protocol, never on a concrete implementation.
protocol PetRepository {
    func fetchFeed(preferences: AdoptionPreferences, near location: Location?) async throws -> [Pet]
    func fetchPet(id: UUID) async throws -> Pet
    func createListing(_ pet: Pet) async throws -> Pet
    func recordSwipe(petID: UUID, decision: SwipeDecision) async throws
    func fetchInterestedPets() async throws -> [Pet]
    func fetchMyListings(ownerID: UUID) async throws -> [Pet]
    func updateListingStatus(petID: UUID, status: Pet.Status) async throws
}
