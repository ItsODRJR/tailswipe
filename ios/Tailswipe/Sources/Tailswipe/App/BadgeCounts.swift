import Foundation

/// Lightweight counts shown as tab-bar badges: pending requests waiting for the current
/// user (as a lister) to review, and matched interests (as an adopter) they haven't
/// necessarily opened chat for yet. Refreshed by the Requests/Interests screens whenever
/// they load or after an action changes the underlying counts.
@MainActor
final class BadgeCounts: ObservableObject {
    @Published var pendingRequestsCount = 0
    @Published var matchedInterestsCount = 0

    private let petRepository: PetRepository
    private let chatRepository: ChatRepository
    private let currentUserID: () -> UUID?

    init(petRepository: PetRepository, chatRepository: ChatRepository, currentUserID: @escaping () -> UUID?) {
        self.petRepository = petRepository
        self.chatRepository = chatRepository
        self.currentUserID = currentUserID
    }

    func refresh() async {
        guard let userID = currentUserID() else {
            pendingRequestsCount = 0
            matchedInterestsCount = 0
            return
        }

        let incoming = (try? await chatRepository.fetchIncomingRequests(listerID: userID)) ?? []
        pendingRequestsCount = incoming.count

        let interestedPets = (try? await petRepository.fetchInterestedPets()) ?? []
        var matched = 0
        for pet in interestedPets {
            if let status = try? await chatRepository.fetchRequestStatus(petID: pet.id, adopterID: userID), status == .accepted {
                matched += 1
            }
        }
        matchedInterestsCount = matched
    }
}
