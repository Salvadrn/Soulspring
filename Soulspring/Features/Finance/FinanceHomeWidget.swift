import SwiftUI

/// Small card for the Home dashboard summarising this month's balance.
/// Taps into the full FinancesView.
struct FinanceHomeWidget: View {
    @EnvironmentObject private var store: AppStore

    private var totals: (income: Double, expense: Double) {
        let month = FinanceReport.filter(store.transactions, in: Date())
        return FinanceReport.totals(month)
    }

    private var balance: Double { totals.income - totals.expense }

    var body: some View {
        SoulCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(balance >= 0
                              ? SoulTheme.Palette.moss.opacity(0.15)
                              : SoulTheme.Palette.heart.opacity(0.15))
                        .frame(width: 54, height: 54)
                    Image(systemName: balance >= 0 ? "chart.line.uptrend.xyaxis"
                                                   : "chart.line.downtrend.xyaxis")
                        .foregroundStyle(balance >= 0
                                         ? SoulTheme.Palette.moss
                                         : SoulTheme.Palette.heart)
                        .font(.system(size: 22))
                }
                VStack(alignment: .leading, spacing: 3) {
                    SoulEyebrow(text: "Finanzas · este mes")
                    Text(formatted(balance))
                        .font(SoulTheme.Font.display(22, weight: .semibold))
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    HStack(spacing: 10) {
                        Label(formatted(totals.income), systemImage: "arrow.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(SoulTheme.Palette.moss)
                        Label(formatted(totals.expense), systemImage: "arrow.up")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(SoulTheme.Palette.heart)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SoulTheme.Color.textSecondary)
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
