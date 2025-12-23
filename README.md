<p align="center">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange.svg" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/Platforms-iOS%20|%20macOS%20|%20tvOS%20|%20watchOS%20|%20visionOS-blue.svg" alt="Platforms">
  <img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg" alt="SPM">
  <img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="License">
</p>

# AsyncSwiftyNetworking

A modern, production-ready Swift networking library built with async/await. Features automatic token refresh, retry policies, interceptor chains, and 100% testability through protocol-based dependency injection.

## ✨ Features

- 🚀 **Modern Swift Concurrency** - Built entirely with async/await
- 🔄 **Automatic Token Refresh** - Seamless 401 handling with refresh tokens
- 🔁 **Configurable Retry Policies** - Exponential backoff, fixed delay, or custom
- 🔗 **Interceptor Chain** - Request/response transformation pipeline
- 📦 **Multipart Uploads** - Easy file and image uploads
- 📄 **Pagination Support** - Built-in paginated request handling
- 🔐 **Secure Token Storage** - Keychain integration out of the box
- ✅ **100% Testable** - Protocol-based architecture with mock session support
- 📱 **Multi-Platform** - iOS 15+, macOS 12+, tvOS 15+, watchOS 8+, visionOS 1+

## 📦 Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/YourUsername/AsyncSwiftyNetworking.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** → paste the repository URL.

## 🚀 Quick Start

### 1. Define Your Endpoints

```swift
import AsyncSwiftyNetworking

enum UserAPI: Endpoint {
    case getUser(id: Int)
    case createUser(name: String, email: String)
    case updateUser(id: Int, name: String)
    case deleteUser(id: Int)
    
    var path: String {
        switch self {
        case .getUser(let id): return "/users/\(id)"
        case .createUser, .updateUser, .deleteUser: return "/users"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getUser: return .get
        case .createUser: return .post
        case .updateUser: return .put
        case .deleteUser: return .delete
        }
    }
    
    var body: Data? {
        switch self {
        case .createUser(let name, let email):
            return try? JSONEncoder().encode(["name": name, "email": email])
        default:
            return nil
        }
    }
}
```

### 2. Define Response Models

```swift
struct User: HTTPResponseDecodable {
    let id: Int
    let name: String
    let email: String
    var statusCode: Int?
}
```

### 3. Make Requests

```swift
let client = URLSessionNetworkClient()

// GET request
let user: User = try await client.request(
    UserAPI.getUser(id: 123),
    baseUrl: "https://api.example.com"
)

// POST request
let newUser: User = try await client.request(
    UserAPI.createUser(name: "John", email: "john@example.com"),
    baseUrl: "https://api.example.com"
)
```

## 🔐 Authentication

### Basic Token Storage

```swift
// Store token after login
KeychainTokenStorage().save("your-jwt-token")

// Client automatically adds Authorization header
let client = URLSessionNetworkClient(
    requestInterceptors: [AuthInterceptor()]
)
```

### Automatic Token Refresh

```swift
// 1. Implement your refresh handler
final class MyRefreshHandler: TokenRefreshHandler {
    func refreshToken() async throws -> String {
        // Call your refresh endpoint
        let response = try await refreshAPI()
        return response.accessToken
    }
    
    func onRefreshFailure(_ error: Error) async {
        // Handle logout
        NotificationCenter.default.post(name: .sessionExpired, object: nil)
    }
}

// 2. Configure the client
let storage = KeychainExtendedTokenStorage()
let refreshInterceptor = RefreshTokenInterceptor(
    tokenStorage: storage,
    refreshHandler: MyRefreshHandler()
)

let client = URLSessionNetworkClient(
    requestInterceptors: [refreshInterceptor],
    responseInterceptors: [refreshInterceptor]  // Handles 401 responses
)
```

## 🔁 Retry Policies

```swift
// Exponential backoff: 1s, 2s, 4s...
let config = NetworkConfiguration(
    retryPolicy: .exponentialBackoff(maxRetries: 3, baseDelay: 1.0)
)

// Fixed delay
let config = NetworkConfiguration(
    retryPolicy: .fixed(maxRetries: 3, delay: 2.0)
)

// Mobile-optimized preset (60s timeout, 3 retries)
let client = URLSessionNetworkClient(configuration: .mobile)
```

## 📦 Multipart Uploads

```swift
let formData = MultipartFormData()

// Add text fields
formData.addTextField(name: "description", value: "Profile photo")

// Add files
formData.addFile(MultipartFormData.FileData(
    data: imageData,
    name: "avatar",
    fileName: "avatar.jpg",
    mimeType: "image/jpeg"
))

// Upload
let response: UploadResponse = try await client.upload(
    UserAPI.uploadAvatar,
    baseUrl: baseURL,
    formData: formData
)
```

## 📄 Pagination

