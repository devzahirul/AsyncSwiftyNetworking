import SwiftUI
import AsyncSwiftyNetworking

// MARK: - App Entry Point

@main
struct SwiftUIExampleApp: App {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}

// MARK: - Main Content View

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    var body: some View {
        TabView {
            PostsView()
                .tabItem {
                    Label("Posts", systemImage: "list.bullet")
                }
            
            CreatePostView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle")
                }
            
            ImageUploadView()
                .tabItem {
                    Label("Upload", systemImage: "photo.stack")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AuthManager.shared)
}
