import Foundation

public final class KarrotNetworkingFacade: @unchecked Sendable {
    public struct Configuration: Sendable {
        public static let defaultBaseURL = "http://karrot-api.touhidur.me/api/app"

        public var baseURL: String
        public var loggingLevel: LoggingInterceptor.LogLevel
        public var tokenStorage: TokenStorage
        public var userProfileStorage: UserProfileStorage
        public var session: any URLSessionProtocol
        public var decoder: JSONDecoder
        public var networkConfiguration: NetworkConfiguration
        public var requestInterceptors: [RequestInterceptor]
        public var responseInterceptors: [ResponseInterceptor]
        public var includeAuthInterceptor: Bool
        public var syncSharedContainers: Bool

        public init(
            baseURL: String = Configuration.defaultBaseURL,
            loggingLevel: LoggingInterceptor.LogLevel = .verbose,
            tokenStorage: TokenStorage = TokenStorageContainer.shared,
            userProfileStorage: UserProfileStorage = UserProfileStorageContainer.shared,
            session: any URLSessionProtocol = URLSession.shared,
            decoder: JSONDecoder = URLSessionNetworkClient.defaultDecoder,
            networkConfiguration: NetworkConfiguration = .default,
            requestInterceptors: [RequestInterceptor] = [],
            responseInterceptors: [ResponseInterceptor] = [],
            includeAuthInterceptor: Bool = true,
            syncSharedContainers: Bool = true
        ) {
            self.baseURL = baseURL
            self.loggingLevel = loggingLevel
            self.tokenStorage = tokenStorage
            self.userProfileStorage = userProfileStorage
            self.session = session
            self.decoder = decoder
            self.networkConfiguration = networkConfiguration
            self.requestInterceptors = requestInterceptors
            self.responseInterceptors = responseInterceptors
            self.includeAuthInterceptor = includeAuthInterceptor
            self.syncSharedContainers = syncSharedContainers
        }
    }

    public struct Builder {
        private var configuration: Configuration

        public init(configuration: Configuration = Configuration()) {
            self.configuration = configuration
        }

        public func baseURL(_ value: String) -> Builder {
            var copy = self
            copy.configuration.baseURL = value
            return copy
        }

        public func logging(_ level: LoggingInterceptor.LogLevel) -> Builder {
            var copy = self
            copy.configuration.loggingLevel = level
            return copy
        }

        public func enableLogging(_ enabled: Bool) -> Builder {
            logging(enabled ? .verbose : .none)
        }

        public func tokenStorage(_ storage: TokenStorage) -> Builder {
            var copy = self
            copy.configuration.tokenStorage = storage
            return copy
        }

        public func userProfileStorage(_ storage: UserProfileStorage) -> Builder {
            var copy = self
            copy.configuration.userProfileStorage = storage
            return copy
        }

        public func session(_ session: any URLSessionProtocol) -> Builder {
            var copy = self
            copy.configuration.session = session
            return copy
        }

        public func decoder(_ decoder: JSONDecoder) -> Builder {
            var copy = self
            copy.configuration.decoder = decoder
            return copy
        }
        
        public func networkConfiguration(_ config: NetworkConfiguration) -> Builder {
            var copy = self
            copy.configuration.networkConfiguration = config
            return copy
        }

        public func requestInterceptors(_ interceptors: [RequestInterceptor]) -> Builder {
            var copy = self
            copy.configuration.requestInterceptors = interceptors
            return copy
        }

        public func responseInterceptors(_ interceptors: [ResponseInterceptor]) -> Builder {
            var copy = self
            copy.configuration.responseInterceptors = interceptors
            return copy
        }

        public func addRequestInterceptor(_ interceptor: RequestInterceptor) -> Builder {
            var copy = self
            copy.configuration.requestInterceptors.append(interceptor)
            return copy
        }

