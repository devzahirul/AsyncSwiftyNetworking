import SwiftUI

/// A SwiftUI view that handles loading, error, and content states automatically
/// Works with GenericNetworkViewModel<T>
public struct NetworkDataView<T: HTTPResponseDecodable, Content: View>: View {
    
    @ObservedObject private var viewModel: GenericNetworkViewModel<T>
    private let content: (T) -> Content
    
    /// Initialize with a ViewModel and content builder
    /// - Parameters:
    ///   - viewModel: The GenericNetworkViewModel to observe
    ///   - content: A view builder that takes the loaded data
    public init(
        _ viewModel: GenericNetworkViewModel<T>,
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self.viewModel = viewModel
        self.content = content
    }
    
    public var body: some View {
        Group {
            if viewModel.isLoading && viewModel.data == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                NetworkErrorView(error: error) {
                    Task { await viewModel.load() }
                }
            } else if let data = viewModel.data {
                content(data)
            } else {
                Color.clear
            }
        }
        .task {
            if viewModel.data == nil {
                await viewModel.load()
            }
        }
    }
}

// MARK: - List View

/// A SwiftUI view for lists that handles loading, error, and content states
public struct NetworkListDataView<T: Decodable & Identifiable, Row: View>: View {
    
    @ObservedObject private var viewModel: GenericListViewModel<T>
    private let row: (T) -> Row
    
    public init(
        _ viewModel: GenericListViewModel<T>,
        @ViewBuilder row: @escaping (T) -> Row
    ) {
        self.viewModel = viewModel
        self.row = row
    }
    
    public var body: some View {
        Group {
            if viewModel.isLoading && viewModel.items.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error, viewModel.items.isEmpty {
                NetworkErrorView(error: error) {
                    Task { await viewModel.load() }
                }
            } else {
                List {
                    ForEach(viewModel.items) { item in
                        row(item)
                    }
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .task {
            if viewModel.items.isEmpty {
                await viewModel.load()
            }
        }
    }
}

// MARK: - Error View

/// Reusable error view with retry
public struct NetworkErrorView: View {
    let error: NetworkError
    let onRetry: () -> Void
    
    public init(error: NetworkError, onRetry: @escaping () -> Void) {
        self.error = error
        self.onRetry = onRetry
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(error.userMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            if let buttonTitle = error.recoveryAction.buttonTitle {
                Button(buttonTitle, action: onRetry)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
