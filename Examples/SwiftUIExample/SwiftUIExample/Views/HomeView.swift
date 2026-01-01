import SwiftUI
import AsyncSwiftyNetworking

struct HomeView: View {
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView {
            MoviesView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            FavoritesView()
                .tabItem {
                    Label("My Netflix", systemImage: "person.crop.circle")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .preferredColorScheme(.dark)
        .accentColor(.white)
    }
}

// MARK: - Movies View (Netflix Style)

struct MoviesView: View {
    @StateObject private var vm = PopularMoviesViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()
                
                if vm.isLoading && vm.movies.isEmpty {
                    ProgressView()
                        .tint(.red)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = vm.error, vm.movies.isEmpty {
                    NetworkErrorView(error: error) {
                        Task { await vm.load() }
                    }
                } else {
                    GeometryReader { geo in
                        let spacing: CGFloat = 8
                        let padding: CGFloat = 8
                        let totalHorizontalSpacing = (spacing * 2) + (padding * 2)
                        let itemWidth = (geo.size.width - totalHorizontalSpacing) / 3
                        
                        ScrollView {
                            VStack(spacing: 0) {
                                // Hero Header (Featured Movie)
                                if let heroMovie = vm.movies.first {
                                    HeroHeaderView(movie: heroMovie, width: geo.size.width)
                                }
                                
                                // Content Switcher
                                switch vm.mode {
                                case .popular:
                                    // Horizontal Rows (Netflix Style)
                                    LazyVStack(alignment: .leading, spacing: 30) {
                                        ForEach(vm.sections, id: \.genre) { section in
                                            VStack(alignment: .leading, spacing: 10) {
                                                Text(section.genre)
                                                    .font(.headline)
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(.white)
                                                    .padding(.horizontal, padding)
                                                
                                                ScrollView(.horizontal, showsIndicators: false) {
                                                    LazyHStack(spacing: 12) {
                                                        ForEach(section.movies) { movie in
                                                            NavigationLink(destination: MovieDetailView(movieId: movie.id)) {
                                                                MoviePoster(movie: movie)
                                                                    .frame(width: 140)
                                                            }
                                                            .buttonStyle(.plain)
                                                            .onAppear {
                                                                if movie.id == section.movies.last?.id {
                                                                    Task { await vm.loadNextPage() }
                                                                }
                                                            }
                                                        }
                                                    }
                                                    .padding(.horizontal, padding)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.vertical, 10)
                                    
                                case .search:
                                    // Search Results Grid (3 Columns)
                                    LazyVGrid(
                                        columns: Array(repeating: GridItem(.fixed(itemWidth), spacing: spacing), count: 3),
                                        spacing: spacing
                                    ) {
                                        ForEach(vm.movies) { movie in
                                            NavigationLink(destination: MovieDetailView(movieId: movie.id)) {
                                                MoviePoster(movie: movie)
                                            }
                                            .buttonStyle(.plain)
                                            .onAppear {
                                                if movie.id == vm.movies.last?.id {
                                                    Task { await vm.loadNextPage() }
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, padding)
                                    .padding(.vertical, 20)
                                }
                                
                                if vm.currentPage < vm.totalPages {
                                    ProgressView()
                                        .tint(.red)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                }
                            }
                        }
                        .ignoresSafeArea(edges: .top)
                        .refreshable {
                            await vm.load()
                        }
                        .searchable(text: Binding(
                            get: { vm.searchQuery },
                            set: { vm.search(query: $0) }
                        ), prompt: "Search movies, genres...")
                    }
                }
                
                // Custom Navigation Bar Overlay
                LinearGradient(colors: [.black.opacity(0.8), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 100)
                    .ignoresSafeArea()
                    .overlay(alignment: .top) {
                        HStack {
                            Text("N") // Logo
                                .font(.system(size: 40, weight: .black, design: .serif))
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "magnifyingglass")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        .padding(.top, 50) // Approx safe area
                    }
            }
            .task {
                if vm.movies.isEmpty {
                    await vm.load()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Subcomponents

struct HeroHeaderView: View {
    let movie: Movie
    let width: CGFloat
    
    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: movie.posterURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(Color.gray.opacity(0.3))
            }
            .frame(width: width, height: width * 1.5)
            .clipped()
            .overlay(
                LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
            )
            
            VStack(spacing: 16) {
                Text(movie.displayTitle)
                    .font(.system(size: 32, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .shadow(radius: 10)
                
                HStack(spacing: 8) {
                    Text("Popular")
                    Text("•")
                    Text("Movie")
                    if let date = movie.displayReleaseDate?.prefix(4) {
                        Text("•")
                        Text(String(date))
                    }
                }
                .font(.footnote)
                .fontWeight(.semibold)
                
                HStack(spacing: 20) {
                    Button(action: {}) {
                        VStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("My List").font(.caption2)
                        }
                    }
                    .foregroundColor(.white)
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Play")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(Color.white)
                        .cornerRadius(4)
                    }
                    
                    Button(action: {}) {
                        VStack(spacing: 4) {
                            Image(systemName: "info.circle")
                            Text("Info").font(.caption2)
                        }
                    }
                    .foregroundColor(.white)
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal)
            .frame(width: width) // Ensure content respects width
        }
    }
}

struct MoviePoster: View {
    let movie: Movie
    
    var body: some View {
        AsyncImage(url: movie.posterURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(Color(.systemGray6))
                .overlay {
                    Image(systemName: "film")
                        .foregroundColor(.gray)
                }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(2/3, contentMode: .fit)
        .cornerRadius(4)
        .clipped()
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
                
                Text("My List")
                    .font(.title.bold())
                
                Text("Your favorite movies will appear here")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("My List")
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
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    HomeView()
}
