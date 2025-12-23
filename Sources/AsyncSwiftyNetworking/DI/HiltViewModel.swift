import SwiftUI

/// Property wrapper for ViewModel injection with caching
/// Like Android's `by viewModels()` - returns cached instance if exists
@propertyWrapper
public struct HiltViewModel<VM: ObservableObject>: DynamicProperty {
    
    @StateObject private var container: Container
    
    /// Initialize with type - factory creates instance with default init
    public init(_ type: VM.Type) where VM: DefaultInitializable {
        _container = StateObject(wrappedValue: Container(factory: { VM() }))
    }
    
    /// Initialize with custom factory
    public init(_ type: VM.Type, factory: @escaping () -> VM) {
        _container = StateObject(wrappedValue: Container(factory: factory))
    }
    
    /// Initialize with key for parameter-based VMs
    public init(key: String, factory: @escaping () -> VM) {
        _container = StateObject(wrappedValue: Container(key: key, factory: factory))
    }
    
    public var wrappedValue: VM {
        container.viewModel
    }
    
    public var projectedValue: ObservedObject<VM>.Wrapper {
        ObservedObject(wrappedValue: container.viewModel).projectedValue
    }
    
    // MARK: - Container
    
    private class Container: ObservableObject {
        let viewModel: VM
        
        init(factory: @escaping () -> VM) {
            let type = VM.self
            self.viewModel = DI.shared.viewModel(type, factory: factory)
        }
        
        init(key: String, factory: @escaping () -> VM) {
            self.viewModel = DI.shared.viewModel(key: key, factory: factory)
        }
    }
}

// MARK: - Protocol for default initialization

/// Protocol for ViewModels that can be created with no arguments
public protocol DefaultInitializable {
    init()
}
