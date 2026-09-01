import SwiftUI

struct SwipeDeckView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: SwipeDeckViewModel

    init(
        petRepository: PetRepository,
        locationService: LocationService,
        preferences: AdoptionPreferences,
        currentUserID: @escaping () -> UUID?
    ) {
        _viewModel = StateObject(wrappedValue: SwipeDeckViewModel(
            petRepository: petRepository,
            locationService: locationService,
            preferences: preferences,
            currentUserID: currentUserID
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                quickFilters
                content
                if !viewModel.pets.isEmpty {
                    actionButtons
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            .navigationTitle("Discover")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        EditPreferencesView()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .overlay(alignment: .top) {
                if let message = viewModel.interestSentMessage {
                    Text(message)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.thinMaterial, in: Capsule())
                        .shadow(radius: 4, y: 2)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.interestSentMessage)
        }
        .task {
            await viewModel.loadFeed()
        }
        .onChange(of: appState.preferences) { _, newValue in
            viewModel.updatePreferences(newValue)
        }
    }

    private var quickFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Pet.Species.allCases) { species in
                    FilterChip(title: species.displayName, isSelected: appState.preferences.species.contains(species)) {
                        toggleSpecies(species)
                    }
                }
                Divider().frame(height: 20)
                ForEach([5.0, 25.0, 50.0, 100.0], id: \.self) { miles in
                    FilterChip(title: "\(Int(miles)) mi", isSelected: appState.preferences.maxDistanceMiles == miles) {
                        setDistance(miles)
                    }
                }
            }
        }
    }

    private func toggleSpecies(_ species: Pet.Species) {
        var prefs = appState.preferences
        if prefs.species.contains(species) {
            guard prefs.species.count > 1 else { return }
            prefs.species.removeAll { $0 == species }
        } else {
            prefs.species.append(species)
        }
        Task { await appState.updatePreferences(prefs) }
    }

    private func setDistance(_ miles: Double) {
        var prefs = appState.preferences
        prefs.maxDistanceMiles = miles
        Task { await appState.updatePreferences(prefs) }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.pets.isEmpty {
            SkeletonCardView().padding(.top, 8)
        } else if let errorMessage = viewModel.errorMessage, viewModel.pets.isEmpty {
            ErrorStateView(message: errorMessage) {
                Task { await viewModel.loadFeed() }
            }
        } else if viewModel.pets.isEmpty {
            EmptyStateView(
                systemImage: "pawprint",
                title: "No pets match right now",
                message: "Try widening your distance or adjusting your filters."
            )
        } else {
            CardStackContainer(items: viewModel.pets, onSwipe: { pet, decision in
                viewModel.swipe(pet, decision: decision)
            }) { pet in
                PetCardView(pet: pet)
            }
            .padding(.top, 8)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 24) {
            actionButton(systemImage: "xmark", color: .red, size: 56) {
                if let top = viewModel.pets.first {
                    viewModel.swipe(top, decision: .passed)
                }
            }
            actionButton(systemImage: "star.fill", color: .blue, size: 44) {
                if let top = viewModel.pets.first {
                    viewModel.swipe(top, decision: .superInterested)
                }
            }
            actionButton(systemImage: "heart.fill", color: .green, size: 56) {
                if let top = viewModel.pets.first {
                    viewModel.swipe(top, decision: .interested)
                }
            }
        }
    }

    private func actionButton(systemImage: String, color: Color, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title2.bold())
                .foregroundStyle(color)
                .frame(width: size, height: size)
                .background(Color(.secondarySystemBackground), in: Circle())
                .shadow(radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}
