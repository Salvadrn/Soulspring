import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var health: HealthKitManager

    var body: some View {
        NavigationStack {
            ZStack {
                SoulBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: SoulTheme.Spacing.lg) {
                        greeting

                        RachaHero()

                        quickActions

                        metricsGrid

                        dailyRecommendation

                        remindersStrip
                    }
                    .padding(.horizontal, SoulTheme.Spacing.lg)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
        .task { await health.refreshAll() }
    }

    // MARK: Greeting

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 6) {
            SoulEyebrow(text: Self.formattedToday())
            Text("Hola, \(firstName).")
                .font(SoulTheme.Font.hero)
                .foregroundStyle(SoulTheme.Color.textPrimary)
            Text("Tu santuario te recibe. Así va tu día.")
                .font(SoulTheme.Font.bodyText)
                .foregroundStyle(SoulTheme.Color.textSecondary)
        }
        .padding(.top, 20)
    }

    private var firstName: String {
        let n = store.profile.name.trimmingCharacters(in: .whitespaces)
        return n.isEmpty ? "alma" : n.components(separatedBy: " ").first ?? n
    }

    // MARK: Quick actions (external links)

    private var quickActions: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                NavigationLink {
                    BookingView()
                        .navigationTitle("Reservar")
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    QuickActionTile(
                        eyebrow: "Santuario",
                        title: "Reservar estancia",
                        subtitle: "Fechas disponibles ahora",
                        icon: "calendar",
                        gradient: SoulTheme.Gradient.forest)
                }
                Link(destination: SoulLinks.foodInstagram) {
                    QuickActionTile(
                        eyebrow: "Soul Kitchen",
                        title: "Menú del día",
                        subtitle: SoulLinks.foodHandle,
                        icon: "fork.knife",
                        gradient: SoulTheme.Gradient.sunset)
                }
            }

            NavigationLink { HydrationView() } label: {
                HydrationWidget()
            }
            .buttonStyle(.plain)

            NavigationLink { FinancesView() } label: {
                FinanceHomeWidget()
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Metrics

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)],
                  spacing: 12) {
            SoulMetricTile(
                eyebrow: "Ritmo cardíaco",
                value: health.heartRate.map { "\(Int($0))" } ?? "—",
                unit: "bpm",
                icon: "heart.fill",
                tint: SoulTheme.Color.heart)

            SoulMetricTile(
                eyebrow: "Pasos hoy",
                value: "\(health.steps)",
                unit: "pasos",
                icon: "figure.walk",
                tint: SoulTheme.Palette.moss)

            SoulMetricTile(
                eyebrow: "Energía",
                value: "\(Int(health.activeEnergy))",
                unit: "kcal",
                icon: "flame.fill",
                tint: SoulTheme.Palette.terracotta)

            SoulMetricTile(
                eyebrow: "Sueño",
                value: String(format: "%.1f", health.sleepHours),
                unit: "hrs",
                icon: "moon.stars.fill",
                tint: SoulTheme.Palette.earth)
        }
    }

    // MARK: Daily recommendation

    private var dailyRecommendation: some View {
        let rec = store.recommendations.first ?? RecommendationEngine.catalog[0]
        return VStack(alignment: .leading, spacing: 12) {
            SoulSectionHeader(eyebrow: "Para ti hoy",
                              title: "Recomendación del día",
                              subtitle: nil)

            NavigationLink {
                RecommendationsView()
            } label: {
                SoulCard {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                                .fill(SoulTheme.Gradient.sunset)
                                .frame(width: 64, height: 64)
                            Image(systemName: rec.interest.icon)
                                .font(.system(size: 26))
                                .foregroundStyle(SoulTheme.Color.backgroundWarm)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            SoulEyebrow(text: rec.category.rawValue)
                            Text(rec.title)
                                .font(SoulTheme.Font.card)
                                .foregroundStyle(SoulTheme.Color.textPrimary)
                            Text(rec.summary)
                                .font(SoulTheme.Font.caption)
                                .foregroundStyle(SoulTheme.Color.textSecondary)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(SoulTheme.Color.textSecondary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Reminders strip

    private var remindersStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SoulSectionHeader(eyebrow: "Hoy",
                                  title: "Recordatorios",
                                  subtitle: nil)
                Spacer()
                NavigationLink("Ver todos") {
                    SanctuaryView(initialTab: .reminders)
                }
                .font(SoulTheme.Font.caption)
                .foregroundStyle(SoulTheme.Color.primary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(store.reminders) { reminder in
                        HStack(spacing: 10) {
                            Image(systemName: iconFor(reminder.kind))
                                .foregroundStyle(tintFor(reminder.kind))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(reminder.title)
                                    .font(SoulTheme.Font.caption)
                                    .foregroundStyle(SoulTheme.Color.textPrimary)
                                Text(reminder.time.formatted(date: .omitted, time: .shortened))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(SoulTheme.Color.textSecondary)
                            }
                            Circle()
                                .fill(reminder.isOn ? SoulTheme.Color.primary : SoulTheme.Color.divider)
                                .frame(width: 8, height: 8)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                                .fill(SoulTheme.Color.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                                .stroke(SoulTheme.Color.divider, lineWidth: 0.5)
                        )
                    }
                }
            }
        }
    }

    private func iconFor(_ kind: SoulReminder.Kind) -> String {
        switch kind {
        case .hydration: return "drop.fill"
        case .movement:  return "figure.run"
        case .breath:    return "wind"
        case .sleep:     return "moon.stars.fill"
        case .meal:      return "fork.knife"
        }
    }

    private func tintFor(_ kind: SoulReminder.Kind) -> Color {
        switch kind {
        case .hydration: return SoulTheme.Palette.sky
        case .movement:  return SoulTheme.Palette.terracotta
        case .breath:    return SoulTheme.Palette.sage
        case .sleep:     return SoulTheme.Palette.earth
        case .meal:      return SoulTheme.Palette.gold
        }
    }

    private static func formattedToday() -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_MX")
        df.dateFormat = "EEEE, d MMMM"
        return df.string(from: Date()).capitalized
    }
}

