import SwiftUI

/// Manual income / expense entry. Used both to create new transactions and
/// to edit existing ones (when `initial != nil`).
struct AddTransactionSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let initial: FinanceTransaction?
    let onSave: (FinanceTransaction) -> Void

    @State private var type: FinanceTransaction.Kind = .expense
    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var category: FinanceCategory = .comida
    @State private var date: Date = Date()
    @State private var notes: String = ""

    init(initial: FinanceTransaction?,
         onSave: @escaping (FinanceTransaction) -> Void) {
        self.initial = initial
        self.onSave = onSave
        _type     = State(initialValue: initial?.type ?? .expense)
        _title    = State(initialValue: initial?.title ?? "")
        _amount   = State(initialValue: initial.map { String(format: "%.2f", $0.amountMXN) } ?? "")
        _category = State(initialValue: initial?.category ?? .comida)
        _date     = State(initialValue: initial?.date ?? Date())
        _notes    = State(initialValue: initial?.notes ?? "")
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SoulTheme.Color.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: SoulTheme.Spacing.md) {
                        typePicker
                        amountField
                        titleField
                        categoryPicker
                        dateField
                        notesField
                        if initial != nil { deleteButton }
                    }
                    .padding(SoulTheme.Spacing.lg)
                }
            }
            .navigationTitle(initial == nil ? "Nuevo movimiento" : "Editar movimiento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }.tint(SoulTheme.Color.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") { save() }
                        .tint(SoulTheme.Color.primary)
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
        .onChange(of: type) { _, _ in
            if !availableCategories.contains(category) {
                category = availableCategories.first ?? .otro
            }
        }
    }

    // MARK: Fields

    private var typePicker: some View {
        Picker("Tipo", selection: $type) {
            ForEach(FinanceTransaction.Kind.allCases) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
    }

    private var amountField: some View {
        SoulCard(padding: SoulTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 6) {
                SoulEyebrow(text: "Monto")
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("$")
                        .font(SoulTheme.Font.display(32, weight: .semibold))
                        .foregroundStyle(SoulTheme.Color.primary)
                    TextField("0", text: $amount)
                        .keyboardType(.decimalPad)
                        .font(SoulTheme.Font.display(40, weight: .semibold))
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Text("MXN")
                        .font(SoulTheme.Font.unit)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
            }
        }
    }

    private var titleField: some View {
        SoulCard {
            VStack(alignment: .leading, spacing: 4) {
                SoulEyebrow(text: "Descripción")
                TextField("Ej. Super de la semana", text: $title)
                    .font(SoulTheme.Font.bodyText)
                    .padding(.vertical, 4)
            }
        }
    }

    private var availableCategories: [FinanceCategory] {
        type == .income ? FinanceCategory.incomeCategories : FinanceCategory.expenseCategories
    }

    private var categoryPicker: some View {
        SoulCard {
            VStack(alignment: .leading, spacing: 10) {
                SoulEyebrow(text: "Categoría")
                let columns = [GridItem(.adaptive(minimum: 120), spacing: 8)]
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(availableCategories) { cat in
                        Button { category = cat } label: {
                            HStack(spacing: 6) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 13))
                                Text(cat.rawValue)
                                    .font(SoulTheme.Font.caption)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(category == cat
                                             ? SoulTheme.Color.backgroundWarm
                                             : Color(hex: cat.tintHex))
                            .padding(.horizontal, 12).padding(.vertical, 9)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule().fill(category == cat
                                               ? AnyShapeStyle(Color(hex: cat.tintHex))
                                               : AnyShapeStyle(Color(hex: cat.tintHex).opacity(0.14)))
                            )
                        }
                    }
                }
            }
        }
    }

    private var dateField: some View {
        SoulCard {
            HStack {
                SoulEyebrow(text: "Fecha")
                Spacer()
                DatePicker("", selection: $date,
                           in: ...Date().addingTimeInterval(86_400),
                           displayedComponents: .date)
                    .labelsHidden()
                    .tint(SoulTheme.Color.primary)
            }
        }
    }

    private var notesField: some View {
        SoulCard {
            VStack(alignment: .leading, spacing: 4) {
                SoulEyebrow(text: "Notas (opcional)")
                TextField("Detalles", text: $notes, axis: .vertical)
                    .font(SoulTheme.Font.bodyText)
                    .lineLimit(3, reservesSpace: true)
            }
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            if let initial { store.deleteTransaction(initial) }
            dismiss()
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Eliminar movimiento")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Capsule().fill(SoulTheme.Palette.heart.opacity(0.12)))
            .foregroundStyle(SoulTheme.Palette.heart)
        }
    }

    // MARK: Save

    private func save() {
        guard let value = Double(amount.replacingOccurrences(of: ",", with: ".")),
              value > 0 else { return }
        let tx = FinanceTransaction(
            id: initial?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespaces),
            amountMXN: value,
            type: type,
            category: category,
            date: date,
            notes: notes,
            source: initial?.source ?? .manual,
            linkedObjectID: initial?.linkedObjectID
        )
        onSave(tx)
        dismiss()
    }
}
