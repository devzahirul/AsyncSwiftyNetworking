import Foundation

/// Generic Mutation Service for POST/PUT/DELETE requests with dynamic body
public final class GenericMutationService<Request: Encodable, Response: HTTPResponseDecodable>: @unchecked Sendable {
    
    private let path: String
    private let method: HTTPMethod
    private var client: URLSessionNetworkClient?
    
    /// Initialize with HTTP method and path
    public init(_ method: HTTPMethod, _ path: String) {
        self.method = method
        self.path = path
    }
    
    /// Execute the mutation with request body
    public func execute(_ request: Request) async throws -> Response {
        let resolvedClient = getClient()
        let builder = createBuilder().body(request)
        return try await resolvedClient.request(builder)
    }
    
    private func createBuilder() -> RequestBuilder {
        switch method {
        case .get: return .get(path)
        case .post: return .post(path)
        case .put: return .put(path)
        case .delete: return .delete(path)
        case .patch: return .patch(path)
        }
    }
    
    private func getClient() -> URLSessionNetworkClient {
        if client == nil {
            client = DI.shared.resolve(URLSessionNetworkClient.self)
        }
        return client!
    }
}

