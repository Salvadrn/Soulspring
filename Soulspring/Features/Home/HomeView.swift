import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var health: HealthKitManager
    @State private var isShowingMoodCheckin = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                SoulBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                        topBar
                        greeting
                        moodPrompt
                        RachaHero()
                        quickActions
                        metricsGrid
                        dailyRecommendation
                        remindersStrip
                    }
                    .padding(.horizontal, SoulTheme.Spacing.lg)
                    .padding(.top, 10)
                    .padding(.bottom, 120)  // space for floating tab bar
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $isShowingMoodCheckin) {
            MoodCheckinView()
                .presentationDetents([.medium, .large])
        }
        .task { await health.refreshAll() }
    }

    // MARK: Mood prompt — only when not checked in today

    @ViewBuilder
    private var moodPrompt: some View {
        if !store.hasCheckedInToday {
            Button { isShowingMoodCheckin = true } label: {
                HStack(spacing: 14) {
                    Text("🪷").font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("¿Cómo te sientes hoy?")
                            .font(SoulTheme.Font.card)
                            .foregroundStyle(SoulTheme.Color.textPrimary)
                        Text("3 segundos. Lo cruzamos con tu HRV y sueño.")
                            .font(SoulTheme.Font.caption)
                            .foregroundStyle(SoulTheme.Color.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .fill(SoulTheme.Color.surface))
                .overlay(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .stroke(SoulTheme.Color.divider, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .hapticOnTap()
        } else if let last = store.moodLog.first {
            HStack(spacing: 12) {
                Text(last.emoji).font(.system(size: 22))
                Text("Check-in de hoy guardado.")
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                Spacer()
                NavigationLink {
                    MoodPatternsView()
                } label: {
                    Text("Ver patrones")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.primary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                .fill(SoulTheme.Color.surface))
            .overlay(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                .stroke(SoulTheme.Color.divider, lineWidth: 0.5))
        }
    }

    // MARK: Top bar — streak pill + energy lightning

    private var topBar: some View {
        HStack {
            SoulPillStat(
                icon: "flame.fill",
                value: "\(store.streak.currentStreak)",
                tint: SoulTheme.Palette.gold
            )
            Spacer()
            SoulPillStat(
                icon: "bolt.fill",
                value: "\(Int(health.activeEnergy))",
                tint: SoulTheme.Palette.terracotta
            )
        }
        .padding(.top, 4)
    }

    // MARK: Greeting

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            SoulEyebrow(text: Self.formattedToday(),
                        color: SoulTheme.Color.textSecondary)
            Text("Hola, \(firstName)")
                .font(SoulTheme.Font.hero)
                .foregroundStyle(SoulTheme.Color.textPrimary)
        }
        .padding(.top, 8)
    }

    private var firstName: String {
        let n = store.profile.name.trimmingCharacters(in: .whitespaces)
        return n.isEmpty ? "alma" : n.components(separatedBy: " ").first ?? n
    }

    // MARK: Quick actions

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
                        title: "Reservar",
                        subtitle: "Estancia y experiencias",
                        icon: "calendar",
                        tint: SoulTheme.Palette.moss)
                }
                Link(destination: SoulLinks.foodInstagram) {
                    QuickActionTile(
                        eyebrow: "Soul Kitchen",
                        title: "Menú",
                        subtitle: SoulLinks.foodHandle,
                        icon: "fork.knife",
                        tint: SoulTheme.Palette.terracotta)
                }
            }

            NavigationLink { HydrationView() } label: {
                HydrationWidget()
            }
            .buttonStyle(.plain)
            .hapticOnTap()

            NavigationLink { FinancesView() } label: {
                FinanceHomeWidget()
            }
            .buttonStyle(.plain)
            .hapticOnTap()
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
                value: formatted(health.steps),
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
                tint: SoulTheme.Palette.lilac)
        }
    }

    private func formatted(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    // MARK: Daily recommendation

    private var dailyRecommendation: some View {
        let rec = store.recommendations.first ?? RecommendationEngine.catalog[0]
        return VStack(alignment: .leading, spacing: 10) {
            SoulSectionHeader(eyebrow: "Para ti hoy",
                              title: "Recomendación",
                              subtitle: nil)

            NavigationLink {
                RecommendationsView()
            } label: {
                SoulCard(padding: 16) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(SoulTheme.Palette.terracotta.opacity(0.18))
                                .frame(width: 52, height: 52)
                            Image(systemName: rec.interest.icon)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(SoulTheme.Palette.terracotta)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            SoulEyebrow(text: rec.category.rawValue,
                                        color: SoulTheme.Palette.terracotta)
                            Text(rec.title)
                                .font(SoulTheme.Font.card)
                                .foregroundStyle(SoulTheme.Color.textPrimary)
                                .lineLimit(1)
                            Text(rec.summary)
                                .font(SoulTheme.Font.caption)
                                .foregroundStyle(SoulTheme.Color.textSecondary)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(SoulTheme.Color.textSecondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .hapticOnTap()
        }
    }

    // MARK: Reminders strip

    private var remindersStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SoulSectionHeader(eyebrow: "Hoy",
                                  title: "Recordatorios",
                                  subtitle: nil)
                Spacer()
                NavigationLink("Ver todos") {
                    RoutineView()
                }
                .font(SoulTheme.Font.caption)
                .foregroundStyle(SoulTheme.Color.primary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(store.reminders) { reminder in
                        ReminderPill(reminder: reminder)
                    }
                }
            }
        }
    }

    private static func formattedToday() -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_MX")
        df.dateFormat = "EEEE, d MMMM"
        return df.string(from: Date()).capitalized
    }
}

