import SwiftUI

struct MatchCelebrationView: View {
    let pet: Pet
    let adopter: User
    let onSendMessage: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ConfettiView()

            VStack(spacing: 24) {
                Spacer()

                Text("It's a match!")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("You accepted \(adopter.displayName)'s interest in \(pet.name).")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                HStack(spacing: -24) {
                    petThumbnail
                    adopterAvatar
                }

                Spacer()

                Button(action: onSendMessage) {
                    Text("Send a Message")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 40)

                Button("Maybe Later", action: onDismiss)
                    .foregroundStyle(.white)
                    .padding(.bottom, 24)
            }
        }
    }

    private var petThumbnail: some View {
        AsyncImage(url: pet.photoURLs.first.flatMap(URL.init)) { phase in
            if case .success(let image) = phase {
                image.resizable().aspectRatio(contentMode: .fill)
            } else {
                Rectangle().fill(Color.white.opacity(0.3))
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white, lineWidth: 4))
    }

    private var adopterAvatar: some View {
        Group {
            if let path = adopter.avatarImagePath, let url = URL(string: path) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        ZStack {
                            Color.white.opacity(0.3)
                            Text(initials)
                                .font(.title.bold())
                                .foregroundStyle(.white)
                        }
                    }
                }
            } else {
                ZStack {
                    Color.white.opacity(0.3)
                    Text(initials)
                        .font(.title.bold())
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white, lineWidth: 4))
    }

    private var initials: String {
        let parts = adopter.displayName.split(separator: " ")
        let letters = parts.prefix(2).compactMap(\.first).map(String.init)
        return letters.isEmpty ? "?" : letters.joined().uppercased()
    }
}
