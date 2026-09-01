import Foundation
import Combine

@MainActor
final class ChatThreadViewModel: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published var draft = ""
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let thread: ChatThread
    private let chatRepository: ChatRepository
    private let currentUserID: () -> UUID?
    private var liveUpdatesCancellable: AnyCancellable?

    init(thread: ChatThread, chatRepository: ChatRepository, currentUserID: @escaping () -> UUID?) {
        self.thread = thread
        self.chatRepository = chatRepository
        self.currentUserID = currentUserID
    }

    /// Appends messages that arrive over the live WebSocket connection for this thread.
    /// No-op in mock mode, where `chatSocketService` is nil.
    func subscribeToLiveUpdates(_ service: ChatSocketService?) {
        guard let service else { return }
        let threadID = thread.id
        liveUpdatesCancellable = service.messagePublisher
            .filter { $0.threadID == threadID }
            .sink { [weak self] message in
                guard let self, !self.messages.contains(where: { $0.id == message.id }) else { return }
                self.messages.append(message)
            }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            messages = try await chatRepository.fetchMessages(threadID: thread.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func send() {
        let body = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty, let userID = currentUserID() else { return }
        draft = ""
        Task {
            do {
                let message = try await chatRepository.sendMessage(threadID: thread.id, senderID: userID, body: body)
                messages.append(message)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func isFromCurrentUser(_ message: ChatMessage) -> Bool {
        message.senderID == currentUserID()
    }
}
