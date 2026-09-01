import XCTest
@testable import Tailswipe

@MainActor
final class SwipeDeckViewModelTests: XCTestCase {
    func testSwipeRemovesPetFromDeckAndRecordsDecision() async throws {
        let pet = TestFactory.pet(name: "Test Pup")
        let petRepo = StubPetRepository(feed: [pet])
        let viewModel = SwipeDeckViewModel(
            petRepository: petRepo,
            locationService: MockLocationService(currentLocation: nil),
            preferences: .default,
            currentUserID: { UUID() }
        )
        await viewModel.loadFeed()
        XCTAssertEqual(viewModel.pets.count, 1)

        await viewModel.swipe(pet, decision: .passed).value

        XCTAssertTrue(viewModel.pets.isEmpty)
        XCTAssertEqual(petRepo.recordedSwipes.first?.decision, .passed)
    }

    func testInterestedSwipeRecordsInterestWithoutOpeningChat() async throws {
        let pet = TestFactory.pet(name: "Test Pup")
        let petRepo = StubPetRepository(feed: [pet])
        let userID = UUID()
        let viewModel = SwipeDeckViewModel(
            petRepository: petRepo,
            locationService: MockLocationService(currentLocation: nil),
            preferences: .default,
            currentUserID: { userID }
        )
        await viewModel.loadFeed()

        await viewModel.swipe(pet, decision: .interested).value

        XCTAssertEqual(petRepo.recordedSwipes.first?.decision, .interested)
        XCTAssertEqual(viewModel.interestSentMessage, "💌 Interest sent for Test Pup!")
    }
}
