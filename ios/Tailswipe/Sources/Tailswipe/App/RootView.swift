import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        Group {
            if appState.isLoading {
                ProgressView()
            } else if appState.currentUser == nil {
                AuthFlowView(userRepository: environment.userRepository)
            } else if !appState.hasCompletedOnboarding {
                PreferencesSetupView(mode: .onboarding)
            } else {
                MainTabView()
            }
        }
        .task {
            await appState.bootstrap()
        }
        .onChange(of: appState.currentUser?.id) { _, newValue in
            if newValue == nil {
                environment.chatSocketService?.disconnect()
            }
        }
    }
}
