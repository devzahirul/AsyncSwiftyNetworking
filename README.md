<p align="center">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange.svg" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/Platforms-iOS%20|%20macOS%20|%20tvOS%20|%20watchOS%20|%20visionOS-blue.svg" alt="Platforms">
  <img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg" alt="SPM">
  <img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="License">
  <a href="https://github.com/devzahirul/AsyncSwiftyNetworking/actions"><img src="https://github.com/devzahirul/AsyncSwiftyNetworking/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
</p>

# AsyncSwiftyNetworking

A modern, production-ready Swift networking library built with async/await. Features automatic token refresh, retry policies, interceptor chains, and 100% testability through protocol-based dependency injection.

## ✨ Features

- 🚀 **Modern Swift Concurrency** - Built entirely with async/await
- ⚡ **Quick Start API** - One-liner setup with `quick()`, `withAuth()`, `mobile()` factory methods
- 🛠️ **Fluent Request Builder** - Build requests without defining Endpoint enums
- 🔄 **Automatic Token Refresh** - Seamless 401 handling with refresh tokens
- 🔁 **Configurable Retry Policies** - Exponential backoff, fixed delay, or custom
- 🔗 **Interceptor Chain** - Request/response transformation pipeline
- 📦 **Multipart Uploads** - Easy file and image uploads
- 📄 **Pagination Support** - Built-in paginated request handling
- 🔐 **Secure Token Storage** - Keychain integration out of the box
- ⚠️ **Smart Error Recovery** - User-friendly messages with recovery suggestions
- ✅ **100% Testable** - Protocol-based architecture with mock session support
- 📱 **Multi-Platform** - iOS 15+, macOS 12+, tvOS 15+, watchOS 8+, visionOS 1+

## 📦 Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/devzahirul/AsyncSwiftyNetworking.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** → paste the repository URL.

## 🚀 Quick Start

### Option 1: Fluent Request Builder (Fastest)

No need to define Endpoint enums - just build and execute:

```swift
import AsyncSwiftyNetworking

// One-liner setup
let client = URLSessionNetworkClient.quick(baseURL: "https://api.example.com")

// GET request with fluent builder
let user: User = try await client.request(
    RequestBuilder.get("/users/1")
)

// POST with headers and body
let newUser: User = try await client.request(
    RequestBuilder.post("/users")
        .header("X-API-Key", apiKey)
        .body(CreateUserRequest(name: "John", email: "john@example.com"))
)

// Full chain example
let result: SearchResponse = try await client.request(
    RequestBuilder.get("/search")
        .query("q", "swift")
        .query("limit", "20")
        .header("Accept-Language", "en")
        .timeout(30)
)
```

### Option 2: Type-Safe Endpoints (Recommended for larger projects)

```swift
enum UserAPI: Endpoint {
    case getUser(id: Int)
    case createUser(name: String, email: String)
    
    var path: String {
        switch self {
        case .getUser(let id): return "/users/\(id)"
        case .createUser: return "/users"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getUser: return .get
        case .createUser: return .post
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

// Use the endpoint
let user: User = try await client.request(UserAPI.getUser(id: 123))
```

## ⚡ Convenience Factory Methods

```swift
// Quick prototyping - minimal setup
let client = URLSessionNetworkClient.quick(
    baseURL: "https://api.example.com",
    logging: true  // Enable request/response logging
)

// Full authentication flow with auto-refresh
let client = URLSessionNetworkClient.withAuth(
    baseURL: "https://api.example.com",
    tokenStorage: KeychainTokenStorage(),
    refreshHandler: MyRefreshHandler()
)

// Mobile-optimized (60s timeout, exponential backoff retry)
let client = URLSessionNetworkClient.mobile(baseURL: "https://api.example.com")
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
        let response = try await refreshAPI()
        return response.accessToken
    }
    
    func onRefreshFailure(_ error: Error) async {
        NotificationCenter.default.post(name: .sessionExpired, object: nil)
    }
}

// 2. Use the withAuth factory method (easiest)
let client = URLSessionNetworkClient.withAuth(
    baseURL: "https://api.example.com",
    tokenStorage: KeychainTokenStorage(),
    refreshHandler: MyRefreshHandler()
)
```

## 💉 Dependency Injection

### DI Container Setup

```swift
import AsyncSwiftyNetworking

// Configure once at app startup
DI.configure { di in
    di.baseURL = "https://api.example.com"
    di.tokenStorage = KeychainTokenStorage()
    
    // Register services
    di.register(NetworkClient.self) {
        URLSessionNetworkClient.quick(baseURL: di.baseURL)
    }
    di.register(ProfileService.self) { ProfileServiceImpl() }
    di.register(UserService.self) { UserServiceImpl() }
}
```

### @Inject Property Wrapper

```swift
// Services auto-resolve from DI container
class ProfileServiceImpl: ProfileService {
    @Inject var client: NetworkClient  // Auto-injected!
    
    func getProfile() async throws -> Profile {
        try await client.request(.get("/profile"))
    }
}
```

### @HiltViewModel (Like Android's `by viewModels()`)

ViewModels are cached in a HashMap - same instance returned on re-entry:

```swift
// Define ViewModel
class ProfileVM: ObservableObject, DefaultInitializable {
    @Inject var service: ProfileService
    
    @Published var profile: Profile?
    
    required init() {}
    
    func load() async {
        profile = try? await service.getProfile()
    }
}

// Use in View - cached by type!
struct ProfileView: View {
    @HiltViewModel(ProfileVM.self) var vm
    
    var body: some View {
        if let profile = vm.profile {
            Text(profile.name)
        }
    }
    .task { await vm.load() }
}
```

