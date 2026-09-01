import Foundation
import Combine

/// Maintains one live WebSocket connection to the backend (`/ws?token=...`) for the
/// duration of a signed-in session, and republishes incoming chat messages so any open
/// `ChatThreadViewModel` can append them without polling. Only used in `.live` mode —
/// mock mode has no server to connect to.
///
/// Deliberately not `@MainActor`: it's constructed from `AppEnvironment.init`, which runs
/// in a nonisolated context, so a main-actor-isolated initializer can't be called there.
/// The receive loop still hops onto the main actor explicitly before touching state or
/// publishing, since every caller (View `.task`/`.onReceive`) expects main-thread delivery.
final class ChatSocketService: ObservableObject {
    let messagePublisher = PassthroughSubject<ChatMessage, Never>()

    private let baseURL: URL
    private let tokenProvider: () -> String?
    private let session = URLSession(configuration: .default)
    private var task: URLSessionWebSocketTask?
    private var shouldReconnect = false

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init(baseURL: URL, tokenProvider: @escaping () -> String?) {
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
    }

    func connect() {
        shouldReconnect = true
        openSocket()
    }

    func disconnect() {
        shouldReconnect = false
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
    }

    private func openSocket() {
        guard let token = tokenProvider(),
              var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return }
        components.scheme = (components.scheme == "https") ? "wss" : "ws"
        components.path = "/ws"
        components.queryItems = [URLQueryItem(name: "token", value: token)]
        guard let url = components.url else { return }

        let newTask = session.webSocketTask(with: url)
        task = newTask
        newTask.resume()
        receiveLoop(on: newTask)
    }

    private func receiveLoop(on task: URLSessionWebSocketTask) {
        task.receive { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch result {
                case .success(let message):
                    if case .string(let text) = message, let data = text.data(using: .utf8) {
                        self.handle(data)
                    }
                    self.receiveLoop(on: task)
                case .failure:
                    self.handleDisconnect()
                }
            }
        }
    }

    private func handleDisconnect() {
        task = nil
        guard shouldReconnect else { return }
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard let self, self.shouldReconnect else { return }
            self.openSocket()
        }
    }

    private func handle(_ data: Data) {
        struct Envelope: Decodable { let type: String; let message: ChatMessage? }
        guard let envelope = try? decoder.decode(Envelope.self, from: data),
              envelope.type == "message", let message = envelope.message else { return }
        messagePublisher.send(message)
    }
}