        public func addResponseInterceptor(_ interceptor: ResponseInterceptor) -> Builder {
            var copy = self
            copy.configuration.responseInterceptors.append(interceptor)
            return copy
        }

        public func includeAuthInterceptor(_ include: Bool) -> Builder {
            var copy = self
            copy.configuration.includeAuthInterceptor = include
            return copy
        }

        public func syncSharedContainers(_ sync: Bool) -> Builder {
            var copy = self
            copy.configuration.syncSharedContainers = sync
            return copy
        }

        public func useKeychainTokenStorage(
            service: String? = nil,
            account: String = "auth_token"
        ) -> Builder {
            let resolvedService = service ?? Bundle.main.bundleIdentifier ?? "com.app.auth"
            let storage = KeychainTokenStorage(service: resolvedService, account: account)
            return tokenStorage(storage)
        }

        public func useUserDefaultsTokenStorage(
            key: String = "auth_token",
            defaults: UserDefaults = .standard
        ) -> Builder {
            let storage = UserDefaultsTokenStorage(key: key, defaults: defaults)
            return tokenStorage(storage)
        }

        public func useUserDefaultsUserProfileStorage(
            key: String = "user_profile",
            defaults: UserDefaults = .standard
        ) -> Builder {
            let storage = UserDefaultsUserProfileStorage(key: key, defaults: defaults)
            return userProfileStorage(storage)
        }

        public func build() -> KarrotNetworkingFacade {
            let config = configuration

            if config.syncSharedContainers {
                TokenStorageContainer.shared = config.tokenStorage
                UserProfileStorageContainer.shared = config.userProfileStorage
            }

            var requestInterceptors = config.requestInterceptors
            var responseInterceptors = config.responseInterceptors

            if config.includeAuthInterceptor {
                requestInterceptors.insert(AuthInterceptor(storage: config.tokenStorage), at: 0)
            }

            if config.loggingLevel != .none {
                let loggingInterceptor = LoggingInterceptor(level: config.loggingLevel)
                requestInterceptors.append(loggingInterceptor)
                responseInterceptors.append(loggingInterceptor)
            }

            let client = URLSessionNetworkClient(
                session: config.session,
                configuration: config.networkConfiguration,
                decoder: config.decoder,
                requestInterceptors: requestInterceptors,
                responseInterceptors: responseInterceptors
            )

            let auth = AuthService(
                client: client,
                storage: config.tokenStorage,
                profileStorage: config.userProfileStorage,
                baseUrl: config.baseURL
            )

            return KarrotNetworkingFacade(
                configuration: config,
                client: client,
                auth: auth
            )
        }
    }

    public static func builder() -> Builder {
        Builder()
    }

    public let configuration: Configuration
    public let client: NetworkClient
    public let auth: AuthService
    
    // MARK: - Initialization
    
    /// Creates a new KarrotNetworkingFacade instance.
    /// - Parameters:
    ///   - configuration: The facade configuration.
    ///   - client: The network client to use.
    ///   - auth: The authentication service.
    public init(
        configuration: Configuration,
        client: NetworkClient,
        auth: AuthService
    ) {
        self.configuration = configuration
        self.client = client
        self.auth = auth
    }

    public func request<T: HTTPResponseDecodable>(_ endpoint: Endpoint) async throws -> T {
        try await client.request(endpoint, baseUrl: configuration.baseURL)
    }

    public func requestPaginated<T: Decodable>(
        _ endpoint: Endpoint,
        pagination: PaginationParams
    ) async throws -> PaginatedResponse<T> {
        try await client.requestPaginated(
            endpoint,
            baseUrl: configuration.baseURL,
            pagination: pagination
        )
    }

    public func upload<T: HTTPResponseDecodable>(
        _ endpoint: Endpoint,
        formData: MultipartFormData
    ) async throws -> T {
        try await client.upload(
            endpoint,
            baseUrl: configuration.baseURL,
            formData: formData
        )
    }
}

