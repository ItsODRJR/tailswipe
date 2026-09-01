import Foundation

final class APIChatRepository: ChatRepository {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchThreads(for userID: UUID) async throws -> [ChatThread] {
        try await client.get(.threads)
    }

    func fetchOrCreateThread(petID: UUID, participantUserID: UUID, listerID: UUID) async throws -> ChatThread {
        struct Body: Encodable { let petID: UUID }
        return try await client.post(.threads, body: Body(petID: petID))
    }

    func fetchMessages(threadID: UUID) async throws -> [ChatMessage] {
        try await client.get(.messages(threadID: threadID))
    }

    func sendMessage(threadID: UUID, senderID: UUID, body: String) async throws -> ChatMessage {
        struct Body: Encodable { let body: String }
        return try await client.post(.messages(threadID: threadID), body: Body(body: body))
    }

    func fetchRequestStatus(petID: UUID, adopterID: UUID) async throws -> AdoptionRequest.Status? {
        struct Response: Decodable { let status: AdoptionRequest.Status? }
        let response: Response = try await client.get(.requestStatus(petID: petID, adopterID: adopterID))
        return response.status
    }

    func fetchIncomingRequests(listerID: UUID) async throws -> [AdoptionRequestInfo] {
        try await client.get(.incomingRequests)
    }

    func respondToRequest(petID: UUID, adopterID: UUID, listerID: UUID, accept: Bool) async throws -> ChatThread? {
        struct Body: Encodable { let adopterID: UUID; let accept: Bool }
        struct Response: Decodable { let thread: ChatThread? }
        let response: Response = try await client.post(.respondToRequest(petID: petID), body: Body(adopterID: adopterID, accept: accept))
        return response.thread
    }
}
