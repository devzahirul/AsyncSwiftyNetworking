import SwiftUI

/// AuthView - Generic authentication view with success/failure callbacks
public struct AuthView<Request: Encodable, Response: HTTPResponseDecodable, Form: View>: View {
    
    @ObservedObject private var viewModel: GenericMutationViewModel<Request, Response>
    private let form: (Binding<Bool>, @escaping (Request) async -> Void) -> Form
    private let onSuccess: (Response) -> Void
    private let onFailure: (NetworkError) -> Void
    
    /// Initialize AuthView
    /// - Parameters:
    ///   - viewModel: The mutation ViewModel
    ///   - form: Form builder with (isLoading, submit) parameters
    ///   - onSuccess: Called when auth succeeds
    ///   - onFailure: Called when auth fails
    public init(
        _ viewModel: GenericMutationViewModel<Request, Response>,
        @ViewBuilder form: @escaping (Binding<Bool>, @escaping (Request) async -> Void) -> Form,
        onSuccess: @escaping (Response) -> Void,
        onFailure: @escaping (NetworkError) -> Void = { _ in }
    ) {
        self.viewModel = viewModel
        self.form = form
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }
    
    public var body: some View {
        form(
            Binding(get: { viewModel.isLoading }, set: { _ in }),
            { request in
                await viewModel.execute(request)
                if let response = viewModel.response {
                    onSuccess(response)
                } else if let error = viewModel.error {
                    onFailure(error)
                }
            }
        )
    }
}

// MARK: - Simple AuthView Alternative

/// Simple auth container that wraps login flow
public struct AuthContainer<Content: View>: View {
    @Binding var isLoggedIn: Bool
    let loginView: () -> Content
    let homeView: () -> AnyView
    
    public init(
        isLoggedIn: Binding<Bool>,
        @ViewBuilder loginView: @escaping () -> Content,
        @ViewBuilder homeView: @escaping () -> some View
    ) {
        self._isLoggedIn = isLoggedIn
        self.loginView = loginView
        self.homeView = { AnyView(homeView()) }
    }
    
    public var body: some View {
        if isLoggedIn {
            homeView()
        } else {
            loginView()
        }
    }
}
