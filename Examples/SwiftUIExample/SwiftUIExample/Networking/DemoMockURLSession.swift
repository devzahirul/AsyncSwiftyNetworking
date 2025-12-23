import Foundation
import AsyncSwiftyNetworking

// MARK: - Demo Mock URL Session

/// A mock URLSession that simulates network responses with realistic delays.
/// Use this for demo/preview purposes without needing a real API.
final class DemoMockURLSession: URLSessionProtocol, @unchecked Sendable {
    
    // MARK: - Configuration
    
    /// Minimum delay in milliseconds
    var minDelayMs: UInt64 = 300
    
    /// Maximum delay in milliseconds
    var maxDelayMs: UInt64 = 1500
    
    /// Simulated error rate (0.0 - 1.0)
    var errorRate: Double = 0.05
    
    /// Whether to simulate occasional slow responses
    var simulateSlowResponses: Bool = true
    
    // MARK: - Mock Data
    
    private let mockPosts: [MockPost] = (1...100).map { id in
        MockPost(
            id: id,
            userId: (id % 10) + 1,
            title: "Post #\(id): \(randomTitle())",
            body: "This is the content of post \(id). \(randomBody())"
        )
    }
    
    private let mockUsers: [MockUser] = [
        MockUser(id: 1, name: "John Doe", email: "john@example.com", avatarUrl: nil),
        MockUser(id: 2, name: "Jane Smith", email: "jane@example.com", avatarUrl: nil),
        MockUser(id: 3, name: "Bob Johnson", email: "bob@example.com", avatarUrl: nil)
    ]
    
    // MARK: - URLSessionProtocol
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        // Simulate network delay
        let delay = randomDelay()
        try await Task.sleep(nanoseconds: delay * 1_000_000)
        
        // Simulate occasional errors
        if Double.random(in: 0...1) < errorRate {
            throw simulatedError()
        }
        
        // Get the path from the request
        guard let url = request.url else {
            throw URLError(.badURL)
        }
        
        let path = url.path
        let method = request.httpMethod ?? "GET"
        
