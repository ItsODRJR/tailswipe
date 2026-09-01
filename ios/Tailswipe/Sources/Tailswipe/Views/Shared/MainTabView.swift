import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var badgeCounts: BadgeCounts

    var body: some View {
        TabView {
            SwipeDeckView(
                petRepository: environment.petRepository,
                locationService: environment.locationService,
                preferences: appState.preferences,
                currentUserID: { appState.currentUser?.id }
            )
            .tabItem { Label("Discover", systemImage: "heart.circle") }

            InterestsListView(
                petRepository: environment.petRepository,
                chatRepository: environment.chatRepository,
                currentUserID: { appState.currentUser?.id }
            )
            .tabItem { Label("Interests", systemImage: "bubble.left.and.bubble.right") }
            .badge(badgeCounts.matchedInterestsCount)

            MyListingsView(
                petRepository: environment.petRepository,
                currentUserID: { appState.currentUser?.id }
            )
            .tabItem { Label("My Listings", systemImage: "pawprint") }

            RequestsView(
                chatRepository: environment.chatRepository,
                currentUserID: { appState.currentUser?.id }
            )
            .tabItem { Label("Requests", systemImage: "person.crop.circle.badge.checkmark") }
            .badge(badgeCounts.pendingRequestsCount)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle") }
        }
        .task {
            await badgeCounts.refresh()
            environment.locationService.requestPermission()
            environment.locationService.startUpdating()
            environment.chatSocketService?.connect()
        }
        .onReceive(PushTokenStore.shared.tokenSubject.compactMap { $0 }) { token in
            Task { await environment.userRepository.registerDeviceToken(token) }
        }
    }
}
