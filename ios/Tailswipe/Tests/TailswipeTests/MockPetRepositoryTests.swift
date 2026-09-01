import XCTest
@testable import Tailswipe

final class MockPetRepositoryTests: XCTestCase {
    private var store: MockDataStore!
    private var repository: MockPetRepository!

    override func setUp() {
        super.setUp()
        store = MockDataStore.shared
        store.pets = MockSeedData.samplePets
        store.currentUserID = MockSeedData.demoUser.id
        store.swipeRecords[MockSeedData.demoUser.id] = [:]
        repository = MockPetRepository(store: store)
    }

    func testFeedFiltersBySpecies() async throws {
        var prefs = AdoptionPreferences.default
        prefs.species = [.cat]
        let feed = try await repository.fetchFeed(preferences: prefs, near: nil)
        XCTAssertFalse(feed.isEmpty)
        XCTAssertTrue(feed.allSatisfy { $0.species == .cat })
    }

    func testFeedFiltersByMaxDistance() async throws {
        var prefs = AdoptionPreferences.default
        prefs.maxDistanceMiles = 5
        let origin = try XCTUnwrap(MockSeedData.demoUser.location)
        let feed = try await repository.fetchFeed(preferences: prefs, near: origin)
        XCTAssertTrue(feed.allSatisfy { ($0.distanceMiles ?? .greatestFiniteMagnitude) <= 5 })
    }

    func testFeedSortsByDistanceAscending() async throws {
        let prefs = AdoptionPreferences.default
        let origin = try XCTUnwrap(MockSeedData.demoUser.location)
        let feed = try await repository.fetchFeed(preferences: prefs, near: origin)
        let distances = feed.compactMap(\.distanceMiles)
        XCTAssertEqual(distances, distances.sorted())
    }

    func testRecordSwipeExcludesPetFromFutureFeed() async throws {
        let prefs = AdoptionPreferences.default
        let firstFeed = try await repository.fetchFeed(preferences: prefs, near: nil)
        let firstPet = try XCTUnwrap(firstFeed.first)

        try await repository.recordSwipe(petID: firstPet.id, decision: .passed)

        let secondFeed = try await repository.fetchFeed(preferences: prefs, near: nil)
        XCTAssertFalse(secondFeed.contains { $0.id == firstPet.id })
    }

    func testInterestedSwipeAppearsInInterestedPets() async throws {
        let prefs = AdoptionPreferences.default
        let feed = try await repository.fetchFeed(preferences: prefs, near: nil)
        let pet = try XCTUnwrap(feed.first)

        try await repository.recordSwipe(petID: pet.id, decision: .interested)

        let interested = try await repository.fetchInterestedPets()
        XCTAssertTrue(interested.contains { $0.id == pet.id })
    }
}
