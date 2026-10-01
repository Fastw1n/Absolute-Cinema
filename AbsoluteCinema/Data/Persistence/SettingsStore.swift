import Foundation
import Observation

@MainActor
@Observable
final class SettingsStore {
    static let sortKey = "ratings.sortOrder"
    private let defaults: UserDefaults
    private(set) var sortOrder: RatingSortOrder

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        sortOrder = defaults.string(forKey: Self.sortKey).flatMap(RatingSortOrder.init) ?? .newestFirst
    }

    func setSortOrder(_ order: RatingSortOrder) {
        defaults.set(order.rawValue, forKey: Self.sortKey)
        sortOrder = order
    }

    func resetSortOrder() {
        defaults.removeObject(forKey: Self.sortKey)
        sortOrder = .newestFirst
    }
}
