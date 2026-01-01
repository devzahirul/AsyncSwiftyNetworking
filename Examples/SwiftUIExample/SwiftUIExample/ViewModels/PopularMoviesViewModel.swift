import SwiftUI
import AsyncSwiftyNetworking

@MainActor
final class PopularMoviesViewModel: ObservableObject, DefaultInitializable {
    
    enum ListMode {
        case popular
        case search(String)
    }
    
    @Published var movies: [Movie] = []
    @Published var sections: [(genre: String, movies: [Movie])] = []
    @Published var isLoading = false
    @Published var error: NetworkError?
    @Published var errorMessage: String?
    @Published var debugInfo: String = ""
    @Published var searchQuery: String = ""
    
    // Pagination
    var currentPage = 1
    var totalPages = 1
    private var isFetching = false
    
    // Search
    private(set) var mode: ListMode = .popular
    private var searchTask: Task<Void, Never>?
    
    required init() {}
    
    // MARK: - API
    
    func search(query: String) {
        self.searchQuery = query
        searchTask?.cancel()
        
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if case .popular = mode { return } // Already popular
            self.mode = .popular
            self.resetPagination()
            Task { await load() }
            return
        }
        
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s Debounce
            if Task.isCancelled { return }
            
            await MainActor.run {
                self.mode = .search(query)
                self.resetPagination()
            }
            await self.fetchPage(page: 1)
        }
    }
    
    func load() async {
        guard !isFetching else { return }
        await fetchPage(page: 1)
    }
    
    func loadNextPage() async {
        guard !isFetching, currentPage < totalPages else { return }
        await fetchPage(page: currentPage + 1)
    }
    
    private func resetPagination() {
        self.movies = []
        self.sections = []
        self.currentPage = 1
        self.isFetching = false
    }
    
    private func fetchPage(page: Int) async {
        guard !isFetching else { return }
        isFetching = true
        
        await MainActor.run { isLoading = true }
        
        // Determine Endpoint
        let endpointPath: String
        var queryItems: [String: String] = [
            "api_key": "YOUR_API_KEY", // Ideally injected or Config
            "language": "en-US",
            "page": "\(page)"
        ]
        
        switch mode {
        case .popular:
            endpointPath = "/movie/popular"
        case .search(let query):
            endpointPath = "/search/movie"
            queryItems["query"] = query
        }
        
        // Build Request using static factory
        var builder = RequestBuilder.get(endpointPath)
        
        // Apply Query Items
        for (key, value) in queryItems {
            builder = builder.query(key, value)
        }
        
        do {
            // Resolve Client using DI
            let client = DI.shared.resolve(URLSessionNetworkClient.self)
            
            // Execute Request
            let data = try await client.requestData(builder)
            
            // Manual Decoding Logic (Preserving your robust fixes)
            let decoder = JSONDecoder()
            let response: PopularMoviesResponse
            
            do {
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                response = try decoder.decode(PopularMoviesResponse.self, from: data)
            } catch {
                print("SnakeCase failed, trying default: \(error)")
                decoder.keyDecodingStrategy = .useDefaultKeys
                response = try decoder.decode(PopularMoviesResponse.self, from: data)
            }
            
            await MainActor.run {
                if page == 1 {
                    self.movies = response.results ?? []
                } else {
                    if let newMovies = response.results {
                        let currentIds = Set(self.movies.map { $0.id })
                        let uniqueNewMovies = newMovies.filter { !currentIds.contains($0.id) }
                        self.movies.append(contentsOf: uniqueNewMovies)
                    }
                }
                
                self.updateSections()
                
                self.currentPage = response.page ?? 1
                self.totalPages = response.totalPages ?? 1
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error as? NetworkError ?? .unknown
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
        
        isFetching = false
    }
    
    private func updateSections() {
        // If Search Mode: Show all results in one section or keep categorized?
        // Usually Search Results are flat. But we can still categorize them if we want.
        // For distinct UI, let's keep them categorized if possible, OR just one "Results" section.
        // User said "show same view".
        
        switch mode {
        case .popular:
            let grouped = Dictionary(grouping: movies) { movie in
                guard let genreId = movie.genreIds?.first else { return "Other" }
                return GenreUtils.genreName(for: genreId)
            }
            self.sections = grouped
                .map { (genre: $0.key, movies: $0.value) }
                .sorted { $0.genre < $1.genre }
                
        case .search:
            // For search, usually flat list is better.
            // But to reuse the "Rows" UI, we could put them in one "Results" section?
            // OR we switch UI to Grid.
            // View will decide. But let's populate 'sections' just in case View uses it.
            // Let's create one section "Top Results"
             self.sections = [(genre: "Results", movies: self.movies)]
        }
    }
}
