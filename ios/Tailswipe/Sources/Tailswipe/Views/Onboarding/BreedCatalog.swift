import Foundation

/// Static breed lists shown on the wizard's breed step. Only dogs and cats have curated
/// lists — "Other" species skip the breed step entirely since there's no catalog for them.
enum BreedCatalog {
    static let dog = [
        "Labrador Retriever", "German Shepherd", "Golden Retriever", "Poodle", "Bulldog",
        "Beagle", "Chihuahua", "Boxer", "Dachshund", "Border Collie", "Australian Shepherd",
        "Great Dane", "Vizsla", "Mixed / Other"
    ]

    static let cat = [
        "Domestic Shorthair", "Domestic Longhair", "Siamese", "Maine Coon", "Tabby",
        "Russian Blue", "Persian", "Bengal", "Ragdoll", "Sphynx", "Mixed / Other"
    ]

    static func breeds(for species: Pet.Species) -> [String] {
        switch species {
        case .dog: return dog
        case .cat: return cat
        case .other: return []
        }
    }
}
