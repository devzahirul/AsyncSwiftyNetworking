import Foundation

// MARK: - Network Error

/// Comprehensive error types for network operations.
/// Conforms to Equatable and Sendable for testing and concurrency safety.
/// Conforms to LocalizedError for proper error messaging.
public enum NetworkError: Error, Equatable, Sendable, LocalizedError, CustomStringConvertible {
    /// The URL provided was invalid or could not be constructed.
    case invalidURL
    
    /// No data was returned from the server.
    case noData
    
    /// Failed to decode the response data.
    /// - Parameter description: A description of the decoding error.
    case decodingError(String)
    
    /// Server returned an error response.
    /// - Parameters:
    ///   - statusCode: The HTTP status code.
    ///   - message: An optional error message from the server.
    ///   - data: The raw response data, if available.
    case serverError(statusCode: Int, message: String? = nil, data: Data? = nil)
    
    /// An underlying system error occurred.
    /// - Parameter description: A description of the underlying error.
    case underlying(String)
    
    /// An unknown error occurred.
    case unknown
    
    /// The request timed out.
    case timeout
    
    /// No network connection is available.
    case noConnection
    
    /// The request was cancelled.
    case cancelled
    
    /// An SSL/TLS error occurred.
    case sslError
    
    /// All retry attempts have been exhausted.
    /// - Parameter attempts: The number of attempts made.
    case retryExhausted(attempts: Int)
    
    /// The request was rate limited.
    /// - Parameter retryAfter: Seconds to wait before retrying, if provided.
    case rateLimited(retryAfter: TimeInterval?)
    
    /// Authentication is required or has failed.
    case unauthorized
    
    /// The requested resource was not found.
    case notFound
    
    // MARK: - LocalizedError
    
    public var errorDescription: String? {
        return description
    }
    
    // MARK: - CustomStringConvertible
    
