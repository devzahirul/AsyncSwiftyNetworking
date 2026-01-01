import SwiftUI

/// Generic Network ViewModel that works with any HTTPResponseDecodable type
/// Automatically fetches data from GenericNetworkService<T>
@MainActor
public final class GenericNetworkViewModel<T: HTTPResponseDecodable>: ObservableObject, DefaultInitializable {
    
    @Published public var data: T?
    @Published public var isLoading = false
    @Published public var error: NetworkError?
    
    private var service: GenericNetworkService<T>?
    private var loadTask: Task<Void, Never>?
    private var currentLoadID: UUID?
    
    public required init() {}
    
    /// Initialize with a pre-configured service
    public init(service: GenericNetworkService<T>) {
        self.service = service
    }
    
    /// Set service dynamically (for parameterized endpoints)
    public func setService(_ service: GenericNetworkService<T>) {
        self.service = service
    }
    
    /// Load data from the network
    /// - Note: Cancels any existing load operation before starting a new one
    public func load() async {
        let loadID = UUID()
        currentLoadID = loadID
        
        isLoading = true
        error = nil
        
        // Yield to let SwiftUI render loading state
        await Task.yield()
        
        // Check cancellation/supersession after yield
        if Task.isCancelled || currentLoadID != loadID {
            return
        }
        
        do {
            let resolvedService = try getService()
            data = try await resolvedService.fetch()
        } catch is CancellationError {
            // Ignored - user navigated away or called cancel()
        } catch let networkError as NetworkError {
            if currentLoadID == loadID {
                error = networkError
            }
        } catch {
            if currentLoadID == loadID {
                self.error = .underlying(error.localizedDescription)
            }
        }
        
        if !Task.isCancelled && currentLoadID == loadID {
            isLoading = false
        }
    }
    
    /// Load data with task tracking for cancellation support
    public func loadWithTask() {
        loadTask?.cancel()
        loadTask = Task {
            await load()
        }
    }
    
    /// Cancel the current load operation
    public func cancel() {
        loadTask?.cancel()
        loadTask = nil
        currentLoadID = UUID() // Invalidate current load
        isLoading = false
    }
    
    /// Refresh data (cancels existing load first)
    public func refresh() async {
        cancel()
        await load()
    }
    
    private func getService() throws -> GenericNetworkService<T> {
        if let existingService = service {
            return existingService
        }
        
        guard let resolved = DI.shared.tryResolve(GenericNetworkService<T>.self) else {
            throw NetworkError.underlying("GenericNetworkService<\(T.self)> not registered in DI container. Call DI.configure() first.")
        }
        
        service = resolved
        return resolved
    }
    
    deinit {
        loadTask?.cancel()
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
    private var loadTask: Task<Void, Never>?
    private var currentLoadID: UUID?
    
    public required init() {}
    
    public init(service: GenericListService<T>) {
        self.service = service
    }
    
    /// Set service dynamically (for parameterized endpoints)
    public func setService(_ service: GenericListService<T>) {
        self.service = service
    }
    
    /// Load data from the network
    /// - Note: Cancels any existing load operation before starting a new one
    public func load() async {
        let loadID = UUID()
        currentLoadID = loadID
        
        isLoading = true
        error = nil
        
        // Yield to let SwiftUI render loading state
        await Task.yield()
        
        // Check cancellation/supersession after yield
        if Task.isCancelled || currentLoadID != loadID {
            return
        }
        
        do {
            let resolvedService = try getService()
            items = try await resolvedService.fetch()
        } catch is CancellationError {
            // Ignored - user navigated away or called cancel()
        } catch let networkError as NetworkError {
            if currentLoadID == loadID {
                error = networkError
            }
        } catch {
            if currentLoadID == loadID {
                self.error = .underlying(error.localizedDescription)
            }
        }
        
        if !Task.isCancelled && currentLoadID == loadID {
            isLoading = false
        }
    }
    
    /// Load data with task tracking for cancellation support
    public func loadWithTask() {
        loadTask?.cancel()
        loadTask = Task {
            await load()
        }
    }
    
    /// Cancel the current load operation
    public func cancel() {
        loadTask?.cancel()
        loadTask = nil
        currentLoadID = UUID() // Invalidate current load
        isLoading = false
    }
    
    /// Refresh data (cancels existing load first)
    public func refresh() async {
        cancel()
        await load()
    }
    
    private func getService() throws -> GenericListService<T> {
        if let existingService = service {
            return existingService
        }
        
        guard let resolved = DI.shared.tryResolve(GenericListService<T>.self) else {
            throw NetworkError.underlying("GenericListService<\(T.self)> not registered in DI container. Call DI.configure() first.")
        }
        
        service = resolved
        return resolved
    }
    
    deinit {
        loadTask?.cancel()
    }
}

