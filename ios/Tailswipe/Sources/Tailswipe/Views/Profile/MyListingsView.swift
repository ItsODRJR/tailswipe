import SwiftUI

struct MyListingsView: View {
    @StateObject private var viewModel: MyListingsViewModel
    @State private var isPresentingAddPet = false
    @State private var pendingAdoptionPet: Pet?

    init(petRepository: PetRepository, currentUserID: @escaping () -> UUID?) {
        _viewModel = StateObject(wrappedValue: MyListingsViewModel(
            petRepository: petRepository,
            currentUserID: currentUserID
        ))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("My Listings")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isPresentingAddPet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .sheet(isPresented: $isPresentingAddPet) {
            NavigationStack {
                AddPetListingView { pet in
                    Task { await viewModel.addListing(pet) }
                }
            }
        }
        .confirmationDialog(
            "Mark \(pendingAdoptionPet?.name ?? "this pet") as adopted?",
            isPresented: Binding(
                get: { pendingAdoptionPet != nil },
                set: { if !$0 { pendingAdoptionPet = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Mark Adopted") {
                if let pet = pendingAdoptionPet {
                    Task { await viewModel.markAdopted(pet) }
                }
                pendingAdoptionPet = nil
            }
            Button("Cancel", role: .cancel) { pendingAdoptionPet = nil }
        } message: {
            Text("This removes them from everyone's Discover deck.")
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.listings.isEmpty {
            SkeletonListView()
        } else if let errorMessage = viewModel.errorMessage, viewModel.listings.isEmpty {
            ErrorStateView(message: errorMessage) {
                Task { await viewModel.load() }
            }
        } else if viewModel.listings.isEmpty {
            EmptyStateView(
                systemImage: "pawprint.circle",
                title: "No listings yet",
                message: "Tap + to list a pet you're rehoming."
            )
        } else {
            List(viewModel.listings) { pet in
                InterestRowView(pet: pet, trailing: pet.status == .adopted ? .adoptedBadge : .chatIcon)
                    .swipeActions(edge: .trailing) {
                        if pet.status != .adopted {
                            Button("Mark Adopted") {
                                pendingAdoptionPet = pet
                            }
                            .tint(.green)
                        }
                    }
            }
            .listStyle(.plain)
        }
    }
}
