import Foundation

/// Sample data for the mock data layer. Locations are scattered around College Station /
/// Bryan, TX (the Brazos Valley) at varying distances from `demoUser` so distance
/// filtering/sorting is visibly exercised without any real backend.
enum MockSeedData {
    static let demoUser = User(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        email: "demo@tailswipe.org",
        displayName: "Jordan",
        location: Location(latitude: 30.6280, longitude: -96.3344, city: "College Station", region: "TX"),
        createdAt: daysAgo(120)
    )

    private static let shelterLister = PetLister(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        displayName: "Brazos Valley Animal Rescue",
        contactType: .shelter
    )

    private static let secondShelterLister = PetLister(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        displayName: "Second Chance Shelter",
        contactType: .shelter
    )

    private static let individualLister = PetLister(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
        displayName: "Casey R.",
        contactType: .individual
    )

    private static let demoUserLister = PetLister(
        id: demoUser.id,
        displayName: demoUser.displayName,
        contactType: .individual
    )

    /// Mock adopters interested in the demo user's own listing (Bella, below), so the
    /// Requests tab has something to swipe on immediately after a fresh sign-in.
    static let sampleAdopters: [User] = [
        User(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
            email: "alex.kim@example.com",
            displayName: "Alex Kim",
            location: Location(latitude: 30.6260, longitude: -96.3320, city: "College Station", region: "TX"),
            createdAt: daysAgo(60)
        ),
        User(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
            email: "sam.rivera@example.com",
            displayName: "Sam Rivera",
            location: Location(latitude: 30.6744, longitude: -96.3700, city: "Bryan", region: "TX"),
            createdAt: daysAgo(45)
        )
    ]

