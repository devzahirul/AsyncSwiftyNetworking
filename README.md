<p align="center">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange.svg" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/Platforms-iOS%20|%20macOS%20|%20tvOS%20|%20watchOS%20|%20visionOS-blue.svg" alt="Platforms">
  <img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg" alt="SPM">
  <img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="License">
  <a href="https://github.com/devzahirul/AsyncSwiftyNetworking/actions"><img src="https://github.com/devzahirul/AsyncSwiftyNetworking/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
</p>

# AsyncSwiftyNetworking

A modern Swift networking library with **zero boilerplate**. Built with async/await, generic services, and Hilt-style dependency injection.

## ✨ Features

- 🚀 **Zero Boilerplate** - Generic service, ViewModel & views
- 💉 **Hilt-Style DI** - `@Inject`, `@HiltViewModel` with caching
- 📱 **SwiftUI Ready** - `NetworkDataView` handles loading/error/content
- 🔐 **Auto Token Refresh** - Seamless 401 handling

## 📦 Installation

```swift
dependencies: [
    .package(url: "https://github.com/devzahirul/AsyncSwiftyNetworking.git", from: "1.0.0")
]
```

---

## 📁 Recommended File Structure

```
YourApp/
├── Networking/
│   ├── DI.swift              # DI configuration
│   ├── ServiceType.swift     # Service typealiases
│   └── ViewModelType.swift   # ViewModel typealiases
├── Models/
│   └── Models.swift          # API models
└── Views/
    └── ...
```

---

## 🚀 Quick Start

### 1. Models.swift

```swift
struct Profile: Codable, HTTPResponseDecodable {
    var statusCode: Int?
    let id: String
    let name: String
    let email: String
}

struct User: Codable, HTTPResponseDecodable, Identifiable {
    var statusCode: Int?
    let id: String
    let name: String
}
```

### 2. ServiceType.swift

```swift
import AsyncSwiftyNetworking

// Fetch services
typealias ProfileService = GenericNetworkService<Profile>
typealias UserListService = GenericListService<User>

// Mutation services (POST/PUT/DELETE)
typealias LoginService = GenericMutationService<LoginRequest, LoginResponse>
typealias SignupService = GenericMutationService<SignupRequest, SignupResponse>
```

### 3. ViewModelType.swift

```swift
import AsyncSwiftyNetworking

// Fetch ViewModels
typealias ProfileViewModel = GenericNetworkViewModel<Profile>
typealias UserListViewModel = GenericListViewModel<User>

// Mutation ViewModels (subclass for custom behavior)
typealias LoginViewModelBase = GenericMutationViewModel<LoginRequest, LoginResponse>
```

### 4. DI.swift

```swift
import AsyncSwiftyNetworking

enum AppDI {
    static func configure() {
        DI.configure { di in
            di.baseURL = "https://api.example.com"
            
            // Token Storage
            let storage = KeychainTokenStorage()
            di.registerSingleton(TokenStorage.self, instance: storage)
            
            // Network Client
            di.register(URLSessionNetworkClient.self) {
                URLSessionNetworkClient.quick(baseURL: di.baseURL)
            }
            
            // Services
            di.register(ProfileService.self) {
                ProfileService(.get("/profile"))
            }
            
            di.register(UserListService.self) {
                UserListService(.get("/users"))
            }
        }
    }
}
```

### 5. App.swift

```swift
@main
struct MyApp: App {
    init() {
        AppDI.configure()
    }
    
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

### 6. Views

```swift
struct ProfileView: View {
    @HiltViewModel(ProfileViewModel.self) var vm
    
    var body: some View {
        NetworkDataView(vm) { profile in
            VStack {
                Text(profile.name).font(.title)
                Text(profile.email).foregroundColor(.secondary)
            }
        }
    }
}

struct UsersView: View {
    @HiltViewModel(UserListViewModel.self) var vm
    
    var body: some View {
        NetworkListDataView(vm) { user in
            Text(user.name)
        }
    }
}
```

---

## 📝 Full Login Example (Using GenericMutation)

### Models.swift

```swift
struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct LoginResponse: Codable, HTTPResponseDecodable {
    var statusCode: Int?
    let token: String
    let user: User
}
```

### ServiceType.swift

```swift
typealias LoginService = GenericMutationService<LoginRequest, LoginResponse>
```

### DI.swift

```swift
di.register(LoginService.self) { LoginService(.post, "/auth/login") }
```

### LoginViewModel.swift (Using AuthState)

```swift
@MainActor
class LoginViewModel: AuthLoginViewModel<LoginRequest, LoginResponse> {
    @Published var email = ""
    @Published var password = ""
    
