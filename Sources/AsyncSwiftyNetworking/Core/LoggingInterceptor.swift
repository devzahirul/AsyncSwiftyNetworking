import Foundation
import os.log

/// An interceptor that logs requests and responses.
/// Thread-safe implementation suitable for concurrent use.
public final class LoggingInterceptor: RequestInterceptor, ResponseInterceptor, @unchecked Sendable {
    
    /// Log level options for controlling verbosity.
    public enum LogLevel: Sendable {
        case none
        case basic
        case verbose
    }
    
    private let level: LogLevel
    private let logger: Logger
    
    /// Creates a new logging interceptor.
    /// - Parameters:
    ///   - level: The logging verbosity level.
    ///   - subsystem: The subsystem for OSLog. Defaults to bundle identifier.
    ///   - category: The category for OSLog. Defaults to "Network".
    public init(
        level: LogLevel = .verbose,
        subsystem: String = Bundle.main.bundleIdentifier ?? "AsyncSwiftyNetworking",
        category: String = "Network"
    ) {
        self.level = level
        self.logger = Logger(subsystem: subsystem, category: category)
    }
    
    // MARK: - RequestInterceptor
    
    public func intercept(_ request: URLRequest) async throws -> URLRequest {
        guard level != .none else { return request }
        
        let method = request.httpMethod ?? "UNKNOWN"
        let url = request.url?.absoluteString ?? "<no url>"
        
        if level == .basic {
            logger.info("🚀 [REQUEST] \(method) \(url)")
        } else {
            logger.info("🚀 [REQUEST] \(method) \(url)")
            if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
                logger.debug("📋 Headers: \(headers)")
            }
            if let body = request.httpBody, let jsonString = String(data: body, encoding: .utf8) {
                logger.debug("📦 Body: \(jsonString)")
            }
        }
        
        return request
    }
    
    // MARK: - ResponseInterceptor
    
    public func intercept(_ response: HTTPURLResponse, data: Data) async throws -> Data {
        guard level != .none else { return data }
        
        let statusCode = response.statusCode
        let url = response.url?.absoluteString ?? "<no url>"
        let isSuccess = (200...299).contains(statusCode)
        
        if level == .basic {
            if isSuccess {
                logger.info("✅ [RESPONSE] \(statusCode) \(url)")
            } else {
                logger.error("❌ [RESPONSE] \(statusCode) \(url)")
            }
        } else {
            if isSuccess {
                logger.info("✅ [RESPONSE] \(statusCode) \(url)")
            } else {
                logger.error("❌ [RESPONSE] \(statusCode) \(url)")
            }
            if let jsonString = String(data: data, encoding: .utf8) {
                let truncated = String(jsonString.prefix(500))
                let suffix = jsonString.count > 500 ? "..." : ""
                logger.debug("📦 Data: \(truncated)\(suffix)")
            }
        }
        
        return data
    }
}
