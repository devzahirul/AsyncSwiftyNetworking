import Foundation

public enum AuthEndpoint: Endpoint {
    case login(request: LoginRequest)
    case signupStart(request: SignupStartRequest)
    case validateOtp(request: ValidateOtpRequest)
    case signupComplete(request: SignupCompleteRequest)
    
    public var path: String {
        switch self {
        case .login:
            return "/login"
        case .signupStart:
            return "/signup"
        case .validateOtp:
            return "/validate-otp"
        case .signupComplete:
            return "/signup/complete"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .login, .signupStart, .validateOtp, .signupComplete:
            return .post
        }
    }
    
    public var body: Data? {
        let encoder = URLSessionNetworkClient.defaultEncoder
        switch self {
        case .login(let request):
            return try? encoder.encode(request)
        case .signupStart(let request):
            return try? encoder.encode(request)
        case .validateOtp(let request):
            return try? encoder.encode(request)
        case .signupComplete(let request):
            return try? encoder.encode(request)
        }
    }
}
