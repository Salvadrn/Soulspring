import SwiftUI
import Charts

/// Personal finance manager — income and expenses for the current month,
/// with automatic entries from in-app Soulspring flows (stays, experiences,
/// gift cards, room service). Month picker at top, hero balance card,
/// daily spend chart, category breakdown, transaction list.
struct FinancesView: View {
    @EnvironmentObject private var store: AppStore
    @State private var month: Date = Date()
    @State private var isAdding: Bool = false
    @State private var editing: FinanceTransaction? = nil
    @State private var isShowingBudgets: Bool = false

    private var monthTxs: [FinanceTransaction] {
        FinanceReport.filter(store.transactions, in: month)
            .sorted { $0.date > $1.date }
    }

    private var totals: (income: Double, expense: Double) {
        FinanceReport.totals(monthTxs)
    }

    private var balance: Double { totals.income - totals.expense }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                header
                monthPicker
                balanceCard
                flowsRow
                trendChart
                categoriesCard
                transactionsSection
            }
            .padding(SoulTheme.Spacing.lg)
        }
        .background(SoulBackground())
        .navigationTitle("Finanzas")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        isShowingBudgets = true
                    } label: { Label("Presupuestos", systemImage: "target") }
                    Button {
                        isAdding = true
                    } label: { Label("Nuevo movimiento", systemImage: "plus") }
                } label: { Image(systemName: "ellipsis.circle") }
                .tint(SoulTheme.Color.primary)
            }
        }
        .overlay(alignment: .bottomTrailing) { fab }
        .sheet(isPresented: $isAdding) {
            AddTransactionSheet(initial: nil) { store.addTransaction($0) }
        }
        .sheet(item: $editing) { tx in
            AddTransactionSheet(initial: tx) { store.updateTransaction($0) }
        }
        .sheet(isPresented: $isShowingBudgets) { BudgetsView() }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            SoulEyebrow(text: "Gestor de dinero")
            Text("Tus ingresos y egresos.")
                .font(SoulTheme.Font.title)
                .foregroundStyle(SoulTheme.Color.textPrimary)
        }
    }

    // MARK: Month picker

    private var monthPicker: some View {
        HStack(spacing: 12) {
            Button { shiftMonth(-1) } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(SoulTheme.Color.primary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(SoulTheme.Color.surface))
                    .overlay(Circle().stroke(SoulTheme.Color.divider, lineWidth: 0.5))
            }

            VStack(spacing: 2) {
                Text(monthLabel.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                Text(yearLabel)
                    .font(SoulTheme.Font.card)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
            }
            .frame(maxWidth: .infinity)

            Button { shiftMonth(1) } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(SoulTheme.Color.primary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(SoulTheme.Color.surface))
                    .overlay(Circle().stroke(SoulTheme.Color.divider, lineWidth: 0.5))
            }
        }
    }

    private func shiftMonth(_ delta: Int) {
        if let d = Calendar.current.date(byAdding: .month, value: delta, to: month) {
            month = d
        }
    }

    private var monthLabel: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_MX")
        df.dateFormat = "LLLL"
        return df.string(from: month)
    }
    private var yearLabel: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_MX")
        df.dateFormat = "yyyy"
        return df.string(from: month)
    }

    // MARK: Balance card

    private var balanceCard: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: SoulTheme.Radius.lg)
                .fill(balance >= 0 ? SoulTheme.Gradient.forest : SoulTheme.Gradient.heart)

            VStack(alignment: .leading, spacing: 10) {
                Text("SALDO DEL MES")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2.5)
                    .foregroundStyle(.white.opacity(0.85))

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(formatCurrency(balance))
                        .font(SoulTheme.Font.display(40, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("MXN")
                        .font(SoulTheme.Font.unit)
                        .foregroundStyle(.white.opacity(0.85))
                }

                HStack(spacing: 18) {
                    miniStat(icon: "arrow.down.circle.fill",
                             label: "Ingresos",
                             value: totals.income)
                    miniStat(icon: "arrow.up.circle.fill",
                             label: "Egresos",
                             value: totals.expense)
                }
            }
            .padding(SoulTheme.Spacing.lg)
        }
        .shadow(color: SoulTheme.Palette.earth.opacity(0.15), radius: 18, y: 10)
    }

    private func miniStat(icon: String, label: String, value: Double) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.white.opacity(0.9))
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.85))
                Text(formatCurrency(value))
                    .font(SoulTheme.Font.card)
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: Flows row

    private var flowsRow: some View {
        HStack(spacing: 12) {
            flowCard(title: "Ingresos",
                     amount: totals.income,
                     icon: "arrow.down.circle.fill",
                     tint: SoulTheme.Palette.moss)
            flowCard(title: "Egresos",
                     amount: totals.expense,
                     icon: "arrow.up.circle.fill",
                     tint: SoulTheme.Palette.heart)
        }
    }

    private func flowCard(title: String, amount: Double, icon: String, tint: Color) -> some View {
        SoulCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon).foregroundStyle(tint)
                    SoulEyebrow(text: title, color: tint)
                    Spacer()
                }
                Text(formatCurrency(amount))
                    .font(SoulTheme.Font.display(22, weight: .semibold))
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
    }

    // MARK: Trend chart

    private var trendChart: some View {
        let days = FinanceReport.dailyExpenses(store.transactions, in: month)
        return SoulCard(padding: SoulTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 10) {
                SoulSectionHeader(eyebrow: "Gasto diario",
                                  title: "Tendencia del mes",
                                  subtitle: nil)
                Chart {
                    ForEach(days, id: \.0) { (date, value) in
                        BarMark(
                            x: .value("Día", date, unit: .day),
                            y: .value("Gasto", value)
                        )
                        .foregroundStyle(SoulTheme.Gradient.sunset)
                        .cornerRadius(4)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 5)) { _ in
                        AxisGridLine().foregroundStyle(SoulTheme.Color.divider)
                        AxisValueLabel(format: .dateTime.day())
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
                .frame(height: 170)
            }
        }
    }

    // MARK: Categories

    private var categoriesCard: some View {
        let data = FinanceReport.byCategory(monthTxs, type: .expense)
        return SoulCard {
            VStack(alignment: .leading, spacing: 12) {
                SoulSectionHeader(eyebrow: "Egresos por categoría",
                                  title: "A dónde va tu dinero",
                                  subtitle: nil)
                if data.isEmpty {
                    Text("Aún no hay egresos este mes.")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                ForEach(data, id: \.0) { (cat, value) in
                    CategoryBar(
                        category: cat,
                        amount: value,
                        total: totals.expense,
                        limit: store.budget.limit(for: cat)
                    )
                }
            }
        }
    }

    // MARK: Transactions

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoulSectionHeader(eyebrow: "Movimientos",
                              title: "Lo que pasó este mes",
                              subtitle: nil)
            if monthTxs.isEmpty {
                SoulCard {
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.system(size: 26))
                            .foregroundStyle(SoulTheme.Color.primarySoft)
                        Text("Sin movimientos")
                            .font(SoulTheme.Font.card)
                            .foregroundStyle(SoulTheme.Color.textPrimary)
                        Text("Toca + para agregar tu primer ingreso o egreso.")
                            .font(SoulTheme.Font.caption)
                            .foregroundStyle(SoulTheme.Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            ForEach(groupedByDay, id: \.0) { (day, items) in
                VStack(alignment: .leading, spacing: 8) {
                    Text(dayLabel(day).uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.4)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                    VStack(spacing: 8) {
                        ForEach(items) { tx in
                            Button { editing = tx } label: {
                                TransactionRow(tx: tx)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var groupedByDay: [(Date, [FinanceTransaction])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: monthTxs) { cal.startOfDay(for: $0.date) }
        return dict.sorted { $0.key > $1.key }
    }

    private func dayLabel(_ day: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_MX")
        df.dateFormat = "EEEE d 'de' MMMM"
        return df.string(from: day)
    }

    // MARK: Floating add button

    private var fab: some View {
        Button { isAdding = true } label: {
            ZStack {
                Circle().fill(SoulTheme.Gradient.forest).frame(width: 58, height: 58)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            .shadow(color: SoulTheme.Palette.moss.opacity(0.35), radius: 14, y: 8)
        }
        .padding(SoulTheme.Spacing.lg)
    }

    // MARK: Helpers

    private func formatCurrency(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 0
        f.groupingSeparator = ","
        return "$" + (f.string(from: NSNumber(value: v)) ?? "0")
    }
}

// MARK: - Transaction row

struct TransactionRow: View {
    let tx: FinanceTransaction

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: tx.category.tintHex).opacity(0.18))
                    .frame(width: 42, height: 42)
                Image(systemName: tx.category.icon)
                    .foregroundStyle(Color(hex: tx.category.tintHex))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(tx.title)
                    .font(SoulTheme.Font.card)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(tx.category.rawValue)
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                    if tx.source != .manual {
                        Text("· \(tx.source.rawValue)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(SoulTheme.Palette.gold)
                    }
                }
            }
            Spacer()
            Text(amountString)
                .font(SoulTheme.Font.card)
                .foregroundStyle(tx.type == .income
                                 ? SoulTheme.Palette.moss
                                 : SoulTheme.Palette.heart)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
            .fill(SoulTheme.Color.surface))
        .overlay(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
            .stroke(SoulTheme.Color.divider, lineWidth: 0.5))
    }

    private var amountString: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 0
        let str = f.string(from: NSNumber(value: tx.amountMXN)) ?? "0"
        return (tx.type == .income ? "+$" : "−$") + str
    }
}

// MARK: - Category bar

struct CategoryBar: View {
    let category: FinanceCategory
    let amount: Double
    let total: Double
    let limit: Double?

    private var percent: Double {
        guard total > 0 else { return 0 }
        return min(1, amount / total)
    }

    private var budgetRatio: Double? {
        guard let limit, limit > 0 else { return nil }
        return amount / limit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundStyle(Color(hex: category.tintHex))
                    .frame(width: 20)
                Text(category.rawValue)
                    .font(SoulTheme.Font.bodyText)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                Spacer()
                Text(formatted(amount))
                    .font(SoulTheme.Font.card)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(SoulTheme.Palette.sand).frame(height: 7)
                    Capsule()
                        .fill(Color(hex: category.tintHex))
                        .frame(width: geo.size.width * percent, height: 7)
                }
            }
            .frame(height: 7)
            if let ratio = budgetRatio, let limit {
                HStack(spacing: 6) {
                    Image(systemName: ratio >= 1 ? "exclamationmark.triangle.fill"
                                                 : "target")
                        .font(.system(size: 10))
                        .foregroundStyle(ratio >= 1 ? SoulTheme.Palette.heart
                                                    : SoulTheme.Color.textSecondary)
                    Text("\(formatted(amount)) / \(formatted(limit)) · \(Int(ratio * 100))%")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(ratio >= 1 ? SoulTheme.Palette.heart
                                                    : SoulTheme.Color.textSecondary)
                }
            }
        }
    }

    private func formatted(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 0
        return "$" + (f.string(from: NSNumber(value: v)) ?? "0")
    }
}
