import Foundation

// MARK: - API Error Response

/// Standard error response structure from APIs
internal struct APIErrorResponse: Decodable, Sendable {
    let message: String?
    let code: String?
    let details: [String: String]?
    let errors: [String: [String]]?

    var combinedMessage: String? {
        var parts: [String] = []

        if let message, !message.isEmpty {
            parts.append(message)
        }

        if let errors, !errors.isEmpty {
            let formatted = errors.keys.sorted().compactMap { key -> String? in
                guard let messages = errors[key], !messages.isEmpty else {
                    return nil
                }
                return "\(key): \(messages.joined(separator: " "))"
            }
            parts.append(contentsOf: formatted)
        }

        if let details, !details.isEmpty {
            let formatted = details.keys.sorted().map { key in
                let value = details[key] ?? ""
                return value.isEmpty ? key : "\(key): \(value)"
            }
            parts.append(contentsOf: formatted)
        }

        return parts.isEmpty ? nil : parts.joined(separator: "\n")
    }
}

// MARK: - Network Client Protocol

/// A protocol that defines the behavior of a network client.
/// Supports standard requests, paginated requests, and file uploads.
public protocol NetworkClient: Sendable {
    /// Performs a network request for the given endpoint.
    /// - Parameters:
    ///   - endpoint: The endpoint to request.
    ///   - baseUrl: The base URL for the API.
    /// - Returns: The decoded response.
    func request<T: HTTPResponseDecodable>(_ endpoint: Endpoint, baseUrl: String) async throws -> T
    
    /// Performs a paginated request.
    /// - Parameters:
    ///   - endpoint: The endpoint to request.
    ///   - baseUrl: The base URL for the API.
    ///   - pagination: The pagination parameters.
    /// - Returns: A paginated response containing the decoded items.
    func requestPaginated<T: Decodable>(_ endpoint: Endpoint, baseUrl: String, pagination: PaginationParams) async throws -> PaginatedResponse<T>
    
    /// Uploads files with multipart/form-data.
    /// - Parameters:
    ///   - endpoint: The endpoint to upload to.
    ///   - baseUrl: The base URL for the API.
    ///   - formData: The multipart form data containing files and fields.
    /// - Returns: The decoded response.
    func upload<T: HTTPResponseDecodable>(_ endpoint: Endpoint, baseUrl: String, formData: MultipartFormData) async throws -> T
}

// MARK: - URLSession Network Client

/// A concrete implementation of `NetworkClient` using `URLSession`.
/// Supports dependency injection for testing, configurable retry policies, and interceptor chains.
public final class URLSessionNetworkClient: NetworkClient, @unchecked Sendable {
    
    // MARK: - Properties
    
    private let session: any URLSessionProtocol
    private let decoder: JSONDecoder
    private let configuration: NetworkConfiguration
    private let requestInterceptors: [RequestInterceptor]
    private let responseInterceptors: [ResponseInterceptor]
    private let retryExecutor = RetryExecutor()
    
    // Internal properties for convenience extensions
    internal let _baseURL: String?
    internal let _hasLoggingInterceptor: Bool
    internal let _hasAuthInterceptor: Bool
    internal let _hasRefreshInterceptor: Bool
    
    /// Shared decoder to avoid recreating it multiple times.
    public static let defaultDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    /// Shared encoder to avoid recreating it multiple times.
    public static let defaultEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
    
    // MARK: - Initialization
    
    /// Creates a new URLSessionNetworkClient.
    /// - Parameters:
    ///   - session: The URLSession to use. Accepts any `URLSessionProtocol` for testing.
    ///   - configuration: The network configuration including timeouts and retry policies.
    ///   - decoder: The JSON decoder.
    ///   - requestInterceptors: Interceptors applied before sending requests.
    ///   - responseInterceptors: Interceptors applied after receiving responses.
    public init(
        session: any URLSessionProtocol = URLSession.shared,
        configuration: NetworkConfiguration = .default,
        decoder: JSONDecoder = URLSessionNetworkClient.defaultDecoder,
        requestInterceptors: [RequestInterceptor] = [],
        responseInterceptors: [ResponseInterceptor] = []
    ) {
        self.session = session
        self.configuration = configuration
        self.decoder = decoder
        self.requestInterceptors = requestInterceptors
        self.responseInterceptors = responseInterceptors
        self._baseURL = nil
        self._hasLoggingInterceptor = false
        self._hasAuthInterceptor = false
        self._hasRefreshInterceptor = false
    }
    
    /// Internal initializer with full configuration for convenience factory methods.
    internal init(
        session: any URLSessionProtocol = URLSession.shared,
        configuration: NetworkConfiguration = .default,
        decoder: JSONDecoder = URLSessionNetworkClient.defaultDecoder,
        requestInterceptors: [RequestInterceptor] = [],
        responseInterceptors: [ResponseInterceptor] = [],
        baseURL: String?,
        hasLoggingInterceptor: Bool,
        hasAuthInterceptor: Bool,
        hasRefreshInterceptor: Bool
    ) {
        self.session = session
        self.configuration = configuration
        self.decoder = decoder
        self.requestInterceptors = requestInterceptors
        self.responseInterceptors = responseInterceptors
        self._baseURL = baseURL
        self._hasLoggingInterceptor = hasLoggingInterceptor
        self._hasAuthInterceptor = hasAuthInterceptor
        self._hasRefreshInterceptor = hasRefreshInterceptor
    }
    
