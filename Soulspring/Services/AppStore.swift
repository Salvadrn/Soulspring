import Foundation
import SwiftUI

/// Central store for user data, habits, reminders and orders. Persisted to
/// UserDefaults as a lightweight MVP.
@MainActor
final class AppStore: ObservableObject {

    // MARK: Auth state

    enum AuthState: Equatable {
        case signedOut
        case guest              // "Ver sin cuenta" — demo data
        case signedIn(email: String)

        var isAuthorized: Bool {
            switch self {
            case .signedOut:           return false
            case .guest, .signedIn:    return true
            }
        }

        var isGuest: Bool {
            if case .guest = self { return true }
            return false
        }
    }

    @Published var auth: AuthState = .signedOut

    // MARK: Published state

    @Published var profile: UserProfile {
        didSet { persist(profile, key: Keys.profile) }
    }
    @Published var habits: [Habit] {
        didSet { persist(habits, key: Keys.habits) }
    }
    @Published var reminders: [SoulReminder]
    @Published var orders: [RoomServiceOrder] = []
    @Published var sharedStreaks: [SharedStreak] = SharedStreakEngine.samples

    /// Today's curated menu from the Soul Kitchen chef.
    @Published var dailyMenu: DailyMenu {
        didSet { persist(dailyMenu, key: Keys.menu) }
    }

    /// Whether this account can edit the Menú del día (chef role).
    @Published var isChef: Bool {
        didSet { UserDefaults.standard.set(isChef, forKey: Keys.chef) }
    }

    /// How many habits the user must complete each day to defend the racha.
    @Published var dailyGoalTarget: Int {
        didSet { UserDefaults.standard.set(dailyGoalTarget, forKey: Keys.goal) }
    }

    // MARK: Init

    init() {
        self.profile   = AppStore.load(UserProfile.self, key: Keys.profile) ?? UserProfile()
        self.habits    = AppStore.load([Habit].self, key: Keys.habits) ?? Habit.samples
        self.reminders = SoulReminder.defaults
        let saved = UserDefaults.standard.integer(forKey: Keys.goal)
        self.dailyGoalTarget = saved == 0 ? 3 : saved
        self.dailyMenu = AppStore.load(DailyMenu.self, key: Keys.menu) ?? DailyMenu.sample
        self.isChef = UserDefaults.standard.bool(forKey: Keys.chef)
    }

    // MARK: Auth actions

    func signIn(email: String) {
        auth = .signedIn(email: email)
    }

    func continueAsGuest() {
        // Seed a demo profile so every section looks alive.
        var demo = UserProfile()
        demo.name = "Invitado"
        demo.age = .mid
        demo.activity = .moderate
        demo.interests = [.cardiovascular, .sleep, .mindfulness, .nutrition]
        demo.goal = "Explorar el Santuario y mantener mis rachas."
        demo.membershipTier = .essential
        demo.hasCompletedOnboarding = true
        self.profile = demo

        self.habits = Habit.samples
        self.reminders = SoulReminder.defaults
        self.dailyGoalTarget = 3
        self.auth = .guest
    }

    func signOut() {
        auth = .signedOut
    }

    // MARK: Habits

    func toggleHabit(_ habit: Habit) {
        guard let idx = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let today = Calendar.current.startOfDay(for: Date())
        if let hit = habits[idx].completedDates.firstIndex(where: {
            Calendar.current.isDate($0, inSameDayAs: today)
        }) {
            habits[idx].completedDates.remove(at: hit)
        } else {
            habits[idx].completedDates.append(Date())
        }
    }

    func addHabit(title: String, cue: String, icon: String, colorHex: UInt32) {
        habits.append(Habit(title: title, cue: cue, icon: icon, colorHex: colorHex))
    }

    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
    }

    // MARK: Reminders

    func toggleReminder(_ reminder: SoulReminder) {
        guard let idx = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[idx].isOn.toggle()
    }

    // MARK: Room service

    func placeOrder(meal: Meal, at date: Date, notes: String) {
        orders.append(RoomServiceOrder(meal: meal, scheduledFor: date, notes: notes))
    }

    // MARK: Derived

    var streak: StreakEngine {
        StreakEngine(habits: habits, dailyGoalTarget: dailyGoalTarget)
    }

    var recommendations: [Recommendation] {
        RecommendationEngine.feed(for: profile.interests)
    }

    // MARK: Persistence

    private enum Keys {
        static let profile = "soul.profile"
        static let habits  = "soul.habits"
        static let goal    = "soul.goal"
        static let menu    = "soul.menu"
        static let chef    = "soul.chef"
    }

    private func persist<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
