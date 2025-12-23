import Foundation
import SwiftUI
import AsyncSwiftyNetworking

// MARK: - Auth Manager

@MainActor
final class AuthManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AuthManager()
    
    // MARK: - Published State
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let network = NetworkManager.shared
    
    // MARK: - Initialization
    
    private init() {
        // Check if we have a valid token
        isAuthenticated = network.hasValidToken
        
        // Listen for session expiry
        NotificationCenter.default.addObserver(
            forName: .sessionExpired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleSessionExpired()
            }
        }
    }
    
    // MARK: - Login
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // For demo, we'll simulate a login response
            // In real app, call: network.client.request(API.Auth.login(...))
            try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
            
            // Simulate successful login
            let demoUser = User(id: 1, name: "John Doe", email: email, avatarUrl: nil)
            
            // Save demo tokens
            network.saveTokens(
                access: "demo-access-token-\(UUID().uuidString)",
                refresh: "demo-refresh-token-\(UUID().uuidString)"
            )
            
            currentUser = demoUser
            isAuthenticated = true
            
        } catch let error as NetworkError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Login failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Register
    
    func register(name: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate registration
            try await Task.sleep(nanoseconds: 1_500_000_000)
            
            // Auto login after registration
            await login(email: email, password: password)
            
        } catch let error as NetworkError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Registration failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Logout
    
    func logout() {
        network.clearTokens()
        currentUser = nil
        isAuthenticated = false
    }
    
    // MARK: - Session Expiry
    
    private func handleSessionExpired() {
        currentUser = nil
        isAuthenticated = false
        errorMessage = "Your session has expired. Please log in again."
    }
}
