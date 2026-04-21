import SwiftUI

// MARK: - Screen background

struct SoulBackground: View {
    var body: some View {
        ZStack {
            SoulTheme.Color.background.ignoresSafeArea()

            // Soft organic blobs — subtle, editorial
            Circle()
                .fill(SoulTheme.Palette.leaf.opacity(0.25))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: -140, y: -260)

            Circle()
                .fill(SoulTheme.Palette.gold.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: 160, y: 320)
        }
    }
}

// MARK: - Eyebrow label (small caps editorial label)

struct SoulEyebrow: View {
    let text: String
    var color: Color = SoulTheme.Palette.earth

    var body: some View {
        Text(text.uppercased())
            .font(SoulTheme.Font.eyebrow)
            .tracking(2)
            .foregroundStyle(color.opacity(0.75))
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

struct SoulCard<Content: View>: View {
    var padding: CGFloat = SoulTheme.Spacing.md
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.lg, style: .continuous)
                    .fill(SoulTheme.Color.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.lg, style: .continuous)
                    .stroke(SoulTheme.Color.divider, lineWidth: 0.5)
            )
            .shadow(color: SoulTheme.Palette.earth.opacity(0.06), radius: 18, x: 0, y: 10)
    }
}

// MARK: - Metric tile

struct SoulMetricTile: View {
    let eyebrow: String
    let value: String
    let unit: String
    let icon: String
    var tint: Color = SoulTheme.Color.primary

    var body: some View {
        SoulCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(tint)
                    SoulEyebrow(text: eyebrow, color: tint)
                    Spacer()
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(SoulTheme.Font.metric)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Text(unit)
                        .font(SoulTheme.Font.unit)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
            }
        }
    }
}

// MARK: - Pill button

struct SoulPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SoulTheme.Font.body(16, weight: .semibold))
            .foregroundStyle(SoulTheme.Color.backgroundWarm)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                Capsule().fill(SoulTheme.Gradient.forest)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SoulSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SoulTheme.Font.body(16, weight: .semibold))
            .foregroundStyle(SoulTheme.Color.primary)
            .padding(.horizontal, 28)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .stroke(SoulTheme.Color.primary, lineWidth: 1.25)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
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
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(tint.opacity(0.10))
            )
    }
}

// MARK: - Divider

struct SoulDivider: View {
    var body: some View {
        Rectangle()
            .fill(SoulTheme.Color.divider)
            .frame(height: 0.5)
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
                .stroke(SoulTheme.Palette.sand, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: progress)
        }
    }
}
