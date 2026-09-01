import Foundation
@testable import Tailswipe

final class StubPetRepository: PetRepository {
    var feed: [Pet]
    private(set) var recordedSwipes: [(petID: UUID, decision: SwipeDecision)] = []

    init(feed: [Pet]) {
        self.feed = feed
    }

    func fetchFeed(preferences: AdoptionPreferences, near location: Location?) async throws -> [Pet] {
        feed
    }

    func fetchPet(id: UUID) async throws -> Pet {
        guard let pet = feed.first(where: { $0.id == id }) else { throw RepositoryError.notFound }
        return pet
    }

    func createListing(_ pet: Pet) async throws -> Pet {
        feed.append(pet)
        return pet
    }

    func recordSwipe(petID: UUID, decision: SwipeDecision) async throws {
        recordedSwipes.append((petID, decision))
        feed.removeAll { $0.id == petID }
    }

    func fetchInterestedPets() async throws -> [Pet] {
        []
    }

    func fetchMyListings(ownerID: UUID) async throws -> [Pet] {
        []
    }

    func updateListingStatus(petID: UUID, status: Pet.Status) async throws {
        guard let index = feed.firstIndex(where: { $0.id == petID }) else { return }
        feed[index].status = status
    }
}

enum TestFactory {
    static func pet(name: String, species: Pet.Species = .dog) -> Pet {
        Pet(
            id: UUID(),
            name: name,
            species: species,
            breed: ["Mix"],
            ageCategory: .young,
            ageMonths: nil,
            size: .medium,
            sex: .unknown,
            temperamentTags: [],
            description: "",
            photoURLs: [],
            location: Location(latitude: 0, longitude: 0, city: nil, region: nil),
            distanceMiles: nil,
            source: PetSource(type: .individual, label: nil),
            listedBy: PetLister(id: UUID(), displayName: "Tester", contactType: .individual),
            status: .available,
            createdAt: Date()
        )
    }
}
