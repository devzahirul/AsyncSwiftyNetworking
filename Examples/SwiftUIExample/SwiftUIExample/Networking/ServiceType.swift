import AsyncSwiftyNetworking

// MARK: - Service Type Aliases

// Fetch Services
typealias UserService = GenericNetworkService<User>
typealias PostListService = GenericListService<Post>

// Mutation Services
typealias LoginService = GenericMutationService<LoginRequest, LoginResponse>