    static var samplePets: [Pet] = [
        Pet(
            id: UUID(), name: "Biscuit", species: .dog, breed: ["Labrador Retriever"],
            ageCategory: .young, ageMonths: 18, size: .large, sex: .male,
            temperamentTags: ["good with kids", "high energy", "friendly"],
            description: "Biscuit loves fetch and long walks. Great with kids and other dogs.",
            photoURLs: ["https://images.dog.ceo/breeds/dane-great/n02109047_22193.jpg", "https://images.dog.ceo/breeds/spaniel-sussex/n02102480_7831.jpg", "https://images.dog.ceo/breeds/corgi-cardigan/n02113186_7676.jpg"],
            location: Location(latitude: 30.6320, longitude: -96.3300, city: "College Station", region: "TX"),
            distanceMiles: nil, source: PetSource(type: .shelter, label: "Brazos Valley Animal Rescue", isVerified: true),
            listedBy: shelterLister, status: .available, createdAt: daysAgo(3)
        ),
        Pet(
            id: UUID(), name: "Luna", species: .cat, breed: ["Domestic Shorthair"],
            ageCategory: .adult, ageMonths: 36, size: .small, sex: .female,
            temperamentTags: ["calm", "independent"],
            description: "Luna is a chill lap cat who enjoys sunny windowsills.",
            photoURLs: ["https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/1j.jpg", "https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/MTkxNTA0MA.jpg", "https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/cge.jpg"],
            location: Location(latitude: 30.6744, longitude: -96.3700, city: "Bryan", region: "TX"),
            distanceMiles: nil, source: PetSource(type: .petfinder, label: nil),
            listedBy: secondShelterLister, status: .available, createdAt: daysAgo(7)
        ),
        Pet(
            id: UUID(), name: "Rocky", species: .dog, breed: ["Boxer", "Mix"],
            ageCategory: .adult, ageMonths: 48, size: .large, sex: .male,
            temperamentTags: ["good with kids", "protective"],
            description: "Rocky is a loyal boxer mix looking for an active family.",
            photoURLs: ["https://images.dog.ceo/breeds/pyrenees/n02111500_2232.jpg", "https://images.dog.ceo/breeds/mountain-bernese/n02107683_3138.jpg", "https://images.dog.ceo/breeds/clumber/n02101556_1819.jpg"],
            location: Location(latitude: 30.5400, longitude: -96.3600, city: "Wellborn", region: "TX"),
            distanceMiles: nil, source: PetSource(type: .individual, label: nil),
            listedBy: individualLister, status: .available, createdAt: daysAgo(1)
        ),
        Pet(
            id: UUID(), name: "Peanut", species: .dog, breed: ["Chihuahua"],
            ageCategory: .senior, ageMonths: 108, size: .small, sex: .female,
            temperamentTags: ["calm", "good with seniors"],
            description: "Peanut is a sweet senior who just wants a warm lap.",
            photoURLs: ["https://images.dog.ceo/breeds/african-wild/n02116738_2942.jpg", "https://images.dog.ceo/breeds/entlebucher/n02108000_2172.jpg", "https://images.dog.ceo/breeds/malamute/n02110063_6276.jpg"],
            location: Location(latitude: 30.3877, longitude: -96.0847, city: "Navasota", region: "TX"),
            distanceMiles: nil, source: PetSource(type: .shelter, label: "Second Chance Shelter", isVerified: true),
            listedBy: secondShelterLister, status: .available, createdAt: daysAgo(14)
        ),
        Pet(
            id: UUID(), name: "Milo", species: .cat, breed: ["Tabby"],
            ageCategory: .baby, ageMonths: 4, size: .small, sex: .male,
            temperamentTags: ["playful", "good with kids"],
            description: "Milo is a curious kitten who loves toys and cardboard boxes.",
            photoURLs: ["https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/tOGSsMx5J.jpg", "https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/e07.jpg", "https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/5kr.jpg"],
            location: Location(latitude: 30.6250, longitude: -96.3400, city: "College Station", region: "TX"),
            distanceMiles: nil, source: PetSource(type: .petfinder, label: nil),
            listedBy: shelterLister, status: .available, createdAt: daysAgo(2)
        ),
        Pet(
            id: UUID(), name: "Bella", species: .dog, breed: ["Poodle Mix"],
            ageCategory: .young, ageMonths: 14, size: .medium, sex: .female,
            temperamentTags: ["friendly", "hypoallergenic-friendly"],
            description: "Bella is a bouncy poodle mix, great for apartment living.",
            photoURLs: ["https://images.dog.ceo/breeds/retriever-flatcoated/n02099267_3097.jpg", "https://images.dog.ceo/breeds/retriever-golden/pxl_20220311_055548510.mp_2.jpg", "https://images.dog.ceo/breeds/pomeranian/n02112018_5560.jpg"],
            location: Location(latitude: 30.7650, longitude: -96.3950, city: "Kurten", region: "TX"),
            distanceMiles: nil, source: PetSource(type: .individual, label: nil),
            listedBy: demoUserLister, status: .available, createdAt: daysAgo(5)
        ),
        Pet(
            id: UUID(), name: "Shadow", species: .cat, breed: ["Domestic Longhair"],
            ageCategory: .adult, ageMonths: 30, size: .medium, sex: .male,
            temperamentTags: ["independent", "quiet"],
            description: "Shadow prefers a calm home without small children.",
            photoURLs: ["https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/90b.jpg", "https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/793.jpg", "https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/e4b.jpg"],
            location: Location(latitude: 30.5324, longitude: -96.6939, city: "Caldwell", region: "TX"),
            distanceMiles: nil, source: PetSource(type: .shelter, label: "Brazos Valley Animal Rescue", isVerified: true),
            listedBy: shelterLister, status: .available, createdAt: daysAgo(9)
        ),
        Pet(
            id: UUID(), name: "Duke", species: .dog, breed: ["German Shepherd"],
            ageCategory: .adult, ageMonths: 40, size: .xlarge, sex: .male,
            temperamentTags: ["protective", "high energy", "needs training"],
            medicalConditions: "Mild hip dysplasia, managed with a daily joint supplement.",
            isVaccinated: true, isSpayedNeutered: true,
            description: "Duke is smart and loyal; best with an experienced owner.",
            photoURLs: ["https://images.dog.ceo/breeds/shihtzu/n02086240_4430.jpg", "https://images.dog.ceo/breeds/spaniel-japanese/n02085782_3121.jpg", "https://images.dog.ceo/breeds/retriever-flatcoated/n02099267_4906.jpg"],
            location: Location(latitude: 30.8749, longitude: -96.5964, city: "Hearne", region: "TX"),
            distanceMiles: nil, source: PetSource(type: .petfinder, label: nil),
            listedBy: secondShelterLister, status: .available, createdAt: daysAgo(20)
        ),
        Pet(
            id: UUID(), name: "Coco", species: .dog, breed: ["Dachshund"],
            ageCategory: .baby, ageMonths: 6, size: .small, sex: .female,
            temperamentTags: ["playful", "good with kids"],
            description: "Coco is a spunky dachshund puppy full of energy.",
            photoURLs: ["https://images.dog.ceo/breeds/terrier-tibetan/n02097474_2554.jpg", "https://images.dog.ceo/breeds/hound-walker/n02089867_1048.jpg", "https://images.dog.ceo/breeds/clumber/n02101556_1469.jpg"],
            location: Location(latitude: 30.5300, longitude: -96.4830, city: "Snook", region: "TX"),
            distanceMiles: nil, source: PetSource(type: .individual, label: nil),
            listedBy: individualLister, status: .available, createdAt: daysAgo(0)
        ),
        Pet(
            id: UUID(), name: "Simba", species: .cat, breed: ["Maine Coon Mix"],
            ageCategory: .young, ageMonths: 16, size: .large, sex: .male,
            temperamentTags: ["friendly", "good with kids"],
            description: "Simba is a gentle giant who loves attention.",
            photoURLs: ["https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/VwGK1QO3m.jpg", "https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/cu0.jpg", "https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/cl7.jpg"],
            location: Location(latitude: 30.6200, longitude: -96.3450, city: "College Station", region: "TX"),
            distanceMiles: nil, source: PetSource(type: .shelter, label: "Brazos Valley Animal Rescue", isVerified: true),
            listedBy: shelterLister, status: .available, createdAt: daysAgo(11)
        ),
        Pet(
            id: UUID(), name: "Zeus", species: .dog, breed: ["Great Dane"],
            ageCategory: .adult, ageMonths: 30, size: .xlarge, sex: .male,
            temperamentTags: ["calm", "good with kids"],
            description: "Zeus is a gentle giant despite his size, loves to nap.",
            photoURLs: ["https://images.dog.ceo/breeds/poodle-miniature/n02113712_8595.jpg", "https://images.dog.ceo/breeds/malinois/n02105162_8841.jpg", "https://images.dog.ceo/breeds/terrier-dandie/n02096437_140.jpg"],
            location: Location(latitude: 30.7235, longitude: -95.5508, city: "Huntsville", region: "TX"),
            distanceMiles: nil, source: PetSource(type: .petfinder, label: nil),
            listedBy: secondShelterLister, status: .available, createdAt: daysAgo(25)
        ),
        Pet(
            id: UUID(), name: "Nala", species: .cat, breed: ["Siamese Mix"],
            ageCategory: .senior, ageMonths: 96, size: .small, sex: .female,
            temperamentTags: ["calm", "quiet", "good with seniors"],
            medicalConditions: "Hyperthyroidism, currently medicated and stable.",
            isVaccinated: true, isSpayedNeutered: true, isGoodWithKids: true,
            description: "Nala is a sweet senior cat who enjoys quiet company.",
            photoURLs: ["https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/1tb.jpg", "https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/dub.jpg", "https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/MTY2MjcxMw.jpg"],
            location: Location(latitude: 30.6350, longitude: -96.3250, city: "College Station", region: "TX"),
            distanceMiles: nil, source: PetSource(type: .individual, label: nil),
            listedBy: individualLister, status: .available, createdAt: daysAgo(4)
        ),
        Pet(
            id: UUID(), name: "Max", species: .dog, breed: ["Beagle"],
            ageCategory: .young, ageMonths: 20, size: .medium, sex: .male,
            temperamentTags: ["friendly", "good with kids", "high energy"],
            description: "Max loves sniffing out adventures on every walk.",
            photoURLs: ["https://images.dog.ceo/breeds/terrier-yorkshire/n02094433_2537.jpg", "https://images.dog.ceo/breeds/pinscher/coffee_soul_bari024.jpg", "https://images.dog.ceo/breeds/weimaraner/n02092339_8029.jpg"],
            location: Location(latitude: 30.6800, longitude: -96.2950, city: "Wixon Valley", region: "TX"),
            distanceMiles: nil, source: PetSource(type: .shelter, label: "Second Chance Shelter", isVerified: true),
            listedBy: secondShelterLister, status: .available, createdAt: daysAgo(6)
        ),
        Pet(
            id: UUID(), name: "Willow", species: .dog, breed: ["Border Collie Mix"],
            ageCategory: .young, ageMonths: 22, size: .medium, sex: .female,
            temperamentTags: ["high energy", "needs training", "friendly"],
            description: "Willow is whip-smart and needs an active household.",
            photoURLs: ["https://images.dog.ceo/breeds/spaniel-cocker/n02102318_10818.jpg", "https://images.dog.ceo/breeds/terrier-norwich/n02094258_1678.jpg", "https://images.dog.ceo/breeds/entlebucher/n02108000_1547.jpg"],
            location: Location(latitude: 30.4988, longitude: -96.0088, city: "Anderson", region: "TX"),
            distanceMiles: nil, source: PetSource(type: .petfinder, label: nil),
            listedBy: shelterLister, status: .available, createdAt: daysAgo(8)
        ),
        Pet(
            id: UUID(), name: "Oliver", species: .cat, breed: ["Orange Tabby"],
            ageCategory: .baby, ageMonths: 5, size: .small, sex: .male,
            temperamentTags: ["playful", "good with kids"],
            description: "Oliver is a playful orange tabby kitten looking for a forever home.",
            photoURLs: ["https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/kh.jpg", "https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/vVF7hE-Py.jpg", "https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/MTg1MTYwNg.jpg"],
            location: Location(latitude: 30.6180, longitude: -96.3380, city: "College Station", region: "TX"),
            distanceMiles: nil, source: PetSource(type: .individual, label: nil),
            listedBy: individualLister, status: .available, createdAt: daysAgo(1)
        ),
        Pet(
            id: UUID(), name: "Ranger", species: .dog, breed: ["Australian Shepherd"],
            ageCategory: .adult, ageMonths: 42, size: .large, sex: .male,
            temperamentTags: ["high energy", "protective", "friendly"],
            description: "Ranger thrives with hiking, running, and a job to do.",
            photoURLs: ["https://images.dog.ceo/breeds/hound-blood/n02088466_7421.jpg", "https://images.dog.ceo/breeds/terrier-norwich/n02094258_1823.jpg", "https://images.dog.ceo/breeds/retriever-golden/n02099601_5679.jpg"],
            location: Location(latitude: 30.3477, longitude: -96.5313, city: "Somerville", region: "TX"),
            distanceMiles: nil, source: PetSource(type: .shelter, label: "Brazos Valley Animal Rescue", isVerified: true),
            listedBy: shelterLister, status: .available, createdAt: daysAgo(16)
        ),
        Pet(
            id: UUID(), name: "Pixel", species: .cat, breed: ["Russian Blue Mix"],
            ageCategory: .young, ageMonths: 15, size: .small, sex: .female,
            temperamentTags: ["independent", "quiet", "calm"],
            description: "Pixel is a quiet, elegant cat who prefers a peaceful home.",
            photoURLs: ["https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/MTU1OTA2MA.jpg", "https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/d08.jpg", "https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/9pf.jpg"],
            location: Location(latitude: 30.1669, longitude: -96.3977, city: "Brenham", region: "TX"),
            distanceMiles: nil, source: PetSource(type: .petfinder, label: nil),
            listedBy: secondShelterLister, status: .available, createdAt: daysAgo(12)
        ),
        Pet(
            id: UUID(), name: "Copper", species: .dog, breed: ["Vizsla Mix"],
            ageCategory: .young, ageMonths: 17, size: .medium, sex: .male,
            temperamentTags: ["high energy", "friendly", "good with kids"],
            description: "Copper is an athletic, affectionate companion for an active home.",
            photoURLs: ["https://images.dog.ceo/breeds/airedale/n02096051_584.jpg", "https://images.dog.ceo/breeds/stbernard/n02109525_12041.jpg", "https://images.dog.ceo/breeds/retriever-golden/n02099601_6105.jpg"],
            location: Location(latitude: 30.7450, longitude: -96.0050, city: "Millican", region: "TX"),
            distanceMiles: nil, source: PetSource(type: .individual, label: nil),
            listedBy: individualLister, status: .available, createdAt: daysAgo(2)
        )
    ]

    private static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }
}
