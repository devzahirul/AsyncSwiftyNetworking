import Foundation

/// A service class responsible for authentication operations.
public actor AuthService {
    
    private let client: NetworkClient
    private let storage: TokenStorage
    private let profileStorage: UserProfileStorage
    private let baseUrl: String
    
    /// Initializes the AuthService.
    public init(
        client: NetworkClient = URLSessionNetworkClient.withDefaultInterceptors(),
        storage: TokenStorage = TokenStorageContainer.shared,
        profileStorage: UserProfileStorage = UserProfileStorageContainer.shared,
        baseUrl: String = "http://karrot-api.touhidur.me/api/app"
    ) {
        self.client = client
        self.storage = storage
        self.profileStorage = profileStorage
        self.baseUrl = baseUrl
    }
    
    // MARK: - Login
    
    /// Logs in a user with mobile number and password.
    public func login(mobile: String, password: String) async throws -> LoginResponse {
        let request = LoginRequest(mobile: mobile, password: password)
        let endpoint = AuthEndpoint.login(request: request)
        let response: LoginResponse = try await client.request(endpoint, baseUrl: baseUrl)
        
        if let token = response.token {
            storage.save(token)
        }
        saveProfile(
            id: response.id,
            name: response.name,
            phone: response.phone,
            dob: response.dob,
            neighbourhoodId: response.neighbourhoodId
        )
        
        return response
    }
    
    // MARK: - Signup

    /// Starts signup with neighbourhood and profile details.
    public func startSignup(
        neighbourhoodId: Int,
        name: String,
        dob: String,
        mobile: String
    ) async throws -> AuthStatusResponse {
        let request = SignupStartRequest(
            neighbourhoodId: neighbourhoodId,
            name: name,
            dob: dob,
            mobile: mobile
        )
        let endpoint = AuthEndpoint.signupStart(request: request)
        let response: AuthStatusResponse = try await client.request(endpoint, baseUrl: baseUrl)

        return response
    }

    /// Validates the OTP sent to the user's mobile number.
    public func validateOtp(mobile: String, otp: String) async throws -> AuthStatusResponse {
        let request = ValidateOtpRequest(mobile: mobile, otp: otp)
        let endpoint = AuthEndpoint.validateOtp(request: request)
        let response: AuthStatusResponse = try await client.request(endpoint, baseUrl: baseUrl)

        return response
    }

    /// Completes signup by setting the user's password.
    public func completeSignup(
        mobile: String,
        password: String,
        passwordConfirmation: String
    ) async throws -> SignupCompleteResponse {
        let request = SignupCompleteRequest(
            mobile: mobile,
            password: password,
            passwordConfirmation: passwordConfirmation
        )
        let endpoint = AuthEndpoint.signupComplete(request: request)
        let response: SignupCompleteResponse = try await client.request(endpoint, baseUrl: baseUrl)

        if let token = response.token {
            storage.save(token)
        }
        saveProfile(
            id: response.id,
            name: response.name,
            phone: response.phone,
            dob: response.dob,
            neighbourhoodId: response.neighbourhoodId
        )
        
        return response
    }
    
    // MARK: - Logout
    
    public func logout() {
        storage.clear()
        profileStorage.clear()
    }
    
    // MARK: - Token Status
    
    public var isAuthenticated: Bool {
        return storage.currentToken != nil
    }

    private func saveProfile(
        id: Int?,
        name: String?,
        phone: String?,
        dob: String?,
        neighbourhoodId: Int?
    ) {
        let profile = UserProfile(
            id: id,
            name: name,
            phone: phone,
            dob: dob,
            neighbourhoodId: neighbourhoodId
        )
        profileStorage.save(profile)
    }
}