```swift
let pagination = PaginationParams(page: 1, pageSize: 20)

let response: PaginatedResponse<User> = try await client.requestPaginated(
    UserAPI.listUsers,
    baseUrl: baseURL,
    pagination: pagination
)

print("Users: \(response.data)")
print("Has more: \(response.hasNextPage)")
```

## ⚠️ Error Handling

```swift
do {
    let user = try await client.request(UserAPI.getUser(id: 123), baseUrl: baseURL)
} catch let error as NetworkError {
    switch error {
    case .unauthorized:
        // Redirect to login
    case .notFound:
        // Handle 404
    case .noConnection:
        // Show offline message
    case .timeout:
        // Suggest retry
    case .serverError(let code, let message, _):
        // Log server error
    default:
        print(error.localizedDescription)
    }
    
    // Helper properties
    if error.isRetryable { /* safe to retry */ }
    if error.isClientError { /* 4xx error */ }
    if error.isServerError { /* 5xx error */ }
}
```

## 🔗 Custom Interceptors

### Request Interceptor

```swift
struct APIKeyInterceptor: RequestInterceptor {
    let apiKey: String
    
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        var modified = request
        modified.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        return modified
    }
}
```

### Response Interceptor

```swift
struct AnalyticsInterceptor: ResponseInterceptor {
    func intercept(_ response: HTTPURLResponse, data: Data) async throws -> Data {
        Analytics.track("api_response", ["status": response.statusCode])
        return data
    }
}
```

## 🧪 Testing

The library is designed for 100% testability through protocol-based dependency injection.

```swift
import XCTest
@testable import AsyncSwiftyNetworking

class UserServiceTests: XCTestCase {
    var mockSession: MockURLSession!
    var client: URLSessionNetworkClient!
    
    override func setUp() {
        mockSession = MockURLSession()
        client = URLSessionNetworkClient(session: mockSession)
    }
    
    func testGetUser() async throws {
        // Arrange
        let expectedUser = User(id: 1, name: "John", email: "john@test.com")
        mockSession.mockSuccess(expectedUser)
        
        // Act
        let user: User = try await client.request(
            UserAPI.getUser(id: 1),
            baseUrl: "https://api.test.com"
        )
        
        // Assert
        XCTAssertEqual(user.name, "John")
    }
    
    func testNetworkError() async {
        // Arrange
        mockSession.mockError(statusCode: 404)
        
        // Act & Assert
        do {
            let _: User = try await client.request(
                UserAPI.getUser(id: 999),
                baseUrl: "https://api.test.com"
            )
            XCTFail("Expected error")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .notFound)
        }
    }
}
```

## 📱 SwiftUI Integration

```swift
@MainActor
class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var error: NetworkError?
    @Published var isLoading = false
    
    private let client = URLSessionNetworkClient()
    
    func loadUser(id: Int) {
        isLoading = true
        Task {
            do {
                user = try await client.request(
                    UserAPI.getUser(id: id),
                    baseUrl: "https://api.example.com"
                )
            } catch let networkError as NetworkError {
                error = networkError
            }
            isLoading = false
        }
    }
}
```

## 📁 Project Structure

```
Sources/AsyncSwiftyNetworking/
├── Core/
│   ├── NetworkConfiguration.swift    # Timeout & retry settings
│   ├── URLSessionProtocol.swift      # Testable session abstraction
│   ├── RequestInterceptor.swift      # Request/response interceptors
│   ├── AuthInterceptor.swift         # Bearer token injection
│   ├── RefreshTokenInterceptor.swift # Automatic token refresh
│   ├── LoggingInterceptor.swift      # OSLog-based logging
│   ├── TokenStorage.swift            # Token storage protocol
│   ├── KeychainTokenStorage.swift    # Secure keychain storage
│   ├── MultipartFormData.swift       # File upload support
│   └── PaginatedResponse.swift       # Pagination helpers
├── NetworkClient.swift               # Main client protocol & implementation
├── NetworkError.swift                # Comprehensive error types
├── Endpoint.swift                    # API endpoint protocol
└── HTTPResponseDecodable.swift       # Response decoding protocol
```

## 🎯 Example App

A complete SwiftUI example app is included in the `Examples/SwiftUIExample` directory, demonstrating:

- ✅ Login/Registration with token storage
- ✅ GET requests with loading states
- ✅ POST requests for creating resources
- ✅ DELETE with swipe actions
- ✅ Multi-image uploads with PhotosPicker
- ✅ Automatic token refresh
- ✅ Error handling and retry
- ✅ Mock session with realistic delays

```bash
cd Examples/SwiftUIExample
open Package.swift
```

## 📋 Requirements

- Swift 5.9+
- iOS 15.0+ / macOS 12.0+ / tvOS 15.0+ / watchOS 8.0+ / visionOS 1.0+
- Xcode 15.0+

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with Swift's modern concurrency features
- Inspired by best practices from the iOS community
- Designed for real-world production use

---

<p align="center">
  Made with ❤️ for the Swift community
</p>
