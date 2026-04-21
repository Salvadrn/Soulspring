import SwiftUI

/// SoulSpring brand system.
///
/// Inspired by the SoulSpring Sanctuary aesthetic: earthy, organic, calm
/// and sophisticated. A warm cream canvas with sage greens, soft terracotta
/// and gold accents, paired with an elegant serif display face.
enum SoulTheme {

    // MARK: Color palette

    enum Palette {
        static let moss       = Color(hex: 0x3F5248)   // Deep sage, primary brand
        static let sage       = Color(hex: 0x8FA189)   // Soft sage
        static let leaf       = Color(hex: 0xB9C4A8)   // Pale leaf
        static let cream      = Color(hex: 0xF4EDE1)   // Warm cream canvas
        static let mist       = Color(hex: 0xFAF7F0)   // Near-white background
        static let sand       = Color(hex: 0xE8D9C4)   // Warm sand surface
        static let terracotta = Color(hex: 0xC68863)   // Soft terracotta accent
        static let gold       = Color(hex: 0xC9A66B)   // Muted gold
        static let earth      = Color(hex: 0x6B4F3B)   // Grounded earth brown
        static let ink        = Color(hex: 0x2A2E2B)   // Primary text
        static let inkSoft    = Color(hex: 0x55605A)   // Secondary text
        static let heart      = Color(hex: 0xB85C5C)   // Heart / pulse accent
        static let sky        = Color(hex: 0x9FB4B8)   // Breath / mindfulness
    }

    // MARK: Semantic colors

    enum Color {
        static let background       = Palette.mist
        static let backgroundWarm   = Palette.cream
        static let surface          = SwiftUI.Color.white
        static let surfaceElevated  = Palette.sand.opacity(0.55)
        static let primary          = Palette.moss
        static let primarySoft      = Palette.sage
        static let accent           = Palette.terracotta
        static let accentSoft       = Palette.gold
        static let textPrimary      = Palette.ink
        static let textSecondary    = Palette.inkSoft
        static let divider          = Palette.earth.opacity(0.12)
        static let heart            = Palette.heart
        static let breath           = Palette.sky
    }

    // MARK: Gradients

    enum Gradient {
        static let dawn = LinearGradient(
            colors: [Palette.cream, Palette.sand.opacity(0.6), Palette.leaf.opacity(0.35)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let forest = LinearGradient(
            colors: [Palette.moss, Palette.sage],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let sunset = LinearGradient(
            colors: [Palette.terracotta, Palette.gold],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let breath = LinearGradient(
            colors: [Palette.sky, Palette.leaf.opacity(0.7)],
            startPoint: .top,
            endPoint: .bottom
        )

        static let heart = LinearGradient(
            colors: [Palette.heart, Palette.terracotta],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: Typography

    /// The app uses the system "New York" serif family for display type
    /// and SF Pro for body, mirroring the editorial feel of soulspring.world.
    enum Font {
        static func display(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .serif)
        }

        static func body(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .default)
        }

        static let hero        = display(40, weight: .regular)
        static let title       = display(28, weight: .regular)
        static let sectionHead = display(22, weight: .regular)
        static let card        = body(18, weight: .semibold)
        static let metric      = body(34, weight: .semibold)
        static let unit        = body(14, weight: .medium)
        static let bodyText    = body(16, weight: .regular)
        static let caption     = body(13, weight: .medium)
        static let eyebrow     = body(11, weight: .semibold)
    }

    // MARK: Radius & Spacing

    enum Radius {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 18
        static let lg: CGFloat = 26
        static let xl: CGFloat = 36
    }

    enum Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 12
        static let md: CGFloat = 18
        static let lg: CGFloat = 24
        static let xl: CGFloat = 36
    }
}

// MARK: - Color hex helper

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >>  8) & 0xFF) / 255
        let b = Double( hex        & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
