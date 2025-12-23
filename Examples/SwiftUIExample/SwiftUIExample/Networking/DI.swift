import Foundation
import AsyncSwiftyNetworking

// MARK: - DI Configuration

enum AppDI {
    
    static func configure() {
        DI.configure { di in
            // Base URL (using JSONPlaceholder for demo)
            di.baseURL = "https://jsonplaceholder.typicode.com"
            
            // Token Storage
            let storage = UserDefaultsTokenStorage()
            di.registerSingleton(TokenStorage.self, instance: storage)
            
            // Network Client
            di.register(URLSessionNetworkClient.self) {
                URLSessionNetworkClient.quick(
                    baseURL: di.baseURL,
                    logging: true
                )
            }
            
            // Services
            di.register(UserService.self) {
                UserService(.get("/users/1"))
            }
            
            di.register(PostListService.self) {
                PostListService(.get("/posts"))
            }
            
            di.register(LoginService.self) {
                LoginService(.post, "/login")
            }
        }
    }
}
