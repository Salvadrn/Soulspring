import Foundation

/// Slim snapshots that the main app writes into the shared App Group
/// UserDefaults so WidgetKit can render without touching the full AppStore.
/// Compiled into both the app and the widget extension.
enum SoulAppGroup {
    /// Must match the App Group id in both the app's and widget's
    /// entitlements files.
    static let id = "group.mx.soulspring.app"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: id) ?? .standard
    }

    enum Keys {
        static let budget   = "widget.budget"
        static let routines = "widget.routines"
    }
}

// MARK: - Budget

struct BudgetSnapshot: Codable {
    var monthLabel: String        // "Abril 2026"
    var income: Double
    var expense: Double
    var balance: Double
    var topCategories: [Category]
    var updatedAt: Date

    struct Category: Codable, Identifiable {
        var id: String { name }
        var name: String
        var iconSystemName: String
        var tintHex: UInt32
        var amount: Double
        var limit: Double?
    }

    static let placeholder = BudgetSnapshot(
        monthLabel: "Abril 2026",
        income: 32_500,
        expense: 18_420,
        balance: 14_080,
        topCategories: [
            .init(name: "Hogar",     iconSystemName: "house.fill",   tintHex: 0x6B4F3B, amount: 12_000, limit: 13_000),
            .init(name: "Alimentos", iconSystemName: "fork.knife",   tintHex: 0xC68863, amount:  3_200, limit: 4_500),
            .init(name: "Bienestar", iconSystemName: "leaf.fill",    tintHex: 0x8FA189, amount:  2_400, limit: 3_000),
        ],
        updatedAt: Date()
    )
}

// MARK: - Routines / rachas

struct RoutinesSnapshot: Codable {
    var streakDays: Int
    var completedToday: Int
    var goalTarget: Int
    var habits: [Habit]
    var updatedAt: Date

    struct Habit: Codable, Identifiable {
        var id: String { title }
        var title: String
        var iconSystemName: String
        var tintHex: UInt32
        var done: Bool
    }

    var progress: Double {
        guard goalTarget > 0 else { return 0 }
        return min(1, Double(completedToday) / Double(goalTarget))
    }

    var goalMet: Bool { completedToday >= goalTarget }

    static let placeholder = RoutinesSnapshot(
        streakDays: 14,
        completedToday: 2,
        goalTarget: 3,
        habits: [
            .init(title: "8 vasos de agua",     iconSystemName: "drop.fill",        tintHex: 0x9FB4B8, done: true),
            .init(title: "Meditación 10 min",   iconSystemName: "wind",             tintHex: 0x8FA189, done: true),
            .init(title: "Movimiento 30 min",   iconSystemName: "figure.run",       tintHex: 0xC68863, done: false),
            .init(title: "Dormir antes de 23h", iconSystemName: "moon.stars.fill",  tintHex: 0x6B4F3B, done: false),
        ],
        updatedAt: Date()
    )
}

// MARK: - Read / write helpers

enum SharedSnapshotStore {
    static func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        SoulAppGroup.defaults.set(data, forKey: key)
    }

    static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = SoulAppGroup.defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
