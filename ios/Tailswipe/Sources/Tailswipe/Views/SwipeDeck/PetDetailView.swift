import SwiftUI

struct PetDetailView: View {
    let pet: Pet
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    gallery

                    VStack(alignment: .leading, spacing: 12) {
                        header
                        if !pet.description.isEmpty {
                            Text(pet.description)
                                .font(.body)
                        }
                        if !pet.temperamentTags.isEmpty {
                            wrapTags
                        }
                        healthBadges
                        if let conditions = pet.medicalConditions, !conditions.isEmpty {
                            Label(conditions, systemImage: "cross.case.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        listerRow
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
            .navigationTitle(pet.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var gallery: some View {
        if pet.photoURLs.isEmpty {
            Rectangle()
                .fill(Color(.tertiarySystemFill))
                .frame(height: 320)
                .overlay(
                    Image(systemName: pet.species == .cat ? "cat.fill" : "dog.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                )
        } else {
            TabView {
                ForEach(pet.photoURLs, id: \.self) { url in
                    AsyncImage(url: URL(string: url)) { phase in
                        if case .success(let image) = phase {
                            image.resizable().aspectRatio(contentMode: .fill).clipped()
                        } else {
                            Rectangle().fill(Color(.tertiarySystemFill))
                        }
                    }
                }
            }
            .tabViewStyle(.page)
            .frame(height: 320)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let badge = pet.source.badgeText {
                    BadgeView(text: badge)
                }
                if pet.source.isVerified {
                    Label("Verified", systemImage: "checkmark.seal.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue)
                }
            }
            HStack(alignment: .firstTextBaseline) {
                Text(pet.name).font(.largeTitle.bold())
                Text(pet.ageCategory.displayName).font(.title3).foregroundStyle(.secondary)
            }
            Text("\(pet.breedDisplay) · \(pet.size.displayName) · \(pet.sex.displayName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let distance = pet.distanceMiles {
                Text(DistanceFormatter.string(fromMiles: distance) + " away")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var wrapTags: some View {
        FlowLayout(spacing: 6) {
            ForEach(pet.temperamentTags, id: \.self) { tag in
                Text(tag)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(.secondarySystemBackground), in: Capsule())
            }
        }
    }

    @ViewBuilder
    private var healthBadges: some View {
        let items: [(String, String, Bool)] = [
            ("Vaccinated", "syringe.fill", pet.isVaccinated),
            ("Spayed/Neutered", "pawprint.fill", pet.isSpayedNeutered),
            ("Good with kids", "figure.2.and.child.holdinghands", pet.isGoodWithKids),
            ("Good with other pets", "heart.fill", pet.isGoodWithOtherPets)
        ]
        let active = items.filter(\.2)
        if !active.isEmpty {
            FlowLayout(spacing: 6) {
                ForEach(active, id: \.0) { title, icon, _ in
                    Label(title, systemImage: icon)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.15), in: Capsule())
                        .foregroundStyle(.green)
                }
            }
        }
    }

    private var listerRow: some View {
        HStack {
            Image(systemName: pet.listedBy.contactType == .shelter ? "building.2.fill" : "person.fill")
                .foregroundStyle(.secondary)
            Text("Listed by \(pet.listedBy.displayName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
