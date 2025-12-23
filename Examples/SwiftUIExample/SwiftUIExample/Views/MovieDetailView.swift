import SwiftUI
import AsyncSwiftyNetworking
import WebKit

// MARK: - Movie Detail View

struct MovieDetailView: View {
    let movieId: Int
    @StateObject private var vm = MovieDetailViewModel()
    @StateObject private var videosVM = VideosViewModel()
    
    var body: some View {
        ScrollView {
            if vm.isLoading && vm.data == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else if let error = vm.error {
                VStack(spacing: 16) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(error.userMessage)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task { await loadMovie() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if let movie = vm.data {
                MovieDetailContent(movie: movie, videos: videosVM.data)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadMovie()
            await loadVideos()
        }
    }
    
    private func loadMovie() async {
        let service = MovieDetailService(
            .get("/movie/\(movieId)")
                .query("language", "en-US")
        )
        vm.setService(service)
        await vm.load()
    }
    
    private func loadVideos() async {
        let service = VideosService(
            .get("/movie/\(movieId)/videos")
                .query("language", "en-US")
        )
        videosVM.setService(service)
        await videosVM.load()
    }
}

// MARK: - Movie Detail Content

struct MovieDetailContent: View {
    let movie: MovieDetail
    let videos: VideosResponse?
    @State private var showingTrailer = false
    
    private var trailer: Video? {
        videos?.results.first { $0.isTrailer } ?? videos?.results.first
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Trailer Player or Backdrop
            if let trailer = trailer {
                TrailerThumbnail(video: trailer, showingTrailer: $showingTrailer)
            } else {
                // Fallback to Backdrop
                AsyncImage(url: movie.backdropURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(height: 220)
                .clipped()
            }
            
            // Content
            VStack(alignment: .leading, spacing: 16) {
                // Title & Rating
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(movie.title)
                            .font(.title.bold())
                        
                        if let tagline = movie.tagline, !tagline.isEmpty {
                            Text(tagline)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                    
                    Spacer()
                    
                    VStack {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", movie.voteAverage))
                                .font(.title2.bold())
                        }
                        Text("\(movie.voteCount) votes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Genres
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(movie.genres) { genre in
                            Text(genre.name)
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(16)
                        }
                    }
                }
                
                // Info Row
                HStack(spacing: 24) {
                    InfoItem(icon: "clock", title: "Runtime", value: movie.formattedRuntime)
                    InfoItem(icon: "calendar", title: "Release", value: movie.releaseDate ?? "N/A")
                    InfoItem(icon: "globe", title: "Language", value: movie.originalLanguage.uppercased())
                }
                
                Divider()
                
                // Overview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Overview")
                        .font(.headline)
                    Text(movie.overview)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Stats
                HStack(spacing: 24) {
                    InfoItem(icon: "dollarsign.circle", title: "Budget", value: movie.formattedBudget)
                    InfoItem(icon: "chart.bar", title: "Revenue", value: movie.formattedRevenue)
                    InfoItem(icon: "checkmark.seal", title: "Status", value: movie.status)
                }
                
                // Collection
                if let collection = movie.belongsToCollection {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Collection")
                            .font(.headline)
                        HStack {
                            AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w200\(collection.posterPath ?? "")")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 60, height: 90)
                            .cornerRadius(8)
                            
                            Text(collection.name)
                                .font(.subheadline.bold())
                        }
                    }
                }
                
                // Production Companies
                if !movie.productionCompanies.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Production")
                            .font(.headline)
                        Text(movie.productionCompanies.map { $0.name }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingTrailer) {
            if let trailer = trailer, let url = trailer.youtubeURL {
                YouTubePlayerSheet(url: url, title: trailer.name)
            }
        }
    }
}

// MARK: - Trailer Thumbnail

struct TrailerThumbnail: View {
    let video: Video
    @Binding var showingTrailer: Bool
    
    var body: some View {
        ZStack {
            AsyncImage(url: video.thumbnailURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(height: 220)
            .clipped()
            
            // Play Button Overlay
            Button {
                showingTrailer = true
            } label: {
                ZStack {
                    Circle()
                        .fill(.black.opacity(0.6))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
            }
            
            // Trailer Label
            VStack {
                Spacer()
                HStack {
                    Label("Watch Trailer", systemImage: "film")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    Spacer()
                }
                .padding()
            }
        }
    }
}

// MARK: - YouTube Player Sheet

struct YouTubePlayerSheet: View {
    let url: URL
    let title: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            WebView(url: url)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - WebView for YouTube

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.configuration.allowsInlineMediaPlayback = true
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

// MARK: - Info Item

struct InfoItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption.bold())
        }
    }
}

// MARK: - Videos ViewModel

typealias VideosService = GenericNetworkService<VideosResponse>
typealias VideosViewModel = GenericNetworkViewModel<VideosResponse>
