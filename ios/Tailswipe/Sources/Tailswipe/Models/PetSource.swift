import Foundation

/// Where a pet listing originated. Purely informational for the UI (badge display) —
/// the app treats pets from every source identically once they arrive from `GET /pets`.
/// Petfinder sync, dedup, and normalization into this shape are entirely backend concerns;
/// the iOS app never talks to Petfinder directly.
struct PetSource: Codable, Equatable {
    enum SourceType: String, Codable {
        case individual
        case shelter
        case petfinder
    }

    var type: SourceType
    var label: String?
    var isVerified: Bool = false

    var badgeText: String? {
        switch type {
        case .individual:
            return nil
        case .shelter:
            return label.map { "Posted by \($0)" } ?? "Shelter"
        case .petfinder:
            return "Via Petfinder"
        }
    }
}
