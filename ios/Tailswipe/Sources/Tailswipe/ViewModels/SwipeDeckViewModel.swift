import Foundation

@MainActor
final class SwipeDeckViewModel: ObservableObject {
    @Published private(set) var pets: [Pet] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    /// Text for a brief toast shown after an "interested"/"super interested" swipe. A right
    /// swipe no longer opens chat directly — it creates a pending request that the pet's
    /// lister has to accept from the Requests tab first.
    @Published var interestSentMessage: String?

    private let petRepository: PetRepository
    private let locationService: LocationService
    private var preferences: AdoptionPreferences
    private let currentUserID: () -> UUID?

    init(
        petRepository: PetRepository,
        locationService: LocationService,
        preferences: AdoptionPreferences,
        currentUserID: @escaping () -> UUID?
    ) {
        self.petRepository = petRepository
        self.locationService = locationService
        self.preferences = preferences
        self.currentUserID = currentUserID

        // Permission is requested asynchronously (the system prompt takes a moment for the
        // user to respond to), so the very first `loadFeed()` often runs before a GPS fix
        // exists. Re-fetch once a real location arrives so distance filtering/sorting kicks
        // in without the user having to manually pull-to-refresh.
        locationService.onLocationUpdate = { [weak self] _ in
            Task { await self?.loadFeed() }
        }
    }

    func updatePreferences(_ preferences: AdoptionPreferences) {
        self.preferences = preferences
        Task { await loadFeed() }
    }

    func loadFeed() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            pets = try await petRepository.fetchFeed(preferences: preferences, near: locationService.currentLocation)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Returns the underlying `Task` (discardable in normal UI use) so tests can await
    /// completion of the fire-and-forget record work.
    @discardableResult
    func swipe(_ pet: Pet, decision: SwipeDecision) -> Task<Void, Never> {
        pets.removeAll { $0.id == pet.id }
        return Task {
            do {
                try await petRepository.recordSwipe(petID: pet.id, decision: decision)
                switch decision {
                case .interested:
                    showToast("💌 Interest sent for \(pet.name)!")
                case .superInterested:
                    showToast("⭐ Super interest sent for \(pet.name)!")
                case .passed:
                    break
                }
                if pets.count < 3 {
                    await loadMore()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func showToast(_ message: String) {
        interestSentMessage = message
        Task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            if interestSentMessage == message {
                interestSentMessage = nil
            }
        }
    }

    /// Mock feed re-fetches the whole filtered/sorted set and appends anything not
    /// already on screen; the real API will page here instead once it exists.
    private func loadMore() async {
        guard let fresh = try? await petRepository.fetchFeed(preferences: preferences, near: locationService.currentLocation) else {
            return
        }
        let existingIDs = Set(pets.map(\.id))
        pets.append(contentsOf: fresh.filter { !existingIDs.contains($0.id) })
    }
}
