import Foundation

@MainActor
final class InterestsViewModel: ObservableObject {
    struct Item: Identifiable {
        var id: UUID { pet.id }
        let pet: Pet
        let status: AdoptionRequest.Status
    }

    @Published private(set) var items: [Item] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var presentedChat: ChatPresentation?

    private let petRepository: PetRepository
    private let chatRepository: ChatRepository
    private let currentUserID: () -> UUID?

    init(petRepository: PetRepository, chatRepository: ChatRepository, currentUserID: @escaping () -> UUID?) {
        self.petRepository = petRepository
        self.chatRepository = chatRepository
        self.currentUserID = currentUserID
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        guard let userID = currentUserID() else {
            items = []
            return
        }
        do {
            let pets = try await petRepository.fetchInterestedPets()
            var loaded: [Item] = []
            for pet in pets {
                let fetched = try? await chatRepository.fetchRequestStatus(petID: pet.id, adopterID: userID)
                let status: AdoptionRequest.Status = (fetched ?? nil) ?? .pending
                loaded.append(Item(pet: pet, status: status))
            }
            items = loaded
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func openChat(for item: Item) {
        guard item.status == .accepted, let userID = currentUserID() else { return }
        Task {
            do {
                let thread = try await chatRepository.fetchOrCreateThread(
                    petID: item.pet.id,
                    participantUserID: userID,
                    listerID: item.pet.listedBy.id
                )
                presentedChat = ChatPresentation(pet: item.pet, thread: thread)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
