import Foundation

// MARK: - Network Configuration

/// Centralized configuration for network behavior.
/// Allows customization of timeouts, retry policies, and caching strategies.
public struct NetworkConfiguration: Sendable {
    
    /// The timeout interval for requests.
    public let timeoutInterval: TimeInterval
    
    /// The retry policy for failed requests.
    public let retryPolicy: RetryPolicy
    
    /// The cache policy for requests.
    public let cachePolicy: URLRequest.CachePolicy
    
    /// Creates a new network configuration.
    /// - Parameters:
    ///   - timeoutInterval: The timeout interval in seconds. Default is 30.
    ///   - retryPolicy: The retry policy. Default is `.none`.
    ///   - cachePolicy: The cache policy. Default is `.useProtocolCachePolicy`.
    public init(
        timeoutInterval: TimeInterval = 30,
        retryPolicy: RetryPolicy = .none,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    ) {
        self.timeoutInterval = timeoutInterval
        self.retryPolicy = retryPolicy
        self.cachePolicy = cachePolicy
    }
    
    /// The default configuration with sensible defaults.
    public static let `default` = NetworkConfiguration()
    
    /// A configuration optimized for mobile networks with retry support.
    public static let mobile = NetworkConfiguration(
        timeoutInterval: 60,
        retryPolicy: .exponentialBackoff(maxRetries: 3, baseDelay: 1.0),
        cachePolicy: .returnCacheDataElseLoad
    )
}

// MARK: - Retry Policy

/// Defines the retry strategy for failed network requests.
public enum RetryPolicy: Sendable, Equatable {
    /// No retry attempts will be made.
    case none
    
    /// Retry with exponential backoff.
    /// - Parameters:
    ///   - maxRetries: Maximum number of retry attempts.
    ///   - baseDelay: The base delay in seconds (doubles with each retry).
    case exponentialBackoff(maxRetries: Int, baseDelay: TimeInterval)
    
    /// Retry with a fixed delay between attempts.
    /// - Parameters:
    ///   - maxRetries: Maximum number of retry attempts.
    ///   - delay: The fixed delay between retries in seconds.
    case fixed(maxRetries: Int, delay: TimeInterval)
    
    /// The maximum number of retries for this policy.
    public var maxRetries: Int {
        switch self {
        case .none:
            return 0
        case .exponentialBackoff(let maxRetries, _):
            return maxRetries
        case .fixed(let maxRetries, _):
            return maxRetries
        }
    }
    
    /// Calculates the delay for a given attempt.
    /// - Parameter attempt: The current attempt number (0-indexed).
    /// - Returns: The delay in seconds before the next retry.
    public func delay(for attempt: Int) -> TimeInterval {
        switch self {
        case .none:
            return 0
        case .exponentialBackoff(_, let baseDelay):
            return baseDelay * pow(2.0, Double(attempt))
        case .fixed(_, let delay):
            return delay
        }
    }
    
    /// Determines if a retry should be attempted based on the error.
    /// - Parameter error: The error that occurred.
    /// - Returns: `true` if the request should be retried.
    public func shouldRetry(for error: Error) -> Bool {
        guard self != .none else { return false }
        
        // Check for retryable URL errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                return true
            default:
                return false
            }
        }
        
        // Check for server errors (5xx) that are retryable
        if let networkError = error as? NetworkError {
            switch networkError {
            case .serverError(let statusCode, _, _):
                return (500...599).contains(statusCode)
            case .timeout, .noConnection:
                return true
            default:
                return false
            }
        }
        
        return false
    }
}

// MARK: - Retry Executor

/// Helper actor to execute retry logic with proper concurrency.
actor RetryExecutor {
    
    /// Executes an operation with retry logic based on the given policy.
    /// - Parameters:
    ///   - policy: The retry policy to use.
    ///   - operation: The async operation to execute.
    /// - Returns: The result of the operation.
    func execute<T>(
        with policy: RetryPolicy,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0...policy.maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Check if we should retry
                guard attempt < policy.maxRetries && policy.shouldRetry(for: error) else {
                    throw error
                }
                
                // Wait before retrying
                let delay = policy.delay(for: attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        throw lastError ?? NetworkError.retryExhausted(attempts: policy.maxRetries)
    }
}
