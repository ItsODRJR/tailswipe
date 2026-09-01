import SwiftUI

struct PetCardView: View {
    let pet: Pet

    @State private var photoIndex = 0
    @State private var showDetail = false

    var body: some View {
        // `photo`'s aspect-fill computation can report a size larger than whatever this
        // card was allotted (that's what "fill" means — it overflows one axis rather than
        // letterbox). A plain `.frame()` on the card doesn't clip that overflow, only its
        // own reported size to the parent — so without pinning `photo` to a concrete,
        // known size here and clipping it, the photo paints past the card's rounded bounds.
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                photo
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                photoTapZones

                infoOverlay
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
        .overlay(alignment: .top) { photoProgressBar }
        .overlay(alignment: .bottomTrailing) { infoButton }
        .sheet(isPresented: $showDetail) {
            PetDetailView(pet: pet)
        }
    }

    private var photo: some View {
        AsyncImage(url: currentPhotoURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill).clipped()
            default:
                Rectangle().fill(Color(.tertiarySystemFill))
                    .overlay(
                        Image(systemName: pet.species == .cat ? "cat.fill" : "dog.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.secondary)
                    )
            }
        }
    }

    private var currentPhotoURL: URL? {
        guard pet.photoURLs.indices.contains(photoIndex) else { return nil }
        return URL(string: pet.photoURLs[photoIndex])
    }

    /// Tap the left third to go back a photo, the right two-thirds to advance — mirrors
    /// the Instagram Stories / Tinder-detail convention. Sits above the gradient but below
    /// `infoOverlay`'s text so the caption block never eats taps meant for the photo.
    private var photoTapZones: some View {
        HStack(spacing: 0) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { step(-1) }
                .frame(maxWidth: .infinity)
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { step(1) }
                .frame(maxWidth: .infinity)
        }
    }

    private func step(_ delta: Int) {
        guard pet.photoURLs.count > 1 else { return }
        let newIndex = photoIndex + delta
        guard pet.photoURLs.indices.contains(newIndex) else { return }
        photoIndex = newIndex
    }

    @ViewBuilder
    private var photoProgressBar: some View {
        if pet.photoURLs.count > 1 {
            HStack(spacing: 4) {
                ForEach(pet.photoURLs.indices, id: \.self) { index in
                    Capsule()
                        .fill(index <= photoIndex ? Color.white : Color.white.opacity(0.35))
                        .frame(height: 3)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
        }
    }

    private var infoButton: some View {
        Button {
            showDetail = true
        } label: {
            Image(systemName: "info.circle.fill")
                .font(.title2)
                .foregroundStyle(.white, .black.opacity(0.35))
        }
        .padding(14)
    }

    private var infoOverlay: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let badge = pet.source.badgeText {
                    BadgeView(text: badge)
                }
                if pet.source.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.blue)
                }
            }
            HStack(alignment: .firstTextBaseline) {
                Text(pet.name)
                    .font(.title.bold())
                Text(pet.ageCategory.displayName)
                    .font(.headline)
                    .opacity(0.85)
                Spacer()
                if let distance = pet.distanceMiles {
                    Text(DistanceFormatter.string(fromMiles: distance))
                        .font(.subheadline.weight(.semibold))
                }
            }
            Text(pet.breedDisplay)
                .font(.subheadline)
            if !pet.temperamentTags.isEmpty {
                Text(pet.temperamentTags.prefix(3).joined(separator: " · "))
                    .font(.caption)
                    .opacity(0.85)
            }
            if let conditions = pet.medicalConditions, !conditions.isEmpty {
                Label(conditions, systemImage: "cross.case.fill")
                    .font(.caption)
                    .lineLimit(1)
                    .opacity(0.85)
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .allowsHitTesting(false)
    }
}
