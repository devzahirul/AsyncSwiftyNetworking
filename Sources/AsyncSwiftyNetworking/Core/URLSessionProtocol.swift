import Foundation

// MARK: - URLSession Protocol

/// Protocol abstraction for URLSession enabling dependency injection and testing.
/// This allows mocking URLSession in unit tests for complete isolation.
public protocol URLSessionProtocol: Sendable {
    /// Performs a data task for the given request.
    /// - Parameter request: The URL request to perform.
    /// - Returns: A tuple containing the response data and URL response.
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

// MARK: - URLSession Conformance

extension URLSession: URLSessionProtocol {}

// MARK: - Data Task Publisher (for Combine support if needed)

#if canImport(Combine)
import Combine

extension URLSessionProtocol {
    /// Returns a publisher that wraps a URL session data task for a given request.
    /// - Parameter request: The URL request to perform.
    /// - Returns: A publisher that publishes data and response when the task completes.
    public func dataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), Error> {
        Future { promise in
            Task {
                do {
                    let result = try await self.data(for: request)
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
#endif