    // Auto-extracts token and notifies AuthState!
    override func extractToken(from response: LoginResponse) -> String? {
        return response.token
    }
    
    override func extractUser(from response: LoginResponse) -> (any Sendable)? {
        return response.user
    }
    
    func login() async {
        await execute(LoginRequest(email: email, password: password))
    }
}
```

### ContentView.swift (Subscribes to AuthState)

```swift
struct ContentView: View {
    @ObservedObject var authState = AuthState.shared
    
    var body: some View {
        if authState.isLoggedIn {
            HomeView()
        } else {
            LoginView()
        }
    }
}
```

### LoginView.swift

```swift
struct LoginView: View {
    @StateObject var vm = LoginViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $vm.email)
                .textFieldStyle(.roundedBorder)
            
            SecureField("Password", text: $vm.password)
                .textFieldStyle(.roundedBorder)
            
            if let error = vm.error {
                Text(error.userMessage).foregroundColor(.red)
            }
            
            Button("Login") { Task { await vm.login() } }
                .buttonStyle(.borderedProminent)
                .disabled(vm.isLoading)
        }
        .padding()
    }
}
```

---

## 🔔 AuthState (Central Auth Manager)

```swift
// Singleton - subscribe to auth state
@ObservedObject var authState = AuthState.shared

// Logout
AuthState.shared.logout()

// Check auth events (Combine)
AuthState.shared.authEvents
    .sink { event in
        switch event {
        case .loggedIn: print("Logged in")
        case .loggedOut: print("Logged out")
        case .sessionExpired: print("Session expired")
        }
    }
```

### Auth Flow

```
LoginViewModel → AuthState.onLoginSuccess() → Views update
                         ↓
          @Published isLoggedIn = true
                         ↓
         ContentView.body re-renders → HomeView()
```

---

## 🔐 Authenticated API Calls

When you register the client with `withAuth()`, **all services automatically get the token header**:

### DI.swift

```swift
DI.configure { di in
    let storage = KeychainTokenStorage()
    di.registerSingleton(TokenStorage.self, instance: storage)
    
    // All requests auto-include: Authorization: Bearer <token>
    di.register(URLSessionNetworkClient.self) {
        URLSessionNetworkClient.withAuth(
            baseURL: di.baseURL,
            tokenStorage: storage,
            refreshHandler: MyRefreshHandler()
        )
    }
    
    // These services use the auth-enabled client
    di.register(ProfileService.self) { ProfileService(.get("/profile")) }
    di.register(OrderListService.self) { OrderListService(.get("/orders")) }
}
```

### How It Works

```
GenericNetworkService<Profile> → Resolves URLSessionNetworkClient from DI
                                            ↓
                               AuthInterceptor adds header:
                               "Authorization: Bearer <token>"
                                            ↓
                               Request sent with token!
```

---

## 🔗 Interceptors

### AuthInterceptor (Built-in)

Automatically adds Bearer token from TokenStorage:

```swift
// Request:
GET /profile
Authorization: Bearer eyJhbGciOi...
```

### RefreshTokenInterceptor (Built-in)

Handles 401 responses:

```swift
class MyRefreshHandler: TokenRefreshHandler {
    func refreshToken() async throws -> String {
        let response = try await refreshAPI()
        return response.accessToken
    }
    
    func onRefreshFailure(_ error: Error) async {
        AuthState.shared.onSessionExpired()  // Navigate to login
    }
}
```

### Custom Interceptor

```swift
class LoggingInterceptor: RequestInterceptor {
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        print("➡️ \(request.httpMethod ?? "") \(request.url?.path ?? "")")
        return request
    }
}
```

## 🛠️ Request Builder

```swift
// GET
let user: User = try await client.request(.get("/users/1"))

// POST
let created: User = try await client.request(
    .post("/users").body(CreateUserRequest(name: "John"))
)

// With query & headers
let results: SearchResponse = try await client.request(
    .get("/search")
        .query("q", "swift")
        .header("X-API-Key", apiKey)
)
```

---

## 📄 License

MIT License
