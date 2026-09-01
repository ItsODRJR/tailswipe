import SwiftUI

/// Thin wrapper so callers (e.g. the swipe deck toolbar) can push preference editing
/// without needing to know the current preferences ahead of time.
struct EditPreferencesView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        PreferencesSetupView(mode: .edit, initialPreferences: appState.preferences)
    }
}
