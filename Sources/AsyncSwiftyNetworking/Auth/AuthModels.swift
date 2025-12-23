import Foundation

// MARK: - Auth Response

public struct AuthResponse: HTTPResponseDecodable {
    public let token: String
    public let userId: String
    public let userEmail: String?
    
    // HTTPResponseDecodable requirement
    public var statusCode: Int?
    
    enum CodingKeys: String, CodingKey {
        case token = "access_token"
        case userId = "user_id"
        case userEmail = "email"
    }
}

// MARK: - Login Response

public struct LoginResponse: HTTPResponseDecodable {
    public let message: String?
    public let token: String?
    public let id: Int?
    public let name: String?
    public let phone: String?
    public let dob: String?
    public let neighbourhoodId: Int?

    public var statusCode: Int?

    private enum CodingKeys: String, CodingKey {
        case data
        case message
        case token
        case accessToken
        case id
        case name
        case phone
        case dob
        case neighbourhoodId
    }

    private enum DataKeys: String, CodingKey {
        case message
        case token
        case accessToken
        case id
        case name
        case phone
        case dob
        case neighbourhoodId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let topMessage = try container.decodeIfPresent(String.self, forKey: .message)
        let topToken = try container.decodeIfPresent(String.self, forKey: .token)
        let topAccessToken = try container.decodeIfPresent(String.self, forKey: .accessToken)
        let resolvedTopToken = topToken ?? topAccessToken

        if container.contains(.data),
           let dataContainer = try? container.nestedContainer(keyedBy: DataKeys.self, forKey: .data) {
            let dataMessage = try dataContainer.decodeIfPresent(String.self, forKey: .message)
            message = topMessage ?? dataMessage

            var resolvedToken = resolvedTopToken
            if resolvedToken == nil {
                resolvedToken = try dataContainer.decodeIfPresent(String.self, forKey: .token)
            }
            if resolvedToken == nil {
                resolvedToken = try dataContainer.decodeIfPresent(String.self, forKey: .accessToken)
            }
            token = resolvedToken
            id = try dataContainer.decodeIfPresent(Int.self, forKey: .id)
            name = try dataContainer.decodeIfPresent(String.self, forKey: .name)
            phone = try dataContainer.decodeIfPresent(String.self, forKey: .phone)
            dob = try dataContainer.decodeIfPresent(String.self, forKey: .dob)
            neighbourhoodId = try dataContainer.decodeIfPresent(Int.self, forKey: .neighbourhoodId)
        } else {
            message = topMessage
            token = resolvedTopToken
            id = try container.decodeIfPresent(Int.self, forKey: .id)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            phone = try container.decodeIfPresent(String.self, forKey: .phone)
            dob = try container.decodeIfPresent(String.self, forKey: .dob)
            neighbourhoodId = try container.decodeIfPresent(Int.self, forKey: .neighbourhoodId)
        }

        statusCode = nil
    }
}

// MARK: - Auth Status Response

public struct AuthStatusResponse: HTTPResponseDecodable {
    public let message: String?
    public let success: Bool?

    public var statusCode: Int?

    private enum CodingKeys: String, CodingKey {
        case message
        case success
        case data
    }

    private enum DataKeys: String, CodingKey {
        case message
        case success
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let topMessage = try container.decodeIfPresent(String.self, forKey: .message)
        let topSuccess = try container.decodeIfPresent(Bool.self, forKey: .success)

        var nestedMessage: String?
        var nestedSuccess: Bool?
        if container.contains(.data),
           let dataContainer = try? container.nestedContainer(keyedBy: DataKeys.self, forKey: .data) {
            nestedMessage = try dataContainer.decodeIfPresent(String.self, forKey: .message)
            nestedSuccess = try dataContainer.decodeIfPresent(Bool.self, forKey: .success)
        }

        message = topMessage ?? nestedMessage
        success = topSuccess ?? nestedSuccess
        statusCode = nil
    }
}

// MARK: - Signup Complete Response

public struct SignupCompleteResponse: HTTPResponseDecodable {
    public let id: Int?
    public let name: String?
    public let phone: String?
    public let dob: String?
    public let neighbourhoodId: Int?
    public let token: String?
    public let message: String?

    public var statusCode: Int?

    private enum CodingKeys: String, CodingKey {
        case data
        case message
        case token
        case accessToken
        case id
        case name
        case phone
        case dob
        case neighbourhoodId
    }

    private enum DataKeys: String, CodingKey {
        case id
        case name
        case phone
        case dob
        case neighbourhoodId
        case token
        case accessToken
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = try container.decodeIfPresent(String.self, forKey: .message)

        if container.contains(.data),
           let dataContainer = try? container.nestedContainer(keyedBy: DataKeys.self, forKey: .data) {
            id = try dataContainer.decodeIfPresent(Int.self, forKey: .id)
            name = try dataContainer.decodeIfPresent(String.self, forKey: .name)
            phone = try dataContainer.decodeIfPresent(String.self, forKey: .phone)
            dob = try dataContainer.decodeIfPresent(String.self, forKey: .dob)
            neighbourhoodId = try dataContainer.decodeIfPresent(Int.self, forKey: .neighbourhoodId)
            var resolvedToken = try dataContainer.decodeIfPresent(String.self, forKey: .token)
            if resolvedToken == nil {
                resolvedToken = try dataContainer.decodeIfPresent(String.self, forKey: .accessToken)
            }
            token = resolvedToken
        } else {
            id = try container.decodeIfPresent(Int.self, forKey: .id)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            phone = try container.decodeIfPresent(String.self, forKey: .phone)
            dob = try container.decodeIfPresent(String.self, forKey: .dob)
            neighbourhoodId = try container.decodeIfPresent(Int.self, forKey: .neighbourhoodId)
            var resolvedToken = try container.decodeIfPresent(String.self, forKey: .token)
            if resolvedToken == nil {
                resolvedToken = try container.decodeIfPresent(String.self, forKey: .accessToken)
            }
            token = resolvedToken
        }

        statusCode = nil
    }
}

// MARK: - Login Request

public struct LoginRequest: Encodable {
    public let mobile: String
    public let password: String
    
    public init(mobile: String, password: String) {
        self.mobile = mobile
        self.password = password
    }
}

// MARK: - Signup Start Request

public struct SignupStartRequest: Encodable {
    public let neighbourhoodId: Int
    public let name: String
    public let dob: String
    public let mobile: String

    public init(neighbourhoodId: Int, name: String, dob: String, mobile: String) {
        self.neighbourhoodId = neighbourhoodId
        self.name = name
        self.dob = dob
        self.mobile = mobile
    }
}

// MARK: - Validate OTP Request

public struct ValidateOtpRequest: Encodable {
    public let mobile: String
    public let otp: String

    public init(mobile: String, otp: String) {
        self.mobile = mobile
        self.otp = otp
    }
}

// MARK: - Signup Complete Request

public struct SignupCompleteRequest: Encodable {
    public let mobile: String
    public let password: String
    public let passwordConfirmation: String

    public init(mobile: String, password: String, passwordConfirmation: String) {
        self.mobile = mobile
        self.password = password
        self.passwordConfirmation = passwordConfirmation
    }
}
