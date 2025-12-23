import SwiftUI
import AsyncSwiftyNetworking

struct HomeView: View {
    
    var body: some View {
        TabView {
            MoviesView()
                .tabItem {
                    Label("Movies", systemImage: "film")
                }
            
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

// MARK: - Movies View

struct MoviesView: View {
    @HiltViewModel(PopularMoviesViewModel.self) var vm
    
    var body: some View {
        NavigationStack {
            NetworkDataView(vm) { (response: PopularMoviesResponse) in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(response.results) { movie in
                            NavigationLink(destination: MovieDetailView(movieId: movie.id)) {
                                MovieCard(movie: movie)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Popular Movies")
        }
    }
}

// MARK: - Movie Card

struct MovieCard: View {
    let movie: Movie
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Poster
            AsyncImage(url: movie.posterURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "film")
                            .foregroundColor(.gray)
                    }
            }
            .frame(width: 100, height: 150)
            .cornerRadius(8)
            
            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(movie.title)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", movie.voteAverage))
                        .font(.subheadline.bold())
                }
                
                if let date = movie.releaseDate {
                    Text(date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(movie.overview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                Spacer()
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Favorites View

struct FavoritesView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.red.gradient)
                
                Text("Favorites")
                    .font(.title.bold())
                
                Text("Your favorite movies will appear here")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Favorites")
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
                    } else {
                        Text("Not logged in")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("API", value: "TMDB v3")
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
