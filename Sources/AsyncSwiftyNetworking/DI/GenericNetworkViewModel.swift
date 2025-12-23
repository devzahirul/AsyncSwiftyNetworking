import SwiftUI

/// Generic Network ViewModel that works with any HTTPResponseDecodable type
/// Automatically fetches data from GenericNetworkService<T>
@MainActor
public final class GenericNetworkViewModel<T: HTTPResponseDecodable>: ObservableObject, DefaultInitializable {
    
    @Published public var data: T?
    @Published public var isLoading = false
    @Published public var error: NetworkError?
    
    private var service: GenericNetworkService<T>?
    
    public required init() {}
    
    /// Initialize with a pre-configured service
    public init(service: GenericNetworkService<T>) {
        self.service = service
    }
    
    /// Load data from the network
    public func load() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            let resolvedService = getService()
            data = try await resolvedService.fetch()
        } catch is CancellationError {
            // Ignored - user navigated away
        } catch let networkError as NetworkError {
            error = networkError
        } catch {
            self.error = .unknown
        }
        
        isLoading = false
    }
    
    /// Refresh data
    public func refresh() async {
        await load()
    }
    
    private func getService() -> GenericNetworkService<T> {
        if service == nil {
            service = DI.shared.resolve(GenericNetworkService<T>.self)
        }
        return service!
    }
}

// MARK: - List ViewModel

/// Generic Network ViewModel for lists
@MainActor
public final class GenericListViewModel<T: Decodable>: ObservableObject, DefaultInitializable {
    
    @Published public var items: [T] = []
    @Published public var isLoading = false
    @Published public var error: NetworkError?
    
    private var service: GenericListService<T>?
    
    public required init() {}
    
    public init(service: GenericListService<T>) {
        self.service = service
    }
    
    public func load() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            let resolvedService = getService()
            items = try await resolvedService.fetch()
        } catch is CancellationError {
            // Ignored
        } catch let networkError as NetworkError {
            error = networkError
        } catch {
            self.error = .unknown
        }
        
        isLoading = false
    }
    
    public func refresh() async {
        await load()
    }
    
    private func getService() -> GenericListService<T> {
        if service == nil {
            service = DI.shared.resolve(GenericListService<T>.self)
        }
        return service!
    }
}
