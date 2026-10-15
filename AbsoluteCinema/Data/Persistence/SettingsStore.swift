import Foundation
import Observation

@MainActor
@Observable
final class SettingsStore {
    static let sortKey = "dev.ratings.sortOrder"
    private let defaults: UserDefaults
    private(set) var sortOrder: RatingSortOrder

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let savedValue = defaults.string(forKey: Self.sortKey) ?? ""
        sortOrder = RatingSortOrder(rawValue: savedValue) ?? .newestFirst
    }

    func setSortOrder(_ order: RatingSortOrder) {
        defaults.set(order.rawValue, forKey: Self.sortKey)
        sortOrder = order
    }
}
