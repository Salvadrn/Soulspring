import SwiftUI

/// In-app booking hub. Two flows share this view:
///  • **Estancia** — pick dates, plan and guests (hotel-style)
///  • **Experiencias** — pick an add-on (masaje, temazcal, breathwork…) on
///    a specific day and slot
/// Everything is handled inside the app; no more web redirects.
struct BookingView: View {
    enum Mode: Hashable { case stay, experiences }

    @State private var mode: Mode = .stay
    @State private var pickedExperience: Experience? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                header

                Picker("Reservar", selection: $mode.animation()) {
                    Text("Estancia").tag(Mode.stay)
                    Text("Experiencias").tag(Mode.experiences)
                }
                .pickerStyle(.segmented)

                switch mode {
                case .stay:
                    StayBookingCard()
                case .experiences:
                    ExperienceCatalogSection(picked: $pickedExperience)
                }
            }
            .padding(SoulTheme.Spacing.lg)
        }
        .sheet(item: $pickedExperience) { exp in
            ExperienceBookingSheet(experience: exp)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            SoulEyebrow(text: "Reservaciones")
            Text("Agenda en la app.")
                .font(SoulTheme.Font.title)
                .foregroundStyle(SoulTheme.Color.textPrimary)
            Text("Sincronizado en tiempo real con el Sanctuary.")
                .font(SoulTheme.Font.caption)
                .foregroundStyle(SoulTheme.Color.textSecondary)
        }
    }
}

// MARK: - Stay card (hotel-style)

struct StayBookingCard: View {
    @EnvironmentObject private var store: AppStore

    @State private var checkIn: Date  = Date().addingTimeInterval(86_400)
    @State private var checkOut: Date = Date().addingTimeInterval(4 * 86_400)
    @State private var tier: MembershipTier = .sanctuary
    @State private var guests: Int = 1
    @State private var confirmed: StayBooking? = nil

    private var nights: Int {
        max(1, Calendar.current.dateComponents([.day],
            from: Calendar.current.startOfDay(for: checkIn),
            to: Calendar.current.startOfDay(for: checkOut)).day ?? 1)
    }

    private var total: Int { tier.nightlyCostMXN * nights * max(1, guests) }

    var body: some View {
        VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
            datesCard
            tierPicker
            guestsCard
            totalCard
        }
        .sheet(item: $confirmed) { stay in
            BookingConfirmationSheet(kind: .stay(stay))
        }
    }

    private var datesCard: some View {
        SoulCard {
            VStack(alignment: .leading, spacing: 14) {
                SoulEyebrow(text: "Fechas")
                HStack(spacing: 12) {
                    dateColumn(label: "Check-in", date: $checkIn)
                    Rectangle().fill(SoulTheme.Color.divider).frame(width: 0.5, height: 44)
                    dateColumn(label: "Check-out", date: $checkOut)
                }
                HStack {
                    Text("\(nights) \(nights == 1 ? "noche" : "noches")")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                    Spacer()
                }
            }
        }
        .onChange(of: checkIn) { _, newValue in
            if checkOut <= newValue {
                checkOut = Calendar.current.date(byAdding: .day, value: 1, to: newValue) ?? checkOut
            }
        }
    }

    private func dateColumn(label: String, date: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            SoulEyebrow(text: label)
            DatePicker("", selection: date, in: Date()..., displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(SoulTheme.Color.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tierPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            SoulSectionHeader(eyebrow: "Plan",
                              title: "Elige tu estancia",
                              subtitle: nil)
            VStack(spacing: 10) {
                ForEach(MembershipTier.allCases) { t in
                    Button { tier = t } label: {
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                Circle().stroke(SoulTheme.Color.primary, lineWidth: 1.4)
                                    .frame(width: 22, height: 22)
                                if tier == t {
                                    Circle().fill(SoulTheme.Gradient.forest).frame(width: 14, height: 14)
                                }
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(t.rawValue)
                                    .font(SoulTheme.Font.card)
                                    .foregroundStyle(SoulTheme.Color.textPrimary)
                                Text(t.tagline)
                                    .font(SoulTheme.Font.caption)
                                    .foregroundStyle(SoulTheme.Color.textSecondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("$\(t.nightlyCostMXN)")
                                    .font(SoulTheme.Font.card)
                                    .foregroundStyle(SoulTheme.Color.primary)
                                Text("MXN / noche")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(SoulTheme.Color.textSecondary)
                            }
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                            .fill(SoulTheme.Color.surface))
                        .overlay(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                            .stroke(tier == t ? SoulTheme.Color.primary : SoulTheme.Color.divider,
                                    lineWidth: tier == t ? 1.2 : 0.5))
                    }
                    .buttonStyle(.plain)
            .hapticOnTap()
                }
            }
        }
    }

    private var guestsCard: some View {
        SoulCard {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    SoulEyebrow(text: "Huéspedes")
                    Text("\(guests) \(guests == 1 ? "persona" : "personas")")
                        .font(SoulTheme.Font.card)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                }
                Spacer()
                Stepper("", value: $guests, in: 1...6).labelsHidden()
            }
        }
    }

    private var totalCard: some View {
        SoulCard(padding: SoulTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        SoulEyebrow(text: "Total")
                        Text("$\(total) MXN")
                            .font(SoulTheme.Font.display(32, weight: .semibold))
                            .foregroundStyle(SoulTheme.Color.primary)
                        Text("\(nights) \(nights == 1 ? "noche" : "noches") × \(guests) hosp.")
                            .font(SoulTheme.Font.caption)
                            .foregroundStyle(SoulTheme.Color.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(SoulTheme.Color.primarySoft)
                }

                Button {
                    let stay = store.bookStay(checkIn: checkIn, checkOut: checkOut,
                                              tier: tier, guests: guests)
                    confirmed = stay
                } label: {
                    Text("Confirmar reservación")
                }
                .buttonStyle(SoulPrimaryButtonStyle())

                Text("Al confirmar, el cobro se hará con la tarjeta de tu wallet (o se solicitará al check-in).")
                    .font(.system(size: 11))
                    .foregroundStyle(SoulTheme.Color.textSecondary)
            }
        }
    }
}

