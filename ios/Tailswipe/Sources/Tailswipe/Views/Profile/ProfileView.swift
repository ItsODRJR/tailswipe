import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var environment: AppEnvironment
    @State private var showResetConfirmation = false
    @State private var bio = ""
    @State private var selectedAvatar: PhotosPickerItem?
    @State private var pickedAvatarImage: UIImage?
    @State private var isSavingProfile = false
    @FocusState private var isBioFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                if let user = appState.currentUser {
                    Section("Account") {
                        LabeledContent("Name", value: user.displayName)
                        LabeledContent("Email", value: user.email)
                    }

                    Section("Public Profile") {
                        Text("Listers see your photo and bio when you express interest in their pet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        PhotosPicker(selection: $selectedAvatar, matching: .images) {
                            HStack(spacing: 12) {
                                avatarThumbnail
                                Text(pickedAvatarImage == nil && appState.currentUser?.avatarImagePath == nil ? "Add a photo" : "Change photo")
                            }
                        }
                        .onChange(of: selectedAvatar) { _, newItem in
                            Task {
                                guard let data = try? await newItem?.loadTransferable(type: Data.self) else { return }
                                pickedAvatarImage = UIImage(data: data)
                            }
                        }

                        TextField("Short bio", text: $bio, axis: .vertical)
                            .focused($isBioFocused)

                        Button(isSavingProfile ? "Saving…" : "Save Profile") {
                            isBioFocused = false
                            Task { await saveProfile(user: user) }
                        }
                        .disabled(isSavingProfile)
                    }
                }

                Section {
                    NavigationLink("Edit Preferences") {
                        EditPreferencesView()
                    }
                }

                if let resettable = environment.userRepository as? DemoResettable {
                    Section {
                        Button("Reset Demo Data", role: .destructive) {
                            showResetConfirmation = true
                        }
                        .confirmationDialog(
                            "Reset all demo data?",
                            isPresented: $showResetConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button("Reset", role: .destructive) {
                                Task {
                                    await resettable.resetDemoData()
                                    await appState.signOut()
                                }
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("This clears all accounts, listings, swipes, and messages, and returns you to the sign-in screen.")
                        }
                    } footer: {
                        Text("Restores the app to its original demo state.")
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        Task { await appState.signOut() }
                    }
                }
            }
            .navigationTitle("Profile")
            .onAppear { loadCurrentProfile() }
        }
    }

    private var avatarThumbnail: some View {
        Group {
            if let pickedAvatarImage {
                Image(uiImage: pickedAvatarImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let path = appState.currentUser?.avatarImagePath, let url = URL(string: path) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
    }

    private func loadCurrentProfile() {
        guard let user = appState.currentUser else { return }
        bio = user.bio ?? ""
    }

    private func saveProfile(user: User) async {
        isSavingProfile = true
        defer { isSavingProfile = false }
        var updated = user
        updated.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : bio
        if let pickedAvatarImage, let data = pickedAvatarImage.jpegData(compressionQuality: 0.85) {
            updated.avatarImagePath = try? await environment.imageUploadService.upload(data)
        }
        await appState.updateProfile(updated)
    }
}
