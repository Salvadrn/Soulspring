import Foundation

/// External destinations the app opens in Safari. Verified against
/// soulspring.world and their social presence (Apr 2026).
enum SoulLinks {
    /// Reservar cita / booking oficial.
    static let booking         = URL(string: "https://soulspring.me")!

    /// Instagram de la cocina: Soul Kitchen by @soulspring.sanctuary.
    static let foodInstagram   = URL(string: "https://instagram.com/soulkitchen.ss")!
    static let foodHandle      = "@soulkitchen.ss"

    /// Instagram del Sanctuary.
    static let sanctuaryInstagram = URL(string: "https://instagram.com/soulspring.sanctuary")!

    /// Instagram corporativo de Soulspring México.
    static let mainInstagram   = URL(string: "https://instagram.com/soulspring_mx")!

    /// Sitio principal.
    static let website         = URL(string: "https://soulspring.world")!

    /// Soporte / contacto.
    static let contact         = URL(string: "mailto:mail@soulspring.world")!
}
