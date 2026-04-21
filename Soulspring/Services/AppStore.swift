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

    /// In-app bookings (stays + add-on experiences) and gift cards.
    @Published var stays: [StayBooking] = []
    @Published var bookings: [Booking] = []
    @Published var giftCards: [GiftCard] = []

    /// Hydration + wallet + workouts log.
    @Published var hydration: HydrationLog
    @Published var wallet: MembershipWallet
    @Published var completedWorkouts: [UUID: Date] = [:]

    /// Lifestyle inputs fed into the BioAge engine.
    @Published var bioAgeInputs: BioAgeInputs {
        didSet { persist(bioAgeInputs, key: Keys.bioInputs) }
    }

    /// Uploaded lab reports with parsed biomarkers + AI summary.
    @Published var labReports: [LabReport] {
        didSet { persist(labReports, key: Keys.labs) }
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

        let loadedHydration = AppStore.load(HydrationLog.self, key: Keys.hydration)
        self.hydration = AppStore.refreshDayIfNeeded(loadedHydration) ?? HydrationLog.today()
        self.wallet = AppStore.load(MembershipWallet.self, key: Keys.wallet)
            ?? MembershipWallet.make(for: UserProfile())
        self.bioAgeInputs = AppStore.load(BioAgeInputs.self, key: Keys.bioInputs) ?? BioAgeInputs()
        self.labReports = AppStore.load([LabReport].self, key: Keys.labs) ?? []
    }

    // Reset water log if the stored day is older than today.
    private static func refreshDayIfNeeded(_ log: HydrationLog?) -> HydrationLog? {
        guard let log else { return nil }
        let today = Calendar.current.startOfDay(for: Date())
        if Calendar.current.isDate(log.dayStart, inSameDayAs: today) {
            return log
        }
        return HydrationLog.today(goal: log.goal)
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
        static let profile   = "soul.profile"
        static let habits    = "soul.habits"
        static let goal      = "soul.goal"
        static let menu      = "soul.menu"
        static let chef      = "soul.chef"
        static let hydration = "soul.hydration"
        static let wallet    = "soul.wallet"
        static let bioInputs = "soul.bioInputs"
        static let labs      = "soul.labs"
    }

    // MARK: Lab actions

    func importLab(pdfURL: URL, title: String, lab: String, reportedAt: Date) async -> LabReport? {
        guard var report = LabParser.ingestPDF(at: pdfURL,
                                                title: title,
                                                lab: lab,
                                                reportedAt: reportedAt) else {
            return nil
        }
        labReports.insert(report, at: 0)
        let summary = await LabAIService.summarize(report: report)
        report.aiSummary = summary
        if let idx = labReports.firstIndex(where: { $0.id == report.id }) {
            labReports[idx] = report
        }
        return report
    }

    func deleteLab(_ report: LabReport) {
        labReports.removeAll { $0.id == report.id }
        if let name = report.localFileName, let url = LabParser.localURL(for: name) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - New domain actions

    func addWater() {
        hydration.glasses = min(hydration.goal, hydration.glasses + 1)
        persist(hydration, key: Keys.hydration)
    }

    func removeWater() {
        hydration.glasses = max(0, hydration.glasses - 1)
        persist(hydration, key: Keys.hydration)
    }

    func book(experience: Experience, at date: Date, notes: String) -> Booking {
        let b = Booking(
            experience: experience,
            slotDate: date,
            status: .confirmed,
            notes: notes,
            confirmationCode: Booking.newCode()
        )
        bookings.append(b)
        return b
    }

    func bookStay(checkIn: Date, checkOut: Date, tier: MembershipTier, guests: Int) -> StayBooking {
        let s = StayBooking(
            checkIn: checkIn,
            checkOut: checkOut,
            tier: tier,
            guests: guests,
            addOns: [],
            confirmationCode: Booking.newCode(),
            status: .confirmed
        )
        stays.append(s)
        profile.membershipTier = tier
        persist(profile, key: Keys.profile)
        return s
    }

    func cancelBooking(_ booking: Booking) {
        if let idx = bookings.firstIndex(where: { $0.id == booking.id }) {
            bookings[idx].status = .cancelled
        }
    }

    func cancelStay(_ stay: StayBooking) {
        if let idx = stays.firstIndex(where: { $0.id == stay.id }) {
            stays[idx].status = .cancelled
        }
    }

    func sendGiftCard(to name: String,
                      email: String,
                      amount: Int,
                      message: String,
                      design: GiftCard.Design) -> GiftCard {
        let card = GiftCard(
            recipientName: name,
            recipientEmail: email,
            senderName: profile.name.isEmpty ? "Soulspring" : profile.name,
            message: message,
            amountMXN: amount,
            redeemCode: GiftCard.generateCode(),
            issuedAt: Date(),
            design: design,
            status: .sent
        )
        giftCards.append(card)
        return card
    }

    func attachPayment(_ method: PaymentMethod) {
        wallet.paymentMethod = method
        persist(wallet, key: Keys.wallet)
    }

    func markWorkoutDone(_ id: UUID) {
        completedWorkouts[id] = Date()
    }

    /// Active stay today (for the wallet QR headline).
    var activeStay: StayBooking? {
        let now = Date()
        return stays.first {
            $0.status == .confirmed && $0.checkIn <= now && $0.checkOut >= now
        } ?? stays.filter { $0.status == .confirmed && $0.checkIn > now }
                  .sorted(by: { $0.checkIn < $1.checkIn }).first
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
