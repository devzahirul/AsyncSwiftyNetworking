import XCTest
@testable import AsyncSwiftyNetworking

// MARK: - Error Recovery Tests (TDD - RED Phase)

/// Tests for enhanced error recovery properties on NetworkError
/// These tests are written FIRST, before the implementation
final class ErrorRecoveryTests: XCTestCase {
    
    // MARK: - User Message Tests
    
    func testNoConnectionUserMessage() {
        // Given
        let error = NetworkError.noConnection
        
        // When
        let message = error.userMessage
        
        // Then
        XCTAssertFalse(message.isEmpty)
        XCTAssertTrue(message.lowercased().contains("internet") || message.lowercased().contains("connection"))
    }
    
    func testTimeoutUserMessage() {
        // Given
        let error = NetworkError.timeout
        
        // When
        let message = error.userMessage
        
        // Then
        XCTAssertFalse(message.isEmpty)
        XCTAssertTrue(message.lowercased().contains("timeout") || message.lowercased().contains("try again"))
    }
    
    func testUnauthorizedUserMessage() {
        // Given
        let error = NetworkError.unauthorized
        
        // When
        let message = error.userMessage
        
        // Then
        XCTAssertFalse(message.isEmpty)
        XCTAssertTrue(message.lowercased().contains("login") || message.lowercased().contains("sign in") || message.lowercased().contains("session"))
    }
    
    func testServerErrorUserMessage() {
        // Given
        let error = NetworkError.serverError(statusCode: 500, message: nil, data: nil)
        
        // When
        let message = error.userMessage
        
        // Then
        XCTAssertFalse(message.isEmpty)
        XCTAssertTrue(message.lowercased().contains("server") || message.lowercased().contains("try again"))
    }
    
    func testRateLimitedUserMessage() {
        // Given
        let error = NetworkError.rateLimited(retryAfter: 60)
        
        // When
        let message = error.userMessage
        
        // Then
        XCTAssertFalse(message.isEmpty)
        XCTAssertTrue(message.lowercased().contains("limit") || message.lowercased().contains("wait"))
    }
    
    // MARK: - Recovery Action Tests
    
    func testNoConnectionRecoveryAction() {
        // Given
        let error = NetworkError.noConnection
        
        // When
        let action = error.recoveryAction
        
        // Then
        XCTAssertEqual(action, .retry)
    }
    
    func testTimeoutRecoveryAction() {
        // Given
        let error = NetworkError.timeout
        
        // When
        let action = error.recoveryAction
        
        // Then
        XCTAssertEqual(action, .retry)
    }
    
    func testUnauthorizedRecoveryAction() {
        // Given
        let error = NetworkError.unauthorized
        
        // When
        let action = error.recoveryAction
        
        // Then
        XCTAssertEqual(action, .reauthenticate)
    }
    
    func testServerErrorRecoveryAction() {
        // Given
        let error = NetworkError.serverError(statusCode: 500, message: nil, data: nil)
        
        // When
        let action = error.recoveryAction
        
        // Then
        XCTAssertEqual(action, .retry)
    }
    
    func testServerError400RecoveryAction() {
        // Given
        let error = NetworkError.serverError(statusCode: 400, message: nil, data: nil)
        
        // When
        let action = error.recoveryAction
        
        // Then
        XCTAssertEqual(action, .none) // Client errors typically can't be retried
    }
    
    func testNotFoundRecoveryAction() {
        // Given
        let error = NetworkError.notFound
        
        // When
        let action = error.recoveryAction
        
        // Then
        XCTAssertEqual(action, .none) // Nothing to retry
    }
    
    func testDecodingErrorRecoveryAction() {
        // Given
        let error = NetworkError.decodingError("Invalid JSON")
        
        // When
        let action = error.recoveryAction
        
        // Then
        XCTAssertEqual(action, .contactSupport) // This is a bug
    }
    
    func testSSLErrorRecoveryAction() {
        // Given
        let error = NetworkError.sslError
        
        // When
        let action = error.recoveryAction
        
        // Then
        XCTAssertEqual(action, .contactSupport) // Security issue
    }
    
    // MARK: - Recovery Action Enum Tests
    
    func testRecoveryActionEquality() {
        XCTAssertEqual(RecoveryAction.retry, RecoveryAction.retry)
        XCTAssertEqual(RecoveryAction.reauthenticate, RecoveryAction.reauthenticate)
        XCTAssertEqual(RecoveryAction.contactSupport, RecoveryAction.contactSupport)
        XCTAssertEqual(RecoveryAction.none, RecoveryAction.none)
        
        XCTAssertNotEqual(RecoveryAction.retry, RecoveryAction.reauthenticate)
    }
    
    // MARK: - Suggested Button Title Tests
    
    func testRetryActionHasButtonTitle() {
        // Given
        let error = NetworkError.timeout
        
        // When
        let buttonTitle = error.recoveryAction.buttonTitle
        
        // Then
        XCTAssertFalse(buttonTitle?.isEmpty ?? true)
        XCTAssertTrue(buttonTitle?.lowercased().contains("retry") == true || buttonTitle?.lowercased().contains("try again") == true)
    }
    
    func testReauthenticateActionHasButtonTitle() {
        // Given
        let error = NetworkError.unauthorized
        
        // When
        let buttonTitle = error.recoveryAction.buttonTitle
        
        // Then
        XCTAssertFalse(buttonTitle?.isEmpty ?? true)
        XCTAssertTrue(buttonTitle?.lowercased().contains("login") == true || buttonTitle?.lowercased().contains("sign in") == true)
    }
    
    func testNoneActionHasNoButtonTitle() {
        // Given
        let error = NetworkError.notFound
        
        // When
        let buttonTitle = error.recoveryAction.buttonTitle
        
        // Then
        XCTAssertNil(buttonTitle)
    }
}
