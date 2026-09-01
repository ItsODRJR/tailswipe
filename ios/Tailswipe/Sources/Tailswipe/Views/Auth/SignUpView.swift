import SwiftUI

struct SignUpView: View {
    @ObservedObject var viewModel: AuthViewModel
    let onOutcome: (AuthOutcome) -> Void

    var body: some View {
        VStack(spacing: 16) {
            TextField("Display Name", text: $viewModel.displayName)
                .textFieldStyle(.roundedBorder)
            TextField("Email", text: $viewModel.email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)
            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                Task {
                    if let outcome = await viewModel.signUp() {
                        onOutcome(outcome)
                    }
                }
            } label: {
                if viewModel.isSubmitting {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Sign Up").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(
                viewModel.displayName.isEmpty
                    || viewModel.email.isEmpty
                    || viewModel.password.isEmpty
                    || viewModel.isSubmitting
            )
        }
    }
}