    /// Convenience initializer with common interceptors.
    /// - Parameter enableLogging: Whether to enable request/response logging.
    /// - Returns: A configured URLSessionNetworkClient instance.
    public static func withDefaultInterceptors(
        enableLogging: Bool = true,
        configuration: NetworkConfiguration = .default
    ) -> URLSessionNetworkClient {
        var requestInterceptors: [RequestInterceptor] = [AuthInterceptor()]
        var responseInterceptors: [ResponseInterceptor] = []
        
        if enableLogging {
            let loggingInterceptor = LoggingInterceptor(level: .verbose)
            requestInterceptors.append(loggingInterceptor)
            responseInterceptors.append(loggingInterceptor)
        }
        
        return URLSessionNetworkClient(
            configuration: configuration,
            requestInterceptors: requestInterceptors,
            responseInterceptors: responseInterceptors
        )
    }
    
    // MARK: - Request
    
    public func request<T: HTTPResponseDecodable>(_ endpoint: Endpoint, baseUrl: String) async throws -> T {
        let request = try buildRequest(for: endpoint, baseUrl: baseUrl)
        return try await performWithRetry(request)
    }
    
    // MARK: - Paginated Request
    
    public func requestPaginated<T: Decodable>(_ endpoint: Endpoint, baseUrl: String, pagination: PaginationParams) async throws -> PaginatedResponse<T> {
        var request = try buildRequest(for: endpoint, baseUrl: baseUrl)
        
        // Append pagination query items
        guard let url = request.url,
              var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }
        
        var existingItems = urlComponents.queryItems ?? []
        existingItems.append(contentsOf: pagination.queryItems)
        urlComponents.queryItems = existingItems
        
        guard let paginatedURL = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        request.url = paginatedURL
        return try await performWithRetry(request)
    }
    
    // MARK: - Upload
    
    public func upload<T: HTTPResponseDecodable>(_ endpoint: Endpoint, baseUrl: String, formData: MultipartFormData) async throws -> T {
        var request = try buildRequest(for: endpoint, baseUrl: baseUrl)
        request.httpBody = formData.finalize()
        request.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")
        
        return try await performWithRetry(request)
    }
    
    // MARK: - Private Helpers
    
    private func buildRequest(for endpoint: Endpoint, baseUrl: String) throws -> URLRequest {
        guard var urlComponents = URLComponents(string: baseUrl) else {
            throw NetworkError.invalidURL
        }
        urlComponents.path = urlComponents.path.appending(endpoint.path)
        urlComponents.queryItems = endpoint.queryItems
        
        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        request.timeoutInterval = configuration.timeoutInterval
        request.cachePolicy = configuration.cachePolicy
        
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
    
    private func performWithRetry<T: HTTPResponseDecodable>(_ request: URLRequest) async throws -> T {
        if configuration.retryPolicy == .none {
            return try await perform(request)
        }
        
        return try await retryExecutor.execute(with: configuration.retryPolicy) {
            try await self.perform(request)
        }
    }
    
    private func perform<T: HTTPResponseDecodable>(_ request: URLRequest) async throws -> T {
        // Apply request interceptors
        var interceptedRequest = request
        for interceptor in requestInterceptors {
            interceptedRequest = try await interceptor.intercept(interceptedRequest)
        }
        
        // Perform request with error handling
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: interceptedRequest)
        } catch let urlError as URLError {
            throw NetworkError.from(urlError)
        } catch {
            throw NetworkError.underlying(error.localizedDescription)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }
        
        // Apply response interceptors
        var interceptedData = data
        for interceptor in responseInterceptors {
            interceptedData = try await interceptor.intercept(httpResponse, data: interceptedData)
        }
        
        // Handle specific status codes
        switch httpResponse.statusCode {
        case 200...299:
            break // Success, continue to decode
        case 401:
            throw NetworkError.unauthorized
        case 404:
            throw NetworkError.notFound
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { TimeInterval($0) }
            throw NetworkError.rateLimited(retryAfter: retryAfter)
        default:
            // Try to parse error message from response body
            var errorMessage: String?
            if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: interceptedData) {
                errorMessage = errorResponse.combinedMessage
            }
            throw NetworkError.serverError(
                statusCode: httpResponse.statusCode,
                message: errorMessage,
                data: interceptedData
            )
        }
        
        // Decode response
        do {
            var decodedResponse = try decoder.decode(T.self, from: interceptedData)
            decodedResponse.statusCode = httpResponse.statusCode
            return decodedResponse
        } catch {
            throw NetworkError.decodingError(error.localizedDescription)
        }
    }
}

