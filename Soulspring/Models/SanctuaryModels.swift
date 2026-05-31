import Foundation

// MARK: - Healthy meal (room service / comida saludable)

struct Meal: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let subtitle: String
    let kcal: Int
    let macros: Macros
    let tags: [String]
    let emoji: String
    let photoURL: URL?

    init(name: String, subtitle: String, kcal: Int, macros: Macros,
         tags: [String], emoji: String, photoURL: URL? = nil) {
        self.name = name
        self.subtitle = subtitle
        self.kcal = kcal
        self.macros = macros
        self.tags = tags
        self.emoji = emoji
        self.photoURL = photoURL
    }

    struct Macros: Hashable {
        let protein: Int
        let carbs: Int
        let fats: Int
    }

    /// Real-photo URLs from Unsplash (free, commercial use). Replace with your
    /// own Soul Kitchen photos uploaded to Supabase Storage when ready.
    static let catalog: [Meal] = [
        .init(name: "Bowl de amanecer",
              subtitle: "Chía, frutos del bosque y almendras activadas",
              kcal: 420,
              macros: .init(protein: 14, carbs: 52, fats: 18),
              tags: ["Vegano", "Sin gluten"],
              emoji: "🥣",
              photoURL: URL(string: "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80")),
        .init(name: "Salmón en cama de hierbas",
              subtitle: "Salmón salvaje, quelites y quinoa roja",
              kcal: 540,
              macros: .init(protein: 38, carbs: 40, fats: 24),
              tags: ["Omega-3", "Alta proteína"],
              emoji: "🐟",
              photoURL: URL(string: "https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800&q=80")),
        .init(name: "Caldo regenerador",
              subtitle: "Hueso de pastoreo, cúrcuma, jengibre y apio",
              kcal: 180,
              macros: .init(protein: 22, carbs: 6, fats: 8),
              tags: ["Anti-inflamatorio"],
              emoji: "🍲",
              photoURL: URL(string: "https://images.unsplash.com/photo-1547592180-85f173990554?w=800&q=80")),
        .init(name: "Ensalada del valle",
              subtitle: "Hojas verdes, aguacate, semillas, aceite de oliva",
              kcal: 380,
              macros: .init(protein: 9, carbs: 22, fats: 28),
              tags: ["Keto-friendly"],
              emoji: "🥗",
              photoURL: URL(string: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80")),
        .init(name: "Cena ligera",
              subtitle: "Pescado blanco al vapor, calabacitas y limón",
              kcal: 310,
              macros: .init(protein: 32, carbs: 14, fats: 12),
              tags: ["Digestivo"],
              emoji: "🍋",
              photoURL: URL(string: "https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=800&q=80")),
    ]
}

// MARK: - Spaces inside the resort

/// A space inside the Soulspring Sanctuary. Lives in the "Lugares" section
/// of the Santuario tab and lets the guest discover what the property holds.
struct SoulPlace: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let kind: Kind
    let zone: String        // e.g. "Bosque", "Planta baja", "Ala norte"
    let blurb: String       // one-line description shown in the row
    let openHours: String   // e.g. "06:00 – 22:00"
    let openNow: Bool

    enum Kind: String {
        case spa        = "Spa"
        case sauna      = "Sauna"
        case pool       = "Alberca"
        case coldPlunge = "Cold plunge"
        case gym        = "Gym"
        case yoga       = "Yoga & Meditación"
        case kitchen    = "Soul Kitchen"
        case garden     = "Jardín"
        case sound      = "Sound healing"
        case library    = "Biblioteca"
        case clinic     = "Consultorio"
        case lounge     = "Lounge"
    }

    static let catalog: [SoulPlace] = [
        .init(name: "Spa & tinas",
              kind: .spa,
              zone: "Ala oeste, planta baja",
              blurb: "Hidroterapia, masajes y rituales bio-individualizados.",
              openHours: "08:00 – 21:00",
              openNow: true),
        .init(name: "Sauna finlandesa",
              kind: .sauna,
              zone: "Spa, nivel 1",
              blurb: "75 °C de calor seco para sostener tu sistema cardiovascular.",
              openHours: "08:00 – 21:00",
              openNow: true),
        .init(name: "Alberca de minerales",
              kind: .pool,
              zone: "Patio central",
              blurb: "Agua templada con sal y magnesio. Carriles para nadar al amanecer.",
              openHours: "06:00 – 21:00",
              openNow: true),
        .init(name: "Cold plunge",
              kind: .coldPlunge,
              zone: "Junto al spa",
              blurb: "5 °C controlados para tu sesión de exposición al frío.",
              openHours: "06:00 – 22:00",
              openNow: true),
        .init(name: "Gym de fuerza",
              kind: .gym,
              zone: "Edificio anexo",
              blurb: "Pesas libres, máquinas y rack. Coach disponible bajo cita.",
              openHours: "05:30 – 22:00",
              openNow: true),
        .init(name: "Estudio de yoga",
              kind: .yoga,
              zone: "Pabellón del bosque",
              blurb: "Clases de yoga, pranayama y meditación guiada todo el día.",
              openHours: "07:00 – 20:00",
              openNow: true),
        .init(name: "Soul Kitchen",
              kind: .kitchen,
              zone: "Restaurante principal",
              blurb: "Comida del chef con menú bio-individualizado.",
              openHours: "07:00 – 21:30",
              openNow: true),
        .init(name: "Jardín comestible",
              kind: .garden,
              zone: "Bosque sur",
              blurb: "Huerta orgánica donde se cosecha lo que cenas.",
              openHours: "Abierto siempre",
              openNow: true),
        .init(name: "Sala de sound healing",
              kind: .sound,
              zone: "Pabellón del bosque",
              blurb: "Cuencos de cuarzo y gongs para sesiones de sonoterapia.",
              openHours: "Por cita",
              openNow: true),
        .init(name: "Biblioteca silenciosa",
              kind: .library,
              zone: "Casa principal",
              blurb: "Lectura, té y una butaca. Sin teléfonos.",
              openHours: "07:00 – 23:00",
              openNow: true),
        .init(name: "Consultorio médico",
              kind: .clinic,
              zone: "Ala norte",
              blurb: "Diagnóstico funcional, biomarcadores y consultas.",
              openHours: "09:00 – 18:00",
              openNow: false),
        .init(name: "Lounge de las brasas",
              kind: .lounge,
              zone: "Terraza superior",
              blurb: "Fogata, mantas y conversación al atardecer.",
              openHours: "17:00 – 23:00",
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
