import UIKit
import Combine

/// Bridges the UIKit device-token callback (fires once per launch, often before SwiftUI's
/// environment/auth state is ready) to whoever wants it. A `CurrentValueSubject` replays
/// the last token to a late subscriber, so registration isn't lost to timing.
final class PushTokenStore {
    static let shared = PushTokenStore()
    let tokenSubject = CurrentValueSubject<String?, Never>(nil)
    private init() {}
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenHex = deviceToken.map { String(format: "%02x", $0) }.joined()
        PushTokenStore.shared.tokenSubject.send(tokenHex)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
}
