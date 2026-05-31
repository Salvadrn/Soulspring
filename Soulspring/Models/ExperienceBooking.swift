import Foundation

/// Experience offered at the Sanctuary (temazcal, baño de contraste, masaje,
/// consulta médica, etc.). Each one has a fixed duration and a price.
struct Experience: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var summary: String
    var kind: Kind
    var durationMinutes: Int
    var priceMXN: Int
    var practitioner: String
    var emoji: String
    var includedInTier: MembershipTier?  // free for this tier and above

    enum Kind: String, Codable, CaseIterable, Identifiable {
        case ritual      = "Ritual"
        case bodywork    = "Bodywork"
        case breathwork  = "Breathwork"
        case medical     = "Clínico"
        case nutrition   = "Nutrición"
        case movement    = "Movimiento"
        var id: String { rawValue }
    }

    static let catalog: [Experience] = [
        .init(name: "Temazcal ceremonial",
              summary: "Ritual ancestral de purificación en cúpula de barro, guiado.",
              kind: .ritual,
              durationMinutes: 90,
              priceMXN: 1_800,
              practitioner: "Mtro. Xólotl",
              emoji: "🔥",
              includedInTier: .sanctuary),
        .init(name: "Baño de contraste",
              summary: "3 ciclos calor / frío con sauna infrarroja y tina helada.",
              kind: .ritual,
              durationMinutes: 45,
              priceMXN: 900,
              practitioner: "Equipo Sanctuary",
              emoji: "🧊",
              includedInTier: .essential),
        .init(name: "Masaje de tejidos profundos",
              summary: "Terapia miofascial con aceites esenciales orgánicos.",
              kind: .bodywork,
              durationMinutes: 60,
              priceMXN: 1_500,
              practitioner: "Alejandra Luna",
              emoji: "💆‍♀️",
              includedInTier: .sanctuary),
        .init(name: "Breathwork holotrópico",
              summary: "Sesión guiada de respiración consciente con música en vivo.",
              kind: .breathwork,
              durationMinutes: 75,
              priceMXN: 1_200,
              practitioner: "Dr. Tomás Riera",
              emoji: "💨",
              includedInTier: .essential),
        .init(name: "Consulta médica funcional",
              summary: "Evaluación integral con biomarcadores y plan bio-individualizado.",
              kind: .medical,
              durationMinutes: 50,
              priceMXN: 2_800,
              practitioner: "Dra. Camila Vega",
              emoji: "🧬",
              includedInTier: .longevity),
        .init(name: "Consulta nutricional",
              summary: "Plan de alimentación según tu fenotipo y objetivos.",
              kind: .nutrition,
              durationMinutes: 45,
              priceMXN: 1_400,
              practitioner: "Nutr. Mariana Soto",
              emoji: "🥑",
              includedInTier: .sanctuary),
        .init(name: "Yoga restaurativo",
              summary: "Práctica pasiva con props para regular tu sistema nervioso.",
              kind: .movement,
              durationMinutes: 60,
              priceMXN: 600,
              practitioner: "Sofía Reyes",
              emoji: "🧘‍♀️",
              includedInTier: .essential),
        .init(name: "Acupuntura",
              summary: "Medicina tradicional china para flujo energético y dolor.",
              kind: .bodywork,
              durationMinutes: 60,
              priceMXN: 1_600,
              practitioner: "Dr. Liu Chen",
              emoji: "📍",
              includedInTier: .longevity),
    ]
}

/// A bookable 60-minute slot at a given date for a given practitioner.
/// Emulates what the Sanctuary's calendar API would return; in production
/// this comes from Supabase or an ops booking system.
struct TimeSlot: Identifiable, Hashable, Codable {
    var id = UUID()
    var experienceID: UUID
    var date: Date
    var isAvailable: Bool
}

/// A confirmed or pending add-on experience booking.
struct Booking: Identifiable, Hashable, Codable {
    var id = UUID()
    var experience: Experience
    var slotDate: Date
    var status: Status
    var notes: String = ""
    var confirmationCode: String

    enum Status: String, Codable {
        case confirmed = "Confirmada"
        case pending   = "Pendiente"
        case completed = "Realizada"
        case cancelled = "Cancelada"
    }

    static func newCode() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return "SS-" + String((0..<6).compactMap { _ in chars.randomElement() })
    }
}

/// A multi-night stay at the Sanctuary. Hotel-style: pick check-in and
/// check-out, pick your plan, pay per night.
struct StayBooking: Identifiable, Hashable, Codable {
    var id = UUID()
    var checkIn: Date
    var checkOut: Date
    var tier: MembershipTier
    var guests: Int
    var addOns: [UUID]                  // linked Booking IDs (experiencias)
    var confirmationCode: String
    var status: Booking.Status

    var nights: Int {
        max(1, Calendar.current.dateComponents([.day],
            from: Calendar.current.startOfDay(for: checkIn),
            to: Calendar.current.startOfDay(for: checkOut)).day ?? 1)
    }

    var totalMXN: Int { tier.nightlyCostMXN * nights * max(1, guests) }
}

// MARK: - Gift card

/// A SoulSpring gift card the user sent to someone. Has a balance in MXN
/// and a redeem code the recipient types in. Mock payments for now; later
/// hook to Stripe / Apple Pay.
struct GiftCard: Identifiable, Hashable, Codable {
    var id = UUID()
    var recipientName: String
    var recipientEmail: String
    var senderName: String
    var message: String
    var amountMXN: Int
    var redeemCode: String
    var issuedAt: Date
    var design: Design
    var status: Status

    enum Design: String, Codable, CaseIterable, Identifiable {
        case dawn    = "Amanecer"
        case forest  = "Bosque"
        case sunset  = "Atardecer"
        case breath  = "Respiro"
        var id: String { rawValue }
    }

    enum Status: String, Codable {
        case sent      = "Enviada"
        case redeemed  = "Canjeada"
        case scheduled = "Programada"
    }

    static func generateCode() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        let part = { String((0..<4).map { _ in chars.randomElement()! }) }
        return "\(part())-\(part())-\(part())"
    }

    static let amountOptions: [Int] = [500, 1_000, 2_500, 5_000, 10_000, 20_000]
}

// MARK: - Availability engine

/// Generates the next 14 days of slots for an experience. Morning (09, 11)
/// and afternoon (15, 17) openings, with deterministic "already booked"
/// holes so the UI feels real. Replace with a Supabase fetch when the
/// booking table exists.
enum AvailabilityEngine {
    static func nextDays(_ count: Int = 14) -> [Date] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        return (0..<count).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    static func slots(for experience: Experience, on day: Date) -> [TimeSlot] {
        let cal = Calendar.current
        let hours = [9, 11, 13, 15, 17, 19]
        return hours.compactMap { hour in
            guard let date = cal.date(bySettingHour: hour, minute: 0, second: 0, of: day) else {
                return nil
            }
            // Deterministic "availability" so the same day looks the same.
            let daySeed = cal.ordinality(of: .day, in: .year, for: day) ?? 0
            let expSeed = abs(experience.name.hashValue) % 17
            let available = ((hour + daySeed + expSeed) % 7) != 0 && date > Date()
            return TimeSlot(experienceID: experience.id, date: date, isAvailable: available)
        }
    }
}
