import SwiftUI
import UIKit

/// SoulSpring brand system.
///
/// **Shape-first**: pills, rounded-icon badges, floating tab bar. The shape
/// language stays constant across light and dark mode — what swaps are the
/// surface, text and primary colors.
///
/// Accent tones (moss, terracotta, gold, sky, lilac) are palette swatches
/// that look intentional in both modes; only surfaces and text rotate.
enum SoulTheme {

    // MARK: Fixed palette (swatches, non-adaptive)

    enum Palette {
        // Cream canvas family (used as light background + as dark text)
        static let cream      = Color(hex: 0xF4EDE1)
        static let mist       = Color(hex: 0xFAF7F0)
        static let sand       = Color(hex: 0xE8D9C4)

        // Ink canvas family (used as dark background + as light text)
        static let ink        = Color(hex: 0x14171A)
        static let inkSoft    = Color(hex: 0x1E2320)
        static let inkRaised  = Color(hex: 0x2A2F2C)
        static let inkBorder  = Color(hex: 0x343A35)

        // Muted text tones
        static let muted      = Color(hex: 0x8B9689)
        static let whisper    = Color(hex: 0x5A665D)
        static let earthDark  = Color(hex: 0x6B4F3B)

        // Accent tones — work in both modes
        static let moss       = Color(hex: 0x4F6B57)   // primary on light
        static let mossBright = Color(hex: 0xA8C3A0)   // primary on dark
        static let sage       = Color(hex: 0x8FA189)
        static let leaf       = Color(hex: 0xB9C4A8)
        static let terracotta = Color(hex: 0xC68863)
        static let terracottaBright = Color(hex: 0xE89B70)
        static let gold       = Color(hex: 0xC9A66B)
        static let goldBright = Color(hex: 0xE5C27A)
        static let heart      = Color(hex: 0xD87373)
        static let sky        = Color(hex: 0x9FB4B8)
        static let lilac      = Color(hex: 0xB8A3D4)

        // Used inside the flame shape
        static let earth      = Color(hex: 0x8B7A67)
    }

    // MARK: Adaptive semantic colors (auto-switch with system appearance)

    enum Color {
        static let background       = adaptive(light: 0xFAF7F0, dark: 0x14171A)
        static let backgroundWarm   = adaptive(light: 0xF4EDE1, dark: 0x1E2320)
        static let surface          = adaptive(light: 0xFFFFFF, dark: 0x1E2320)
        static let surfaceElevated  = adaptive(light: 0xF4EDE1, dark: 0x2A2F2C)
        static let divider          = adaptive(light: 0x2A2F2C, dark: 0x343A35,
                                               lightAlpha: 0.10, darkAlpha: 1.0)
        static let textPrimary      = adaptive(light: 0x14171A, dark: 0xF4EDE1)
        static let textSecondary    = adaptive(light: 0x5A665D, dark: 0x8B9689)
        static let textTertiary     = adaptive(light: 0x8B9689, dark: 0x5A665D)

        static let primary          = adaptive(light: 0x4F6B57, dark: 0xA8C3A0)
        static let primarySoft      = adaptive(light: 0x8FA189, dark: 0x8FA189)
        static let accent           = adaptive(light: 0xC68863, dark: 0xE89B70)
        static let accentSoft       = adaptive(light: 0xC9A66B, dark: 0xE5C27A)
        static let heart            = adaptive(light: 0xB85C5C, dark: 0xE07D7D)
        static let breath           = adaptive(light: 0x9FB4B8, dark: 0x9FC4CA)

        /// Text color that sits on top of a `primary` fill (e.g. pill CTA).
        static let onAccent         = adaptive(light: 0xFAF7F0, dark: 0x14171A)

        // MARK: Helper

        private static func adaptive(light: UInt32,
                                     dark: UInt32,
                                     lightAlpha: Double = 1.0,
                                     darkAlpha: Double = 1.0) -> SwiftUI.Color {
            SwiftUI.Color(uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(SwiftUI.Color(hex: dark, alpha: darkAlpha))
                    : UIColor(SwiftUI.Color(hex: light, alpha: lightAlpha))
            })
        }
    }

    // MARK: Gradients

    enum Gradient {
        static let dawn = LinearGradient(
            colors: [Palette.cream, Palette.sand.opacity(0.7)],
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
            colors: [Palette.sky, Palette.lilac],
            startPoint: .top,
            endPoint: .bottom
        )

        static let heart = LinearGradient(
            colors: [Palette.heart, Palette.terracotta],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let flame = LinearGradient(
            colors: [Palette.terracotta, Palette.gold],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: Typography

    enum Font {
        static func display(_ size: CGFloat,
                            weight: SwiftUI.Font.Weight = .bold) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .default)
        }
        static func number(_ size: CGFloat,
                           weight: SwiftUI.Font.Weight = .bold) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .rounded)
        }
        static func body(_ size: CGFloat,
                         weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .default)
        }

        static let hero        = display(36, weight: .bold)
        static let title       = display(26, weight: .bold)
        static let sectionHead = display(20, weight: .bold)
        static let card        = body(16, weight: .semibold)
        static let metric      = number(30, weight: .bold)
        static let unit        = body(12, weight: .medium)
        static let bodyText    = body(15, weight: .regular)
        static let caption     = body(12, weight: .medium)
        static let eyebrow     = body(10, weight: .bold)
    }

    // MARK: Radius & Spacing

    enum Radius {
        static let xs: CGFloat = 10
        static let sm: CGFloat = 14
        static let md: CGFloat = 20
        static let lg: CGFloat = 28
        static let xl: CGFloat = 40
        static let pill: CGFloat = 999
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
