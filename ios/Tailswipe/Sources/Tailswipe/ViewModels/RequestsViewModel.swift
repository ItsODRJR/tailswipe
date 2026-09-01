import Foundation

/// Backs the lister-facing Requests tab: people interested in adopting a pet you've
/// listed, shown as swipeable profile cards. Swiping right accepts (unlocking chat),
/// swiping left declines.
@MainActor
final class RequestsViewModel: ObservableObject {
    struct MatchCelebration: Identifiable {
        let id = UUID()
        let pet: Pet
        let adopter: User
        let thread: ChatThread
    }

    @Published private(set) var requests: [AdoptionRequestInfo] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var presentedChat: ChatPresentation?
    @Published var matchCelebration: MatchCelebration?

    private let chatRepository: ChatRepository
    private let currentUserID: () -> UUID?

    init(chatRepository: ChatRepository, currentUserID: @escaping () -> UUID?) {
        self.chatRepository = chatRepository
        self.currentUserID = currentUserID
    }

    func load() async {
        guard let userID = currentUserID() else {
            requests = []
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            requests = try await chatRepository.fetchIncomingRequests(listerID: userID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func respond(_ info: AdoptionRequestInfo, accept: Bool) -> Task<Void, Never> {
        requests.removeAll { $0.id == info.id }
        return Task {
            guard let userID = currentUserID() else { return }
            do {
                let thread = try await chatRepository.respondToRequest(
                    petID: info.pet.id,
                    adopterID: info.adopter.id,
                    listerID: userID,
                    accept: accept
                )
                if accept, let thread {
                    Haptics.match()
                    NotificationService.scheduleMatchNotification(
                        title: "It's a match!",
                        body: "You matched with \(info.adopter.displayName) about \(info.pet.name)."
                    )
                    matchCelebration = MatchCelebration(pet: info.pet, adopter: info.adopter, thread: thread)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func openChatFromCelebration() {
        guard let celebration = matchCelebration else { return }
        presentedChat = ChatPresentation(pet: celebration.pet, thread: celebration.thread)
        matchCelebration = nil
    }
}
