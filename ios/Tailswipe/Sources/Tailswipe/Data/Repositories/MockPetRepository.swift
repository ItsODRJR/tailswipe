import Foundation

final class MockPetRepository: PetRepository {
    private let store: MockDataStore

    init(store: MockDataStore = .shared) {
        self.store = store
    }

    func fetchFeed(preferences: AdoptionPreferences, near location: Location?) async throws -> [Pet] {
        let alreadySwiped = store.currentUserID.flatMap { store.swipeRecords[$0] } ?? [:]

        var candidates = store.pets.filter { pet in
            pet.status == .available
                && pet.listedBy.id != store.currentUserID
                && alreadySwiped[pet.id] == nil
                && preferences.species.contains(pet.species)
                && preferences.ageCategories.contains(pet.ageCategory)
                && preferences.sizes.contains(pet.size)
                && (preferences.openToMedicalConditions || (pet.medicalConditions?.isEmpty ?? true))
        }

        if let breeds = preferences.breeds, !breeds.isEmpty {
            let breedSet = Set(breeds)
            candidates = candidates.filter { !Set($0.breed).isDisjoint(with: breedSet) }
        }

        if let tags = preferences.temperamentTags, !tags.isEmpty {
            let tagSet = Set(tags)
            candidates = candidates.filter { !Set($0.temperamentTags).isDisjoint(with: tagSet) }
        }

        candidates = candidates.map { pet in
            var pet = pet
            if let location {
                pet.distanceMiles = pet.location.distanceMiles(from: location)
            }
            return pet
        }

        if location != nil {
            candidates = candidates.filter { ($0.distanceMiles ?? .greatestFiniteMagnitude) <= preferences.maxDistanceMiles }
            candidates.sort { ($0.distanceMiles ?? .greatestFiniteMagnitude) < ($1.distanceMiles ?? .greatestFiniteMagnitude) }
        } else {
            candidates.sort { $0.createdAt > $1.createdAt }
        }

        return candidates
    }

    func fetchPet(id: UUID) async throws -> Pet {
        guard let pet = store.pets.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        return pet
    }

    func createListing(_ pet: Pet) async throws -> Pet {
        store.pets.insert(pet, at: 0)
        return pet
    }

    func recordSwipe(petID: UUID, decision: SwipeDecision) async throws {
        guard let userID = store.currentUserID else { throw RepositoryError.notAuthenticated }
        store.swipeRecords[userID, default: [:]][petID] = decision

        let expressedInterest = decision == .interested || decision == .superInterested
        if expressedInterest, let pet = store.pets.first(where: { $0.id == petID }) {
            let key = AdoptionRequest.key(petID: petID, adopterID: userID)
            if store.requests[key] == nil {
                store.requests[key] = AdoptionRequest(
                    id: key,
                    petID: petID,
                    adopterID: userID,
                    listerID: pet.listedBy.id,
                    status: .pending,
                    isSuper: decision == .superInterested,
                    createdAt: Date()
                )
            }
        }
    }

    func fetchInterestedPets() async throws -> [Pet] {
        guard let userID = store.currentUserID else { return [] }
        let interestedIDs = Set((store.swipeRecords[userID] ?? [:]).filter { $0.value == .interested || $0.value == .superInterested }.keys)
        return store.pets
            .filter { interestedIDs.contains($0.id) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func fetchMyListings(ownerID: UUID) async throws -> [Pet] {
        store.pets
            .filter { $0.listedBy.id == ownerID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func updateListingStatus(petID: UUID, status: Pet.Status) async throws {
        guard let index = store.pets.firstIndex(where: { $0.id == petID }) else {
            throw RepositoryError.notFound
        }
        store.pets[index].status = status
    }
}
