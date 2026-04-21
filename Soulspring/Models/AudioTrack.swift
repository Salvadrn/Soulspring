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
    /// Curated starter library. Replace `url` with your Supabase Storage
    /// signed URLs (or bundle the .m4a files and set `bundleResource`).
    static let library: [AudioTrack] = [
        // Meditación
        .init(id: "med.morning",
              title: "Despertar consciente",
              teacher: "Soulspring · Mariel",
              category: .meditation,
              durationSec: 600,
              blurb: "Diez minutos para abrir el día con presencia y sin prisa.",
              url: nil, bundleResource: nil),
        .init(id: "med.body-scan",
              title: "Body scan completo",
              teacher: "Soulspring · Andrés",
              category: .meditation,
              durationSec: 1500,
              blurb: "Recorrido lento por cada parte del cuerpo, soltando tensión.",
              url: nil, bundleResource: nil),
        .init(id: "med.compassion",
              title: "Práctica de compasión",
              teacher: "Soulspring · Mariel",
              category: .meditation,
              durationSec: 720,
              blurb: "Metta breve para suavizar el diálogo interno.",
              url: nil, bundleResource: nil),

        // Yoga nidra
        .init(id: "nidra.20",
              title: "Yoga nidra · 20 min",
              teacher: "Soulspring · Lía",
              category: .yogaNidra,
              durationSec: 1200,
              blurb: "Descanso profundo equivalente a una siesta restauradora.",
              url: nil, bundleResource: nil),
        .init(id: "nidra.45",
              title: "Yoga nidra largo · 45 min",
              teacher: "Soulspring · Lía",
              category: .yogaNidra,
              durationSec: 2700,
              blurb: "Inducción guiada al estado de conciencia entre sueño y vigilia.",
              url: nil, bundleResource: nil),

        // Breathwork
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
        .init(id: "breath.energizer",
              title: "Respiración energizante",
              teacher: "Soulspring · Lía",
              category: .breath,
              durationSec: 480,
              blurb: "Exhalaciones activas para despertar la mente y limpiar.",
              url: nil, bundleResource: nil),

        // Sound healing
        .init(id: "sound.bowls",
              title: "Cuencos de cuarzo",
              teacher: "Soulspring Sanctuary",
              category: .sound,
              durationSec: 1200,
              blurb: "Frecuencias para anclarte. Audífonos recomendados.",
              url: nil, bundleResource: nil),
        .init(id: "sound.gong",
              title: "Baño de gong",
              teacher: "Soulspring Sanctuary",
              category: .sound,
              durationSec: 1800,
              blurb: "Vibración profunda. Acuéstate y déjate llevar.",
              url: nil, bundleResource: nil),

        // Sleep
        .init(id: "sleep.story",
              title: "Cuento para dormir",
              teacher: "Soulspring · Mariel",
              category: .sleep,
              durationSec: 1800,
              blurb: "Voz suave que te lleva al bosque y al silencio.",
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
