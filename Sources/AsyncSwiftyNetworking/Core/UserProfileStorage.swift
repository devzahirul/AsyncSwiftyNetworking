import Foundation

/// A model representing a user profile.
public struct UserProfile: Codable, Sendable {
    public let id: Int?
    public let name: String?
    public let phone: String?
    public let dob: String?
    public let neighbourhoodId: Int?

    public init(
        id: Int?,
        name: String?,
        phone: String?,
        dob: String?,
        neighbourhoodId: Int?
    ) {
        self.id = id
        self.name = name
        self.phone = phone
        self.dob = dob
        self.neighbourhoodId = neighbourhoodId
    }
}

/// Protocol for user profile storage.
/// Must be `Sendable` for safe concurrent access.
public protocol UserProfileStorage: AnyObject, Sendable {
    var currentProfile: UserProfile? { get }
    func save(_ profile: UserProfile)
    func clear()
}

/// UserDefaults-based implementation of UserProfileStorage.
/// Thread-safe implementation for storing user profile data.
public final class UserDefaultsUserProfileStorage: UserProfileStorage, @unchecked Sendable {
    private let key: String
    private let defaults: UserDefaults
    private let queue = DispatchQueue(label: "com.asyncswiftynetworking.userprofile", qos: .userInitiated)

    public init(key: String = "user_profile", defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
    }

    public var currentProfile: UserProfile? {
        queue.sync {
            guard let data = defaults.data(forKey: key) else {
                return nil
            }
            return try? JSONDecoder().decode(UserProfile.self, from: data)
        }
    }

    public func save(_ profile: UserProfile) {
        queue.sync {
            guard let data = try? JSONEncoder().encode(profile) else {
                return
            }
            defaults.set(data, forKey: key)
        }
    }

    public func clear() {
        queue.sync {
            defaults.removeObject(forKey: key)
        }
    }
}

/// Container for shared UserProfileStorage instance.
public final class UserProfileStorageContainer: @unchecked Sendable {
    private static let lock = NSLock()
    private static var _shared: UserProfileStorage = UserDefaultsUserProfileStorage()
    
    public static var shared: UserProfileStorage {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _shared
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _shared = newValue
        }
    }
}
