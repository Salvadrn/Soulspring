import SwiftUI

/// 3-second mood check-in: tap an emoji + optional one-line note.
struct MoodCheckinView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var health: HealthKitManager
    @Environment(\.dismiss) private var dismiss

    @State private var picked: Int? = nil   // 1...5
    @State private var note: String = ""

    var body: some View {
        ZStack {
            SoulTheme.Color.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: SoulTheme.Spacing.lg) {
                SoulSectionHeader(
                    eyebrow: "Check-in",
                    title: "¿Cómo te sientes?",
                    subtitle: "Tres segundos. Lo cruzamos con tu HRV y sueño para ver patrones."
                )

                HStack(spacing: 8) {
                    ForEach(MoodCheckin.palette, id: \.1) { item in
                        let (emoji, score, label) = item
                        Button {
                            withAnimation(.spring(duration: 0.25)) {
                                picked = score
                            }
                            SoulHaptics.select()
                        } label: {
                            VStack(spacing: 6) {
                                Text(emoji).font(.system(size: 38))
                                Text(label)
                                    .font(SoulTheme.Font.caption)
                                    .foregroundStyle(picked == score
                                                     ? SoulTheme.Color.textPrimary
                                                     : SoulTheme.Color.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                                    .fill(picked == score
                                          ? AnyShapeStyle(SoulTheme.Color.primary.opacity(0.18))
                                          : AnyShapeStyle(SoulTheme.Color.surface))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                                    .stroke(picked == score
                                            ? SoulTheme.Color.primary
                                            : SoulTheme.Color.divider,
                                            lineWidth: picked == score ? 2 : 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    SoulEyebrow(text: "Una línea (opcional)")
                    TextField("Ej. dormí mal pero entrené.", text: $note, axis: .vertical)
                        .lineLimit(2, reservesSpace: true)
                        .font(SoulTheme.Font.bodyText)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                                .fill(SoulTheme.Color.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                                .stroke(SoulTheme.Color.divider, lineWidth: 0.5)
                        )
                }

                Spacer()

                Button {
                    save()
                } label: {
                    Text("Guardar check-in")
                }
                .buttonStyle(SoulPrimaryButtonStyle())
                .disabled(picked == nil)
                .opacity(picked == nil ? 0.5 : 1)
            }
            .padding(SoulTheme.Spacing.lg)
        }
    }

    private func save() {
        guard let score = picked,
              let entry = MoodCheckin.palette.first(where: { $0.1 == score }) else { return }
        store.recordMood(
            emoji: entry.0,
            score: score,
            note: note.trimmingCharacters(in: .whitespaces),
            hrv: health.hrv,
            sleepHours: health.sleepHours,
            restingHR: health.restingHeartRate
        )
        SoulHaptics.success()
        dismiss()
    }
}

// MARK: - Patterns view

struct MoodPatternsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: SoulTheme.Spacing.lg) {
                SoulSectionHeader(
                    eyebrow: "Patrones",
                    title: "Qué te pone bien — y qué no",
                    subtitle: "Cruza tus check-ins con HRV, sueño y pulso. Necesitas al menos 4 entradas."
                )

                if store.moodLog.count < 4 {
                    SoulCard(padding: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Aún no hay suficientes datos.")
                                .font(SoulTheme.Font.card)
                                .foregroundStyle(SoulTheme.Color.textPrimary)
                            Text("Agrega \(4 - store.moodLog.count) check-in\(store.moodLog.count == 3 ? "" : "s") más para empezar a ver tendencias.")
                                .font(SoulTheme.Font.caption)
                                .foregroundStyle(SoulTheme.Color.textSecondary)
                        }
                    }
                } else {
                    let patterns = MoodAnalyzer.patterns(from: store.moodLog)
                    if patterns.isEmpty {
                        SoulCard(padding: 20) {
                            Text("Tu ánimo se mantiene parejo. Buen lugar para estar.")
                                .font(SoulTheme.Font.bodyText)
                                .foregroundStyle(SoulTheme.Color.textPrimary)
                        }
                    } else {
                        VStack(spacing: 10) {
                            ForEach(patterns) { p in patternRow(p) }
                        }
                    }
                }

                if !store.moodLog.isEmpty {
                    SoulSectionHeader(eyebrow: "Historial", title: "Tus últimos check-ins", subtitle: nil)
                    VStack(spacing: 8) {
                        ForEach(store.moodLog.prefix(20)) { entry in
                            historyRow(entry)
                        }
                    }
                }
            }
            .padding(SoulTheme.Spacing.lg)
        }
        .background(SoulTheme.Color.background.ignoresSafeArea())
        .navigationTitle("Mood")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func patternRow(_ p: MoodPattern) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: iconFor(p.direction))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(colorFor(p.direction))
                .frame(width: 36, height: 36)
                .background(Circle().fill(colorFor(p.direction).opacity(0.15)))

            VStack(alignment: .leading, spacing: 4) {
                Text(p.title)
                    .font(SoulTheme.Font.card)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                Text(p.detail)
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: SoulTheme.Radius.md).fill(SoulTheme.Color.surface))
        .overlay(RoundedRectangle(cornerRadius: SoulTheme.Radius.md).stroke(SoulTheme.Color.divider, lineWidth: 0.5))
    }

    private func historyRow(_ entry: MoodCheckin) -> some View {
        HStack(spacing: 14) {
            Text(entry.emoji).font(.system(size: 28))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.capturedAt, format: .dateTime.weekday(.wide).day().month())
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(SoulTheme.Font.bodyText)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                        .lineLimit(2)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: SoulTheme.Radius.md).fill(SoulTheme.Color.surface))
        .overlay(RoundedRectangle(cornerRadius: SoulTheme.Radius.md).stroke(SoulTheme.Color.divider, lineWidth: 0.5))
    }

    private func iconFor(_ d: MoodPattern.Direction) -> String {
        switch d {
        case .positive: return "arrow.up.right"
        case .negative: return "arrow.down.right"
        case .neutral:  return "equal"
        }
    }

    private func colorFor(_ d: MoodPattern.Direction) -> Color {
        switch d {
        case .positive: return SoulTheme.Palette.moss
        case .negative: return SoulTheme.Palette.heart
        case .neutral:  return SoulTheme.Palette.sky
        }
    }
}
