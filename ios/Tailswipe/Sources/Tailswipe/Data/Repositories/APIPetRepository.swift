import Foundation

/// Talks to the real backend once `AppEnvironment` is switched to `.live`. Endpoints and
/// payload shapes follow docs/BACKEND_SPEC.md. Not exercised until that backend exists —
/// kept in lockstep with `PetRepository` so swapping from mock to live is a one-line change.
final class APIPetRepository: PetRepository {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchFeed(preferences: AdoptionPreferences, near location: Location?) async throws -> [Pet] {
        var query: [URLQueryItem] = [
            URLQueryItem(name: "species", value: preferences.species.map(\.rawValue).joined(separator: ",")),
            URLQueryItem(name: "ageCategories", value: preferences.ageCategories.map(\.rawValue).joined(separator: ",")),
            URLQueryItem(name: "sizes", value: preferences.sizes.map(\.rawValue).joined(separator: ",")),
            URLQueryItem(name: "maxDistanceMiles", value: String(preferences.maxDistanceMiles))
        ]
        if let breeds = preferences.breeds, !breeds.isEmpty {
            query.append(URLQueryItem(name: "breeds", value: breeds.joined(separator: ",")))
        }
        if let location {
            query.append(URLQueryItem(name: "lat", value: String(location.latitude)))
            query.append(URLQueryItem(name: "lng", value: String(location.longitude)))
        }
        return try await client.get(.feed(query: query))
    }

    func fetchPet(id: UUID) async throws -> Pet {
        try await client.get(.pet(id: id))
    }

    func createListing(_ pet: Pet) async throws -> Pet {
        try await client.post(.createPet, body: pet)
    }

    func recordSwipe(petID: UUID, decision: SwipeDecision) async throws {
        struct SwipeBody: Encodable { let decision: SwipeDecision }
        let _: EmptyResponse = try await client.post(.swipe(petID: petID), body: SwipeBody(decision: decision))
    }

    func fetchInterestedPets() async throws -> [Pet] {
        try await client.get(.myInterests)
    }

    func fetchMyListings(ownerID: UUID) async throws -> [Pet] {
        try await client.get(.myListings)
    }

    func updateListingStatus(petID: UUID, status: Pet.Status) async throws {
        struct Body: Encodable { let status: Pet.Status }
        let _: EmptyResponse = try await client.patch(.pet(id: petID), body: Body(status: status))
    }
}

private struct EmptyResponse: Decodable {}
