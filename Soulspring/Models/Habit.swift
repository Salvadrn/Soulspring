import Foundation

/// A daily habit that the user commits to. Rachas (streaks) are computed from
/// `completedDates` — consecutive days up to today.
struct Habit: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var cue: String               // When / where to do it
    var icon: String              // SF Symbol
    var colorHex: UInt32          // tint color for the card
    var targetPerDay: Int = 1
    var completedDates: [Date] = []

    /// Number of consecutive days — today counts if completed.
    var streak: Int {
        let calendar = Calendar.current
        let sorted = completedDates
            .map { calendar.startOfDay(for: $0) }
            .sorted(by: >)
            .reduce(into: [Date]()) { acc, d in
                if acc.last != d { acc.append(d) }
            }

        var count = 0
        var cursor = calendar.startOfDay(for: Date())

        for day in sorted {
            if day == cursor {
                count += 1
                cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
            } else if day < cursor {
                break
            }
        }
        return count
    }

    var isDoneToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return completedDates.contains { Calendar.current.isDate($0, inSameDayAs: today) }
    }

    static let samples: [Habit] = [
        Habit(title: "8 vasos de agua",
              cue: "A lo largo del día",
              icon: "drop.fill",
              colorHex: 0x9FB4B8,
              completedDates: Habit.seed(days: 6)),
        Habit(title: "10 min de meditación",
              cue: "Al despertar",
              icon: "wind",
              colorHex: 0x8FA189,
              completedDates: Habit.seed(days: 12)),
        Habit(title: "30 min de movimiento",
              cue: "Antes de comer",
              icon: "figure.run",
              colorHex: 0xC68863,
              completedDates: Habit.seed(days: 4)),
        Habit(title: "Dormir antes de 23:00",
              cue: "Rutina nocturna",
              icon: "moon.stars.fill",
              colorHex: 0x6B4F3B,
              completedDates: Habit.seed(days: 9)),
        Habit(title: "Journaling de gratitud",
              cue: "Antes de dormir",
              icon: "sparkles",
              colorHex: 0xC9A66B,
              completedDates: Habit.seed(days: 3)),
    ]

    private static func seed(days: Int) -> [Date] {
        let cal = Calendar.current
        return (0..<days).compactMap { cal.date(byAdding: .day, value: -$0, to: Date()) }
    }
}
