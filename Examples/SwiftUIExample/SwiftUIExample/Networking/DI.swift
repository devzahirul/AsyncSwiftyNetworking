import Foundation
import AsyncSwiftyNetworking

// MARK: - DI Configuration

enum AppDI {
    
    // TMDB Bearer Token
    static let tmdbBearerToken = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJjM2ZkM2Y3Mzc4OTFkYTE3YWZiOTY5NzA5MDE0YWQ1MSIsIm5iZiI6MTY4MDA2MjkzMi4zODYsInN1YiI6IjY0MjNiOWQ0YWFlYzcxMDBmMmIzMTdlOCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.PM7Zpey8aw8oI2nmp8bT8z8yLEJB1-Ju4wbnflQc534"
    
    static func configure() {
        DI.configure { di in
            // Base URL
            di.baseURL = "https://api.themoviedb.org/3"
            
            // Token Storage (for session ID)
            let storage = UserDefaultsTokenStorage()
            di.registerSingleton(TokenStorage.self, instance: storage)
            
            // TMDB Bearer Token Interceptor
            let tmdbAuthInterceptor = TMDBAuthInterceptor(bearerToken: tmdbBearerToken)
            let loggingInterceptor = LoggingInterceptor(level: .verbose)
            
            // Network Client with TMDB auth
            di.register(URLSessionNetworkClient.self) {
                URLSessionNetworkClient.custom(
                    baseURL: di.baseURL,
                    requestInterceptors: [tmdbAuthInterceptor, loggingInterceptor],
                    responseInterceptors: [loggingInterceptor]
                )
            }
            
            // Services
            di.register(PopularMoviesService.self) {
                PopularMoviesService(.get("/movie/popular"))
            }
        }
    }
}

// MARK: - TMDB Auth Interceptor

class TMDBAuthInterceptor: RequestInterceptor {
    private let bearerToken: String
    
    init(bearerToken: String) {
        self.bearerToken = bearerToken
    }
    
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        var req = request
        req.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return req
    }
}


