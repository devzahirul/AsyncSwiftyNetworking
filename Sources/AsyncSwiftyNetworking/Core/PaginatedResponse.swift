import Foundation

// MARK: - Paginated Response

/// A generic paginated response wrapper.
public struct PaginatedResponse<T: Decodable>: HTTPResponseDecodable {
    public let data: [T]
    public let page: Int
    public let totalPages: Int
    public let totalItems: Int
    
    public var hasNextPage: Bool {
        return page < totalPages
    }
    
    // HTTPResponseDecodable
    public var statusCode: Int?
    
    enum CodingKeys: String, CodingKey {
        case data
        case page
        case totalPages = "total_pages"
        case totalItems = "total"
    }
}

// MARK: - Pagination Request

/// Parameters for paginated requests.
public struct PaginationParams {
    public let page: Int
    public let pageSize: Int
    
    public init(page: Int = 1, pageSize: Int = 20) {
        self.page = page
        self.pageSize = pageSize
    }
    
    public var queryItems: [URLQueryItem] {
        return [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(pageSize)")
        ]
    }
}
