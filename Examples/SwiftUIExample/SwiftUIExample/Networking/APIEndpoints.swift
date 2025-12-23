import Foundation
import AsyncSwiftyNetworking

// MARK: - API Endpoints

/// All API endpoints organized by feature area
enum API {
    
    // MARK: - Auth Endpoints
    
    enum Auth: Endpoint {
        case login(email: String, password: String)
        case register(name: String, email: String, password: String)
        case refreshToken
        case logout
        
        var path: String {
            switch self {
            case .login: return "/auth/login"
            case .register: return "/auth/register"
            case .refreshToken: return "/auth/refresh"
            case .logout: return "/auth/logout"
            }
        }
        
        var method: HTTPMethod {
            switch self {
            case .login, .register, .refreshToken, .logout:
                return .post
            }
        }
        
        var body: Data? {
            switch self {
            case .login(let email, let password):
                return encode(["email": email, "password": password])
            case .register(let name, let email, let password):
                return encode(["name": name, "email": email, "password": password])
            case .refreshToken, .logout:
                return nil
            }
        }
    }
    
    // MARK: - Posts Endpoints
    
    enum Posts: Endpoint {
        case list
        case get(id: Int)
        case create(title: String, body: String)
        case update(id: Int, title: String, body: String)
        case delete(id: Int)
        
        var path: String {
            switch self {
            case .list: return "/posts"
            case .get(let id): return "/posts/\(id)"
            case .create: return "/posts"
            case .update(let id, _, _): return "/posts/\(id)"
            case .delete(let id): return "/posts/\(id)"
            }
        }
        
        var method: HTTPMethod {
            switch self {
            case .list, .get: return .get
            case .create: return .post
            case .update: return .put
            case .delete: return .delete
            }
        }
        
        var body: Data? {
            switch self {
            case .create(let title, let body):
                return encode(["title": title, "body": body])
            case .update(_, let title, let body):
                return encode(["title": title, "body": body])
            default:
                return nil
            }
        }
    }
    
    // MARK: - User Endpoints
    
    enum Users: Endpoint {
        case me
        case update(name: String)
        case uploadAvatar
        case uploadImages
        
        var path: String {
            switch self {
            case .me: return "/users/me"
            case .update: return "/users/me"
            case .uploadAvatar: return "/users/me/avatar"
            case .uploadImages: return "/users/me/images"
            }
        }
        
        var method: HTTPMethod {
            switch self {
            case .me: return .get
            case .update: return .patch
            case .uploadAvatar, .uploadImages: return .post
            }
        }
        
        var body: Data? {
            switch self {
            case .update(let name):
                return encode(["name": name])
            default:
                return nil
            }
        }
    }
}

// MARK: - Helper

private func encode<T: Encodable>(_ value: T) -> Data? {
    try? JSONEncoder().encode(value)
}
