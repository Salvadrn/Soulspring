import SwiftUI
import Charts

/// Detailed sleep breakdown pulled from HealthKit (REM, deep, core, awake)
/// plus an ideal-bedtime heuristic based on the user's target wake time and
/// sleep cycles of ~90 minutes.
struct SleepDetailView: View {
    @EnvironmentObject private var health: HealthKitManager
    @State private var targetWake: Date = SleepDetailView.defaultWake
    @State private var smartAlarm: Bool = true

    private static var defaultWake: Date {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        c.hour = 6; c.minute = 45
        return Calendar.current.date(from: c) ?? Date()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                header
                totalCard
                stagesChart
                idealBedtimeCard
                smartAlarmCard
                tipsCard
            }
            .padding(SoulTheme.Spacing.lg)
        }
        .background(SoulBackground())
        .navigationTitle("Sueño")
        .navigationBarTitleDisplayMode(.inline)
        .task { await health.refreshAll() }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            SoulEyebrow(text: "Anoche")
            Text("Tu sueño, en capas.")
                .font(SoulTheme.Font.title)
                .foregroundStyle(SoulTheme.Color.textPrimary)
            Text("REM, profundo y ligero sincronizados desde Apple Health.")
                .font(SoulTheme.Font.caption)
                .foregroundStyle(SoulTheme.Color.textSecondary)
        }
    }

    // MARK: Totals

    private var totalCard: some View {
        SoulCard(padding: SoulTheme.Spacing.lg) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    SoulEyebrow(text: "Total dormido")
                    Text(formattedHours(health.sleepStages.totalAsleep / 60))
                        .font(SoulTheme.Font.display(46, weight: .semibold))
                        .foregroundStyle(SoulTheme.Color.primary)
                    Text(scoreText)
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
                Spacer()
                ZStack {
                    SoulProgressRing(
                        progress: min(1, (health.sleepStages.totalAsleep / 60) / 8),
                        lineWidth: 9,
                        gradient: SoulTheme.Gradient.forest
                    )
                    .frame(width: 72, height: 72)
                    Image(systemName: "moon.stars.fill")
                        .foregroundStyle(SoulTheme.Palette.earth)
                }
            }
        }
    }

    private var scoreText: String {
        let h = health.sleepStages.totalAsleep / 60
        switch h {
        case 0..<6:    return "Bajo · prioriza acostarte 30 min antes."
        case 6..<7:    return "Aceptable · podrías sumar una fase más."
        case 7..<9:    return "Ideal · tu ritmo está en equilibrio."
        default:       return "Muy largo · revisa si estás cansada durante el día."
        }
    }

    // MARK: Chart

    private struct StageSlice: Identifiable {
        let id = UUID()
        let name: String
        let minutes: Double
        let color: Color
    }

    private var slices: [StageSlice] {
        let s = health.sleepStages
        return [
            .init(name: "Profundo", minutes: s.deepMinutes, color: SoulTheme.Palette.moss),
            .init(name: "REM",      minutes: s.remMinutes,  color: SoulTheme.Palette.terracotta),
            .init(name: "Ligero",   minutes: s.coreMinutes, color: SoulTheme.Palette.sage),
            .init(name: "Despierto",minutes: s.awakeMinutes,color: SoulTheme.Palette.gold),
        ]
    }

    private var stagesChart: some View {
        SoulCard(padding: SoulTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 14) {
                SoulEyebrow(text: "Fases")
                Chart(slices) { s in
                    SectorMark(
                        angle: .value("Minutos", s.minutes),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(s.color)
                    .cornerRadius(3)
                }
                .frame(height: 160)

                VStack(spacing: 8) {
                    ForEach(slices) { slice in
                        HStack {
                            Circle().fill(slice.color).frame(width: 10, height: 10)
                            Text(slice.name)
                                .font(SoulTheme.Font.bodyText)
                                .foregroundStyle(SoulTheme.Color.textPrimary)
                            Spacer()
                            Text(formattedHours(slice.minutes / 60))
                                .font(SoulTheme.Font.caption)
                                .foregroundStyle(SoulTheme.Color.textSecondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: Ideal bedtime

    private var idealBedtimeCard: some View {
        SoulCard {
            VStack(alignment: .leading, spacing: 12) {
                SoulEyebrow(text: "Hora ideal de dormir")
                Text("Basada en 5 ciclos de 90 minutos + 15 min para conciliar.")
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        SoulEyebrow(text: "Te despiertas a las")
                        DatePicker("", selection: $targetWake, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        SoulEyebrow(text: "Ve a dormir")
                        Text(idealBedtime.formatted(date: .omitted, time: .shortened))
                            .font(SoulTheme.Font.display(28, weight: .semibold))
                            .foregroundStyle(SoulTheme.Color.primary)
                    }
                }
            }
        }
    }

    private var idealBedtime: Date {
        Calendar.current.date(byAdding: .minute, value: -(5 * 90 + 15), to: targetWake) ?? targetWake
    }

    // MARK: Smart alarm

    private var smartAlarmCard: some View {
        SoulCard {
            HStack(spacing: 12) {
                Image(systemName: "alarm.waves.left.and.right.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(SoulTheme.Color.primary)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Alarma inteligente")
                        .font(SoulTheme.Font.card)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Text("Te despierta en la fase más ligera, hasta 20 min antes de \(targetWake.formatted(date: .omitted, time: .shortened)).")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
                Spacer()
                Toggle("", isOn: $smartAlarm).labelsHidden().tint(SoulTheme.Color.primary)
            }
        }
    }

    // MARK: Tips

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SoulSectionHeader(eyebrow: "Rituales",
                              title: "Para dormir mejor",
                              subtitle: nil)
            tip(icon: "sun.haze.fill", title: "Luz de sol al despertar",
                detail: "10 minutos de luz natural regulan tu melatonina nocturna.")
            tip(icon: "cup.and.saucer.fill", title: "Cafeína antes de las 14:00",
                detail: "Su vida media es de 5–6 horas.")
            tip(icon: "iphone.slash", title: "Sin pantallas 45 min antes",
                detail: "Luz azul retrasa el inicio del sueño.")
        }
    }

    private func tip(icon: String, title: String, detail: String) -> some View {
        SoulCard {
            HStack(spacing: 12) {
                Image(systemName: icon).foregroundStyle(SoulTheme.Color.primary).font(.system(size: 20))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(SoulTheme.Font.card).foregroundStyle(SoulTheme.Color.textPrimary)
                    Text(detail).font(SoulTheme.Font.caption).foregroundStyle(SoulTheme.Color.textSecondary)
                }
            }
        }
    }

    private func formattedHours(_ h: Double) -> String {
        let hours = Int(h)
        let minutes = Int((h - Double(hours)) * 60)
        return String(format: "%dh %02dm", hours, minutes)
    }
}