// MARK: - Experience catalog

struct ExperienceCatalogSection: View {
    @Binding var picked: Experience?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SoulSectionHeader(eyebrow: "Experiencias",
                              title: "Elige y agenda",
                              subtitle: "Días y horas reales del Sanctuary.")
            ForEach(Experience.catalog) { exp in
                Button { picked = exp } label: { ExperienceRow(exp: exp) }
                    .buttonStyle(.plain)
            .hapticOnTap()
            }
        }
    }
}

struct ExperienceRow: View {
    let exp: Experience
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .fill(SoulTheme.Palette.cream)
                    .frame(width: 56, height: 56)
                Text(exp.emoji).font(.system(size: 28))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(exp.name)
                    .font(SoulTheme.Font.card)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                Text(exp.summary)
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    SoulChip(text: "\(exp.durationMinutes) min", tint: SoulTheme.Palette.earth)
                    SoulChip(text: "$\(exp.priceMXN) MXN", tint: SoulTheme.Palette.terracotta)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SoulTheme.Color.textSecondary)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
            .fill(SoulTheme.Color.surface))
        .overlay(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
            .stroke(SoulTheme.Color.divider, lineWidth: 0.5))
    }
}

// MARK: - Experience booking sheet

struct ExperienceBookingSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let experience: Experience

    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedSlot: TimeSlot? = nil
    @State private var notes = ""
    @State private var confirmed: Booking? = nil

    private var days: [Date] { AvailabilityEngine.nextDays(14) }
    private var slots: [TimeSlot] {
        AvailabilityEngine.slots(for: experience, on: selectedDay)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SoulTheme.Color.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                        header
                        daySelector
                        slotGrid
                        notesField
                        confirmButton
                    }
                    .padding(SoulTheme.Spacing.lg)
                }
            }
            .navigationTitle("Reservar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .tint(SoulTheme.Color.primary)
                }
            }
            .sheet(item: $confirmed) { b in
                BookingConfirmationSheet(kind: .experience(b))
                    .onDisappear { dismiss() }
            }
        }
    }

    private var header: some View {
        SoulCard(padding: SoulTheme.Spacing.lg) {
            HStack(spacing: 14) {
                Text(experience.emoji).font(.system(size: 40))
                VStack(alignment: .leading, spacing: 4) {
                    Text(experience.name)
                        .font(SoulTheme.Font.sectionHead)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Text(experience.summary)
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                    HStack(spacing: 6) {
                        SoulChip(text: experience.practitioner, tint: SoulTheme.Palette.moss)
                        SoulChip(text: "\(experience.durationMinutes) min", tint: SoulTheme.Palette.earth)
                    }
                }
            }
        }
    }

    private var daySelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            SoulEyebrow(text: "Elige día")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(days, id: \.self) { day in
                        dayPill(day: day)
                    }
                }
            }
        }
    }

    private func dayPill(day: Date) -> some View {
        let isSelected = Calendar.current.isDate(day, inSameDayAs: selectedDay)
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_MX")
        df.dateFormat = "EEE"
        let weekday = df.string(from: day).uppercased()
        let dayNum = Calendar.current.component(.day, from: day)

        return Button {
            selectedDay = day
            selectedSlot = nil
        } label: {
            VStack(spacing: 4) {
                Text(weekday)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                Text("\(dayNum)")
                    .font(SoulTheme.Font.card)
            }
            .foregroundStyle(isSelected ? SoulTheme.Color.backgroundWarm : SoulTheme.Color.textPrimary)
            .frame(width: 56, height: 66)
            .background(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .fill(isSelected
                          ? AnyShapeStyle(SoulTheme.Gradient.forest)
                          : AnyShapeStyle(SoulTheme.Color.surface))
            )
            .overlay(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .stroke(SoulTheme.Color.divider, lineWidth: 0.5)
            )
        }
    }

    private var slotGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            SoulEyebrow(text: "Horas disponibles")
            let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(slots) { slot in
                    slotButton(slot)
                }
            }
            if slots.allSatisfy({ !$0.isAvailable }) {
                Text("No hay disponibilidad. Prueba otro día.")
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
            }
        }
    }

    private func slotButton(_ slot: TimeSlot) -> some View {
        let isPicked = selectedSlot?.id == slot.id
        return Button {
            guard slot.isAvailable else { return }
            selectedSlot = slot
        } label: {
            Text(slot.date.formatted(date: .omitted, time: .shortened))
                .font(SoulTheme.Font.card)
                .frame(maxWidth: .infinity, minHeight: 46)
                .foregroundStyle(
                    !slot.isAvailable ? SoulTheme.Color.textSecondary.opacity(0.6)
                    : isPicked ? SoulTheme.Color.backgroundWarm
                    : SoulTheme.Color.textPrimary
                )
                .background(
                    RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                        .fill(
                            !slot.isAvailable ? AnyShapeStyle(SoulTheme.Palette.sand.opacity(0.5))
                            : isPicked ? AnyShapeStyle(SoulTheme.Gradient.forest)
                            : AnyShapeStyle(SoulTheme.Color.surface)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                        .stroke(SoulTheme.Color.divider, lineWidth: 0.5)
                )
        }
        .disabled(!slot.isAvailable)
    }

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 6) {
            SoulEyebrow(text: "Notas (opcional)")
            TextField("Preferencias, restricciones, acompañantes…", text: $notes, axis: .vertical)
                .font(SoulTheme.Font.bodyText)
                .lineLimit(2, reservesSpace: true)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(SoulTheme.Color.surface))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(SoulTheme.Color.divider, lineWidth: 0.5))
        }
    }

    private var confirmButton: some View {
        Button {
            guard let slot = selectedSlot else { return }
            let booking = store.book(experience: experience, at: slot.date, notes: notes)
            confirmed = booking
        } label: {
            Text(selectedSlot == nil ? "Selecciona una hora" : "Reservar · $\(experience.priceMXN) MXN")
        }
        .buttonStyle(SoulPrimaryButtonStyle())
        .disabled(selectedSlot == nil)
        .opacity(selectedSlot == nil ? 0.5 : 1)
    }
}

