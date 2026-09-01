import Foundation

struct Pet: Identifiable, Codable, Equatable {
    enum Species: String, Codable, CaseIterable, Identifiable {
        case dog, cat, other

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .dog: return "Dog"
            case .cat: return "Cat"
            case .other: return "Other"
            }
        }
    }

    enum AgeCategory: String, Codable, CaseIterable, Identifiable {
        case baby, young, adult, senior

        var id: String { rawValue }
        var displayName: String { rawValue.capitalized }
    }

    enum Size: String, Codable, CaseIterable, Identifiable {
        case small, medium, large, xlarge

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .small: return "Small"
            case .medium: return "Medium"
            case .large: return "Large"
            case .xlarge: return "X-Large"
            }
        }
    }

    enum Sex: String, Codable, CaseIterable, Identifiable {
        case male, female, unknown

        var id: String { rawValue }
        var displayName: String { rawValue.capitalized }
    }

    enum Status: String, Codable {
        case available, pending, adopted
    }

    var id: UUID
    var name: String
    var species: Species
    var breed: [String]
    var ageCategory: AgeCategory
    var ageMonths: Int?
    var size: Size
    var sex: Sex
    var temperamentTags: [String]
    var medicalConditions: String? = nil
    var isVaccinated: Bool = false
    var isSpayedNeutered: Bool = false
    var isGoodWithKids: Bool = false
    var isGoodWithOtherPets: Bool = false
    var description: String
    var photoURLs: [String]
    var location: Location
    /// Computed relative to the requesting user; only populated on feed responses.
    var distanceMiles: Double?
    var source: PetSource
    var listedBy: PetLister
    var status: Status
    var createdAt: Date

    var breedDisplay: String {
        breed.isEmpty ? species.displayName : breed.joined(separator: " / ")
    }
}

struct PetLister: Identifiable, Codable, Equatable {
    enum ContactType: String, Codable {
        case individual, shelter
    }

    var id: UUID
    var displayName: String
    var contactType: ContactType
}
