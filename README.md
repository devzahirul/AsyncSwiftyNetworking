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

// Define all service typealiases here
typealias ProfileService = GenericNetworkService<Profile>
typealias UserListService = GenericListService<User>
```

### 3. ViewModelType.swift

```swift
import AsyncSwiftyNetworking

// Define all ViewModel typealiases here
typealias ProfileViewModel = GenericNetworkViewModel<Profile>
typealias UserListViewModel = GenericListViewModel<User>
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

## 📝 Full Login Example

### ServiceType.swift (add)

```swift
typealias AuthServiceType = AuthService
```

### AuthService.swift

```swift
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
    
    func logout() {
        tokenStorage.clearToken()
        DI.shared.clearViewModels()
    }
}
```

### DI.swift (add)

```swift
di.register(AuthServiceType.self) { AuthService() }
```

### LoginViewModel.swift

```swift
@MainActor
class LoginViewModel: ObservableObject {
    @Inject var authService: AuthServiceType
    
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var error: String?
    @Published var isLoggedIn = false
    
    func login() async {
        isLoading = true
        error = nil
        
        do {
            let response = try await authService.login(email: email, password: password)
            authService.saveToken(response.token)
            isLoggedIn = true
        } catch let e as NetworkError {
            error = e.userMessage
        }
        
        isLoading = false
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
                Text(error).foregroundColor(.red)
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

## 🔐 Authentication with Token Refresh

### DI.swift

```swift
di.register(URLSessionNetworkClient.self) {
    URLSessionNetworkClient.withAuth(
        baseURL: di.baseURL,
        tokenStorage: storage,
        refreshHandler: MyRefreshHandler()
    )
}
```

### RefreshHandler.swift

```swift
class MyRefreshHandler: TokenRefreshHandler {
    func refreshToken() async throws -> String {
        let response = try await refreshAPI()
        return response.accessToken
    }
    
    func onRefreshFailure(_ error: Error) async {
        // Navigate to login
    }
}
```

---

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
