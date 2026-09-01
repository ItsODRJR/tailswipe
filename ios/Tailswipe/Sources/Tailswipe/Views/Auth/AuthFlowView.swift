import SwiftUI

struct AuthFlowView: View {
    enum Mode {
        case signIn
        case signUp
    }

    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: AuthViewModel
    @State private var mode: Mode = .signIn
    @State private var pendingVerificationEmail: String?

    init(userRepository: UserRepository) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(userRepository: userRepository))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.18), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        hero

                        VStack(spacing: 16) {
                            modePicker

                            if mode == .signIn {
                                SignInView(viewModel: viewModel, onOutcome: handleOutcome)
                            } else {
                                SignUpView(viewModel: viewModel, onOutcome: handleOutcome)
                            }
                        }
                        .padding(20)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                        tryDemoButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { pendingVerificationEmail != nil },
            set: { isPresented in if !isPresented { pendingVerificationEmail = nil } }
        )) {
            if let email = pendingVerificationEmail {
                VerifyEmailView(viewModel: viewModel, email: email) { user in
                    pendingVerificationEmail = nil
                    handleOutcome(.success(user))
                }
                .presentationDetents([.medium])
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 10) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.accentColor)
            Text("Tailswipe")
                .font(.system(size: 40, weight: .bold, design: .rounded))
            Text("Swipe right to meet your new best friend.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var modePicker: some View {
        Picker("Mode", selection: $mode.animation()) {
            Text("Sign In").tag(Mode.signIn)
            Text("Create Account").tag(Mode.signUp)
        }
        .pickerStyle(.segmented)
        .onChange(of: mode) { _, _ in viewModel.errorMessage = nil }
    }

    private var tryDemoButton: some View {
        Button {
            viewModel.email = "demo@tailswipe.org"
            viewModel.password = "password123"
            Task {
                if let outcome = await viewModel.signIn() {
                    handleOutcome(outcome)
                }
            }
        } label: {
            Label("Try the Demo Account", systemImage: "sparkles")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }

    private func handleOutcome(_ outcome: AuthOutcome) {
        switch outcome {
        case .success(let user):
            Task { await appState.setCurrentUser(user) }
        case .needsVerification(let email):
            pendingVerificationEmail = email
        }
    }
}
