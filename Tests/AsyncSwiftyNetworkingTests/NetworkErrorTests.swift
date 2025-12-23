import Testing
import Foundation
@testable import AsyncSwiftyNetworking

// MARK: - NetworkError Tests

@Suite("NetworkError Tests")
struct NetworkErrorTests {
    
    // MARK: - Equatable Tests
    
    @Test("Errors are equatable")
    func testEquatable() {
        #expect(NetworkError.invalidURL == NetworkError.invalidURL)
        #expect(NetworkError.noData == NetworkError.noData)
        #expect(NetworkError.timeout == NetworkError.timeout)
        #expect(NetworkError.noConnection == NetworkError.noConnection)
        #expect(NetworkError.cancelled == NetworkError.cancelled)
        #expect(NetworkError.sslError == NetworkError.sslError)
        #expect(NetworkError.unknown == NetworkError.unknown)
        #expect(NetworkError.unauthorized == NetworkError.unauthorized)
        #expect(NetworkError.notFound == NetworkError.notFound)
        
        #expect(NetworkError.decodingError("error") == NetworkError.decodingError("error"))
        #expect(NetworkError.decodingError("error1") != NetworkError.decodingError("error2"))
        
        #expect(NetworkError.serverError(statusCode: 500) == NetworkError.serverError(statusCode: 500))
        #expect(NetworkError.serverError(statusCode: 500) != NetworkError.serverError(statusCode: 404))
        
        #expect(NetworkError.retryExhausted(attempts: 3) == NetworkError.retryExhausted(attempts: 3))
        #expect(NetworkError.retryExhausted(attempts: 3) != NetworkError.retryExhausted(attempts: 5))
        
        #expect(NetworkError.rateLimited(retryAfter: 60) == NetworkError.rateLimited(retryAfter: 60))
        #expect(NetworkError.rateLimited(retryAfter: nil) == NetworkError.rateLimited(retryAfter: nil))
    }
    
    // MARK: - localized Description Tests
    
    @Test("invalidURL has correct description")
    func testInvalidURLDescription() {
        let error = NetworkError.invalidURL
        #expect(error.localizedDescription == "The URL provided was invalid.")
    }
    
    @Test("noData has correct description")
    func testNoDataDescription() {
        let error = NetworkError.noData
        #expect(error.localizedDescription == "No data was returned from the server.")
    }
    
    @Test("decodingError has correct description")
    func testDecodingErrorDescription() {
        let error = NetworkError.decodingError("Invalid JSON format")
        #expect(error.localizedDescription.contains("Invalid JSON format"))
    }
    
    @Test("serverError with message uses message")
    func testServerErrorWithMessage() {
        let error = NetworkError.serverError(statusCode: 500, message: "Custom error message")
        #expect(error.localizedDescription == "Custom error message")
    }
    
    @Test("serverError without message uses status code")
    func testServerErrorWithoutMessage() {
        let error = NetworkError.serverError(statusCode: 503)
        #expect(error.localizedDescription.contains("503"))
    }
    
    @Test("timeout has correct description")
    func testTimeoutDescription() {
        let error = NetworkError.timeout
        #expect(error.localizedDescription == "The request timed out.")
    }
    
    @Test("noConnection has correct description")
    func testNoConnectionDescription() {
        let error = NetworkError.noConnection
        #expect(error.localizedDescription == "No network connection is available.")
    }
    
    @Test("cancelled has correct description")
    func testCancelledDescription() {
        let error = NetworkError.cancelled
        #expect(error.localizedDescription == "The request was cancelled.")
    }
    
    @Test("sslError has correct description")
    func testSSLErrorDescription() {
        let error = NetworkError.sslError
        #expect(error.localizedDescription == "A secure connection could not be established.")
    }
    
    @Test("retryExhausted has correct description")
    func testRetryExhaustedDescription() {
        let error = NetworkError.retryExhausted(attempts: 5)
        #expect(error.localizedDescription.contains("5"))
    }
    
    @Test("rateLimited with retryAfter shows seconds")
    func testRateLimitedWithRetryAfter() {
        let error = NetworkError.rateLimited(retryAfter: 120)
        #expect(error.localizedDescription.contains("120"))
    }
    
    @Test("rateLimited without retryAfter has generic message")
    func testRateLimitedWithoutRetryAfter() {
        let error = NetworkError.rateLimited(retryAfter: nil)
        #expect(error.localizedDescription.contains("try again later"))
    }
    
    @Test("unauthorized has correct description")
    func testUnauthorizedDescription() {
        let error = NetworkError.unauthorized
        #expect(error.localizedDescription.contains("Authentication"))
    }
    
