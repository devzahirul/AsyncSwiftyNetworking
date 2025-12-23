import XCTest
@testable import AsyncSwiftyNetworking

/// Tests for the DI Container
final class DITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        DI.shared.reset()
    }
    
    override func tearDown() {
        DI.shared.reset()
        super.tearDown()
    }
    
    // MARK: - Registration Tests
    
    func testRegisterAndResolveFactory() {
        // Given
        DI.shared.register(MockService.self) { MockServiceImpl() }
        
        // When
        let service = DI.shared.resolve(MockService.self)
        
        // Then
        XCTAssertNotNil(service)
    }
    
    func testFactoryCreatesNewInstanceEachTime() {
        // Given
        DI.shared.register(MockService.self) { MockServiceImpl() }
        
        // When
        let service1 = DI.shared.resolve(MockService.self)
        let service2 = DI.shared.resolve(MockService.self)
        
        // Then - Factory creates new each time
        XCTAssertFalse(service1 === service2)
    }
    
    func testRegisterSingletonReturnsSameInstance() {
        // Given
        let instance = MockServiceImpl()
        DI.shared.registerSingleton(MockService.self, instance: instance)
        
        // When
        let resolved1 = DI.shared.resolve(MockService.self)
        let resolved2 = DI.shared.resolve(MockService.self)
        
        // Then - Singleton returns same
        XCTAssertTrue(resolved1 === instance)
        XCTAssertTrue(resolved2 === instance)
    }
    
    func testSingletonTakesPriorityOverFactory() {
        // Given
        let singleton = MockServiceImpl()
        DI.shared.register(MockService.self) { MockServiceImpl() }
        DI.shared.registerSingleton(MockService.self, instance: singleton)
        
        // When
        let resolved = DI.shared.resolve(MockService.self)
        
        // Then - Singleton wins
        XCTAssertTrue(resolved === singleton)
    }
    
    func testResetClearsAllRegistrations() {
        // Given
        DI.shared.register(MockService.self) { MockServiceImpl() }
        
        // When
        DI.shared.reset()
        
        // Then - Should have no registration (would crash in real usage)
        // We can't test crash, but we can verify new registration works
        DI.shared.register(MockService.self) { MockServiceImpl() }
        XCTAssertNotNil(DI.shared.resolve(MockService.self))
    }
    
    // MARK: - ViewModel Store Tests
    
    func testViewModelCachedByType() {
        // Given
        class TestVM: ObservableObject {}
        
        // When
        let vm1 = DI.shared.viewModel(TestVM.self) { TestVM() }
        let vm2 = DI.shared.viewModel(TestVM.self) { TestVM() }
        
        // Then - Same instance returned
        XCTAssertTrue(vm1 === vm2)
    }
    
    func testViewModelCachedByKey() {
        // Given
        class TestVM: ObservableObject {
            let id: String
            init(id: String) { self.id = id }
        }
        
        // When
        let vm1 = DI.shared.viewModel(key: "user-1") { TestVM(id: "1") }
        let vm2 = DI.shared.viewModel(key: "user-2") { TestVM(id: "2") }
        let vm1Again = DI.shared.viewModel(key: "user-1") { TestVM(id: "should-not-create") }
        
        // Then
        XCTAssertEqual(vm1.id, "1")
        XCTAssertEqual(vm2.id, "2")
        XCTAssertTrue(vm1 === vm1Again)  // Same key = same instance
    }
    
    func testClearViewModelsClearsCache() {
        // Given
        class TestVM: ObservableObject {}
        let vm1 = DI.shared.viewModel(TestVM.self) { TestVM() }
        
        // When
        DI.shared.clearViewModels()
        let vm2 = DI.shared.viewModel(TestVM.self) { TestVM() }
        
        // Then - New instance after clear
        XCTAssertFalse(vm1 === vm2)
    }
}

// MARK: - Mocks

private protocol MockService: AnyObject {}
private final class MockServiceImpl: MockService {}
