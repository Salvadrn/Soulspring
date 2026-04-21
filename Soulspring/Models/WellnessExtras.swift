import Foundation

// MARK: - Hydration

struct HydrationLog: Codable {
    var dayStart: Date
    var glasses: Int
    var goal: Int

    static let defaultGoal = 8

    static func today(goal: Int = HydrationLog.defaultGoal) -> HydrationLog {
        HydrationLog(dayStart: Calendar.current.startOfDay(for: Date()),
                     glasses: 0,
                     goal: goal)
    }

    var percent: Double {
        guard goal > 0 else { return 0 }
        return min(1, Double(glasses) / Double(goal))
    }
}

// MARK: - Workouts

struct Workout: Identifiable, Hashable, Codable {
    var id = UUID()
    var title: String
    var summary: String
    var durationMinutes: Int
    var intensity: Intensity
    var zone: Zone
    var exercises: [Exercise]
    var emoji: String

    enum Intensity: String, Codable { case easy = "Suave", moderate = "Moderado", hard = "Fuerte" }
    enum Zone: String, Codable, CaseIterable {
        case mobility = "Movilidad"
        case zone2    = "Zona 2"
        case strength = "Fuerza"
        case hiit     = "HIIT"
        case yoga     = "Yoga"
    }

    struct Exercise: Identifiable, Hashable, Codable {
        var id = UUID()
        var name: String
        var detail: String     // sets/reps or duration
    }

    static let catalog: [Workout] = [
        .init(title: "Fuerza fundamental",
              summary: "Siete movimientos esenciales para construir base. Sin equipo más que pesas.",
              durationMinutes: 30,
              intensity: .moderate,
              zone: .strength,
              exercises: [
                .init(name: "Sentadilla goblet",    detail: "4 × 8"),
                .init(name: "Peso muerto rumano",   detail: "4 × 8"),
                .init(name: "Press inclinado",      detail: "3 × 10"),
                .init(name: "Remo con mancuerna",   detail: "3 × 10"),
                .init(name: "Puente de glúteos",    detail: "3 × 12"),
                .init(name: "Plancha",              detail: "3 × 45 s"),
                .init(name: "Farmer carry",         detail: "3 × 30 s"),
              ],
              emoji: "🏋🏽‍♀️"),
        .init(title: "Caminata Zona 2",
              summary: "35 minutos a ritmo conversacional. Base aeróbica y mitocondrias felices.",
              durationMinutes: 35,
              intensity: .easy,
              zone: .zone2,
              exercises: [
                .init(name: "Calentamiento",        detail: "5 min caminata suave"),
                .init(name: "Zona 2 sostenida",     detail: "25 min HR 60–70% max"),
                .init(name: "Enfriamiento",         detail: "5 min + estiramiento"),
              ],
              emoji: "🚶🏽"),
        .init(title: "Movilidad matutina",
              summary: "Despierta tu columna, caderas y hombros en 12 minutos.",
              durationMinutes: 12,
              intensity: .easy,
              zone: .mobility,
              exercises: [
                .init(name: "Gato-vaca",            detail: "10 rondas"),
                .init(name: "World's greatest stretch", detail: "5 × lado"),
                .init(name: "Rotaciones torácicas", detail: "8 × lado"),
                .init(name: "Aperturas de cadera",  detail: "10 × lado"),
              ],
              emoji: "🌅"),
        .init(title: "HIIT breve",
              summary: "20 minutos de alta intensidad. Cuando quieras quemar y terminar rápido.",
              durationMinutes: 20,
              intensity: .hard,
              zone: .hiit,
              exercises: [
                .init(name: "Calentamiento",        detail: "4 min"),
                .init(name: "Tabata burpees",       detail: "4 × 20/10"),
                .init(name: "Tabata mountain climbers", detail: "4 × 20/10"),
                .init(name: "Tabata sentadilla con salto", detail: "4 × 20/10"),
                .init(name: "Enfriamiento",         detail: "4 min"),
              ],
              emoji: "🔥"),
        .init(title: "Yin yoga nocturno",
              summary: "Posturas sostenidas para bajar cortisol antes de dormir.",
              durationMinutes: 25,
              intensity: .easy,
              zone: .yoga,
              exercises: [
                .init(name: "Mariposa",             detail: "3 min"),
                .init(name: "Paloma",               detail: "3 min × lado"),
                .init(name: "Apertura de pecho",    detail: "4 min"),
                .init(name: "Torsiones supinas",    detail: "3 min × lado"),
                .init(name: "Savasana",             detail: "5 min"),
              ],
              emoji: "🌙"),
    ]
}

// MARK: - Wallet + payment

struct PaymentMethod: Identifiable, Hashable, Codable {
    var id = UUID()
    var brand: Brand
    var last4: String
    var holder: String
    var expMonth: Int
    var expYear: Int

    enum Brand: String, Codable, CaseIterable {
        case visa       = "Visa"
        case mastercard = "Mastercard"
        case amex       = "Amex"
    }
}

/// A digital wallet card that the Sanctuary scans at check-in.
struct MembershipWallet: Codable {
    var memberID: String            // used to generate the QR
    var issuedAt: Date
    var paymentMethod: PaymentMethod?

    static func make(for profile: UserProfile) -> MembershipWallet {
        let suffix = String((0..<6).map { _ in "0123456789".randomElement()! })
        return MembershipWallet(
            memberID: "SS-\(profile.membershipTier.rawValue.prefix(3).uppercased())-\(suffix)",
            issuedAt: Date(),
            paymentMethod: nil
        )
    }
}
