import Foundation

/// Abstraction over whatever backend Soulspring is wired to (today: in-memory
/// / UserDefaults; tomorrow: Supabase). Views talk to `AppStore`, `AppStore`
/// talks to whatever implementation of this protocol is injected. This keeps
/// the UI stable while the data layer evolves.
protocol SoulBackend {
    func signIn(email: String, password: String) async throws -> AuthSession
    func signUp(email: String, password: String) async throws -> AuthSession
    func signOut() async throws

    func fetchProfile() async throws -> UserProfile?
    func saveProfile(_ profile: UserProfile) async throws

    func fetchHabits() async throws -> [Habit]
    func saveHabits(_ habits: [Habit]) async throws

    func pushHealthSnapshot(_ snapshot: HealthSnapshot) async throws
}

struct AuthSession {
    let userId: String
    let email: String
    let accessToken: String
}

struct HealthSnapshot: Codable {
    let capturedAt: Date
    let heartRate: Double?
    let restingHeartRate: Double?
    let hrv: Double?
    let steps: Int
    let activeEnergyKcal: Double
    let sleepHours: Double
}

// MARK: - Local implementation (default)

/// Stand-in backend used while the Supabase keys are not configured. It simply
/// echoes success for auth and persists nothing beyond what AppStore already
/// keeps in UserDefaults.
final class LocalBackend: SoulBackend {
    func signIn(email: String, password: String) async throws -> AuthSession {
        AuthSession(userId: UUID().uuidString, email: email, accessToken: "local")
    }
    func signUp(email: String, password: String) async throws -> AuthSession {
        AuthSession(userId: UUID().uuidString, email: email, accessToken: "local")
    }
    func signOut() async throws {}
    func fetchProfile() async throws -> UserProfile? { nil }
    func saveProfile(_ profile: UserProfile) async throws {}
    func fetchHabits() async throws -> [Habit] { [] }
    func saveHabits(_ habits: [Habit]) async throws {}
    func pushHealthSnapshot(_ snapshot: HealthSnapshot) async throws {}
}

// MARK: - Supabase implementation (stub)

/// Thin REST client against Supabase's PostgREST and GoTrue endpoints. Kept
/// dependency-free on purpose so it compiles before you add the official SDK.
/// Drop in `supabase-swift` later and replace the internals if you want the
/// Realtime and Storage helpers.
final class SupabaseBackend: SoulBackend {
    private let url: URL
    private let anonKey: String
    private var accessToken: String?

    init?(config: (url: String, anonKey: String) = (SupabaseConfig.url, SupabaseConfig.anonKey)) {
        guard let parsed = URL(string: config.url), SupabaseConfig.isConfigured else { return nil }
        self.url = parsed
        self.anonKey = config.anonKey
    }

    // MARK: Auth (GoTrue)

    func signIn(email: String, password: String) async throws -> AuthSession {
        try await auth(path: "/auth/v1/token?grant_type=password",
                       body: ["email": email, "password": password])
    }

    func signUp(email: String, password: String) async throws -> AuthSession {
        try await auth(path: "/auth/v1/signup",
                       body: ["email": email, "password": password])
    }

    func signOut() async throws {
        accessToken = nil
    }

    private func auth(path: String, body: [String: String]) async throws -> AuthSession {
        var req = URLRequest(url: url.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: req)
        let decoded = try JSONDecoder().decode(GoTrueResponse.self, from: data)
        self.accessToken = decoded.access_token
        return AuthSession(userId: decoded.user.id,
                           email: decoded.user.email ?? body["email"] ?? "",
                           accessToken: decoded.access_token)
    }

    private struct GoTrueResponse: Decodable {
        let access_token: String
        let user: User
        struct User: Decodable { let id: String; let email: String? }
    }

    // MARK: Data (stubs — implement when tables exist)

    func fetchProfile() async throws -> UserProfile? { nil }
    func saveProfile(_ profile: UserProfile) async throws {}
    func fetchHabits() async throws -> [Habit] { [] }
    func saveHabits(_ habits: [Habit]) async throws {}
    func pushHealthSnapshot(_ snapshot: HealthSnapshot) async throws {}
}

// MARK: - Resolver

enum SoulBackendResolver {
    static func make() -> SoulBackend {
        SupabaseBackend() ?? LocalBackend()
    }
}