### ViewModel with Parameters

```swift
class UserDetailVM: ObservableObject {
    @Inject var service: UserService
    
    let userId: String
    @Published var user: User?
    
    init(userId: String) {
        self.userId = userId
    }
}

struct UserDetailView: View {
    let userId: String
    
    // Custom key for unique caching
    @HiltViewModel(key: "user-\(userId)", factory: { UserDetailVM(userId: userId) }) var vm
}
```

### Clean Architecture Flow

```
View → ViewModel → Service → NetworkClient
           ↑            ↑
           └──── @Inject ────┘
```


### 📱 Full SwiftUI Login Example

Complete login flow with DI architecture:

```swift
// MARK: - 1. App Setup

@main
struct MyApp: App {
    init() {
        DI.configure { di in
            di.baseURL = "https://api.example.com"
            di.tokenStorage = KeychainTokenStorage()
            di.register(NetworkClient.self) {
                URLSessionNetworkClient.quick(baseURL: di.baseURL)
            }
            di.register(AuthService.self) { AuthServiceImpl() }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - 2. Models

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct LoginResponse: Decodable, HTTPResponseDecodable {
    let token: String
    let user: User
}

struct User: Decodable, Identifiable {
    let id: String
    let name: String
    let email: String
}

// MARK: - 3. Service

protocol AuthService {
    func login(email: String, password: String) async throws -> LoginResponse
    func logout()
}

class AuthServiceImpl: AuthService {
    @Inject var client: NetworkClient
    
    func login(email: String, password: String) async throws -> LoginResponse {
        try await client.request(
            RequestBuilder.post("/auth/login")
                .body(LoginRequest(email: email, password: password)),
            baseUrl: DI.shared.baseURL
        )
    }
    
    func logout() {
        DI.shared.tokenStorage?.clearToken()
        DI.shared.clearViewModels()
    }
}

// MARK: - 4. ViewModel

@MainActor
class LoginVM: ObservableObject, DefaultInitializable {
    @Inject var authService: AuthService
    
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var error: String?
    @Published var isLoggedIn = false
    
    required init() {}
    
    func login() async {
        guard !email.isEmpty, !password.isEmpty else {
            error = "Please enter email and password"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let response = try await authService.login(email: email, password: password)
            DI.shared.tokenStorage?.save(response.token)
            isLoggedIn = true
        } catch let networkError as NetworkError {
            error = networkError.userMessage
        } catch {
            self.error = "Login failed"
        }
        
        isLoading = false
    }
}

// MARK: - 5. Views

struct ContentView: View {
    @HiltViewModel(LoginVM.self) var vm
    
    var body: some View {
        if vm.isLoggedIn {
            HomeView()
        } else {
            LoginView(vm: vm)
        }
    }
}

struct LoginView: View {
    @ObservedObject var vm: LoginVM
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Login")
                .font(.largeTitle.bold())
            
            TextField("Email", text: $vm.email)
                .textFieldStyle(.roundedBorder)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
            
            SecureField("Password", text: $vm.password)
                .textFieldStyle(.roundedBorder)
                .textContentType(.password)
            
            if let error = vm.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: { Task { await vm.login() } }) {
                if vm.isLoading {
                    ProgressView()
                } else {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.isLoading)
        }
        .padding()
    }
}

struct HomeView: View {
    var body: some View {
        Text("Welcome! 🎉")
            .font(.title)
    }
}
```


## ⚠️ Error Handling

### User-Friendly Error Messages

```swift
do {
    let user = try await client.request(UserAPI.getUser(id: 123))
} catch let error as NetworkError {
    // Show user-friendly message in UI
    showAlert(
        title: "Error",
        message: error.userMessage  // "No internet connection. Please check your network settings."
    )
    
    // Handle suggested recovery action
    switch error.recoveryAction {
    case .retry:
        showRetryButton(title: error.recoveryAction.buttonTitle)  // "Try Again"
    case .reauthenticate:
        navigateToLogin()  // Button title: "Sign In"
    case .contactSupport:
        showSupportInfo()  // Button title: "Contact Support"
    case .none:
        break
    }
}
```

### Programmatic Error Handling

```swift
catch let error as NetworkError {
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
let client = URLSessionNetworkClient.mobile(baseURL: "https://api.example.com")
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
        mockSession.mockError(statusCode: 404)
        
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
    
    private let client = URLSessionNetworkClient.quick(baseURL: "https://api.example.com")
    
    func loadUser(id: Int) {
        isLoading = true
        Task {
            do {
                user = try await client.request(
                    RequestBuilder.get("/users/\(id)")
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
│   ├── RequestBuilder.swift          # Fluent request builder ✨
│   ├── AuthInterceptor.swift         # Bearer token injection
│   ├── RefreshTokenInterceptor.swift # Automatic token refresh
│   ├── LoggingInterceptor.swift      # OSLog-based logging
│   ├── TokenStorage.swift            # Token storage protocol
│   ├── KeychainTokenStorage.swift    # Secure keychain storage
│   ├── MultipartFormData.swift       # File upload support
│   └── PaginatedResponse.swift       # Pagination helpers
├── NetworkClient.swift               # Main client protocol & implementation
├── URLSessionNetworkClient+Conv...   # Convenience factory methods ✨
├── NetworkError.swift                # Error types + recovery actions ✨
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
