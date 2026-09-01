import Foundation

/// Opt-in capability for repositories backed by in-memory demo data. `ProfileView` checks
/// for this via `as?` so the "Reset Demo Data" button only appears in mock mode — a live
/// `APIUserRepository` simply won't conform.
protocol DemoResettable {
    func resetDemoData() async
}

extension MockUserRepository: DemoResettable {
    func resetDemoData() async {
        store.reset()
    }
}
