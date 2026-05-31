import Foundation

// MARK: - Lifestyle inputs

/// Lifestyle answers we can't pull from HealthKit. The user fills them once
/// and can revise them whenever. Persisted via AppStore.
struct BioAgeInputs: Codable, Equatable {
    var smokes: Bool = false
    var alcohol: AlcoholLevel = .light
    var stress: StressLevel = .medium
    var vo2Max: Double? = nil          // ml/kg/min — optional (Apple Watch VO2)
    var heightCm: Double? = nil
    var weightKg: Double? = nil
    var bmi: Double? = nil             // legacy/manual override; prefer heightCm + weightKg
    var lastUpdated: Date = Date()

    /// Prefers BMI derived from height + weight; falls back to the stored
    /// override.
    var effectiveBMI: Double? {
        if let h = heightCm, let w = weightKg, h > 0 {
            let meters = h / 100
            return w / (meters * meters)
        }
        return bmi
    }

    enum AlcoholLevel: String, Codable, CaseIterable, Identifiable {
        case none     = "Nada"
        case light    = "Ligero"
        case moderate = "Moderado"
        case heavy    = "Frecuente"
        var id: String { rawValue }
    }

    enum StressLevel: String, Codable, CaseIterable, Identifiable {
        case low    = "Bajo"
        case medium = "Medio"
        case high   = "Alto"
        var id: String { rawValue }
    }
}

// MARK: - Factor

/// One contribution to the biological age delta. Positive years make you
/// older; negative years make you younger.
struct BioAgeFactor: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let deltaYears: Double     // + ages you, – rejuvenates you
    let valueLabel: String     // how it's rendered on the breakdown
}

// MARK: - Result

struct BioAgeResult: Hashable {
    let chronologicalAge: Double
    let biologicalAge: Double
    let factors: [BioAgeFactor]
    let completeness: Double   // 0...1 — how many fields we had to compute
    let computedAt: Date

    var delta: Double { biologicalAge - chronologicalAge }
    var isYounger: Bool { delta < -0.1 }
    var isOlder: Bool   { delta > 0.1 }

    var summary: String {
        let abs = Swift.abs(delta)
        if abs < 0.5 { return "Tu edad biológica coincide con tu edad cronológica." }
        let years = String(format: "%.1f", abs)
        return isYounger ? "\(years) años más joven."
                         : "\(years) años por encima."
    }
}

// MARK: - Calculator

/// Soulspring biological age engine. Transparent, pure and linear — starts
/// from the user's chronological age and applies evidence-based deltas per
/// marker. Not a medical device; meant as directional feedback.
enum BioAgeCalculator {

