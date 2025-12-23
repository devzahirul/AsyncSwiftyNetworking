import Foundation

/// A protocol that enables a decodable response to also receive the HTTP status code.
public protocol HTTPResponseDecodable: Decodable {
    /// The HTTP status code of the response.
    var statusCode: Int? { get set }
}

// MARK: - Array Conformance

/// Wrapper for array responses to conform to HTTPResponseDecodable
public struct ArrayResponse<T: Decodable>: HTTPResponseDecodable {
    public var items: [T]
    public var statusCode: Int?
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        items = try container.decode([T].self)
        statusCode = nil
    }
}
