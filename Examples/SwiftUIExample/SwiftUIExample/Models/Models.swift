import Foundation
import AsyncSwiftyNetworking

// MARK: - Request Models

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

// MARK: - Response Models

struct LoginResponse: Codable, HTTPResponseDecodable {
    var statusCode: Int?
    let token: String
    let user: User
}

struct User: Codable, HTTPResponseDecodable, Identifiable, Sendable {
    var statusCode: Int?
    let id: String
    let name: String
    let email: String
}

struct Post: Codable, HTTPResponseDecodable, Identifiable, Sendable {
    var statusCode: Int?
    let id: Int
    let userId: Int
    let title: String
    let body: String
}
