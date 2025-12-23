import Foundation

/// A protocol that enables a decodable response to also receive the HTTP status code.
public protocol HTTPResponseDecodable: Decodable {
    /// The HTTP status code of the response.
    var statusCode: Int? { get set }
}
