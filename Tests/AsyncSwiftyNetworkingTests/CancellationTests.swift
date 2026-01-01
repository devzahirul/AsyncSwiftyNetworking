import Testing
import Foundation
import SwiftUI
@testable import AsyncSwiftyNetworking

@Suite("Cancellation Tests")
struct CancellationTests {
    
    @MainActor
    @Test("GenericNetworkViewModel cancels previous load on new load")
    func testViewModelCancellation() async throws {
        // Setup a mock service that waits
        let mockSession = MockURLSession()
        mockSession.requestHandler = { _ in
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            let json = "{\"id\": 1, \"name\": \"Test\"}"
            return (json.data(using: .utf8)!, HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        
        // Register mock client with base URL
        DI.shared.reset()
        
        // Use the internal init to set baseURL
        let client = URLSessionNetworkClient(
            session: mockSession,
            configuration: .default,
            baseURL: "https://test.com",
            hasLoggingInterceptor: false,
            hasAuthInterceptor: false,
            hasRefreshInterceptor: false
        )
        DI.shared.registerSingleton(URLSessionNetworkClient.self, instance: client)
        
        DI.shared.register(GenericNetworkService<TestUserResponse>.self) {
            GenericNetworkService(RequestBuilder.get("/test"))
        }

        let vm = GenericNetworkViewModel<TestUserResponse>()
        
        // Start first load
        vm.loadWithTask()
        
        // Allow task to start
        await Task.yield()
        await Task.yield()
        
        if let error = vm.error {
            Issue.record("VM has error: \(error)")
        }
        #expect(vm.isLoading == true)
        
        // Start second load immediately
        vm.loadWithTask()
        
        // Allow task to start
        await Task.yield()
        
        #expect(vm.isLoading == true)
        
        // Wait for potential completion
        try await Task.sleep(nanoseconds: 150_000_000)
        
        // Only one should have presumably completed "successfully" (or be in state)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil) // Should handle cancellation silently
    }
    
    @Test("NetworkClient propagates cancellation")
    func testNetworkClientCancellation() async throws {
        let mockSession = MockURLSession()
        mockSession.requestHandler = { _ in
            try await Task.sleep(nanoseconds: 500_000_000) // 500ms
            return (Data(), HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        
        let client = URLSessionNetworkClient(session: mockSession)
        
        let task = Task {
            let _: TestUserResponse = try await client.request(
                TestEndpoint.getUser(id: 1),
                baseUrl: "https://test.com"
            )
        }
        
        // Allow task to start
        try await Task.sleep(nanoseconds: 10_000_000)
        
        // Cancel
        task.cancel()
        
        do {
            _ = try await task.value
            Issue.record("Expected cancellation error")
        } catch is CancellationError {
            // Success
        } catch {
            Issue.record("Expected CancellationError, got \(error)")
        }
    }
}