    @Test("notFound has correct description")
    func testNotFoundDescription() {
        let error = NetworkError.notFound
        #expect(error.localizedDescription == "The requested resource was not found.")
    }
    
    // MARK: - isNotFound Tests
    
    @Test("isNotFound returns true for notFound case")
    func testIsNotFoundForNotFoundCase() {
        #expect(NetworkError.notFound.isNotFound == true)
    }
    
    @Test("isNotFound returns true for 404 serverError")
    func testIsNotFoundFor404ServerError() {
        let error = NetworkError.serverError(statusCode: 404)
        #expect(error.isNotFound == true)
    }
    
    @Test("isNotFound returns false for other errors")
    func testIsNotFoundForOtherErrors() {
        #expect(NetworkError.serverError(statusCode: 500).isNotFound == false)
        #expect(NetworkError.timeout.isNotFound == false)
        #expect(NetworkError.unauthorized.isNotFound == false)
    }
    
    // MARK: - isRetryable Tests
    
    @Test("timeout is retryable")
    func testTimeoutIsRetryable() {
        #expect(NetworkError.timeout.isRetryable == true)
    }
    
    @Test("noConnection is retryable")
    func testNoConnectionIsRetryable() {
        #expect(NetworkError.noConnection.isRetryable == true)
    }
    
    @Test("5xx server errors are retryable")
    func test5xxServerErrorsAreRetryable() {
        #expect(NetworkError.serverError(statusCode: 500).isRetryable == true)
        #expect(NetworkError.serverError(statusCode: 502).isRetryable == true)
        #expect(NetworkError.serverError(statusCode: 503).isRetryable == true)
        #expect(NetworkError.serverError(statusCode: 599).isRetryable == true)
    }
    
    @Test("4xx server errors are not retryable")
    func test4xxServerErrorsAreNotRetryable() {
        #expect(NetworkError.serverError(statusCode: 400).isRetryable == false)
        #expect(NetworkError.serverError(statusCode: 401).isRetryable == false)
        #expect(NetworkError.serverError(statusCode: 404).isRetryable == false)
        #expect(NetworkError.serverError(statusCode: 429).isRetryable == false)
    }
    
    @Test("Other errors are not retryable")
    func testOtherErrorsAreNotRetryable() {
        #expect(NetworkError.invalidURL.isRetryable == false)
        #expect(NetworkError.decodingError("error").isRetryable == false)
        #expect(NetworkError.unauthorized.isRetryable == false)
        #expect(NetworkError.cancelled.isRetryable == false)
    }
    
    // MARK: - URLError Conversion Tests
    
    @Test("URLError timedOut converts to timeout")
    func testURLErrorTimedOut() {
        let urlError = URLError(.timedOut)
        let networkError = NetworkError.from(urlError)
        #expect(networkError == .timeout)
    }
    
    @Test("URLError notConnectedToInternet converts to noConnection")
    func testURLErrorNotConnected() {
        let urlError = URLError(.notConnectedToInternet)
        let networkError = NetworkError.from(urlError)
        #expect(networkError == .noConnection)
    }
    
    @Test("URLError networkConnectionLost converts to noConnection")
    func testURLErrorConnectionLost() {
        let urlError = URLError(.networkConnectionLost)
        let networkError = NetworkError.from(urlError)
        #expect(networkError == .noConnection)
    }
    
    @Test("URLError cancelled converts to cancelled")
    func testURLErrorCancelled() {
        let urlError = URLError(.cancelled)
        let networkError = NetworkError.from(urlError)
        #expect(networkError == .cancelled)
    }
    
    @Test("URLError SSL errors convert to sslError")
    func testURLErrorSSL() {
        let sslErrors: [URLError.Code] = [
            .secureConnectionFailed,
            .serverCertificateHasBadDate,
            .serverCertificateUntrusted,
            .serverCertificateHasUnknownRoot,
            .serverCertificateNotYetValid,
            .clientCertificateRejected
        ]
        
        for code in sslErrors {
            let urlError = URLError(code)
            let networkError = NetworkError.from(urlError)
            #expect(networkError == .sslError, "Expected \(code) to convert to sslError")
        }
    }
    
    @Test("Other URLErrors convert to underlying")
    func testURLErrorOther() {
        let urlError = URLError(.badURL)
        let networkError = NetworkError.from(urlError)
        
        if case .underlying = networkError {
            // Expected
        } else {
            Issue.record("Expected underlying error")
        }
    }
}
