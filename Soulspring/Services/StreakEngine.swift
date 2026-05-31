import Foundation

/// The global "Racha" — a streak that the user must defend every day by
/// completing at least `dailyGoalTarget` habits. Missing a day resets it.
///
/// The engine is pure: given the user's habits and the daily target, it
/// answers three questions:
///   • how many habits are complete today,
///   • whether today's goal is already met,
///   • how many consecutive past days have met the goal.
struct StreakEngine {

    let habits: [Habit]
    let dailyGoalTarget: Int

    // MARK: Today

    /// Habits marked done today.
    var completedToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return habits.reduce(0) { acc, habit in
            acc + (habit.completedDates.contains {
                Calendar.current.isDate($0, inSameDayAs: today)
            } ? 1 : 0)
        }
    }

    var isGoalMetToday: Bool { completedToday >= dailyGoalTarget }

    /// 0...1 for a progress ring.
    var todayProgress: Double {
        guard dailyGoalTarget > 0 else { return 0 }
        return min(1, Double(completedToday) / Double(dailyGoalTarget))
    }

    // MARK: Streak

    /// Length of the current global racha, counting today only if the goal is
    /// already met. Walks backward day-by-day until a day fails the target.
    var currentStreak: Int {
        let cal = Calendar.current
        var cursor = cal.startOfDay(for: Date())
        var count = 0

        // Today — only counts if already met
        if completed(on: cursor) >= dailyGoalTarget {
            count += 1
        } else {
            // Start counting from yesterday
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
        }

        while completed(on: cursor) >= dailyGoalTarget {
            count += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
            // Hard stop after a year
            if count > 365 { break }
        }

        return count
    }

    /// Longest streak ever, scanning up to the last 365 days.
    var longestStreak: Int {
        let cal = Calendar.current
        var best = 0
        var running = 0
        for offset in 0..<365 {
            let day = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: Date()))!
            if completed(on: day) >= dailyGoalTarget {
                running += 1
                best = max(best, running)
            } else {
                running = 0
            }
        }
        return best
    }

    /// Completion status for the last `n` days (most recent last).
    func lastDays(_ n: Int) -> [DayStatus] {
        let cal = Calendar.current
        return (0..<n).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: Date()))!
            let done = completed(on: day)
            return DayStatus(
                date: day,
                completed: done,
                target: dailyGoalTarget,
                isToday: cal.isDateInToday(day)
            )
        }
    }

    struct DayStatus: Identifiable, Hashable {
        let id = UUID()
        let date: Date
        let completed: Int
        let target: Int
        let isToday: Bool
        var met: Bool { completed >= target && target > 0 }
    }

    // MARK: Helpers

    private func completed(on day: Date) -> Int {
        let cal = Calendar.current
        return habits.reduce(0) { acc, habit in
            acc + (habit.completedDates.contains {
                cal.isDate($0, inSameDayAs: day)
            } ? 1 : 0)
        }
    }
}
