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
    var handle: String = ""
    var email: String = ""
    var phone: String = ""
    var age: AgeBracket = .mid
    var activity: ActivityLevel = .moderate
    var interests: Set<HealthInterest> = []
    var goal: String = ""
    var membershipTier: MembershipTier = .essential
    var hasCompletedOnboarding: Bool = false

    // Clinical context — visible in the wallet so the practitioner can
    // welcome the guest with full awareness at check-in.
    var emergencyContactName: String = ""
    var emergencyContactPhone: String = ""
    var allergies: String = ""
    var clinicalNotes: String = ""

    /// Server-controlled role flag. Only the actual chef account has this set
    /// to true (in Supabase: `profiles.is_chef`). Toggling locally is a no-op
    /// for the data layer — the next sync wins.
    var isChef: Bool = false

    var memberSince: Date = Date()
}

/// A stay plan at the Sanctuary. Priced per night, hotel-style.
enum MembershipTier: String, CaseIterable, Codable, Identifiable {
    case essential = "Essential"
    case sanctuary = "Sanctuary"
    case longevity = "Longevity"

    var id: String { rawValue }

    /// Nightly rate in MXN. The Sanctuary is hotel-style: you book the
    /// number of nights and pay per night.
    var nightlyCostMXN: Int {
        switch self {
        case .essential: return 2_800
        case .sanctuary: return 6_500
        case .longevity: return 14_800
        }
    }

    var tagline: String {
        switch self {
        case .essential: return "Inmersión breve, esencial."
        case .sanctuary: return "Plan bio-individualizado completo."
        case .longevity: return "Protocolo clínico avanzado."
        }
    }

    var includes: [String] {
        switch self {
        case .essential:
            return ["Habitación Esencial",
                    "3 comidas del chef",
                    "1 experiencia grupal / día",
                    "Acceso a sauna y tinas"]
        case .sanctuary:
            return ["Habitación Sanctuary",
                    "Menú bio-individualizado",
                    "2 experiencias privadas / día",
                    "Masaje de bienvenida",
                    "Consulta nutricional"]
        case .longevity:
            return ["Suite Longevity",
                    "Panel clínico de biomarcadores",
                    "Protocolo médico personalizado",
                    "Concierge médico 24/7",
                    "Acceso a terapias regenerativas"]
        }
    }
}
