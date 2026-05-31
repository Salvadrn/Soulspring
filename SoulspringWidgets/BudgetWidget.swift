import WidgetKit
import SwiftUI

// MARK: - Widget

struct BudgetWidget: Widget {
    let kind = "SoulspringBudgetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BudgetProvider()) { entry in
            BudgetWidgetView(entry: entry)
                .containerBackground(SoulTheme.Palette.mist, for: .widget)
        }
        .configurationDisplayName("Presupuesto Soulspring")
        .description("Tu balance y gasto del mes de un vistazo.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Timeline

struct BudgetEntry: TimelineEntry {
    let date: Date
    let snapshot: BudgetSnapshot
}

struct BudgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BudgetEntry {
        BudgetEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (BudgetEntry) -> Void) {
        let snap = SharedSnapshotStore.load(BudgetSnapshot.self,
                                            key: SoulAppGroup.Keys.budget)
            ?? .placeholder
        completion(BudgetEntry(date: Date(), snapshot: snap))
    }

    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<BudgetEntry>) -> Void) {
        let snap = SharedSnapshotStore.load(BudgetSnapshot.self,
                                            key: SoulAppGroup.Keys.budget)
            ?? .placeholder
        let entry = BudgetEntry(date: Date(), snapshot: snap)
        let next = Calendar.current.date(byAdding: .hour, value: 2, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - View

struct BudgetWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: BudgetEntry

    var body: some View {
        switch family {
        case .systemMedium: medium
        default:            small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SALDO · \(entry.snapshot.monthLabel.uppercased())")
                .font(.system(size: 8.5, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(SoulTheme.Palette.earth.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(formatted(entry.snapshot.balance))
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundStyle(entry.snapshot.balance >= 0
                                 ? SoulTheme.Palette.moss
                                 : SoulTheme.Palette.heart)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Spacer(minLength: 4)

            HStack(spacing: 10) {
                flow(icon: "arrow.down", value: entry.snapshot.income,
                     tint: SoulTheme.Palette.moss)
                flow(icon: "arrow.up", value: entry.snapshot.expense,
                     tint: SoulTheme.Palette.heart)
            }
        }
        .padding(14)
    }

    private var medium: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("SALDO · \(entry.snapshot.monthLabel.uppercased())")
                    .font(.system(size: 8.5, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(SoulTheme.Palette.earth.opacity(0.7))
                    .lineLimit(1)

                Text(formatted(entry.snapshot.balance))
                    .font(.system(size: 30, weight: .semibold, design: .serif))
                    .foregroundStyle(entry.snapshot.balance >= 0
                                     ? SoulTheme.Palette.moss
                                     : SoulTheme.Palette.heart)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                HStack(spacing: 10) {
                    flow(icon: "arrow.down", value: entry.snapshot.income,
                         tint: SoulTheme.Palette.moss)
                    flow(icon: "arrow.up", value: entry.snapshot.expense,
                         tint: SoulTheme.Palette.heart)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(SoulTheme.Palette.earth.opacity(0.12))
                .frame(width: 0.5)

            VStack(alignment: .leading, spacing: 6) {
                Text("CATEGORÍAS")
                    .font(.system(size: 8.5, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(SoulTheme.Palette.earth.opacity(0.7))

                ForEach(entry.snapshot.topCategories) { cat in
                    HStack(spacing: 8) {
                        Image(systemName: cat.iconSystemName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: cat.tintHex))
                            .frame(width: 14)
                        Text(cat.name)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(SoulTheme.Palette.ink)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Text(shortAmount(cat.amount))
                            .font(.system(size: 11, weight: .semibold, design: .serif))
                            .foregroundStyle(SoulTheme.Palette.earth)
                    }
                    if let limit = cat.limit {
                        ProgressBar(progress: min(1, cat.amount / limit))
                            .frame(height: 3)
                            .padding(.leading, 22)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
    }

    private func flow(icon: String, value: Double, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(tint)
            Text(shortAmount(value))
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundStyle(SoulTheme.Palette.earth)
        }
    }

    private func formatted(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 0
        return "$" + (f.string(from: NSNumber(value: v)) ?? "0")
    }

    private func shortAmount(_ v: Double) -> String {
        if v >= 1_000_000 { return String(format: "$%.1fM", v / 1_000_000) }
        if v >= 10_000   { return String(format: "$%.0fk", v / 1_000) }
        if v >= 1_000    { return String(format: "$%.1fk", v / 1_000) }
        return "$" + String(Int(v))
    }
}
