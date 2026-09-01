import SwiftUI

struct AdopterProfileCardView: View {
    let info: AdoptionRequestInfo

    var body: some View {
        // Same fix as `PetCardView`: pin the aspect-fill avatar photo to a concrete size
        // and clip it here, rather than letting it inflate and rely on an outer `.frame()`
        // (which only fixes reported size, not painted overflow).
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                avatarBackground
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                infoOverlay
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
    }

    private var avatarBackground: some View {
        ZStack {
            if let path = info.adopter.avatarImagePath, let url = URL(string: path) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().aspectRatio(contentMode: .fill).clipped()
                    } else {
                        placeholderBackground
                    }
                }
            } else {
                placeholderBackground
            }
        }
    }

    private var placeholderBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color.accentColor.opacity(0.55), Color.accentColor.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            Text(initials)
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private var initials: String {
        let parts = info.adopter.displayName.split(separator: " ")
        let letters = parts.prefix(2).compactMap(\.first).map(String.init)
        return letters.isEmpty ? "?" : letters.joined().uppercased()
    }

    private var infoOverlay: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                BadgeView(text: "Interested in \(info.pet.name)")
                if info.isSuper {
                    BadgeView(text: "⭐ Super Interest")
                }
            }
            Text(info.adopter.displayName)
                .font(.title.bold())
            if let city = info.adopter.location?.city {
                Text(city)
                    .font(.subheadline)
                    .opacity(0.85)
            }
            if let bio = info.adopter.bio, !bio.isEmpty {
                Text(bio)
                    .font(.caption)
                    .lineLimit(2)
                    .opacity(0.9)
            }
            HStack(spacing: 8) {
                AsyncImage(url: info.pet.photoURLs.first.flatMap(URL.init)) { phase in
                    if case .success(let image) = phase {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle().fill(Color.white.opacity(0.2))
                            .overlay(
                                Image(systemName: info.pet.species == .cat ? "cat.fill" : "dog.fill")
                                    .foregroundStyle(.white.opacity(0.7))
                            )
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("\(info.pet.name) · \(info.pet.breedDisplay)")
                    .font(.caption)
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
