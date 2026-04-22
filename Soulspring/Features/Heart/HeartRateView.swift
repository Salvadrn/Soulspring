import SwiftUI
import Charts

/// "Mide tu salud" — detailed cardiovascular study pulled from HealthKit
/// (and Apple Watch by extension). Shows heart rate trend, resting HR, HRV
/// and breath-coherence practice.
struct HeartRateView: View {
    @EnvironmentObject private var health: HealthKitManager
    @EnvironmentObject private var store: AppStore
    @State private var breatheTick: Double = 0
    @State private var isBreathing = false

    var body: some View {
        NavigationStack {
            ZStack {
                SoulBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: SoulTheme.Spacing.lg) {
                        header
                        liveCard
                        shortcutsRow
                        wellnessShortcuts
                        chartCard
                        statsGrid
                        breathCard
                        connectionCard
                    }
                    .padding(.horizontal, SoulTheme.Spacing.lg)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Salud")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await health.refreshAll() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .tint(SoulTheme.Color.primary)
                }
            }
        }
        .task { await health.refreshAll() }
    }

    // MARK: Wellness shortcuts (mood + audios)

    private var wellnessShortcuts: some View {
        HStack(spacing: 12) {
            NavigationLink {
                MoodPatternsView()
            } label: {
                shortcutTile(
                    eyebrow: "Mood",
                    title: "Patrones",
                    subtitle: store.moodLog.isEmpty
                        ? "Empieza tu check-in"
                        : "\(store.moodLog.count) check-ins",
                    icon: "chart.line.uptrend.xyaxis",
                    tint: SoulTheme.Palette.sky
                )
            }
            .buttonStyle(.plain)
            .hapticOnTap()

            NavigationLink {
                AudioLibraryView()
            } label: {
                shortcutTile(
                    eyebrow: "Audios",
                    title: "Biblioteca",
                    subtitle: "Meditación · breath",
                    icon: "headphones",
                    tint: SoulTheme.Palette.lilac
                )
            }
            .buttonStyle(.plain)
            .hapticOnTap()
        }
    }

    private func shortcutTile(eyebrow: String, title: String,
                              subtitle: String, icon: String,
                              tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Circle().fill(tint.opacity(0.18))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                SoulEyebrow(text: eyebrow, color: tint)
                Text(title)
                    .font(SoulTheme.Font.card)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                Text(subtitle)
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                .fill(SoulTheme.Color.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                .stroke(SoulTheme.Color.divider, lineWidth: 0.5)
        )
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            SoulEyebrow(text: "Mide tu salud")
            Text("Tu corazón, visible.")
                .font(SoulTheme.Font.hero)
                .foregroundStyle(SoulTheme.Color.textPrimary)
            Text("Datos vivos desde Apple Health y tu Apple Watch.")
                .font(SoulTheme.Font.bodyText)
                .foregroundStyle(SoulTheme.Color.textSecondary)
        }
        .padding(.top, 8)
    }

    // MARK: Shortcuts to Sleep + Workouts

    private var shortcutsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                NavigationLink { BiologicalAgeView() } label: {
                    shortcut(icon: "hourglass",
                             title: "Edad biológica",
                             subtitle: "Calcular",
                             tint: SoulTheme.Palette.moss)
                }
                NavigationLink { LabsView() } label: {
                    shortcut(icon: "doc.text.magnifyingglass",
                             title: "Laboratorios",
                             subtitle: "Subir PDF",
                             tint: SoulTheme.Palette.gold)
                }
                NavigationLink { SleepDetailView() } label: {
                    shortcut(icon: "moon.stars.fill",
                             title: "Sueño",
                             subtitle: String(format: "%.1f h", health.sleepHours),
                             tint: SoulTheme.Palette.earth)
                }
                NavigationLink { WorkoutsView() } label: {
                    shortcut(icon: "figure.run",
                             title: "Entrenamiento",
                             subtitle: "\(Workout.catalog.count) rutinas",
                             tint: SoulTheme.Palette.terracotta)
                }
                NavigationLink { HydrationView() } label: {
                    shortcut(icon: "drop.fill",
                             title: "Agua",
                             subtitle: "Hidrátate",
                             tint: SoulTheme.Palette.sky)
                }
            }
        }
    }

    private func shortcut(icon: String, title: String, subtitle: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Circle().fill(tint.opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: icon).foregroundStyle(tint)
            }
            Text(title)
                .font(SoulTheme.Font.card)
                .foregroundStyle(SoulTheme.Color.textPrimary)
            Text(subtitle)
                .font(SoulTheme.Font.caption)
                .foregroundStyle(SoulTheme.Color.textSecondary)
        }
        .frame(width: 140, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
            .fill(SoulTheme.Color.surface))
        .overlay(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
            .stroke(SoulTheme.Color.divider, lineWidth: 0.5))
    }

    // MARK: Live heart card

    private var liveCard: some View {
        SoulCard(padding: SoulTheme.Spacing.lg) {
            HStack(alignment: .center, spacing: SoulTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: 6) {
                    SoulEyebrow(text: "Ahora", color: SoulTheme.Color.heart)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(health.heartRate.map { "\(Int($0))" } ?? "—")
                            .font(SoulTheme.Font.display(72, weight: .semibold))
                            .foregroundStyle(SoulTheme.Color.heart)
                        Text("bpm")
                            .font(SoulTheme.Font.unit)
                            .foregroundStyle(SoulTheme.Color.textSecondary)
                    }
                    Text(health.isAuthorized ? "Sincronizado con Apple Health" : "Datos de ejemplo · conecta Salud")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
                Spacer()
                PulsingHeart()
            }
        }
    }

    // MARK: Chart

    private var chartCard: some View {
        SoulCard(padding: SoulTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 10) {
                SoulSectionHeader(eyebrow: "Hoy",
                                  title: "Ritmo del día",
                                  subtitle: "Lecturas cada 15 minutos.")
                Chart(health.heartRateSeries) { sample in
                    LineMark(
                        x: .value("Hora", sample.date),
                        y: .value("bpm", sample.bpm)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(SoulTheme.Gradient.heart)

                    AreaMark(
                        x: .value("Hora", sample.date),
                        y: .value("bpm", sample.bpm)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [SoulTheme.Color.heart.opacity(0.3),
                                     SoulTheme.Color.heart.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom))
                }
                .chartYScale(domain: 40...160)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                        AxisGridLine().foregroundStyle(SoulTheme.Color.divider)
                        AxisValueLabel(format: .dateTime.hour())
                            .foregroundStyle(SoulTheme.Color.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(SoulTheme.Color.divider)
                        AxisValueLabel()
                            .foregroundStyle(SoulTheme.Color.textSecondary)
                    }
                }
                .frame(height: 200)
            }
        }
    }

    // MARK: Stats

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)],
                  spacing: 12) {
            SoulMetricTile(
                eyebrow: "HR en reposo",
                value: health.restingHeartRate.map { "\(Int($0))" } ?? "—",
                unit: "bpm",
                icon: "bed.double.fill",
                tint: SoulTheme.Palette.moss)
            SoulMetricTile(
                eyebrow: "HRV",
                value: health.hrv.map { "\(Int($0))" } ?? "—",
                unit: "ms",
                icon: "waveform.path.ecg",
                tint: SoulTheme.Palette.terracotta)
            SoulMetricTile(
                eyebrow: "Sueño",
                value: String(format: "%.1f", health.sleepHours),
                unit: "hrs",
                icon: "moon.stars.fill",
                tint: SoulTheme.Palette.earth)
            SoulMetricTile(
                eyebrow: "Pasos",
                value: "\(health.steps)",
                unit: "pasos",
                icon: "figure.walk",
                tint: SoulTheme.Palette.sage)
        }
    }

    // MARK: Breath practice

    private var breathCard: some View {
        SoulCard(padding: SoulTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 16) {
                SoulSectionHeader(
                    eyebrow: "Coherencia cardíaca",
                    title: "Respiración 5 – 5",
                    subtitle: "5 segundos inhalando, 5 exhalando. Baja tu HRV.")

                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(SoulTheme.Gradient.breath)
                            .frame(width: 160, height: 160)
                            .scaleEffect(isBreathing ? 1.15 : 0.78)
                            .animation(
                                isBreathing
                                ? .easeInOut(duration: 5).repeatForever(autoreverses: true)
                                : .easeOut(duration: 0.4),
                                value: isBreathing)
                        Text(isBreathing ? "Inhala / Exhala" : "Comenzar")
                            .font(SoulTheme.Font.card)
                            .foregroundStyle(SoulTheme.Color.textPrimary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)

                if isBreathing {
                    Button {
                        store.recordMindfulnessSession()
                        withAnimation { isBreathing.toggle() }
                    } label: {
                        Text("Terminar")
                    }
                    .buttonStyle(SoulSecondaryButtonStyle())
                } else {
                    Button {
                        withAnimation { isBreathing.toggle() }
                    } label: {
                        Text("Empezar práctica de 5 min")
                    }
                    .buttonStyle(SoulPrimaryButtonStyle())
                }
            }
        }
    }

    // MARK: Connection card

    private var connectionCard: some View {
        SoulCard {
            HStack(spacing: 14) {
                Image(systemName: "applewatch.watchface")
                    .font(.system(size: 28))
                    .foregroundStyle(SoulTheme.Color.primary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Conexión por app o Watch")
                        .font(SoulTheme.Font.card)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Text(health.isAuthorized
                         ? "Recibiendo datos de Apple Health."
                         : "Permite acceso a Salud para traer tu ritmo cardíaco real.")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
                Spacer()
                if !health.isAuthorized {
                    Button("Conectar") {
                        Task { await health.requestAuthorization() }
                    }
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.primary)
                }
            }
        }
    }
}

// MARK: - Pulsing heart

private struct PulsingHeart: View {
    @State private var pulse = false
    var body: some View {
        ZStack {
            Circle()
                .fill(SoulTheme.Color.heart.opacity(0.15))
                .frame(width: 100, height: 100)
                .scaleEffect(pulse ? 1.15 : 0.9)
            Circle()
                .fill(SoulTheme.Gradient.heart)
                .frame(width: 72, height: 72)
                .scaleEffect(pulse ? 1.05 : 0.95)
            Image(systemName: "heart.fill")
                .font(.system(size: 30))
                .foregroundStyle(.white)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Type-erased ButtonStyle for conditional styles

private struct AnyButtonStyleAdapter<S: ButtonStyle>: ButtonStyle {
    let style: S
    func makeBody(configuration: Configuration) -> some View {
        style.makeBody(configuration: configuration)
    }
}
