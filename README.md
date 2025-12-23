<p align="center">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange.svg" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/Platforms-iOS%20|%20macOS%20|%20tvOS%20|%20watchOS%20|%20visionOS-blue.svg" alt="Platforms">
  <img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg" alt="SPM">
  <img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="License">
  <a href="https://github.com/devzahirul/AsyncSwiftyNetworking/actions"><img src="https://github.com/devzahirul/AsyncSwiftyNetworking/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
</p>

# AsyncSwiftyNetworking

A modern, production-ready Swift networking library with **minimal boilerplate**. Built with async/await, featuring generic services, dependency injection, and SwiftUI integration.

## ✨ Features

- 🚀 **Zero Boilerplate** - Generic service, ViewModel & views - just define your model
- 💉 **Hilt-Style DI** - `@Inject`, `@HiltViewModel` with HashMap caching
- 🔄 **Automatic Token Refresh** - Seamless 401 handling with refresh tokens
- 📱 **SwiftUI Ready** - `NetworkDataView` handles loading/error/content
- 🔁 **Configurable Retry** - Exponential backoff, fixed delay, or custom
- 📦 **Multipart Uploads** - Easy file and image uploads
- ✅ **100% Testable** - Protocol-based architecture

## 📦 Installation

```swift
dependencies: [
    .package(url: "https://github.com/devzahirul/AsyncSwiftyNetworking.git", from: "1.0.0")
]
```

---

## 🚀 Quick Start (3 Steps!)

### Step 1: Define Model

```swift
struct Profile: Codable, HTTPResponseDecodable {
    var statusCode: Int?
    let id: String
    let name: String
    let email: String
}
```

### Step 2: Register in DI

```swift
@main
struct MyApp: App {
    init() {
        DI.configure { di in
            di.baseURL = "https://api.example.com"
            
            // Register client
            di.register(URLSessionNetworkClient.self) {
                URLSessionNetworkClient.quick(baseURL: di.baseURL)
            }
            
            // Register services
            di.register(GenericNetworkService<Profile>.self) {
                GenericNetworkService(.get("/profile"))
            }
        }
    }
}
```

### Step 3: Use in SwiftUI View

```swift
struct ProfileView: View {
    @HiltViewModel(GenericNetworkViewModel<Profile>.self) var vm
    
    var body: some View {
        NetworkDataView(vm) { profile in
            VStack {
                Text(profile.name).font(.title)
                Text(profile.email).foregroundColor(.secondary)
            }
        }
    }
}
```

**That's it!** Loading indicator, error handling, and retry are all built-in.

---

## 💉 Dependency Injection

### @Inject - Auto-resolve Dependencies

```swift
class MyService {
    @Inject var client: URLSessionNetworkClient
    
    func fetchData() async throws -> Data {
        try await client.requestData(.get("/data"))
    }
}
```

### @HiltViewModel - Cached ViewModels

```swift
struct UserView: View {
    @HiltViewModel(GenericNetworkViewModel<User>.self) var vm  // Cached!
}
```

### DI Registration

```swift
DI.configure { di in
    // Singleton
    di.registerSingleton(TokenStorage.self, instance: KeychainTokenStorage())
    
    // Factory (new instance each time)
    di.register(MyService.self) { MyService() }
    
    // Generic service for any model
    di.register(GenericNetworkService<User>.self) {
        GenericNetworkService(.get("/users/me"))
    }
}
```

---

## 📱 SwiftUI Views

### NetworkDataView - Single Resource

```swift
NetworkDataView(vm) { data in
    Text(data.name)
}
```

### NetworkListDataView - Lists

```swift
NetworkListDataView(listVM) { item in
    Text(item.title)
}
```

Both handle:
- ✅ Loading indicator
- ✅ Error with retry button
- ✅ Pull to refresh (lists)
- ✅ Auto-loads on appear

---

## 🔐 Authentication

### Setup with Token Refresh

```swift
DI.configure { di in
    di.baseURL = "https://api.example.com"
    
    let storage = KeychainTokenStorage()
    di.registerSingleton(TokenStorage.self, instance: storage)
    
    di.register(URLSessionNetworkClient.self) {
        URLSessionNetworkClient.withAuth(
            baseURL: di.baseURL,
            tokenStorage: storage,
            refreshHandler: MyRefreshHandler()
        )
    }
}
```

### Refresh Handler

```swift
class MyRefreshHandler: TokenRefreshHandler {
    func refreshToken() async throws -> String {
        // Call your refresh API
        let response = try await refreshAPI()
        return response.accessToken
    }
    
    func onRefreshFailure(_ error: Error) async {
        // Navigate to login
    }
}
```

---

## 📝 Full Login Example

```swift
// MARK: - Models

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct LoginResponse: Codable, HTTPResponseDecodable {
    var statusCode: Int?
    let token: String
    let user: User
}

// MARK: - Service

class AuthService {
    @Inject var client: URLSessionNetworkClient
    @Inject var tokenStorage: TokenStorage
    
    func login(email: String, password: String) async throws -> LoginResponse {
        try await client.request(
            RequestBuilder.post("/auth/login")
                .body(LoginRequest(email: email, password: password))
        )
    }
    
    func saveToken(_ token: String) {
        tokenStorage.save(token)
    }
}

// MARK: - ViewModel

@MainActor
class LoginVM: ObservableObject {
    @Inject var authService: AuthService
    
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var error: String?
    
    func login() async {
        isLoading = true
        do {
            let response = try await authService.login(email: email, password: password)
            authService.saveToken(response.token)
        } catch let e as NetworkError {
            error = e.userMessage
        }
        isLoading = false
    }
}

// MARK: - View

struct LoginView: View {
    @StateObject var vm = LoginVM()
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $vm.email)
            SecureField("Password", text: $vm.password)
            
            if let error = vm.error {
                Text(error).foregroundColor(.red)
            }
            
            Button("Login") { Task { await vm.login() } }
                .disabled(vm.isLoading)
        }
        .padding()
    }
}
```

---

## 🛠️ Request Builder

```swift
// GET
let user: User = try await client.request(.get("/users/1"))

// POST with body
let created: User = try await client.request(
    .post("/users").body(CreateUserRequest(name: "John"))
)

// With headers and query params
let results: SearchResponse = try await client.request(
    .get("/search")
        .query("q", "swift")
        .header("X-API-Key", apiKey)
)
```

---

## ⚠️ Error Handling

```swift
do {
    let user = try await client.request(.get("/users/1"))
} catch let error as NetworkError {
    print(error.userMessage)       // "No internet connection"
    print(error.recoveryAction)    // .retry, .reauthenticate, etc.
}
```

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.
