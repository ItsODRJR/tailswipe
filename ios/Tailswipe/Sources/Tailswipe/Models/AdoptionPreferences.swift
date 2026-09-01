import Foundation

struct AdoptionPreferences: Codable, Equatable {
    var species: [Pet.Species]
    var breeds: [String]?
    var ageCategories: [Pet.AgeCategory]
    var sizes: [Pet.Size]
    var maxDistanceMiles: Double
    var temperamentTags: [String]?
    var openToMedicalConditions: Bool = true

    static let `default` = AdoptionPreferences(
        species: [.dog, .cat],
        breeds: nil,
        ageCategories: Pet.AgeCategory.allCases,
        sizes: Pet.Size.allCases,
        maxDistanceMiles: 25,
        temperamentTags: nil
    )
}
