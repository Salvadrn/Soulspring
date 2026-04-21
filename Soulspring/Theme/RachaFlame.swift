import SwiftUI

// MARK: - Flame shape

/// A hand-tuned flame shape — bezier curves drawn to feel alive, not iconic.
/// Inspired by the Duolingo streak flame but reshaped for the Soulspring
/// warm-earth palette.
struct FlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height

        // Start at the top tip
        p.move(to: CGPoint(x: w * 0.50, y: h * 0.02))

        // Right upper curve (tapered tongue)
        p.addCurve(to: CGPoint(x: w * 0.82, y: h * 0.42),
                   control1: CGPoint(x: w * 0.62, y: h * 0.10),
                   control2: CGPoint(x: w * 0.78, y: h * 0.24))

        // Right side bulge out
        p.addCurve(to: CGPoint(x: w * 0.95, y: h * 0.70),
                   control1: CGPoint(x: w * 0.90, y: h * 0.55),
                   control2: CGPoint(x: w * 1.00, y: h * 0.60))

        // Right bottom arc to bottom
        p.addCurve(to: CGPoint(x: w * 0.50, y: h * 0.98),
                   control1: CGPoint(x: w * 0.92, y: h * 0.90),
                   control2: CGPoint(x: w * 0.75, y: h * 1.00))

        // Left bottom arc up
        p.addCurve(to: CGPoint(x: w * 0.05, y: h * 0.70),
                   control1: CGPoint(x: w * 0.25, y: h * 1.00),
                   control2: CGPoint(x: w * 0.08, y: h * 0.90))

        // Left side bulge
        p.addCurve(to: CGPoint(x: w * 0.22, y: h * 0.40),
                   control1: CGPoint(x: w * 0.00, y: h * 0.58),
                   control2: CGPoint(x: w * 0.12, y: h * 0.52))

        // Left upper curve back to the tip — creates a soft inner flicker
        p.addCurve(to: CGPoint(x: w * 0.50, y: h * 0.02),
                   control1: CGPoint(x: w * 0.30, y: h * 0.22),
                   control2: CGPoint(x: w * 0.42, y: h * 0.14))

        p.closeSubpath()
        return p
    }
}

/// Small inner highlight — the "pilot light" you see inside real flames.
struct FlameCore: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: w * 0.50, y: h * 0.30))
        p.addCurve(to: CGPoint(x: w * 0.72, y: h * 0.70),
                   control1: CGPoint(x: w * 0.68, y: h * 0.40),
                   control2: CGPoint(x: w * 0.72, y: h * 0.55))
        p.addCurve(to: CGPoint(x: w * 0.50, y: h * 0.92),
                   control1: CGPoint(x: w * 0.72, y: h * 0.85),
                   control2: CGPoint(x: w * 0.62, y: h * 0.92))
        p.addCurve(to: CGPoint(x: w * 0.28, y: h * 0.70),
                   control1: CGPoint(x: w * 0.38, y: h * 0.92),
                   control2: CGPoint(x: w * 0.28, y: h * 0.85))
        p.addCurve(to: CGPoint(x: w * 0.50, y: h * 0.30),
                   control1: CGPoint(x: w * 0.28, y: h * 0.55),
                   control2: CGPoint(x: w * 0.34, y: h * 0.42))
        p.closeSubpath()
        return p
    }
}

// MARK: - Racha badge (flame + number)

/// The icon for personal and shared streaks. Shows a warm flame with the
/// streak count rendered in the brand serif inside. Breathes subtly.
struct RachaFlame: View {
    let days: Int
    var size: CGFloat = 88
    var isAlive: Bool = true

    @State private var flicker = false

    var body: some View {
        ZStack {
            // Soft outer glow
            FlameShape()
                .fill(SoulTheme.Palette.gold.opacity(isAlive ? 0.35 : 0.15))
                .frame(width: size * 1.20, height: size * 1.32)
                .blur(radius: size * 0.18)

            // Outer flame body
            FlameShape()
                .fill(
                    LinearGradient(
                        colors: isAlive
                            ? [SoulTheme.Palette.terracotta,
                               SoulTheme.Palette.gold]
                            : [SoulTheme.Palette.earth.opacity(0.6),
                               SoulTheme.Palette.sand],
                        startPoint: .top,
                        endPoint: .bottom))
                .frame(width: size, height: size * 1.12)
                .shadow(color: SoulTheme.Palette.terracotta.opacity(isAlive ? 0.45 : 0),
                        radius: size * 0.15, x: 0, y: size * 0.10)

            // Inner core — warmer, lighter, gives depth
            FlameCore()
                .fill(
                    LinearGradient(
                        colors: isAlive
                            ? [SoulTheme.Palette.gold,
                               SoulTheme.Palette.cream]
                            : [SoulTheme.Palette.sand,
                               SoulTheme.Palette.mist],
                        startPoint: .top,
                        endPoint: .bottom))
                .frame(width: size * 0.55, height: size * 0.78)
                .offset(y: size * 0.08)

            // Streak number
            VStack(spacing: -2) {
                Text("\(days)")
                    .font(.system(size: numberSize, weight: .bold, design: .serif))
                    .foregroundStyle(SoulTheme.Palette.earth)
                    .shadow(color: .white.opacity(0.6), radius: 0, x: 0, y: 1)
            }
            .offset(y: size * 0.12)
        }
        .scaleEffect(flicker ? 1.03 : 0.97)
        .onAppear {
            guard isAlive else { return }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                flicker = true
            }
        }
    }

    private var numberSize: CGFloat {
        switch days {
        case ..<10:   return size * 0.42
        case ..<100:  return size * 0.34
        default:      return size * 0.26
        }
    }
}

// MARK: - Small pill

/// A compact inline version (e.g. for cards and list rows).
struct RachaPill: View {
    let days: Int
    var isAlive: Bool = true
    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                FlameShape()
                    .fill(
                        LinearGradient(
                            colors: isAlive
                                ? [SoulTheme.Palette.terracotta,
                                   SoulTheme.Palette.gold]
                                : [SoulTheme.Palette.sand,
                                   SoulTheme.Palette.mist],
                            startPoint: .top, endPoint: .bottom))
                    .frame(width: 14, height: 18)
            }
            Text("\(days)")
                .font(.system(size: 14, weight: .bold, design: .serif))
                .foregroundStyle(isAlive ? SoulTheme.Palette.earth : SoulTheme.Color.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(isAlive
                           ? SoulTheme.Palette.gold.opacity(0.20)
                           : SoulTheme.Palette.sand.opacity(0.50))
        )
    }
}
