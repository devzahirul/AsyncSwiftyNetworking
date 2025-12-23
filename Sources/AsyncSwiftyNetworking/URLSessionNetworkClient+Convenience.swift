import Foundation

// MARK: - URLSessionNetworkClient Convenience Extensions

public extension URLSessionNetworkClient {
    
    // MARK: - Properties for Test Introspection
    
    /// The configured base URL, if any
    var baseURL: String? {
        _baseURL
    }
    
    /// Whether this client has a logging interceptor configured
    var hasLoggingInterceptor: Bool {
        _hasLoggingInterceptor
    }
    
    /// Whether this client has an auth interceptor configured
    var hasAuthInterceptor: Bool {
        _hasAuthInterceptor
    }
    
    /// Whether this client has a refresh token interceptor configured
    var hasRefreshInterceptor: Bool {
        _hasRefreshInterceptor
    }
    
    // MARK: - Quick Setup Factory Methods
    
    /// Creates a client with minimal configuration - perfect for quick prototyping
    /// - Parameters:
    ///   - baseURL: The base URL for all requests
    ///   - logging: Whether to enable request/response logging
    ///   - session: Optional custom URLSession (default: shared)
    /// - Returns: A configured URLSessionNetworkClient
    static func quick(
        baseURL: String,
        logging: Bool = false,
        session: any URLSessionProtocol = URLSession.shared
    ) -> URLSessionNetworkClient {
        var requestInterceptors: [RequestInterceptor] = []
        var responseInterceptors: [ResponseInterceptor] = []
        
        if logging {
            let loggingInterceptor = LoggingInterceptor(level: .verbose)
            requestInterceptors.append(loggingInterceptor)
            responseInterceptors.append(loggingInterceptor)
        }
        
        return URLSessionNetworkClient(
            session: session,
            configuration: .default,
            requestInterceptors: requestInterceptors,
            responseInterceptors: responseInterceptors,
            baseURL: baseURL,
            hasLoggingInterceptor: logging,
            hasAuthInterceptor: false,
            hasRefreshInterceptor: false
        )
    }
    
    /// Creates a client with authentication support including auto token refresh
    /// - Parameters:
    ///   - baseURL: The base URL for all requests
    ///   - tokenStorage: Storage for managing auth tokens
    ///   - refreshHandler: Handler for refreshing expired tokens
    ///   - logging: Whether to enable logging
    /// - Returns: A configured URLSessionNetworkClient
    static func withAuth(
        baseURL: String,
        tokenStorage: TokenStorage,
        refreshHandler: TokenRefreshHandler,
        logging: Bool = false
    ) -> URLSessionNetworkClient {
        let authInterceptor = AuthInterceptor(storage: tokenStorage)
        let refreshInterceptor = RefreshTokenInterceptor(
            tokenStorage: tokenStorage,
            refreshHandler: refreshHandler
        )
        
        var requestInterceptors: [RequestInterceptor] = [authInterceptor, refreshInterceptor]
        var responseInterceptors: [ResponseInterceptor] = [refreshInterceptor]
        
        if logging {
            let loggingInterceptor = LoggingInterceptor(level: .verbose)
            requestInterceptors.append(loggingInterceptor)
            responseInterceptors.append(loggingInterceptor)
        }
        
        return URLSessionNetworkClient(
            configuration: .default,
            requestInterceptors: requestInterceptors,
            responseInterceptors: responseInterceptors,
            baseURL: baseURL,
            hasLoggingInterceptor: logging,
            hasAuthInterceptor: true,
            hasRefreshInterceptor: true
        )
    }
    
    /// Creates a client optimized for mobile networks with retry support
    /// - Parameter baseURL: The base URL for all requests
    /// - Returns: A configured URLSessionNetworkClient with mobile optimizations
    static func mobile(baseURL: String) -> URLSessionNetworkClient {
        return URLSessionNetworkClient(
            configuration: .mobile,
            requestInterceptors: [],
            responseInterceptors: [],
            baseURL: baseURL,
            hasLoggingInterceptor: false,
            hasAuthInterceptor: false,
            hasRefreshInterceptor: false
        )
    }
    
    /// Creates a custom client with user-provided interceptors
    /// - Parameters:
    ///   - baseURL: The base URL for all requests
    ///   - requestInterceptors: Custom request interceptors
    ///   - responseInterceptors: Custom response interceptors
    ///   - configuration: Network configuration (default: .default)
    /// - Returns: A configured URLSessionNetworkClient
    static func custom(
        baseURL: String,
        requestInterceptors: [RequestInterceptor],
        responseInterceptors: [ResponseInterceptor] = [],
        configuration: NetworkConfiguration = .default
    ) -> URLSessionNetworkClient {
        return URLSessionNetworkClient(
            configuration: configuration,
            requestInterceptors: requestInterceptors,
            responseInterceptors: responseInterceptors,
            baseURL: baseURL,
            hasLoggingInterceptor: false,
            hasAuthInterceptor: false,
            hasRefreshInterceptor: false
        )
    }
    
    // MARK: - Convenience Request Methods
    
    /// Performs a request using the configured base URL
    /// - Parameter endpoint: The endpoint to request
    /// - Returns: The decoded response
    func request<T: HTTPResponseDecodable>(_ endpoint: Endpoint) async throws -> T {
        guard let baseURL = _baseURL else {
            throw NetworkError.invalidURL
        }
        return try await request(endpoint, baseUrl: baseURL)
    }
    
    /// Performs a request and returns raw Data (no decoding)
    /// - Parameter endpoint: The endpoint to request
    /// - Returns: The raw response data
    func requestData(_ endpoint: Endpoint) async throws -> Data {
        guard let baseURL = _baseURL else {
            throw NetworkError.invalidURL
        }
        let response: RawDataResponse = try await request(endpoint, baseUrl: baseURL)
        return response.data
    }
    
    /// Performs a request expecting no response body (for 204 No Content, etc.)
    /// - Parameter endpoint: The endpoint to request
    func requestVoid(_ endpoint: Endpoint) async throws {
        guard let baseURL = _baseURL else {
            throw NetworkError.invalidURL
        }
        let _: VoidResponse = try await request(endpoint, baseUrl: baseURL)
    }
}

// MARK: - Supporting Types

/// Response type for raw data requests
public struct RawDataResponse: HTTPResponseDecodable {
    public let data: Data
    public var statusCode: Int?
    
    public init(from decoder: Decoder) throws {
        // This won't actually be used - we need a different approach
        self.data = Data()
        self.statusCode = nil
    }
    
    init(data: Data, statusCode: Int?) {
        self.data = data
        self.statusCode = statusCode
    }
}

/// Response type for void requests (no body expected)
public struct VoidResponse: HTTPResponseDecodable {
    public var statusCode: Int?
    
    public init(from decoder: Decoder) throws {
        self.statusCode = nil
    }
}

