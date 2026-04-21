import SwiftUI

// MARK: - Screen background

/// Deep, calm canvas. A subtle vignette warms the top so the app doesn't
/// feel like a pure OLED test pattern.
struct SoulBackground: View {
    var body: some View {
        ZStack {
            SoulTheme.Color.background.ignoresSafeArea()

            LinearGradient(
                colors: [SoulTheme.Color.surface.opacity(0.7),
                         SoulTheme.Color.background.opacity(0)],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Eyebrow label (small caps)

struct SoulEyebrow: View {
    let text: String
    var color: Color = SoulTheme.Palette.muted

    var body: some View {
        Text(text.uppercased())
            .font(SoulTheme.Font.eyebrow)
            .tracking(1.8)
            .foregroundStyle(color)
    }
}

// MARK: - Section header

struct SoulSectionHeader: View {
    let eyebrow: String?
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let eyebrow { SoulEyebrow(text: eyebrow) }
            Text(title)
                .font(SoulTheme.Font.sectionHead)
                .foregroundStyle(SoulTheme.Color.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(SoulTheme.Font.bodyText)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Card surface

/// A solid dark card. No shadows, no hairline — the card lives by its
/// content and its internal accent icons. Radius is rounded but not too
/// extreme.
struct SoulCard<Content: View>: View {
    var padding: CGFloat = SoulTheme.Spacing.md
    var tinted: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.md, style: .continuous)
                    .fill(tinted
                          ? SoulTheme.Color.surfaceElevated
                          : SoulTheme.Color.surface)
            )
    }
}

// MARK: - Metric tile

/// Dark tile with a circular accent icon (Mimo-inspired). Number dominates,
/// always fits on one line, unit in tiny subtitle below. Designed to sit
/// two-up in a grid.
struct SoulMetricTile: View {
    let eyebrow: String
    let value: String
    let unit: String
    let icon: String
    var tint: Color = SoulTheme.Color.primary

    var body: some View {
        SoulCard(padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                iconBadge

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(value)
                            .font(SoulTheme.Font.metric)
                            .foregroundStyle(SoulTheme.Color.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                        Text(unit)
                            .font(SoulTheme.Font.unit)
                            .foregroundStyle(SoulTheme.Color.textSecondary)
                            .lineLimit(1)
                    }
                    Text(eyebrow)
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.18))
                .frame(width: 42, height: 42)
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tint)
        }
    }
}

// MARK: - Buttons

/// Full-width pill, vivid moss fill, ink text. The signature Soulspring
/// call-to-action.
struct SoulPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SoulTheme.Font.body(16, weight: .bold))
            .foregroundStyle(SoulTheme.Color.onAccent)
            .padding(.horizontal, 28)
            .padding(.vertical, 17)
            .frame(maxWidth: .infinity)
            .background(Capsule().fill(SoulTheme.Color.primary))
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Outlined pill — dark fill, moss border + text. Secondary actions.
struct SoulSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SoulTheme.Font.body(15, weight: .semibold))
            .foregroundStyle(SoulTheme.Color.textPrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .stroke(SoulTheme.Color.divider, lineWidth: 1)
                    .background(Capsule().fill(SoulTheme.Color.surface))
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

// MARK: - Tag / chip

struct SoulChip: View {
    let text: String
    var tint: Color = SoulTheme.Palette.moss

    var body: some View {
        Text(text)
            .font(SoulTheme.Font.caption)
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(tint.opacity(0.14)))
    }
}

// MARK: - Divider

struct SoulDivider: View {
    var body: some View {
        Rectangle()
            .fill(SoulTheme.Color.divider)
            .frame(height: 1)
    }
}

// MARK: - Progress ring

struct SoulProgressRing: View {
    let progress: Double          // 0...1
    var lineWidth: CGFloat = 10
    var gradient: LinearGradient = SoulTheme.Gradient.forest

    var body: some View {
        ZStack {
            Circle()
                .stroke(SoulTheme.Color.surfaceElevated, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: progress)
        }
    }
}

// MARK: - Pill stat (used in counters / headers, e.g. streak indicator top-left)

struct SoulPillStat: View {
    let icon: String
    let value: String
    var tint: Color = SoulTheme.Color.accent

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(SoulTheme.Color.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .stroke(SoulTheme.Color.divider, lineWidth: 1)
                .background(Capsule().fill(SoulTheme.Color.surface))
        )
    }
}
