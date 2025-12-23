import Foundation

// MARK: - Request Interceptor Protocol

/// A protocol for intercepting and modifying URLRequests before they are sent.
/// Must be `Sendable` for use with Swift Concurrency.
public protocol RequestInterceptor: Sendable {
    /// Intercepts and potentially modifies a URLRequest.
    /// - Parameter request: The original request.
    /// - Returns: The modified request.
    func intercept(_ request: URLRequest) async throws -> URLRequest
}

// MARK: - Response Interceptor Protocol

/// A protocol for intercepting responses after they are received.
/// Must be `Sendable` for use with Swift Concurrency.
public protocol ResponseInterceptor: Sendable {
    /// Intercepts a response and its data.
    /// - Parameters:
    ///   - response: The HTTP response.
    ///   - data: The response data.
    /// - Returns: Potentially modified data.
    func intercept(_ response: HTTPURLResponse, data: Data) async throws -> Data
}
