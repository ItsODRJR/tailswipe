import SwiftUI

struct ChatThreadView: View {
    let pet: Pet
    @StateObject private var viewModel: ChatThreadViewModel
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    init(pet: Pet, thread: ChatThread, chatRepository: ChatRepository, currentUserID: @escaping () -> UUID?) {
        self.pet = pet
        _viewModel = StateObject(wrappedValue: ChatThreadViewModel(
            thread: thread,
            chatRepository: chatRepository,
            currentUserID: currentUserID
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            messageList
            composer
        }
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .task {
            await viewModel.load()
            viewModel.subscribeToLiveUpdates(environment.chatSocketService)
        }
    }

    @ViewBuilder
    private var messageList: some View {
        if viewModel.messages.isEmpty {
            EmptyStateView(
                systemImage: "bubble.left.and.bubble.right",
                title: "Say hello",
                message: "You're interested in \(pet.name). Send a message to \(pet.listedBy.displayName) to get started."
            )
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.messages) { message in
                        messageBubble(message)
                    }
                }
                .padding()
            }
        }
    }

    private var composer: some View {
        HStack {
            TextField("Message", text: $viewModel.draft, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            Button("Send") { viewModel.send() }
                .disabled(viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }

    private func messageBubble(_ message: ChatMessage) -> some View {
        let isMine = viewModel.isFromCurrentUser(message)
        return HStack {
            if isMine { Spacer(minLength: 40) }
            Text(message.body)
                .padding(10)
                .background(
                    isMine ? Color.accentColor : Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .foregroundStyle(isMine ? .white : .primary)
            if !isMine { Spacer(minLength: 40) }
        }
    }
}
