import AsyncSwiftyNetworking

// MARK: - ViewModel Type Aliases

// Fetch ViewModels
typealias UserViewModel = GenericNetworkViewModel<User>
typealias PostListViewModel = GenericListViewModel<Post>

// Mutation ViewModels (base type for subclassing)
typealias LoginViewModelBase = GenericMutationViewModel<LoginRequest, LoginResponse>
