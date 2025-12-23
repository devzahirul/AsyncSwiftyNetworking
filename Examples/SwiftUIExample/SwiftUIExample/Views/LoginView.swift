import SwiftUI
import AsyncSwiftyNetworking

// MARK: - Login ViewModel

@MainActor
class LoginViewModel: AuthLoginViewModel<LoginRequest, LoginResponse> {
    @Published var email = "demo@example.com"
    @Published var password = "password123"
    
    override func extractToken(from response: LoginResponse) -> String? {
        return response.token
    }
    
    override func extractUser(from response: LoginResponse) -> (any Sendable)? {
        return response.user
    }
    
    func login() async {
        await execute(LoginRequest(email: email, password: password))
    }
}

// MARK: - Login View

struct LoginView: View {
    @StateObject private var vm = LoginViewModel()
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Logo
            Image(systemName: "network")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
            
            Text("AsyncSwiftyNetworking")
                .font(.title.bold())
            
            Text("Demo App")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Form
            VStack(spacing: 16) {
                TextField("Email", text: $vm.email)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $vm.password)
                    .textFieldStyle(.roundedBorder)
                
                if let error = vm.error {
                    Text(error.userMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Button {
                    Task { await vm.login() }
                } label: {
                    if vm.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Login")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.isLoading)
            }
            .padding(.horizontal)
            
            Spacer()
            
            Text("Note: Login simulates success for demo")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    LoginView()
}
