import Foundation
import SwiftUI

/// A milestone the user can earn. Pure local logic for now — counted from
/// streaks, completed habits, sanctuary stays and other deterministic state
/// already in `AppStore`. Once an achievement is reached its `unlockedAt`
/// timestamp gets stored in `UserDefaults` so the celebration animation
/// only fires once.
struct Achievement: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let blurb: String
    let icon: String          // SF Symbol
    let tintHex: UInt32       // celebration tint
    let category: Category
    let target: Int           // numeric goal (days, count, etc.)

    enum Category: String, Codable {
        case streak       // global racha streak
        case habits       // total habit checks
        case sanctuary    // nights at sanctuary
        case mindfulness  // meditations / breath sessions
        case bookings     // experiences booked

        var label: String {
            switch self {
            case .streak:      return "Racha"
            case .habits:      return "Hábitos"
            case .sanctuary:   return "Sanctuary"
            case .mindfulness: return "Mente"
            case .bookings:    return "Experiencias"
            }
        }
    }

    var tint: Color { Color(hex: tintHex) }
}

extension Achievement {
    /// Master catalog — ordered for display. Add new ones at the bottom.
    static let catalog: [Achievement] = [
        // Streak milestones
        .init(id: "streak.7",   title: "Una semana entera",
              blurb: "7 días seguidos defendiendo tu racha.",
              icon: "flame.fill", tintHex: 0xC68863, category: .streak, target: 7),
        .init(id: "streak.30",  title: "Un mes en flujo",
              blurb: "30 días sin romper tu compromiso.",
              icon: "flame.fill", tintHex: 0xC9A66B, category: .streak, target: 30),
        .init(id: "streak.100", title: "Cien días de constancia",
              blurb: "Una práctica que ya es identidad.",
              icon: "flame.fill", tintHex: 0xB85C5C, category: .streak, target: 100),

        // Habit completion totals
        .init(id: "habits.10",  title: "Primeros 10 hábitos",
              blurb: "Diez check-ins. Empieza a sentirse.",
              icon: "checkmark.seal.fill", tintHex: 0x8FA189, category: .habits, target: 10),
        .init(id: "habits.50",  title: "50 hábitos cultivados",
              blurb: "Tu cuerpo ya nota la diferencia.",
              icon: "checkmark.seal.fill", tintHex: 0x4F6B57, category: .habits, target: 50),
        .init(id: "habits.200", title: "200 victorias diarias",
              blurb: "Una vida que se elige todos los días.",
              icon: "checkmark.seal.fill", tintHex: 0x3F5248, category: .habits, target: 200),

        // Sanctuary stays
        .init(id: "sanctuary.first", title: "Tu primera noche",
              blurb: "Llegaste al Sanctuary. Respira.",
              icon: "house.fill", tintHex: 0xC9A66B, category: .sanctuary, target: 1),
        .init(id: "sanctuary.5",     title: "Cinco estancias",
              blurb: "Soulspring ya es parte de tu ritmo.",
              icon: "house.fill", tintHex: 0xC68863, category: .sanctuary, target: 5),

        // Mindfulness (breath / meditation sessions tracked locally)
        .init(id: "mind.10",  title: "10 prácticas de respiración",
              blurb: "Has aprendido a regresar a tu centro.",
              icon: "wind", tintHex: 0x9FB4B8, category: .mindfulness, target: 10),
        .init(id: "mind.50",  title: "50 minutos de calma",
              blurb: "Un sistema nervioso entrenado para volver a casa.",
              icon: "sparkles", tintHex: 0xB8A3D4, category: .mindfulness, target: 50),

        // Bookings
        .init(id: "book.first", title: "Primera experiencia reservada",
              blurb: "Diste el paso.",
              icon: "calendar.badge.plus", tintHex: 0x8FA189, category: .bookings, target: 1),
        .init(id: "book.5",     title: "Cinco experiencias",
              blurb: "Cada una abrió algo nuevo.",
              icon: "calendar.badge.plus", tintHex: 0x4F6B57, category: .bookings, target: 5),
    ]

    static func byID(_ id: String) -> Achievement? {
        catalog.first(where: { $0.id == id })
    }
}

// MARK: - Engine

/// Computes which achievements are currently unlocked from app state.
/// Pure function — no side effects. The store decides when to persist
/// `unlockedAt` and when to fire celebration animations.
enum AchievementEngine {
    struct Progress: Identifiable, Hashable {
        let achievement: Achievement
        let current: Int
        var ratio: Double {
            guard achievement.target > 0 else { return 0 }
            return min(1.0, Double(current) / Double(achievement.target))
        }
        var isUnlocked: Bool { current >= achievement.target }
        var id: String { achievement.id }
    }

    static func progress(
        currentStreakDays: Int,
        totalHabitChecks: Int,
        sanctuaryNights: Int,
        mindfulnessSessions: Int,
        completedBookings: Int
    ) -> [Progress] {
        Achievement.catalog.map { ach in
            let current: Int
            switch ach.category {
            case .streak:      current = currentStreakDays
            case .habits:      current = totalHabitChecks
            case .sanctuary:   current = sanctuaryNights
            case .mindfulness: current = mindfulnessSessions
            case .bookings:    current = completedBookings
            }
            return Progress(achievement: ach, current: current)
        }
    }
}