    /// Compute biological age from HealthKit-derived metrics, user lifestyle
    /// and profile activity level.
    static func compute(
        profile: UserProfile,
        inputs: BioAgeInputs,
        restingHR: Double?,
        hrv: Double?,
        steps: Int,
        sleepHours: Double
    ) -> BioAgeResult {
        let chrono = midpointAge(profile.age)
        var factors: [BioAgeFactor] = []
        var available = 0
        var needed = 0

        // Resting heart rate — ideal 55
        needed += 1
        if let rhr = restingHR {
            available += 1
            let delta = linear(rhr, ideal: 55, worst: 90, youngWeight: -2, oldWeight: 3)
            factors.append(.init(
                title: "Ritmo en reposo",
                subtitle: ideal(delta, good: "Corazón eficiente.", bad: "Elevado.", neutral: "En rango."),
                icon: "heart.fill",
                deltaYears: delta,
                valueLabel: "\(Int(rhr)) bpm"))
        }

        // HRV — higher is better. 70 ideal, 25 worst.
        needed += 1
        if let v = hrv {
            available += 1
            let delta = linear(v, ideal: 70, worst: 25, youngWeight: -3, oldWeight: 3, lowerIsWorse: true)
            factors.append(.init(
                title: "HRV",
                subtitle: ideal(delta, good: "Sistema nervioso resiliente.",
                                bad: "Señal de estrés fisiológico.",
                                neutral: "Aceptable."),
                icon: "waveform.path.ecg",
                deltaYears: delta,
                valueLabel: "\(Int(v)) ms"))
        }

        // Steps — 10k ideal, <3k bad
        needed += 1
        available += 1
        let stepDelta = linear(Double(steps), ideal: 10_000, worst: 2_000,
                               youngWeight: -1.5, oldWeight: 2, lowerIsWorse: true)
        factors.append(.init(
            title: "Movimiento diario",
            subtitle: ideal(stepDelta, good: "Cuerpo activo.", bad: "Muy sedentario.", neutral: "Bien."),
            icon: "figure.walk",
            deltaYears: stepDelta,
            valueLabel: "\(steps) pasos"))

        // Sleep — 8h ideal, <5 bad
        needed += 1
        available += 1
        let sleepDelta = linear(sleepHours, ideal: 8, worst: 4.5,
                                youngWeight: -1.5, oldWeight: 2.5, lowerIsWorse: true)
        factors.append(.init(
            title: "Sueño",
            subtitle: ideal(sleepDelta, good: "Descanso reparador.", bad: "Falta sueño.", neutral: "Suficiente."),
            icon: "moon.stars.fill",
            deltaYears: sleepDelta,
            valueLabel: String(format: "%.1f h", sleepHours)))

        // Activity lifestyle (from profile)
        needed += 1
        available += 1
        let activityDelta: Double = {
            switch profile.activity {
            case .sedentary: return  3
            case .light:     return  1
            case .moderate:  return -0.5
            case .active:    return -1.5
            case .athlete:   return -2.5
            }
        }()
        factors.append(.init(
            title: "Nivel de actividad",
            subtitle: profile.activity.rawValue,
            icon: "figure.run",
            deltaYears: activityDelta,
            valueLabel: profile.activity.rawValue))

        // Stress
        needed += 1
        available += 1
        let stressDelta: Double = {
            switch inputs.stress {
            case .low:    return -1
            case .medium: return  0.5
            case .high:   return  2.5
            }
        }()
        factors.append(.init(
            title: "Estrés percibido",
            subtitle: inputs.stress.rawValue,
            icon: "wind",
            deltaYears: stressDelta,
            valueLabel: inputs.stress.rawValue))

        // Alcohol
        needed += 1
        available += 1
        let alcoholDelta: Double = {
            switch inputs.alcohol {
            case .none:     return -0.5
            case .light:    return  0
            case .moderate: return  1
            case .heavy:    return  3
            }
        }()
        factors.append(.init(
            title: "Alcohol",
            subtitle: inputs.alcohol.rawValue,
            icon: "wineglass",
            deltaYears: alcoholDelta,
            valueLabel: inputs.alcohol.rawValue))

        // Tobacco
        needed += 1
        available += 1
        let smokeDelta: Double = inputs.smokes ? 5 : -0.5
        factors.append(.init(
            title: "Tabaco",
            subtitle: inputs.smokes ? "Fumas actualmente." : "No fumas.",
            icon: "lungs.fill",
            deltaYears: smokeDelta,
            valueLabel: inputs.smokes ? "Sí" : "No"))

        // VO2 Max (optional)
        needed += 1
        if let vo2 = inputs.vo2Max {
            available += 1
            let delta = linear(vo2, ideal: 50, worst: 25,
                               youngWeight: -3, oldWeight: 3, lowerIsWorse: true)
            factors.append(.init(
                title: "VO₂ máx",
                subtitle: ideal(delta, good: "Excelente capacidad aeróbica.",
                                bad: "Baja. Sumar Zona 2 ayuda.",
                                neutral: "Dentro del promedio."),
                icon: "lungs",
                deltaYears: delta,
                valueLabel: String(format: "%.0f ml/kg·min", vo2)))
        }

        // BMI (optional) — prefer derived from height + weight.
        needed += 1
        if let bmi = inputs.effectiveBMI {
            available += 1
            let delta: Double
            switch bmi {
            case ..<18.5:    delta =  1.5
            case 18.5..<25:  delta = -1
            case 25..<30:    delta =  1.5
            default:         delta =  3
            }
            factors.append(.init(
                title: "IMC",
                subtitle: bmi < 18.5 ? "Bajo."
                        : bmi < 25 ? "En rango."
                        : bmi < 30 ? "Sobrepeso." : "Obesidad.",
                icon: "scalemass",
                deltaYears: delta,
                valueLabel: String(format: "%.1f", bmi)))
        }

        let totalDelta = factors.reduce(0.0) { $0 + $1.deltaYears }
        // Clamp to a sensible range (±15 y) to avoid runaway values.
        let clamped = max(-15, min(15, totalDelta))
        let bio = max(14, chrono + clamped)

        return BioAgeResult(
            chronologicalAge: chrono,
            biologicalAge: bio,
            factors: factors.sorted { abs($0.deltaYears) > abs($1.deltaYears) },
            completeness: needed > 0 ? Double(available) / Double(needed) : 0,
            computedAt: Date()
        )
    }

    // MARK: Helpers

    /// Maps an observed value onto a young↔old delta in years. Linearly
    /// interpolates between `ideal` and `worst` and clamps to the weights.
    ///
    /// - Parameter lowerIsWorse: set true when higher values are better
    ///   (steps, HRV, VO2 max, sleep). Defaults to false (RHR, BMI above,
    ///   etc. — higher means older).
    private static func linear(_ value: Double,
                               ideal: Double,
                               worst: Double,
                               youngWeight: Double,
                               oldWeight: Double,
                               lowerIsWorse: Bool = false) -> Double {
        if lowerIsWorse {
            // higher = younger
            if value >= ideal { return youngWeight }
            if value <= worst { return oldWeight }
            let t = (ideal - value) / (ideal - worst)   // 0..1
            return youngWeight + t * (oldWeight - youngWeight)
        } else {
            if value <= ideal { return youngWeight }
            if value >= worst { return oldWeight }
            let t = (value - ideal) / (worst - ideal)   // 0..1
            return youngWeight + t * (oldWeight - youngWeight)
        }
    }

    private static func midpointAge(_ bracket: AgeBracket) -> Double {
        switch bracket {
        case .under25: return 22
        case .mid:     return 32
        case .prime:   return 47
        case .wise:    return 62
        }
    }

    private static func ideal(_ delta: Double,
                              good: String, bad: String, neutral: String) -> String {
        if delta < -0.8 { return good }
        if delta >  0.8 { return bad  }
        return neutral
    }
}
