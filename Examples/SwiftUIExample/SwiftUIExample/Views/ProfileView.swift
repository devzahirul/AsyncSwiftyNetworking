import SwiftUI
import AsyncSwiftyNetworking

// MARK: - Profile View

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                // User Info Section
                Section {
                    userInfoRow
                }
                
                // Features Demo Section
                Section("Library Features") {
                    featureRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Refresh Token",
                        description: "Automatic token refresh on 401"
                    )
                    
                    featureRow(
                        icon: "repeat",
                        title: "Retry Policy",
                        description: "Exponential backoff retry"
                    )
                    
                    featureRow(
                        icon: "lock.shield",
                        title: "Keychain Storage",
                        description: "Secure token storage"
                    )
                    
                    featureRow(
                        icon: "doc.text.magnifyingglass",
                        title: "Request Logging",
                        description: "OSLog integration"
                    )
                }
                
                // Token Info Section
                Section("Token Info") {
                    tokenInfoRow("Access Token", value: viewModel.accessTokenPreview)
                    tokenInfoRow("Refresh Token", value: viewModel.refreshTokenPreview)
                }
                
                // Actions Section
                Section {
                    Button {
                        Task { await viewModel.simulateTokenRefresh() }
                    } label: {
                        Label("Simulate Token Refresh", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(viewModel.isRefreshing)
                    
                    Button {
                        Task { await viewModel.testAuth401() }
                    } label: {
                        Label("Test 401 Response", systemImage: "exclamationmark.triangle")
                    }
                    
                    Button(role: .destructive) {
                        authManager.logout()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
                
                // About Section
                Section("About") {
                    LabeledContent("Library", value: "AsyncSwiftyNetworking")
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Platform", value: "iOS 16+")
                }
            }
            .navigationTitle("Profile")
            .alert("Token Refreshed", isPresented: $viewModel.showRefreshSuccess) {
                Button("OK") { }
            } message: {
                Text("The access token was successfully refreshed.")
            }
        }
    }
    
    // MARK: - Rows
    
    private var userInfoRow: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.blue.gradient)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(authManager.currentUser?.name ?? "User")
                    .font(.headline)
                Text(authManager.currentUser?.email ?? "user@example.com")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func tokenInfoRow(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(1)
        }
    }
}

// MARK: - Profile ViewModel

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var isRefreshing = false
    @Published var showRefreshSuccess = false
    
    private let network = NetworkManager.shared
    
    var accessTokenPreview: String {
        guard let token = network.tokenStorage.currentToken else { return "None" }
        return String(token.prefix(20)) + "..."
    }
    
    var refreshTokenPreview: String {
        guard let token = network.tokenStorage.refreshToken else { return "None" }
        return String(token.prefix(20)) + "..."
    }
    
    func simulateTokenRefresh() async {
        isRefreshing = true
        
        // Generate new tokens
        let newAccess = "refreshed-access-\(UUID().uuidString)"
        let newRefresh = "refreshed-refresh-\(UUID().uuidString)"
        
        // Save new tokens
        network.tokenStorage.save(accessToken: newAccess, refreshToken: newRefresh)
        
        // Simulate delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        showRefreshSuccess = true
        isRefreshing = false
    }
    
    func testAuth401() async {
        // This would normally make a request that returns 401
        // For demo, we just show an alert
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager.shared)
}
