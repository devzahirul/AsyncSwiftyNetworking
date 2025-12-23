import SwiftUI

// MARK: - Login View

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Logo
                Image(systemName: "network")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue.gradient)
                    .padding(.top, 60)
                
                Text("AsyncSwiftyNetworking")
                    .font(.title2.bold())
                
                Text("Demo App")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Login Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    #endif
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                        .textContentType(.password)
                    #endif
                    
                    // Error Message
                    if let error = authManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Login Button
                    Button {
                        Task {
                            await authManager.login(email: email, password: password)
                        }
                    } label: {
                        HStack {
                            if authManager.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Sign In")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)
                    
                    // Register Link
                    Button("Don't have an account? Register") {
                        showRegister = true
                    }
                    .font(.footnote)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Demo Hint
                Text("Use any email/password to login")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom)
            }
            .sheet(isPresented: $showRegister) {
                RegisterView()
            }
        }
    }
}

// MARK: - Register View

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Account Details") {
                    TextField("Full Name", text: $name)
                    
                    TextField("Email", text: $email)
                    #if os(iOS)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    #endif
                }
                
                Section("Password") {
                    SecureField("Password", text: $password)
                    #if os(iOS)
                        .textContentType(.newPassword)
                    #endif
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                    #if os(iOS)
                        .textContentType(.newPassword)
                    #endif
                }
                
                if let error = authManager.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
                
                Section {
                    Button {
                        Task {
                            await authManager.register(name: name, email: email, password: password)
                            if authManager.isAuthenticated {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if authManager.isLoading {
                                ProgressView()
                            }
                            Text("Create Account")
                            Spacer()
                        }
                    }
                    .disabled(isFormInvalid || authManager.isLoading)
                }
            }
            .navigationTitle("Register")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    var isFormInvalid: Bool {
        name.isEmpty || email.isEmpty || password.isEmpty || password != confirmPassword
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager.shared)
}
