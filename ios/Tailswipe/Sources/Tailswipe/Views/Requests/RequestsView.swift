import SwiftUI

struct RequestsView: View {
    @EnvironmentObject private var badgeCounts: BadgeCounts
    @StateObject private var viewModel: RequestsViewModel
    private let chatRepository: ChatRepository
    private let currentUserID: () -> UUID?

    init(chatRepository: ChatRepository, currentUserID: @escaping () -> UUID?) {
        self.chatRepository = chatRepository
        self.currentUserID = currentUserID
        _viewModel = StateObject(wrappedValue: RequestsViewModel(
            chatRepository: chatRepository,
            currentUserID: currentUserID
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                content
                if !viewModel.requests.isEmpty {
                    actionButtons
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            .navigationTitle("Requests")
        }
        .task {
            await viewModel.load()
            await badgeCounts.refresh()
        }
        .refreshable {
            await viewModel.load()
            await badgeCounts.refresh()
        }
        .sheet(item: $viewModel.presentedChat) { presentation in
            NavigationStack {
                ChatThreadView(
                    pet: presentation.pet,
                    thread: presentation.thread,
                    chatRepository: chatRepository,
                    currentUserID: currentUserID
                )
            }
        }
        .fullScreenCover(item: $viewModel.matchCelebration) { celebration in
            MatchCelebrationView(
                pet: celebration.pet,
                adopter: celebration.adopter,
                onSendMessage: { viewModel.openChatFromCelebration() },
                onDismiss: { viewModel.matchCelebration = nil }
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.requests.isEmpty {
            SkeletonCardView().padding(.top, 8)
        } else if let errorMessage = viewModel.errorMessage, viewModel.requests.isEmpty {
            ErrorStateView(message: errorMessage) {
                Task { await viewModel.load() }
            }
        } else if viewModel.requests.isEmpty {
            EmptyStateView(
                systemImage: "person.crop.circle.badge.checkmark",
                title: "No pending requests",
                message: "People interested in adopting your listed pets will show up here to review."
            )
        } else {
            CardStackContainer(items: viewModel.requests, onSwipe: { info, decision in
                Task {
                    await viewModel.respond(info, accept: decision == .interested).value
                    await badgeCounts.refresh()
                }
            }) { info in
                AdopterProfileCardView(info: info)
            }
            .padding(.top, 8)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 32) {
            actionButton(systemImage: "xmark", color: .red) {
                guard let top = viewModel.requests.first else { return }
                Task {
                    await viewModel.respond(top, accept: false).value
                    await badgeCounts.refresh()
                }
            }
            actionButton(systemImage: "checkmark", color: .green) {
                guard let top = viewModel.requests.first else { return }
                Task {
                    await viewModel.respond(top, accept: true).value
                    await badgeCounts.refresh()
                }
            }
        }
    }

    private func actionButton(systemImage: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title2.bold())
                .foregroundStyle(color)
                .frame(width: 56, height: 56)
                .background(Color(.secondarySystemBackground), in: Circle())
                .shadow(radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}
