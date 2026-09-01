import SwiftUI

@main
struct TailswipeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var environment: AppEnvironment
    @StateObject private var appState: AppState
    @StateObject private var badgeCounts: BadgeCounts

    init() {
        let environment = AppEnvironment(mode: .live(baseURL: URL(string: "https://api.tailswipe.app")!))
        _environment = StateObject(wrappedValue: environment)
        let appState = AppState(userRepository: environment.userRepository)
        _appState = StateObject(wrappedValue: appState)
        _badgeCounts = StateObject(wrappedValue: BadgeCounts(
            petRepository: environment.petRepository,
            chatRepository: environment.chatRepository,
            currentUserID: { appState.currentUser?.id }
        ))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(environment)
                .environmentObject(appState)
                .environmentObject(badgeCounts)
                .task { NotificationService.requestPermissionIfNeeded() }
        }
    }
}