    public var description: String {
        switch self {
        case .invalidURL:
            return "NetworkError.invalidURL: The URL provided was invalid."
        case .noData:
            return "NetworkError.noData: No data was returned from the server."
        case .decodingError(let detail):
            return "NetworkError.decodingError: Failed to decode response - \(detail)"
        case .serverError(let statusCode, let message, _):
            if let message = message {
                return "NetworkError.serverError(\(statusCode)): \(message)"
            }
            return "NetworkError.serverError(\(statusCode)): Server returned an error"
        case .underlying(let detail):
            return "NetworkError.underlying: \(detail)"
        case .unknown:
            return "NetworkError.unknown: An unknown error occurred."
        case .timeout:
            return "NetworkError.timeout: The request timed out."
        case .noConnection:
            return "NetworkError.noConnection: No network connection available."
        case .cancelled:
            return "NetworkError.cancelled: The request was cancelled."
        case .sslError:
            return "NetworkError.sslError: Secure connection could not be established."
        case .retryExhausted(let attempts):
            return "NetworkError.retryExhausted: Request failed after \(attempts) retry attempts."
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return "NetworkError.rateLimited: Retry after \(Int(seconds)) seconds."
            }
            return "NetworkError.rateLimited: Please try again later."
        case .unauthorized:
            return "NetworkError.unauthorized: Authentication required or has failed."
        case .notFound:
            return "NetworkError.notFound: The requested resource was not found."
        }
    }
    
    /// A human-readable short description of the error.
    public var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "The URL provided was invalid."
        case .noData:
            return "No data was returned from the server."
        case .decodingError(let description):
            return "Failed to decode the response: \(description)"
        case .serverError(let statusCode, let message, _):
            if let message = message {
                return message
            }
            return "Server returned an error with status code: \(statusCode)"
        case .underlying(let description):
            return description
        case .unknown:
            return "An unknown error occurred."
        case .timeout:
            return "The request timed out."
        case .noConnection:
            return "No network connection is available."
        case .cancelled:
            return "The request was cancelled."
        case .sslError:
            return "A secure connection could not be established."
        case .retryExhausted(let attempts):
            return "Request failed after \(attempts) retry attempts."
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return "Rate limited. Please retry after \(Int(seconds)) seconds."
            }
            return "Rate limited. Please try again later."
        case .unauthorized:
            return "Authentication required or has failed."
        case .notFound:
            return "The requested resource was not found."
        }
    }

    /// Checks if this is a "not found" error.
    public var isNotFound: Bool {
        switch self {
        case .notFound:
            return true
        case .serverError(let statusCode, _, _):
            return statusCode == 404
        default:
            return false
        }
    }
    
    /// Checks if this error is retryable.
    public var isRetryable: Bool {
        switch self {
        case .timeout, .noConnection, .retryExhausted:
            return true
        case .serverError(let statusCode, _, _):
            return (500...599).contains(statusCode)
        default:
            return false
        }
    }
    
    /// Checks if this is a client error (4xx).
    public var isClientError: Bool {
        switch self {
        case .unauthorized, .notFound:
            return true
        case .serverError(let statusCode, _, _):
            return (400...499).contains(statusCode)
        default:
            return false
        }
    }
    
    /// Checks if this is a server error (5xx).
    public var isServerError: Bool {
        switch self {
        case .serverError(let statusCode, _, _):
            return (500...599).contains(statusCode)
        default:
            return false
        }
    }
    
    /// Creates a NetworkError from a URLError.
    /// - Parameter urlError: The URL error to convert.
    /// - Returns: The corresponding NetworkError.
    public static func from(_ urlError: URLError) -> NetworkError {
        switch urlError.code {
        case .timedOut:
            return .timeout
        case .notConnectedToInternet, .networkConnectionLost:
            return .noConnection
        case .cancelled:
            return .cancelled
        case .secureConnectionFailed, .serverCertificateHasBadDate,
             .serverCertificateUntrusted, .serverCertificateHasUnknownRoot,
             .serverCertificateNotYetValid, .clientCertificateRejected:
            return .sslError
        default:
            return .underlying(urlError.localizedDescription)
        }
    }
    
    // MARK: - User-Friendly Messages
    
    /// A user-friendly message suitable for display in UI
    public var userMessage: String {
        switch self {
        case .invalidURL:
            return "The request could not be completed. Please try again."
        case .noData:
            return "No data was received. Please try again."
        case .decodingError:
            return "We couldn't process the server's response. Please contact support."
        case .serverError(let statusCode, let message, _):
            if let message = message, !message.isEmpty {
                return message
            }
            if (500...599).contains(statusCode) {
                return "The server is temporarily unavailable. Please try again later."
            }
            return "Something went wrong. Please try again."
        case .underlying:
            return "An unexpected error occurred. Please try again."
        case .unknown:
            return "An unknown error occurred. Please try again."
        case .timeout:
            return "The request timed out. Please check your connection and try again."
        case .noConnection:
            return "No internet connection. Please check your network settings."
        case .cancelled:
            return "The request was cancelled."
        case .sslError:
            return "A secure connection could not be established. Please contact support."
        case .retryExhausted:
            return "The request failed after multiple attempts. Please try again later."
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return "Too many requests. Please wait \(Int(seconds)) seconds."
            }
            return "Too many requests. Please wait a moment before trying again."
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .notFound:
            return "The requested item could not be found."
        }
    }
    
    // MARK: - Recovery Actions
    
    /// Suggested recovery action for this error
    public var recoveryAction: RecoveryAction {
        switch self {
        case .noConnection, .timeout, .retryExhausted:
            return .retry
        case .serverError(let statusCode, _, _):
            if (500...599).contains(statusCode) {
                return .retry
            }
            return .none
        case .rateLimited:
            return .retry
        case .unauthorized:
            return .reauthenticate
        case .decodingError, .sslError:
            return .contactSupport
        case .invalidURL, .noData, .underlying, .unknown, .cancelled, .notFound:
            return .none
        }
    }
}

// MARK: - Recovery Action

/// Suggested recovery actions for network errors
public enum RecoveryAction: Equatable, Sendable {
    /// User should retry the request
    case retry
    /// User should re-authenticate (login again)
    case reauthenticate
    /// User should contact support
    case contactSupport
    /// No recovery action available
    case none
    
    /// Suggested button title for the recovery action
    public var buttonTitle: String? {
        switch self {
        case .retry:
            return "Try Again"
        case .reauthenticate:
            return "Sign In"
        case .contactSupport:
            return "Contact Support"
        case .none:
            return nil
        }
    }
}

