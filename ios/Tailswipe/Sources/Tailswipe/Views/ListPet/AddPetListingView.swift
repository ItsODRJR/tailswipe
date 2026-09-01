import SwiftUI
import PhotosUI

struct AddPetListingView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    let onCreate: (Pet) -> Void

    @State private var name = ""
    @State private var species: Pet.Species = .dog
    @State private var breedText = ""
    @State private var ageCategory: Pet.AgeCategory = .young
    @State private var size: Pet.Size = .medium
    @State private var sex: Pet.Sex = .unknown
    @State private var temperamentText = ""
    @State private var medicalConditions = ""
    @State private var isVaccinated = false
    @State private var isSpayedNeutered = false
    @State private var isGoodWithKids = false
    @State private var isGoodWithOtherPets = false
    @State private var description = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoImages: [UIImage] = []
    @State private var isSubmitting = false
    @FocusState private var isInputActive: Bool

    var body: some View {
        Form {
            Section("Photos") {
                PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 5, matching: .images) {
                    if photoImages.isEmpty {
                        Label("Add photos", systemImage: "photo.badge.plus")
                    } else {
                        photoStrip
                    }
                }
                .onChange(of: selectedPhotos) { _, newItems in
                    Task {
                        var images: [UIImage] = []
                        for item in newItems {
                            if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                                images.append(image)
                            }
                        }
                        photoImages = images
                    }
                }
            }

            Section("About") {
                TextField("Name", text: $name)
                    .focused($isInputActive)
                Picker("Species", selection: $species) {
                    ForEach(Pet.Species.allCases) { Text($0.displayName).tag($0) }
                }
                TextField("Breed(s), comma separated", text: $breedText)
                    .focused($isInputActive)
                Picker("Age", selection: $ageCategory) {
                    ForEach(Pet.AgeCategory.allCases) { Text($0.displayName).tag($0) }
                }
                Picker("Size", selection: $size) {
                    ForEach(Pet.Size.allCases) { Text($0.displayName).tag($0) }
                }
                Picker("Sex", selection: $sex) {
                    ForEach(Pet.Sex.allCases) { Text($0.displayName).tag($0) }
                }
            }

            Section("Health") {
                Toggle("Vaccinated", isOn: $isVaccinated)
                Toggle("Spayed / Neutered", isOn: $isSpayedNeutered)
                Toggle("Good with kids", isOn: $isGoodWithKids)
                Toggle("Good with other pets", isOn: $isGoodWithOtherPets)
                TextField("Medical conditions — e.g. none, or describe any conditions", text: $medicalConditions, axis: .vertical)
                    .focused($isInputActive)
            }

            Section("Temperament") {
                TextField("e.g. friendly, good with kids", text: $temperamentText)
                    .focused($isInputActive)
            }

            Section("Description") {
                TextEditor(text: $description)
                    .focused($isInputActive)
                    .frame(minHeight: 100)
            }

            Section {
                Button(isSubmitting ? "Listing…" : "List Pet") {
                    isInputActive = false
                    Task { await createListing() }
                }
                .disabled(isSubmitting || name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .navigationTitle("List a Pet")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isInputActive = false }
            }
        }
    }

    private var photoStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(photoImages.enumerated()), id: \.offset) { _, image in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 90, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .frame(height: 90)
    }

    private func createListing() async {
        guard let user = appState.currentUser else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        let location = environment.locationService.currentLocation
            ?? user.location
            ?? Location(latitude: 37.7749, longitude: -122.4194, city: nil, region: nil)
        let breeds = breedText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let tags = temperamentText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let trimmedMedicalConditions = medicalConditions.trimmingCharacters(in: .whitespacesAndNewlines)

        var photoURLs: [String] = []
        for image in photoImages {
            guard let data = image.jpegData(compressionQuality: 0.85) else { continue }
            if let url = try? await environment.imageUploadService.upload(data) {
                photoURLs.append(url)
            }
        }

        let pet = Pet(
            id: UUID(),
            name: name,
            species: species,
            breed: breeds,
            ageCategory: ageCategory,
            ageMonths: nil,
            size: size,
            sex: sex,
            temperamentTags: tags,
            medicalConditions: trimmedMedicalConditions.isEmpty ? nil : trimmedMedicalConditions,
            isVaccinated: isVaccinated,
            isSpayedNeutered: isSpayedNeutered,
            isGoodWithKids: isGoodWithKids,
            isGoodWithOtherPets: isGoodWithOtherPets,
            description: description,
            photoURLs: photoURLs,
            location: location,
            distanceMiles: nil,
            source: PetSource(type: .individual, label: nil),
            listedBy: PetLister(id: user.id, displayName: user.displayName, contactType: .individual),
            status: .available,
            createdAt: Date()
        )
        onCreate(pet)
        dismiss()
    }
}
