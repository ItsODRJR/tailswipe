import SwiftUI

struct InterestsListView: View {
    @EnvironmentObject private var badgeCounts: BadgeCounts
    @StateObject private var viewModel: InterestsViewModel
    private let chatRepository: ChatRepository
    private let currentUserID: () -> UUID?

    init(petRepository: PetRepository, chatRepository: ChatRepository, currentUserID: @escaping () -> UUID?) {
        self.chatRepository = chatRepository
        self.currentUserID = currentUserID
        _viewModel = StateObject(wrappedValue: InterestsViewModel(
            petRepository: petRepository,
            chatRepository: chatRepository,
            currentUserID: currentUserID
        ))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Interests")
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
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.items.isEmpty {
            SkeletonListView()
        } else if let errorMessage = viewModel.errorMessage, viewModel.items.isEmpty {
            ErrorStateView(message: errorMessage) {
                Task { await viewModel.load() }
            }
        } else if viewModel.items.isEmpty {
            EmptyStateView(
                systemImage: "heart",
                title: "No interests yet",
                message: "Pets you swipe right on will show up here."
            )
        } else {
            List(viewModel.items) { item in
                InterestRowView(pet: item.pet, trailing: item.status == .accepted ? .matchedBadge : .pendingBadge)
                    .contentShape(Rectangle())
                    .opacity(item.status == .accepted ? 1 : 0.6)
                    .onTapGesture { viewModel.openChat(for: item) }
            }
            .listStyle(.plain)
        }
    }
}
