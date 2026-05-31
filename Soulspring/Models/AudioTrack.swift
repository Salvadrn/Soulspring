import Foundation

/// A track in the Soulspring audio library — meditations, yoga nidra,
/// breathwork. Sources can be local files (bundled), Soulspring CDN URLs
/// once Storage is wired, or any HTTPS .mp3 / .m4a.
struct AudioTrack: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let teacher: String
    let category: Category
    let durationSec: Int
    let blurb: String
    let url: URL?            // remote stream (may be nil for placeholders)
    let bundleResource: String?  // local file name without extension

    enum Category: String, Codable, CaseIterable, Identifiable {
        case meditation  = "Meditación"
        case yogaNidra   = "Yoga nidra"
        case breath      = "Breathwork"
        case sound       = "Sound healing"
        case sleep       = "Sueño"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .meditation: return "sparkles"
            case .yogaNidra:  return "moon.zzz.fill"
            case .breath:     return "wind"
            case .sound:      return "waveform"
            case .sleep:      return "bed.double.fill"
            }
        }
    }
}

extension AudioTrack {
    /// Curated starter library. Tracks with `bundleResource` ship inside the
    /// app; tracks with `url` stream from Supabase Storage / CDN.
    static let library: [AudioTrack] = [
        // Real bundled audios — ship with the app
        .init(id: "med.bells.20",
              title: "Meditación 20 min · Campanas con intervalos",
              teacher: "Free Mindfulness",
              category: .meditation,
              durationSec: 1200,
              blurb: "Campana al inicio, intervalos suaves para mantenerte presente, y cierre.",
              url: nil, bundleResource: "mindfulness-20"),
        .init(id: "med.bells.25",
              title: "Meditación 25 min · Solo campanas",
              teacher: "Free Mindfulness",
              category: .meditation,
              durationSec: 1500,
              blurb: "Campana al inicio y al final. Práctica silenciosa para sentarte con tu respiración.",
              url: nil, bundleResource: "bells-25"),
        .init(id: "med.bells.30",
              title: "Meditación 30 min · Solo campanas",
              teacher: "Free Mindfulness",
              category: .meditation,
              durationSec: 1800,
              blurb: "Media hora de silencio sostenido. Campana de apertura y cierre.",
              url: nil, bundleResource: "bells-30"),
        .init(id: "med.bells.45.5",
              title: "Meditación 45 min · Campanas cada 5 min",
              teacher: "Free Mindfulness",
              category: .meditation,
              durationSec: 2700,
              blurb: "Sesión larga con campanas suaves cada 5 minutos para anclarte.",
              url: nil, bundleResource: "mindfulness-45-5min"),
        .init(id: "med.bells.45.15",
              title: "Meditación 45 min · Campanas cada 15 min",
              teacher: "Free Mindfulness",
              category: .meditation,
              durationSec: 2700,
              blurb: "Sesión profunda. Campanas espaciadas para sostener largos periodos de silencio.",
              url: nil, bundleResource: "mindfulness-45-15min"),

        // Placeholders — populate `url` with Supabase Storage signed URLs
        // (or replace bundleResource) when you have more content.
        .init(id: "breath.coherence",
              title: "Respiración coherente 5-5",
              teacher: "Soulspring · Andrés",
              category: .breath,
              durationSec: 300,
              blurb: "5 segundos inhala, 5 segundos exhala. Baja el pulso en 5 minutos.",
              url: nil, bundleResource: nil),
        .init(id: "breath.box",
              title: "Box breathing 4-4-4-4",
              teacher: "Soulspring · Andrés",
              category: .breath,
              durationSec: 360,
              blurb: "Patrón cuadrado para regular el sistema nervioso simpático.",
              url: nil, bundleResource: nil),

        .init(id: "nidra.20",
              title: "Yoga nidra · 20 min",
              teacher: "Soulspring · Lía",
              category: .yogaNidra,
              durationSec: 1200,
              blurb: "Descanso profundo equivalente a una siesta restauradora.",
              url: nil, bundleResource: nil),

        .init(id: "sound.bowls",
              title: "Cuencos de cuarzo",
              teacher: "Soulspring Sanctuary",
              category: .sound,
              durationSec: 1200,
              blurb: "Frecuencias para anclarte. Audífonos recomendados.",
              url: nil, bundleResource: nil),

        .init(id: "sleep.rain",
              title: "Lluvia sobre el bosque",
              teacher: "Soulspring Sanctuary",
              category: .sleep,
              durationSec: 3600,
              blurb: "Loop de lluvia continua. Pon en bajo volumen y respira.",
              url: nil, bundleResource: nil),
    ]

    var formattedDuration: String {
        let m = durationSec / 60
        let s = durationSec % 60
        return s == 0 ? "\(m) min" : "\(m):\(String(format: "%02d", s))"
    }
}
