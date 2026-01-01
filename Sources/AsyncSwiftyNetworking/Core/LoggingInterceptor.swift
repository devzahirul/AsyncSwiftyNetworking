import Foundation
import os.log

/// An interceptor that logs requests and responses.
/// Thread-safe implementation suitable for concurrent use.
/// 
/// Supports per-request logging configuration via headers:
/// - `X-Logging-Enabled`: "false" to disable logging for this request
/// - `X-Log-Level`: "none", "basic", or "verbose" to override log level
public final class LoggingInterceptor: RequestInterceptor, ResponseInterceptor, @unchecked Sendable {
    
    /// Header keys used for per-request logging configuration
    public static let loggingEnabledHeader = "X-Logging-Enabled"
    public static let logLevelHeader = "X-Log-Level"
    
    private let defaultLevel: LogLevel
    private let logger: Logger
    
    /// Creates a new logging interceptor.
    /// - Parameters:
    ///   - level: The default logging verbosity level.
    ///   - subsystem: The subsystem for OSLog. Defaults to bundle identifier.
    ///   - category: The category for OSLog. Defaults to "Network".
    public init(
        level: LogLevel = .verbose,
        subsystem: String = Bundle.main.bundleIdentifier ?? "AsyncSwiftyNetworking",
        category: String = "Network"
    ) {
        self.defaultLevel = level
        self.logger = Logger(subsystem: subsystem, category: category)
    }
    
    // MARK: - RequestInterceptor
    
    public func intercept(_ request: URLRequest) async throws -> URLRequest {
        let (isEnabled, level) = getLoggingConfig(from: request)
        guard isEnabled && level != .none else { return request }
        
        let method = request.httpMethod ?? "UNKNOWN"
        let url = request.url?.absoluteString ?? "<no url>"
        
        if level == .basic {
            logger.info("🚀 [REQUEST] \(method) \(url)")
        } else {
            logger.info("🚀 [REQUEST] \(method) \(url)")
            if let headers = request.allHTTPHeaderFields?.filter({ !$0.key.hasPrefix("X-Log") }), !headers.isEmpty {
                logger.debug("📋 Headers: \(headers)")
            }
            if let body = request.httpBody, let jsonString = formatBody(body) {
                logger.debug("📦 Body: \(jsonString)")
            }
        }
        
        return request
    }
    
    // MARK: - ResponseInterceptor
    
    public func intercept(_ response: HTTPURLResponse, data: Data) async throws -> Data {
        // Note: We can't easily get the original request's logging config here
        // So we use the default level for responses
        guard defaultLevel != .none else { return data }
        
        let statusCode = response.statusCode
        let url = response.url?.absoluteString ?? "<no url>"
        
        let icon = self.icon(for: statusCode)
        
        if defaultLevel == .basic {
             logger.info("\(icon) [RESPONSE] \(statusCode) \(url)")
        } else {
             logger.info("\(icon) [RESPONSE] \(statusCode) \(url)")
             
            if let jsonString = formatBody(data) {
                let truncated = String(jsonString.prefix(2000))
                let suffix = jsonString.count > 2000 ? "..." : ""
                logger.debug("📦 Data: \(truncated)\(suffix)")
            }
        }
        
        return data
    }
    
    // MARK: - Private Helpers
    
    // MARK: - Private Helpers
    
    private func getLoggingConfig(from request: URLRequest) -> (enabled: Bool, level: LogLevel) {
        // Check for per-request logging enabled flag
        if let enabledHeader = request.value(forHTTPHeaderField: Self.loggingEnabledHeader),
           enabledHeader.lowercased() == "false" {
            return (false, .none)
        }
        
        // Check for per-request log level
        if let levelHeader = request.value(forHTTPHeaderField: Self.logLevelHeader) {
            switch levelHeader.lowercased() {
            case "none": return (true, .none)
            case "basic": return (true, .basic)
            case "verbose": return (true, .verbose)
            default: break
            }
        }
        
        return (true, defaultLevel)
    }
    
    private func formatBody(_ data: Data) -> String? {
        if let object = try? JSONSerialization.jsonObject(with: data, options: []),
           let prettyData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
           let string = String(data: prettyData, encoding: .utf8) {
            return string
        }
        return String(data: data, encoding: .utf8)
    }
    
    private func icon(for statusCode: Int) -> String {
        switch statusCode {
        case 200...299: return "✅"
        case 300...399: return "↪️"
        case 400...499: return "⚠️"
        case 500...599: return "❌"
        default: return "❓"
        }
    }
}

