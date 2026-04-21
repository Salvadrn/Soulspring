import Foundation

/// A 3-second mood check-in. The user picks an emoji + score from 1-5 and
/// optionally adds a one-line note. We snapshot the day's HRV / sleep / RHR
/// so the patterns view ("qué te pone bien / mal") doesn't need an expensive
/// join later.
struct MoodCheckin: Identifiable, Codable, Hashable {
    let id: UUID
    let emoji: String
    let score: Int            // 1...5 (1 = pésimo, 5 = excelente)
    let note: String
    let hrv: Double?
    let sleepHours: Double?
    let restingHR: Double?
    let capturedAt: Date

    init(id: UUID = UUID(),
         emoji: String,
         score: Int,
         note: String = "",
         hrv: Double? = nil,
         sleepHours: Double? = nil,
         restingHR: Double? = nil,
         capturedAt: Date = Date()) {
        self.id = id
        self.emoji = emoji
        self.score = score
        self.note = note
        self.hrv = hrv
        self.sleepHours = sleepHours
        self.restingHR = restingHR
        self.capturedAt = capturedAt
    }

    static let palette: [(String, Int, String)] = [
        ("😞", 1, "Pésimo"),
        ("😕", 2, "Bajo"),
        ("😐", 3, "Estable"),
        ("🙂", 4, "Bien"),
        ("✨", 5, "Excelente"),
    ]
}

/// Lightweight pattern that emerges across check-ins. Computed in memory.
struct MoodPattern: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let detail: String
    let direction: Direction
    enum Direction { case positive, negative, neutral }
}

enum MoodAnalyzer {
    /// Group recent check-ins by mood quartile (low/high) and surface the
    /// metric (HRV, sleep, RHR) where the difference is largest. Cheap and
    /// directional — not statistical inference.
    static func patterns(from log: [MoodCheckin]) -> [MoodPattern] {
        guard log.count >= 4 else { return [] }
        let highMood = log.filter { $0.score >= 4 }
        let lowMood  = log.filter { $0.score <= 2 }
        guard !highMood.isEmpty, !lowMood.isEmpty else { return [] }

        var out: [MoodPattern] = []

        let avgHRVHi = average(highMood.compactMap { $0.hrv })
        let avgHRVLo = average(lowMood.compactMap { $0.hrv })
        if let hi = avgHRVHi, let lo = avgHRVLo {
            let delta = hi - lo
            if abs(delta) > 5 {
                out.append(MoodPattern(
                    title: "HRV y ánimo",
                    detail: delta > 0
                        ? "Cuando te sientes mejor, tu HRV está \(Int(delta)) ms más alto en promedio."
                        : "Tu HRV baja \(Int(abs(delta))) ms los días que te sientes peor.",
                    direction: delta > 0 ? .positive : .negative))
            }
        }

        let avgSleepHi = average(highMood.compactMap { $0.sleepHours })
        let avgSleepLo = average(lowMood.compactMap { $0.sleepHours })
        if let hi = avgSleepHi, let lo = avgSleepLo, abs(hi - lo) > 0.4 {
            out.append(MoodPattern(
                title: "Sueño y ánimo",
                detail: hi > lo
                    ? "Duermes \(String(format: "%.1f", hi - lo)) h más los días que te sientes mejor."
                    : "Tu ánimo es más alto cuando duermes menos — vale revisar.",
                direction: hi > lo ? .positive : .neutral))
        }

        let avgRHRHi = average(highMood.compactMap { $0.restingHR })
        let avgRHRLo = average(lowMood.compactMap { $0.restingHR })
        if let hi = avgRHRHi, let lo = avgRHRLo, abs(lo - hi) > 3 {
            out.append(MoodPattern(
                title: "Pulso en reposo y ánimo",
                detail: lo > hi
                    ? "Tu pulso en reposo está \(Int(lo - hi)) bpm más alto los días bajos."
                    : "Tu pulso en reposo no parece correlacionar con tu ánimo.",
                direction: lo > hi ? .negative : .neutral))
        }

        return out
    }

    private static func average(_ xs: [Double]) -> Double? {
        guard !xs.isEmpty else { return nil }
        return xs.reduce(0, +) / Double(xs.count)
    }
}
