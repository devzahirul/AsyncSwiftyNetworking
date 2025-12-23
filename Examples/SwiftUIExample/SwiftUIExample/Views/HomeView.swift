import SwiftUI
import AsyncSwiftyNetworking

struct HomeView: View {
    
    var body: some View {
        TabView {
            UserProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
            
            PostsView()
                .tabItem {
                    Label("Posts", systemImage: "list.bullet")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

// MARK: - User Profile View

struct UserProfileView: View {
    @HiltViewModel(UserViewModel.self) var vm
    
    var body: some View {
        NavigationStack {
            NetworkDataView(vm) { (user: User) in
                VStack(spacing: 20) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(.blue.gradient)
                    
                    Text(user.name)
                        .font(.title.bold())
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("User ID: \(user.id)", systemImage: "number")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Posts View

struct PostsView: View {
    @HiltViewModel(PostListViewModel.self) var vm
    
    var body: some View {
        NavigationStack {
            NetworkListDataView(vm) { (post: Post) in
                VStack(alignment: .leading, spacing: 8) {
                    Text(post.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(post.body)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Posts")
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var authState = AuthState.shared
    
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    if authState.isLoggedIn {
                        Button("Logout", role: .destructive) {
                            AuthState.shared.logout()
                        }
                    }
                }
                
                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Library", value: "AsyncSwiftyNetworking")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    HomeView()
}