// MARK: - Quick action tile

struct QuickActionTile: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(SoulTheme.Color.backgroundWarm)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.white.opacity(0.18)))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SoulTheme.Color.backgroundWarm.opacity(0.85))
            }
            Spacer(minLength: 6)
            VStack(alignment: .leading, spacing: 4) {
                Text(eyebrow.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(SoulTheme.Color.backgroundWarm.opacity(0.85))
                Text(title)
                    .font(SoulTheme.Font.display(20, weight: .regular))
                    .foregroundStyle(SoulTheme.Color.backgroundWarm)
                Text(subtitle)
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.backgroundWarm.opacity(0.85))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: SoulTheme.Radius.lg)
                .fill(gradient)
        )
        .shadow(color: SoulTheme.Palette.earth.opacity(0.10), radius: 14, y: 8)
    }
}

// MARK: - Racha Hero

struct RachaHero: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        let engine = store.streak
        SoulCard(padding: SoulTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 16) {
                    RachaFlame(days: engine.currentStreak,
                               size: 96,
                               isAlive: engine.isGoalMetToday)

                    VStack(alignment: .leading, spacing: 6) {
                        SoulEyebrow(text: "Tu racha")
                        Text("\(engine.currentStreak) días")
                            .font(SoulTheme.Font.title)
                            .foregroundStyle(SoulTheme.Color.textPrimary)
                        Text(engine.isGoalMetToday
                             ? "Hoy ya defendiste tu racha."
                             : "Completa \(max(0, store.dailyGoalTarget - engine.completedToday)) hábitos más para no romperla.")
                            .font(SoulTheme.Font.caption)
                            .foregroundStyle(SoulTheme.Color.textSecondary)
                    }
                    Spacer()
                    ZStack {
                        SoulProgressRing(
                            progress: engine.todayProgress,
                            lineWidth: 8,
                            gradient: SoulTheme.Gradient.forest
                        )
                        .frame(width: 58, height: 58)
                        VStack(spacing: 0) {
                            Text("\(engine.completedToday)/\(store.dailyGoalTarget)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(SoulTheme.Color.textPrimary)
                        }
                    }
                }

                HStack(spacing: 6) {
                    ForEach(engine.lastDays(14)) { day in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(day.met
                                      ? AnyShapeStyle(SoulTheme.Gradient.forest)
                                      : AnyShapeStyle(SoulTheme.Palette.sand))
                                .frame(height: 26)
                            Text(day.date.formatted(.dateTime.weekday(.narrow)))
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(day.isToday
                                                 ? SoulTheme.Color.primary
                                                 : SoulTheme.Color.textSecondary)
                        }
                    }
                }
            }
        }
    }
}
