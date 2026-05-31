import Foundation

/// A friend linked to the user's account for joint streaks.
struct SoulFriend: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var handle: String            // @handle — used for invites
    var avatarColorHex: UInt32

    var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last  = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }
}

/// A streak that requires BOTH participants to meet their daily goal every
/// day. One person breaks it → both lose it. Small stakes, big accountability.
struct SharedStreak: Identifiable, Hashable, Codable {
    let id: UUID
    let friend: SoulFriend
    var startedOn: Date
    var currentStreak: Int        // days both met the goal, consecutive
    var longestStreak: Int
    var friendMetToday: Bool      // whether your friend has met their goal today
    var status: Status

    enum Status: String, Codable {
        case pending   // invite sent, friend hasn't accepted
        case active    // both committed
        case broken    // one of the two missed a day
    }
}

enum SharedStreakEngine {
    static let samples: [SharedStreak] = [
        .init(
            id: UUID(),
            friend: .init(id: UUID(),
                          name: "Andrea Cortés",
                          handle: "@andrea",
                          avatarColorHex: 0xC68863),
            startedOn: Date().addingTimeInterval(-18 * 86_400),
            currentStreak: 18,
            longestStreak: 24,
            friendMetToday: true,
            status: .active
        ),
        .init(
            id: UUID(),
            friend: .init(id: UUID(),
                          name: "Mateo Ruiz",
                          handle: "@mateo",
                          avatarColorHex: 0x8FA189),
            startedOn: Date().addingTimeInterval(-6 * 86_400),
            currentStreak: 6,
            longestStreak: 9,
            friendMetToday: false,
            status: .active
        ),
        .init(
            id: UUID(),
            friend: .init(id: UUID(),
                          name: "Sofía Reyes",
                          handle: "@sofia",
                          avatarColorHex: 0xC9A66B),
            startedOn: Date(),
            currentStreak: 0,
            longestStreak: 0,
            friendMetToday: false,
            status: .pending
        ),
    ]

    /// Whether a shared streak is still alive today: both you AND the friend
    /// must have met their daily goal.
    static func isAlive(_ shared: SharedStreak, youMetToday: Bool) -> Bool {
        guard shared.status == .active else { return false }
        return youMetToday && shared.friendMetToday
    }
}
