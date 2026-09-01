import Foundation

protocol ChatRepository {
    func fetchThreads(for userID: UUID) async throws -> [ChatThread]
    func fetchOrCreateThread(petID: UUID, participantUserID: UUID, listerID: UUID) async throws -> ChatThread
    func fetchMessages(threadID: UUID) async throws -> [ChatMessage]
    func sendMessage(threadID: UUID, senderID: UUID, body: String) async throws -> ChatMessage

    /// Status of a single adopter's interest in a pet, from the adopter's point of view.
    func fetchRequestStatus(petID: UUID, adopterID: UUID) async throws -> AdoptionRequest.Status?
    /// Pending requests from adopters interested in pets this lister owns.
    func fetchIncomingRequests(listerID: UUID) async throws -> [AdoptionRequestInfo]
    /// Lister accepts or declines an adopter's request. Accepting opens (and returns) the chat thread.
    func respondToRequest(petID: UUID, adopterID: UUID, listerID: UUID, accept: Bool) async throws -> ChatThread?
}