// MARK: - Confirmation

struct BookingConfirmationSheet: View {
    enum Kind: Identifiable {
        case stay(StayBooking)
        case experience(Booking)
        var id: String {
            switch self {
            case .stay(let s):       return s.id.uuidString
            case .experience(let b): return b.id.uuidString
            }
        }
    }

    let kind: Kind
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            SoulTheme.Gradient.dawn.ignoresSafeArea()
            VStack(spacing: SoulTheme.Spacing.lg) {
                Spacer(minLength: 20)
                ZStack {
                    Circle().fill(SoulTheme.Gradient.forest).frame(width: 96, height: 96)
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(SoulTheme.Color.backgroundWarm)
                }
                VStack(spacing: 6) {
                    Text("Reservación confirmada")
                        .font(SoulTheme.Font.title)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Text(subtitle)
                        .font(SoulTheme.Font.bodyText)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, SoulTheme.Spacing.lg)
                }

                SoulCard(padding: SoulTheme.Spacing.lg) {
                    VStack(spacing: 6) {
                        SoulEyebrow(text: "Código")
                        Text(code)
                            .font(SoulTheme.Font.display(24, weight: .semibold))
                            .foregroundStyle(SoulTheme.Color.primary)
                            .tracking(2)
                    }
                }
                .padding(.horizontal, SoulTheme.Spacing.lg)

                Text("Tu wallet ya tiene este código. En el check-in te lo escanean.")
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                    .multilineTextAlignment(.center)

                Spacer()

                Button { dismiss() } label: { Text("Listo") }
                    .buttonStyle(SoulPrimaryButtonStyle())
                    .padding(.horizontal, SoulTheme.Spacing.lg)
                    .padding(.bottom, SoulTheme.Spacing.lg)
            }
        }
    }

    private var subtitle: String {
        switch kind {
        case .stay(let s):
            return "\(s.tier.rawValue) · \(s.nights) \(s.nights == 1 ? "noche" : "noches") — total $\(s.totalMXN) MXN"
        case .experience(let b):
            return "\(b.experience.name) · \(b.slotDate.formatted(date: .abbreviated, time: .shortened))"
        }
    }

    private var code: String {
        switch kind {
        case .stay(let s):       return s.confirmationCode
        case .experience(let b): return b.confirmationCode
        }
    }
}
