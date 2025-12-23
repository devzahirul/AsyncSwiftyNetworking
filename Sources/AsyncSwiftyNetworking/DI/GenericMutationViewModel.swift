import SwiftUI

/// Generic Mutation ViewModel - subclass for custom behavior
/// Handles POST/PUT/DELETE requests with dynamic body
@MainActor
open class GenericMutationViewModel<Request: Encodable, Response: HTTPResponseDecodable>: ObservableObject {
    
    @Published public var response: Response?
    @Published public var isLoading = false
    @Published public var error: NetworkError?
    @Published public var isSuccess = false
    
    private var service: GenericMutationService<Request, Response>?
    
    public init() {}
    
    public init(service: GenericMutationService<Request, Response>) {
        self.service = service
    }
    
    /// Execute mutation - override onSuccess/onFailure for custom behavior
    public func execute(_ request: Request) async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        isSuccess = false
        
        do {
            response = try await getService().execute(request)
            isSuccess = true
            await onSuccess(response!)
        } catch is CancellationError {
            // Ignored
        } catch let networkError as NetworkError {
            error = networkError
            await onFailure(networkError)
        } catch {
            self.error = .unknown
            await onFailure(.unknown)
        }
        
        isLoading = false
    }
    
    /// Override for custom success handling
    open func onSuccess(_ response: Response) async {
        // Override in subclass
    }
    
    /// Override for custom failure handling
    open func onFailure(_ error: NetworkError) async {
        // Override in subclass
    }
    
    private func getService() -> GenericMutationService<Request, Response> {
        if service == nil {
            service = DI.shared.resolve(GenericMutationService<Request, Response>.self)
        }
        return service!
    }
}

// MARK: - Login ViewModel Example

/// Example: LoginViewModel that saves token on success
@MainActor
open class LoginMutationViewModel<Request: Encodable, Response: HTTPResponseDecodable>: GenericMutationViewModel<Request, Response> {
    
    @Inject private var tokenStorage: TokenStorage
    
    /// Override to provide token from response
    open func extractToken(from response: Response) -> String? {
        return nil // Override in subclass
    }
    
    open override func onSuccess(_ response: Response) async {
        if let token = extractToken(from: response) {
            tokenStorage.save(token)
        }
    }
    
    open override func onFailure(_ error: NetworkError) async {
        // Override for custom error handling
    }
}
