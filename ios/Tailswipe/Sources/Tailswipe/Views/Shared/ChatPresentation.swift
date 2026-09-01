import Foundation

/// Sheet-presentation wrapper so `.sheet(item:)` can drive opening a chat thread
/// for a specific pet from anywhere in the app (swipe deck, interests list).
struct ChatPresentation: Identifiable {
    let id = UUID()
    let pet: Pet
    let thread: ChatThread
}
