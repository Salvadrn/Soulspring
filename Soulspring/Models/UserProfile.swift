import Foundation

/// Domains of interest captured in the onboarding formulario ("Formulario que
/// te lleve a tus intereses de salud"). Each interest unlocks tailored
/// recommendations in the app.
enum HealthInterest: String, CaseIterable, Identifiable, Codable {
    case cardiovascular  = "Salud cardiovascular"
    case sleep           = "Descanso y sueño"
    case nutrition       = "Nutrición consciente"
    case movement        = "Movimiento y fuerza"
    case mindfulness     = "Calma y meditación"
    case longevity       = "Longevidad celular"
    case detox           = "Detox y energía"
    case emotional       = "Bienestar emocional"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .cardiovascular: return "heart.fill"
        case .sleep:          return "moon.stars.fill"
        case .nutrition:      return "leaf.fill"
        case .movement:       return "figure.run"
        case .mindfulness:    return "wind"
        case .longevity:      return "hourglass"
        case .detox:          return "drop.fill"
        case .emotional:      return "sparkles"
        }
    }

    var tagline: String {
        switch self {
        case .cardiovascular: return "Ritmo, coherencia y recuperación."
        case .sleep:          return "Noches reparadoras, días claros."
        case .nutrition:      return "Come para florecer."
        case .movement:       return "Cuerpo fuerte, mente ágil."
        case .mindfulness:    return "Respira. Observa. Vuelve."
        case .longevity:      return "Celularmente vital."
        case .detox:          return "Limpieza. Renovación. Luz."
        case .emotional:      return "Honra lo que sientes."
        }
    }
}

enum AgeBracket: String, CaseIterable, Identifiable, Codable {
    case under25 = "18 – 24"
    case mid     = "25 – 39"
    case prime   = "40 – 54"
    case wise    = "55+"
    var id: String { rawValue }
}

enum ActivityLevel: String, CaseIterable, Identifiable, Codable {
    case sedentary = "Sedentario"
    case light     = "Ligero"
    case moderate  = "Moderado"
    case active    = "Activo"
    case athlete   = "Atlético"
    var id: String { rawValue }
}

struct UserProfile: Codable, Equatable {
    var name: String = ""
    var age: AgeBracket = .mid
    var activity: ActivityLevel = .moderate
    var interests: Set<HealthInterest> = []
    var goal: String = ""
    var membershipTier: MembershipTier = .essential
    var hasCompletedOnboarding: Bool = false
}

enum MembershipTier: String, CaseIterable, Codable, Identifiable {
    case essential = "Essential"
    case sanctuary = "Sanctuary"
    case longevity = "Longevity"

    var id: String { rawValue }

    var monthlyCostMXN: Int {
        switch self {
        case .essential: return 500
        case .sanctuary: return 1_800
        case .longevity: return 4_200
        }
    }

    var perks: [String] {
        switch self {
        case .essential:
            return ["Mide tu salud diaria",
                    "Plan nutricional base",
                    "Meditaciones guiadas"]
        case .sanctuary:
            return ["Todo Essential",
                    "1 visita mensual al Santuario",
                    "Plan bio-individualizado",
                    "Room service saludable"]
        case .longevity:
            return ["Todo Sanctuary",
                    "Estudios clínicos de longevidad",
                    "Terapias regenerativas",
                    "Concierge médico 24/7"]
        }
    }
}
