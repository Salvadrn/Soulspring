import Foundation
import CoreLocation

// MARK: - Healthy meal (room service / comida saludable)

struct Meal: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let subtitle: String
    let kcal: Int
    let macros: Macros
    let tags: [String]
    let emoji: String

    struct Macros: Hashable {
        let protein: Int
        let carbs: Int
        let fats: Int
    }

    static let catalog: [Meal] = [
        .init(name: "Bowl de amanecer",
              subtitle: "Chía, frutos del bosque y almendras activadas",
              kcal: 420,
              macros: .init(protein: 14, carbs: 52, fats: 18),
              tags: ["Vegano", "Sin gluten"],
              emoji: "🥣"),
        .init(name: "Salmón en cama de hierbas",
              subtitle: "Salmón salvaje, quelites y quinoa roja",
              kcal: 540,
              macros: .init(protein: 38, carbs: 40, fats: 24),
              tags: ["Omega-3", "Alta proteína"],
              emoji: "🐟"),
        .init(name: "Caldo regenerador",
              subtitle: "Hueso de pastoreo, cúrcuma, jengibre y apio",
              kcal: 180,
              macros: .init(protein: 22, carbs: 6, fats: 8),
              tags: ["Anti-inflamatorio"],
              emoji: "🍲"),
        .init(name: "Ensalada del valle",
              subtitle: "Hojas verdes, aguacate, semillas, aceite de oliva",
              kcal: 380,
              macros: .init(protein: 9, carbs: 22, fats: 28),
              tags: ["Keto-friendly"],
              emoji: "🥗"),
        .init(name: "Cena ligera",
              subtitle: "Pescado blanco al vapor, calabacitas y limón",
              kcal: 310,
              macros: .init(protein: 32, carbs: 14, fats: 12),
              tags: ["Digestivo"],
              emoji: "🍋"),
    ]
}

// MARK: - Map destinations (Sanctuary + partners)

struct SoulPlace: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let kind: Kind
    let address: String
    let coordinate: Coordinate
    let openNow: Bool

    enum Kind: String {
        case sanctuary = "Santuario"
        case studio    = "Estudio"
        case cafe      = "Café saludable"
        case clinic    = "Clínica"
    }

    struct Coordinate: Hashable {
        let latitude: Double
        let longitude: Double
        var cl: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
    }

    static let catalog: [SoulPlace] = [
        .init(name: "SoulSpring Sanctuary",
              kind: .sanctuary,
              address: "Cuernavaca, Morelos",
              coordinate: .init(latitude: 18.9186, longitude: -99.2342),
              openNow: true),
        .init(name: "SoulSpring Polanco",
              kind: .studio,
              address: "CDMX — Polanco",
              coordinate: .init(latitude: 19.4335, longitude: -99.2005),
              openNow: true),
        .init(name: "Café Raíz",
              kind: .cafe,
              address: "Roma Norte, CDMX",
              coordinate: .init(latitude: 19.4145, longitude: -99.1605),
              openNow: true),
        .init(name: "Clínica Longevidad Sur",
              kind: .clinic,
              address: "Tlalpan, CDMX",
              coordinate: .init(latitude: 19.2934, longitude: -99.1686),
              openNow: false),
    ]
}

// MARK: - Room service booking

struct RoomServiceOrder: Identifiable {
    let id = UUID()
    let meal: Meal
    let scheduledFor: Date
    let notes: String
}

// MARK: - Reminder

struct SoulReminder: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let kind: Kind
    let time: Date
    var isOn: Bool

    enum Kind: String {
        case hydration  = "Hidratación"
        case movement   = "Movimiento"
        case breath     = "Respiración"
        case sleep      = "Descanso"
        case meal       = "Comida"
    }

    static let defaults: [SoulReminder] = [
        .init(title: "Vaso de agua con limón",
              kind: .hydration,
              time: Self.time(hour: 7, minute: 30),
              isOn: true),
        .init(title: "Pausa de respiración 5-5",
              kind: .breath,
              time: Self.time(hour: 11, minute: 0),
              isOn: true),
        .init(title: "Camina 10 minutos",
              kind: .movement,
              time: Self.time(hour: 15, minute: 30),
              isOn: false),
        .init(title: "Cena ligera",
              kind: .meal,
              time: Self.time(hour: 19, minute: 30),
              isOn: true),
        .init(title: "Ritual de anochecer",
              kind: .sleep,
              time: Self.time(hour: 22, minute: 0),
              isOn: true),
    ]

    private static func time(hour: Int, minute: Int) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? Date()
    }
}
