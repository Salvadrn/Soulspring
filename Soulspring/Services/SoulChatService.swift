import Foundation

/// Calls the `chat-with-soul` Supabase Edge Function. The function holds
/// the Anthropic API key as a secret, so the iOS app never sees it.
struct SoulChatService {
    static let shared = SoulChatService()

    struct Message: Codable, Identifiable, Hashable {
        let id: UUID
        let role: Role
        let content: String
        let timestamp: Date

        enum Role: String, Codable { case user, assistant }

        init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date()) {
            self.id = id
            self.role = role
            self.content = content
            self.timestamp = timestamp
        }
    }

    struct Context: Encodable {
        var name: String?
        var age_bracket: String?
        var activity_level: String?
        var interests: [String]?
        var goal: String?
        var current_streak_days: Int?
        var bio_age_years: Double?
        var chronological_age_years: Double?
        var recent_lab_summary: String?
        var recent_mood: [MoodEntry]?
        var membership_tier: String?

        struct MoodEntry: Encodable {
            let score: Int
            let emoji: String
            let note: String
        }
    }

    /// Send a turn. Returns the assistant's reply.
    func send(messages: [Message], context: Context) async throws -> String {
        guard SupabaseConfig.isConfigured,
              let base = URL(string: SupabaseConfig.url) else {
            throw SoulChatError.notConfigured
        }
        let endpoint = base.appendingPathComponent("functions/v1/chat-with-soul")

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")

        struct WireMsg: Encodable { let role: String; let content: String }
        let wire = messages.map { WireMsg(role: $0.role.rawValue, content: $0.content) }

        struct Body: Encodable { let messages: [WireMsg]; let context: Context }
        req.httpBody = try JSONEncoder().encode(Body(messages: wire, context: context))

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            let detail = String(data: data, encoding: .utf8) ?? ""
            throw SoulChatError.upstream(detail)
        }

        struct Reply: Decodable { let reply: String }
        let decoded = try JSONDecoder().decode(Reply.self, from: data)
        return decoded.reply
    }
}

enum SoulChatError: LocalizedError {
    case notConfigured
    case upstream(String)
    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Supabase no está configurado."
        case .upstream(let s):
            if s.contains("ANTHROPIC_API_KEY") {
                return "Falta la API key de Anthropic. Pídele al admin que la agregue como Supabase secret."
            }
            return s.isEmpty ? "Soul no pudo responder ahora." : s
        }
    }
}
