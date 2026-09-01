import Foundation

final class MockChatRepository: ChatRepository {
    private let store: MockDataStore

    init(store: MockDataStore = .shared) {
        self.store = store
    }

    func fetchThreads(for userID: UUID) async throws -> [ChatThread] {
        store.threads
            .filter { $0.participantUserID == userID }
            .sorted { ($0.lastMessageAt ?? $0.createdAt) > ($1.lastMessageAt ?? $1.createdAt) }
    }

    func fetchOrCreateThread(petID: UUID, participantUserID: UUID, listerID: UUID) async throws -> ChatThread {
        if let existing = store.threads.first(where: { $0.petID == petID && $0.participantUserID == participantUserID }) {
            return existing
        }
        let thread = ChatThread(
            id: UUID(),
            petID: petID,
            participantUserID: participantUserID,
            listerID: listerID,
            createdAt: Date(),
            lastMessagePreview: nil,
            lastMessageAt: nil
        )
        store.threads.append(thread)
        store.messages[thread.id] = []
        return thread
    }

    func fetchMessages(threadID: UUID) async throws -> [ChatMessage] {
        store.messages[threadID] ?? []
    }

    func sendMessage(threadID: UUID, senderID: UUID, body: String) async throws -> ChatMessage {
        let message = ChatMessage(id: UUID(), threadID: threadID, senderID: senderID, body: body, sentAt: Date())
        store.messages[threadID, default: []].append(message)
        if let index = store.threads.firstIndex(where: { $0.id == threadID }) {
            store.threads[index].lastMessagePreview = body
            store.threads[index].lastMessageAt = message.sentAt
        }
        return message
    }

    func fetchRequestStatus(petID: UUID, adopterID: UUID) async throws -> AdoptionRequest.Status? {
        store.requests[AdoptionRequest.key(petID: petID, adopterID: adopterID)]?.status
    }

    func fetchIncomingRequests(listerID: UUID) async throws -> [AdoptionRequestInfo] {
        store.requests.values
            .filter { $0.listerID == listerID && $0.status == .pending }
            .compactMap { request -> AdoptionRequestInfo? in
                guard let pet = store.pets.first(where: { $0.id == request.petID }),
                      let adopter = store.users[request.adopterID] else { return nil }
                return AdoptionRequestInfo(id: request.id, pet: pet, adopter: adopter, isSuper: request.isSuper, createdAt: request.createdAt)
            }
            .sorted { lhs, rhs in
                if lhs.isSuper != rhs.isSuper { return lhs.isSuper }
                return lhs.createdAt > rhs.createdAt
            }
    }

    func respondToRequest(petID: UUID, adopterID: UUID, listerID: UUID, accept: Bool) async throws -> ChatThread? {
        let key = AdoptionRequest.key(petID: petID, adopterID: adopterID)
        guard var request = store.requests[key] else { return nil }
        request.status = accept ? .accepted : .declined
        store.requests[key] = request
        guard accept else { return nil }
        return try await fetchOrCreateThread(petID: petID, participantUserID: adopterID, listerID: listerID)
    }
}