        // Route to appropriate handler
        let responseData = try handleRequest(path: path, method: method, body: request.httpBody)
        
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        
        return (responseData, response)
    }
    
    // MARK: - Request Handlers
    
    private func handleRequest(path: String, method: String, body: Data?) throws -> Data {
        // Auth endpoints
        if path.contains("/auth/login") {
            return try handleLogin(body: body)
        }
        if path.contains("/auth/register") {
            return try handleRegister(body: body)
        }
        if path.contains("/auth/refresh") {
            return try handleRefresh()
        }
        
        // Posts endpoints
        if path.contains("/posts") {
            switch method {
            case "GET":
                return try handleGetPosts(path: path)
            case "POST":
                return try handleCreatePost(body: body)
            case "DELETE":
                return try handleDeletePost(path: path)
            default:
                break
            }
        }
        
        // Users endpoints
        if path.contains("/users") {
            if path.contains("/images") {
                return try handleImageUpload()
            }
            return try handleGetUser()
        }
        
        // Default empty response
        return "{}".data(using: .utf8)!
    }
    
    // MARK: - Auth Handlers
    
    private func handleLogin(body: Data?) throws -> Data {
        let response = LoginMockResponse(
            accessToken: "mock-access-\(UUID().uuidString)",
            refreshToken: "mock-refresh-\(UUID().uuidString)",
            user: mockUsers[0]
        )
        return try JSONEncoder().encode(response)
    }
    
    private func handleRegister(body: Data?) throws -> Data {
        let response = RegisterMockResponse(
            message: "Registration successful",
            user: mockUsers[0]
        )
        return try JSONEncoder().encode(response)
    }
    
    private func handleRefresh() throws -> Data {
        let response = TokenRefreshMockResponse(
            accessToken: "refreshed-access-\(UUID().uuidString)",
            refreshToken: "refreshed-refresh-\(UUID().uuidString)"
        )
        return try JSONEncoder().encode(response)
    }
    
    // MARK: - Posts Handlers
    
    private func handleGetPosts(path: String) throws -> Data {
        // Check for specific post ID
        if let id = extractId(from: path, prefix: "/posts/") {
            if let post = mockPosts.first(where: { $0.id == id }) {
                return try JSONEncoder().encode(post)
            }
            throw URLError(.fileDoesNotExist)
        }
        
        // Return list of posts (first 20)
        let posts = Array(mockPosts.prefix(20))
        return try JSONEncoder().encode(posts)
    }
    
    private func handleCreatePost(body: Data?) throws -> Data {
        guard let body = body,
              let input = try? JSONDecoder().decode(CreatePostInput.self, from: body) else {
            throw URLError(.cannotParseResponse)
        }
        
        let newPost = MockPost(
            id: Int.random(in: 100...999),
            userId: 1,
            title: input.title,
            body: input.body
        )
        return try JSONEncoder().encode(newPost)
    }
    
    private func handleDeletePost(path: String) throws -> Data {
        // Simulate successful delete
        return "{}".data(using: .utf8)!
    }
    
    // MARK: - User Handlers
    
    private func handleGetUser() throws -> Data {
        return try JSONEncoder().encode(mockUsers[0])
    }
    
    private func handleImageUpload() throws -> Data {
        // Simulate longer delay for uploads
        let response = ImageUploadMockResponse(
            message: "Upload successful",
            urls: (1...3).map { "https://example.com/images/\(UUID().uuidString.prefix(8))_\($0).jpg" }
        )
        return try JSONEncoder().encode(response)
    }
    
    // MARK: - Helpers
    
    private func randomDelay() -> UInt64 {
        var delay = UInt64.random(in: minDelayMs...maxDelayMs)
        
        // 10% chance of slow response
        if simulateSlowResponses && Double.random(in: 0...1) < 0.1 {
            delay = UInt64.random(in: 2000...4000)
        }
        
        return delay
    }
    
    private func simulatedError() -> Error {
        let errors: [URLError.Code] = [
            .timedOut,
            .notConnectedToInternet,
            .networkConnectionLost
        ]
        return URLError(errors.randomElement()!)
    }
    
    private func extractId(from path: String, prefix: String) -> Int? {
        guard path.hasPrefix(prefix) else { return nil }
        let idPart = String(path.dropFirst(prefix.count)).components(separatedBy: "/").first
        return idPart.flatMap { Int($0) }
    }
}

// MARK: - Mock Response Types

private struct MockPost: Codable {
    let id: Int
    let userId: Int
    let title: String
    let body: String
}

private struct MockUser: Codable {
    let id: Int
    let name: String
    let email: String
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, email
        case avatarUrl = "avatar_url"
    }
}

private struct LoginMockResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: MockUser
}

private struct RegisterMockResponse: Codable {
    let message: String
    let user: MockUser
}

private struct TokenRefreshMockResponse: Codable {
    let accessToken: String
    let refreshToken: String
}

private struct CreatePostInput: Codable {
    let title: String
    let body: String
}

private struct ImageUploadMockResponse: Codable {
    let message: String
    let urls: [String]
}

// MARK: - Random Content Generators

private func randomTitle() -> String {
    let titles = [
        "Getting Started with Swift",
        "Advanced SwiftUI Techniques",
        "Building Scalable APIs",
        "The Art of Clean Code",
        "iOS Development Best Practices",
        "Async/Await Deep Dive",
        "Networking in Swift",
        "Unit Testing Strategies",
        "MVVM Architecture Guide",
        "Protocol-Oriented Programming"
    ]
    return titles.randomElement()!
}

private func randomBody() -> String {
    let bodies = [
        "Learn the fundamentals and advanced concepts.",
        "Discover patterns that make your code maintainable.",
        "Best practices for modern iOS development.",
        "Tips and tricks from experienced developers.",
        "A comprehensive guide to building great apps.",
        "Real-world examples and practical solutions.",
        "Everything you need to know to get started.",
        "Take your skills to the next level.",
        "Expert insights and proven techniques.",
        "From beginner to pro in no time."
    ]
    return bodies.randomElement()!
}
