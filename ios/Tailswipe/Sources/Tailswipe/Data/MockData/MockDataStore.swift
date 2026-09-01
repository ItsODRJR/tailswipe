import Foundation

/// In-memory stand-in for a shared backend. Every Mock*Repository reads and writes
/// through this one shared instance so state (swipes, new listings, messages) stays
/// consistent across the app, the same way a real server's database would.
final class MockDataStore {
    static let shared = MockDataStore()

    var pets: [Pet] = []
    var users: [UUID: User] = [:]
    var credentials: [String: String] = [:]
    var preferences: [UUID: AdoptionPreferences] = [:]
    /// userID -> petID -> decision
    var swipeRecords: [UUID: [UUID: SwipeDecision]] = [:]
    var threads: [ChatThread] = []
    var messages: [UUID: [ChatMessage]] = [:]
    /// AdoptionRequest.key(petID:adopterID:) -> request
    var requests: [String: AdoptionRequest] = [:]
    /// No session by default so the app boots to the landing/sign-in page. The demo
    /// account's credentials (below) are printed on the sign-in screen for quick access.
    var currentUserID: UUID?

    private init() {
        seedFreshState()
    }

    /// Wipes every in-memory table back to its initial seeded state and signs out.
    /// Backs the "Reset Demo Data" button in Settings.
    func reset() {
        seedFreshState()
    }

    private func seedFreshState() {
        pets = MockSeedData.samplePets
        users = [:]
        credentials = [:]
        preferences = [:]
        swipeRecords = [:]
        threads = []
        messages = [:]
        requests = [:]
        currentUserID = nil

        let demo = MockSeedData.demoUser
        users[demo.id] = demo
        credentials[demo.email] = "password123"
        preferences[demo.id] = .default

        for adopter in MockSeedData.sampleAdopters {
            users[adopter.id] = adopter
        }

        if let ownListing = pets.first(where: { $0.listedBy.id == demo.id }) {
            for adopter in MockSeedData.sampleAdopters {
                let key = AdoptionRequest.key(petID: ownListing.id, adopterID: adopter.id)
                requests[key] = AdoptionRequest(
                    id: key,
                    petID: ownListing.id,
                    adopterID: adopter.id,
                    listerID: demo.id,
                    status: .pending,
                    createdAt: Date()
                )
            }
        }
    }
}
