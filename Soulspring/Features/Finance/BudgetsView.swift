import SwiftUI

/// Per-category monthly budget caps. Editing the text field saves on blur.
struct BudgetsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                SoulBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                        SoulSectionHeader(
                            eyebrow: "Presupuestos",
                            title: "Límites mensuales",
                            subtitle: "Define cuánto quieres gastar en cada categoría.")

                        ForEach(FinanceCategory.expenseCategories) { cat in
                            BudgetRow(category: cat)
                        }
                    }
                    .padding(SoulTheme.Spacing.lg)
                }
            }
            .navigationTitle("Presupuestos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }.tint(SoulTheme.Color.primary)
                }
            }
        }
    }
}

struct BudgetRow: View {
    @EnvironmentObject private var store: AppStore
    let category: FinanceCategory

    @State private var value: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        SoulCard {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: category.tintHex).opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: category.icon)
                        .foregroundStyle(Color(hex: category.tintHex))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
                        .font(SoulTheme.Font.card)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Text("Límite mensual")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Text("$")
                        .font(SoulTheme.Font.card)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                    TextField("0", text: $value)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .font(SoulTheme.Font.card)
                        .focused($isFocused)
                        .frame(width: 100)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(RoundedRectangle(cornerRadius: 10)
                            .fill(SoulTheme.Palette.cream.opacity(0.6)))
                        .onSubmit { commit() }
                        .onChange(of: isFocused) { _, focused in
                            if !focused { commit() }
                        }
                }
            }
        }
        .onAppear {
            if let existing = store.budget.limit(for: category) {
                value = String(Int(existing))
            }
        }
    }

    private func commit() {
        let cleaned = value.replacingOccurrences(of: ",", with: "")
        let n = Double(cleaned) ?? 0
        store.setBudget(n, for: category)
    }
}