// MARK: - QuickActionTile (dark)

struct QuickActionTile: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    Circle().fill(tint.opacity(0.18)).frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(tint)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(SoulTheme.Color.textSecondary)
            }
            Spacer(minLength: 2)
            VStack(alignment: .leading, spacing: 2) {
                SoulEyebrow(text: eyebrow, color: tint)
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(subtitle)
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                .fill(SoulTheme.Color.surface)
        )
    }
}

// MARK: - Reminder pill

struct ReminderPill: View {
    let reminder: SoulReminder

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(tint.opacity(0.2)).frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(reminder.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                    .lineLimit(1)
                Text(reminder.time.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(SoulTheme.Color.textSecondary)
            }
            Circle()
                .fill(reminder.isOn ? SoulTheme.Color.primary : SoulTheme.Palette.whisper)
                .frame(width: 6, height: 6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(SoulTheme.Color.surface))
    }

    private var icon: String {
        switch reminder.kind {
        case .hydration: return "drop.fill"
        case .movement:  return "figure.run"
        case .breath:    return "wind"
        case .sleep:     return "moon.stars.fill"
        case .meal:      return "fork.knife"
        }
    }
    private var tint: Color {
        switch reminder.kind {
        case .hydration: return SoulTheme.Palette.sky
        case .movement:  return SoulTheme.Palette.terracotta
        case .breath:    return SoulTheme.Palette.moss
        case .sleep:     return SoulTheme.Palette.lilac
        case .meal:      return SoulTheme.Palette.gold
        }
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
                               size: 86,
                               isAlive: engine.isGoalMetToday)

                    VStack(alignment: .leading, spacing: 6) {
                        SoulEyebrow(text: "Tu racha")
                        Text("\(engine.currentStreak) días")
                            .font(SoulTheme.Font.title)
                            .foregroundStyle(SoulTheme.Color.textPrimary)
                        Text(engine.isGoalMetToday
                             ? "Hoy ya la defendiste."
                             : "Faltan \(max(0, store.dailyGoalTarget - engine.completedToday)) hábitos.")
                            .font(SoulTheme.Font.caption)
                            .foregroundStyle(SoulTheme.Color.textSecondary)
                    }
                    Spacer()
                    ZStack {
                        SoulProgressRing(
                            progress: engine.todayProgress,
                            lineWidth: 6,
                            gradient: SoulTheme.Gradient.forest)
                        .frame(width: 52, height: 52)
                        Text("\(engine.completedToday)/\(store.dailyGoalTarget)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(SoulTheme.Color.textPrimary)
                    }
                }

                HStack(spacing: 5) {
                    ForEach(engine.lastDays(14)) { day in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(day.met
                                      ? AnyShapeStyle(SoulTheme.Gradient.flame)
                                      : AnyShapeStyle(SoulTheme.Color.surfaceElevated))
                                .frame(height: 24)
                            Text(day.date.formatted(.dateTime.weekday(.narrow)))
                                .font(.system(size: 9, weight: .bold))
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
