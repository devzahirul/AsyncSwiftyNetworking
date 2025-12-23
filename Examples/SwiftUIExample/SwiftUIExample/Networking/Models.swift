import Foundation
import AsyncSwiftyNetworking

// MARK: - Auth Models

struct LoginResponse: HTTPResponseDecodable {
    let accessToken: String
    let refreshToken: String
    let user: User
    var statusCode: Int?
}

struct RegisterResponse: HTTPResponseDecodable {
    let message: String
    let user: User
    var statusCode: Int?
}

struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}

// MARK: - User Models

struct User: Codable, Identifiable, Sendable {
    let id: Int
    let name: String
    let email: String
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, email
        case avatarUrl = "avatar_url"
    }
}

struct UserResponse: HTTPResponseDecodable {
    let user: User
    var statusCode: Int?
}

// MARK: - Post Models

struct Post: Codable, Identifiable, Sendable {
    let id: Int
    let userId: Int
    let title: String
    let body: String
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title, body
        case createdAt = "created_at"
    }
    
    // Custom initializer for decoding from different formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        // Handle both "userId" and "user_id"
        if let userId = try? container.decode(Int.self, forKey: .userId) {
            self.userId = userId
        } else {
            self.userId = 1
        }
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
    }
    
    init(id: Int, userId: Int, title: String, body: String, createdAt: String?) {
        self.id = id
        self.userId = userId
        self.title = title
        self.body = body
        self.createdAt = createdAt
    }
}

/// Wrapper for array response (mock session returns array, we need HTTPResponseDecodable)
struct PostsListResponse: HTTPResponseDecodable {
    let posts: [Post]
    var statusCode: Int?
    
    init(from decoder: Decoder) throws {
        // Try to decode as array directly (from mock session)
        if let postsArray = try? [Post](from: decoder) {
            self.posts = postsArray
            self.statusCode = nil
        } else {
            // Try to decode as wrapped response
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.posts = try container.decode([Post].self, forKey: .posts)
            self.statusCode = try container.decodeIfPresent(Int.self, forKey: .statusCode)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case posts, statusCode
    }
}

struct PostResponse: HTTPResponseDecodable {
    let id: Int
    let userId: Int
    let title: String
    let body: String
    var statusCode: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title, body
    }
}

struct PostsResponse: HTTPResponseDecodable {
    let posts: [Post]
    var statusCode: Int?
}

// MARK: - Upload Models

struct ImageUploadResponse: HTTPResponseDecodable {
    let message: String
    let urls: [String]
    var statusCode: Int?
}

struct AvatarUploadResponse: HTTPResponseDecodable {
    let message: String
    let avatarUrl: String
    var statusCode: Int?
    
    enum CodingKeys: String, CodingKey {
        case message
        case avatarUrl = "avatar_url"
    }
}

// MARK: - Empty Response

struct EmptyResponse: HTTPResponseDecodable {
    var statusCode: Int?
}

// MARK: - Error Response

struct ErrorResponse: Decodable {
    let message: String
    let code: String?
}
