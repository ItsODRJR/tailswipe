import Foundation

@MainActor
final class MyListingsViewModel: ObservableObject {
    @Published private(set) var listings: [Pet] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let petRepository: PetRepository
    private let currentUserID: () -> UUID?

    init(petRepository: PetRepository, currentUserID: @escaping () -> UUID?) {
        self.petRepository = petRepository
        self.currentUserID = currentUserID
    }

    func load() async {
        guard let userID = currentUserID() else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            listings = try await petRepository.fetchMyListings(ownerID: userID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addListing(_ pet: Pet) async {
        do {
            _ = try await petRepository.createListing(pet)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markAdopted(_ pet: Pet) async {
        do {
            try await petRepository.updateListingStatus(petID: pet.id, status: .adopted)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
