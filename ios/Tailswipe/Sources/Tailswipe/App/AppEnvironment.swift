import Foundation

/// Single seam that decides whether the app runs against mock or live data.
/// Swap in `.live` once the backend exists (see docs/BACKEND_SPEC.md) — no ViewModel
/// or View code needs to change, since everything depends on the repository protocols.
enum DataMode {
    case mock
    case live(baseURL: URL)
}

final class AppEnvironment: ObservableObject {
    let petRepository: PetRepository
    let userRepository: UserRepository
    let chatRepository: ChatRepository
    let locationService: LocationService
    let imageUploadService: ImageUploadService
    let chatSocketService: ChatSocketService?

    init(mode: DataMode = .mock) {
        switch mode {
        case .mock:
            let store = MockDataStore.shared
            petRepository = MockPetRepository(store: store)
            userRepository = MockUserRepository(store: store)
            chatRepository = MockChatRepository(store: store)
            // Pets/users/chat are mocked, but location is real — there's no reason to fake
            // GPS on a physical device, and the "Use My Location" button is meaningless
            // otherwise.
            locationService = CoreLocationService()
            imageUploadService = LocalImageUploadService()
            chatSocketService = nil
        case .live(let baseURL):
            let client = APIClient(baseURL: baseURL)
            petRepository = APIPetRepository(client: client)
            userRepository = APIUserRepository(client: client)
            chatRepository = APIChatRepository(client: client)
            locationService = CoreLocationService()
            imageUploadService = RemoteImageUploadService(client: client)
            chatSocketService = ChatSocketService(baseURL: baseURL, tokenProvider: { client.authToken })
        }
    }
}
