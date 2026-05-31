import WidgetKit
import SwiftUI

// MARK: - Widget

struct RoutinesWidget: Widget {
    let kind = "SoulspringRoutinesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RoutinesProvider()) { entry in
            RoutinesWidgetView(entry: entry)
                .containerBackground(SoulTheme.Gradient.dawn, for: .widget)
        }
        .configurationDisplayName("Rachas Soulspring")
        .description("Tu racha de hábitos y las metas del día.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Timeline

struct RoutinesEntry: TimelineEntry {
    let date: Date
    let snapshot: RoutinesSnapshot
}

struct RoutinesProvider: TimelineProvider {
    func placeholder(in context: Context) -> RoutinesEntry {
        RoutinesEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (RoutinesEntry) -> Void) {
        let snap = SharedSnapshotStore.load(RoutinesSnapshot.self,
                                            key: SoulAppGroup.Keys.routines)
            ?? .placeholder
        completion(RoutinesEntry(date: Date(), snapshot: snap))
    }

    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<RoutinesEntry>) -> Void) {
        let snap = SharedSnapshotStore.load(RoutinesSnapshot.self,
                                            key: SoulAppGroup.Keys.routines)
            ?? .placeholder
        let entry = RoutinesEntry(date: Date(), snapshot: snap)
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Views

struct RoutinesWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: RoutinesEntry

    var body: some View {
        switch family {
        case .systemMedium: medium
        default:            small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("RACHA")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(SoulTheme.Palette.earth.opacity(0.7))
                Spacer()
                Image(systemName: "leaf.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(SoulTheme.Palette.moss)
            }

            WidgetFlame(days: entry.snapshot.streakDays,
                        alive: entry.snapshot.goalMet)
                .frame(height: 62)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(entry.snapshot.completedToday)/\(entry.snapshot.goalTarget)")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(SoulTheme.Palette.ink)
                Text("hoy")
                    .font(.system(size: 11, design: .serif))
                    .italic()
                    .foregroundStyle(SoulTheme.Palette.earth)
            }

            ProgressBar(progress: entry.snapshot.progress)
                .frame(height: 4)
        }
        .padding(14)
    }

    private var medium: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("RACHA")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(SoulTheme.Palette.earth.opacity(0.7))
                    Spacer()
                }

                WidgetFlame(days: entry.snapshot.streakDays,
                            alive: entry.snapshot.goalMet)
                    .frame(height: 70)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(entry.snapshot.completedToday)/\(entry.snapshot.goalTarget)")
                        .font(.system(size: 22, weight: .semibold, design: .serif))
                        .foregroundStyle(SoulTheme.Palette.ink)
                    Text("hábitos hoy")
                        .font(.system(size: 11, design: .serif))
                        .italic()
                        .foregroundStyle(SoulTheme.Palette.earth)
                }

                ProgressBar(progress: entry.snapshot.progress)
                    .frame(height: 4)
            }
            .frame(maxWidth: 140, alignment: .leading)

            Rectangle()
                .fill(SoulTheme.Palette.earth.opacity(0.12))
                .frame(width: 0.5)

            VStack(alignment: .leading, spacing: 6) {
                Text("HOY")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(SoulTheme.Palette.earth.opacity(0.7))

                ForEach(entry.snapshot.habits.prefix(4)) { h in
                    HStack(spacing: 8) {
                        Image(systemName: h.done ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(h.done
                                             ? SoulTheme.Palette.moss
                                             : SoulTheme.Palette.earth.opacity(0.4))
                            .font(.system(size: 12))
                        Text(h.title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(h.done
                                             ? SoulTheme.Palette.ink
                                             : SoulTheme.Palette.earth)
                            .lineLimit(1)
                            .strikethrough(h.done, color: SoulTheme.Palette.earth.opacity(0.4))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
    }
}

// MARK: - Shared bits

struct WidgetFlame: View {
    let days: Int
    let alive: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                FlameShape()
                    .fill(LinearGradient(
                        colors: alive
                            ? [SoulTheme.Palette.terracotta, SoulTheme.Palette.gold]
                            : [SoulTheme.Palette.sand, SoulTheme.Palette.cream],
                        startPoint: .top,
                        endPoint: .bottom))
                    .frame(width: 42, height: 50)
            }
            VStack(alignment: .leading, spacing: -2) {
                Text("\(days)")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(SoulTheme.Palette.earth)
                Text(days == 1 ? "día" : "días")
                    .font(.system(size: 11, design: .serif))
                    .italic()
                    .foregroundStyle(SoulTheme.Palette.earth.opacity(0.8))
            }
        }
    }
}

struct ProgressBar: View {
    let progress: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(SoulTheme.Palette.sand)
                Capsule()
                    .fill(LinearGradient(
                        colors: [SoulTheme.Palette.moss, SoulTheme.Palette.sage],
                        startPoint: .leading,
                        endPoint: .trailing))
                    .frame(width: geo.size.width * max(0.02, progress))
            }
        }
    }
}
