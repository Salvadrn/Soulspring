import Foundation

/// One plate inside a chef's daily menu.
struct MenuDish: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var description: String
    var course: Course
    var emoji: String

    enum Course: String, CaseIterable, Codable, Identifiable {
        case entrada  = "Entrada"
        case principal = "Principal"
        case postre   = "Postre"
        case bebida   = "Bebida"
        var id: String { rawValue }
    }
}

/// The "Menú del día" curated by the Soul Kitchen chef. Lives in the
/// Sanctuary tab and is editable only in chef mode.
struct DailyMenu: Codable, Equatable {
    var date: Date
    var title: String              // e.g. "Domingo de raíces"
    var headline: String           // Short poetic intro
    var chefName: String           // Who signs the menu
    var dishes: [MenuDish]
    var heroPhotoURL: URL?         // optional attached photo

    static let sample = DailyMenu(
        date: Date(),
        title: "Cocina viva, conectada al origen",
        headline: "Farm to table. De nuestra huerta a tu mesa, hoy.",
        chefName: "Chef Isa Mendoza",
        dishes: [
            MenuDish(name: "Gazpacho de tomate heirloom",
                     description: "Tomates de la huerta, albahaca fresca, aceite de oliva extra virgen.",
                     course: .entrada,
                     emoji: "🍅"),
            MenuDish(name: "Robalo al pibil con plátano macho",
                     description: "Pescado salvaje marinado en achiote, cítricos de temporada y plátano asado.",
                     course: .principal,
                     emoji: "🐟"),
            MenuDish(name: "Flan de cardamomo y piloncillo",
                     description: "Endulzado con piloncillo orgánico, leche de coco y cardamomo tostado.",
                     course: .postre,
                     emoji: "🍮"),
            MenuDish(name: "Agua de pepino, apio y lima",
                     description: "Hidratación fresca, alcalina y digestiva.",
                     course: .bebida,
                     emoji: "🥒"),
        ],
        heroPhotoURL: nil
    )
}

/// A tile displayed in the Instagram-like grid that previews Soul Kitchen's
/// feed. Uses local gradients + emojis while Instagram content isn't pulled
/// through an API. When real photos are available, drop URLs into `photoURL`.
struct InstagramTile: Identifiable, Hashable {
    let id = UUID()
    let caption: String
    let emoji: String
    let gradientHex: (UInt32, UInt32)
    var photoURL: URL? = nil

    static let feed: [InstagramTile] = [
        .init(caption: "Desayuno del domingo",          emoji: "🥣",  gradientHex: (0xC9A66B, 0xE8D9C4)),
        .init(caption: "Cosecha de la huerta",          emoji: "🌿",  gradientHex: (0x8FA189, 0xB9C4A8)),
        .init(caption: "Salmón y quinoa",               emoji: "🐟",  gradientHex: (0x9FB4B8, 0xF4EDE1)),
        .init(caption: "Fermentos del mes",             emoji: "🫙",  gradientHex: (0xC68863, 0xC9A66B)),
        .init(caption: "Caldo regenerador",             emoji: "🍲",  gradientHex: (0x6B4F3B, 0xC9A66B)),
        .init(caption: "Pan de masa madre",             emoji: "🍞",  gradientHex: (0xE8D9C4, 0xC9A66B)),
        .init(caption: "Postre sin azúcar refinada",    emoji: "🍫",  gradientHex: (0x6B4F3B, 0xC68863)),
        .init(caption: "Ensalada del valle",            emoji: "🥗",  gradientHex: (0x8FA189, 0xF4EDE1)),
        .init(caption: "Té de la tarde",                emoji: "🫖",  gradientHex: (0xC9A66B, 0x8FA189)),
    ]
}
