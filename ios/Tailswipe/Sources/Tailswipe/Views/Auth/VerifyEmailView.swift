import SwiftUI

struct VerifyEmailView: View {
    @ObservedObject var viewModel: AuthViewModel
    let email: String
    let onVerified: (User) -> Void

    @State private var code = ""
    @State private var resendMessage: String?
    @FocusState private var isCodeFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.accentColor)

            Text("Check your email")
                .font(.title2.bold())
            Text("We sent a 6-digit code to \(email).")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("6-digit code", text: $code)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.title3.monospacedDigit())
                .focused($isCodeFocused)
                .onChange(of: code) { _, newValue in
                    code = String(newValue.filter(\.isNumber).prefix(6))
                }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
            if let resendMessage {
                Text(resendMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button {
                isCodeFocused = false
                Task {
                    if let user = await viewModel.verifyEmail(email: email, code: code) {
                        onVerified(user)
                    }
                }
            } label: {
                if viewModel.isSubmitting {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Verify").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(code.count != 6 || viewModel.isSubmitting)

            Button("Resend code") {
                Task {
                    let sent = await viewModel.resendVerification(email: email)
                    resendMessage = sent ? "A new code is on its way." : nil
                }
            }
            .font(.footnote)
        }
        .padding(24)
    }
}
