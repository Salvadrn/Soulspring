import SwiftUI
import MapKit

struct SanctuaryView: View {
    enum Tab: Hashable { case menu, map, food, rooms, reminders }

    @State private var tab: Tab
    init(initialTab: Tab = .menu) {
        _tab = State(initialValue: initialTab)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SoulBackground()
                VStack(spacing: 0) {
                    header

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            segment(title: "Menú",    tag: .menu)
                            segment(title: "Lugares", tag: .map)
                            segment(title: "Cocina",  tag: .food)
                            segment(title: "Room",    tag: .rooms)
                            segment(title: "Rutina",  tag: .reminders)
                        }
                        .padding(.horizontal, SoulTheme.Spacing.lg)
                    }
                    .padding(.bottom, 12)

                    Group {
                        switch tab {
                        case .menu:      DailyMenuView()
                        case .map:       SanctuaryMapView()
                        case .food:      FoodView()
                        case .rooms:     RoomServiceView()
                        case .reminders: RemindersView()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func segment(title: String, tag: Tab) -> some View {
        Button { withAnimation { tab = tag } } label: {
            Text(title)
                .font(SoulTheme.Font.caption)
                .foregroundStyle(tab == tag
                                 ? SoulTheme.Color.backgroundWarm
                                 : SoulTheme.Color.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(
                    Capsule().fill(tab == tag
                                   ? AnyShapeStyle(SoulTheme.Gradient.forest)
                                   : AnyShapeStyle(SoulTheme.Color.surface))
                )
                .overlay(
                    Capsule().stroke(SoulTheme.Color.divider, lineWidth: 0.5)
                )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            SoulEyebrow(text: "El Santuario")
            Text("Tu espacio ritual.")
                .font(SoulTheme.Font.hero)
                .foregroundStyle(SoulTheme.Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, SoulTheme.Spacing.lg)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
}

// MARK: - Map

struct SanctuaryMapView: View {
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 19.25, longitude: -99.18),
            span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0))
    )
    @State private var selected: SoulPlace? = nil

    var body: some View {
        VStack(spacing: 0) {
            Map(position: $position) {
                ForEach(SoulPlace.catalog) { place in
                    Annotation(place.name, coordinate: place.coordinate.cl) {
                        Button { selected = place } label: {
                            ZStack {
                                Circle()
                                    .fill(SoulTheme.Gradient.forest)
                                    .frame(width: 34, height: 34)
                                Image(systemName: iconFor(place.kind))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .shadow(color: SoulTheme.Palette.moss.opacity(0.3), radius: 6, y: 3)
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .frame(height: 320)
            .padding(.horizontal, SoulTheme.Spacing.lg)
            .clipShape(RoundedRectangle(cornerRadius: SoulTheme.Radius.lg))

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(SoulPlace.catalog) { place in
                        placeRow(place)
                    }
                }
                .padding(SoulTheme.Spacing.lg)
            }
        }
        .sheet(item: $selected) { place in
            PlaceDetailSheet(place: place)
                .presentationDetents([.medium])
        }
    }

    private func placeRow(_ place: SoulPlace) -> some View {
        Button { selected = place } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(SoulTheme.Palette.cream).frame(width: 44, height: 44)
                    Image(systemName: iconFor(place.kind))
                        .foregroundStyle(SoulTheme.Color.primary)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(place.name)
                        .font(SoulTheme.Font.card)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Text("\(place.kind.rawValue) · \(place.address)")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
                Spacer()
                SoulChip(text: place.openNow ? "Abierto" : "Cerrado",
                         tint: place.openNow ? SoulTheme.Palette.moss : SoulTheme.Palette.earth)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                .fill(SoulTheme.Color.surface))
            .overlay(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                .stroke(SoulTheme.Color.divider, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private func iconFor(_ kind: SoulPlace.Kind) -> String {
        switch kind {
        case .sanctuary: return "leaf.fill"
        case .studio:    return "figure.mind.and.body"
        case .cafe:      return "cup.and.saucer.fill"
        case .clinic:    return "cross.case.fill"
        }
    }
}

struct PlaceDetailSheet: View {
    let place: SoulPlace
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            SoulBackground()
            VStack(alignment: .leading, spacing: 16) {
                SoulEyebrow(text: place.kind.rawValue)
                Text(place.name)
                    .font(SoulTheme.Font.title)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                Text(place.address)
                    .font(SoulTheme.Font.bodyText)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                SoulChip(text: place.openNow ? "Abierto ahora" : "Cerrado por hoy",
                         tint: place.openNow ? SoulTheme.Palette.moss : SoulTheme.Palette.earth)
                Spacer()
                Link(destination: SoulLinks.booking) {
                    Text("Reservar cita")
                }
                .buttonStyle(SoulPrimaryButtonStyle())
            }
            .padding(SoulTheme.Spacing.lg)
        }
    }
}

// MARK: - Food

struct FoodView: View {
    @State private var selected: Meal?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                SoulSectionHeader(eyebrow: "La cocina",
                                  title: "Comida saludable",
                                  subtitle: "Recetas del chef del Sanctuary, todas bio-individualizadas.")
                Link(destination: SoulLinks.foodInstagram) {
                    QuickActionTile(
                        eyebrow: "Instagram",
                        title: "Soul Kitchen",
                        subtitle: "Síguenos en \(SoulLinks.foodHandle)",
                        icon: "camera.fill",
                        gradient: SoulTheme.Gradient.sunset)
                }

                ForEach(Meal.catalog) { meal in
                    Button { selected = meal } label: { MealCard(meal: meal) }
                        .buttonStyle(.plain)
                }
            }
            .padding(SoulTheme.Spacing.lg)
        }
        .sheet(item: $selected) { meal in
            MealDetailSheet(meal: meal)
        }
    }
}

struct MealCard: View {
    let meal: Meal
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .fill(SoulTheme.Palette.cream)
                    .frame(width: 64, height: 64)
                Text(meal.emoji).font(.system(size: 32))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(SoulTheme.Font.card)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                Text(meal.subtitle)
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    SoulChip(text: "\(meal.kcal) kcal", tint: SoulTheme.Palette.earth)
                    ForEach(meal.tags.prefix(1), id: \.self) { tag in
                        SoulChip(text: tag, tint: SoulTheme.Palette.moss)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SoulTheme.Color.textSecondary)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
            .fill(SoulTheme.Color.surface))
        .overlay(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
            .stroke(SoulTheme.Color.divider, lineWidth: 0.5))
    }
}

struct MealDetailSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let meal: Meal
    @State private var whenDate = Date().addingTimeInterval(60 * 30)
    @State private var notes = ""
    @State private var placed = false

    var body: some View {
        ZStack {
            SoulBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        Text(meal.emoji).font(.system(size: 48))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(meal.name).font(SoulTheme.Font.title)
                                .foregroundStyle(SoulTheme.Color.textPrimary)
                            Text(meal.subtitle)
                                .font(SoulTheme.Font.bodyText)
                                .foregroundStyle(SoulTheme.Color.textSecondary)
                        }
                    }

                    HStack(spacing: 10) {
                        MacroPill(label: "Proteína", value: meal.macros.protein, tint: SoulTheme.Palette.moss)
                        MacroPill(label: "Carbs",    value: meal.macros.carbs,   tint: SoulTheme.Palette.terracotta)
                        MacroPill(label: "Grasas",   value: meal.macros.fats,    tint: SoulTheme.Palette.gold)
                    }

                    ForEach(meal.tags, id: \.self) { tag in
                        SoulChip(text: tag, tint: SoulTheme.Palette.moss)
                    }

                    SoulDivider()

                    SoulSectionHeader(eyebrow: "Room service",
                                      title: "Ordenar al cuarto",
                                      subtitle: "Disponible sólo para miembros Sanctuary.")

                    DatePicker("Hora", selection: $whenDate, displayedComponents: [.hourAndMinute])
                        .font(SoulTheme.Font.bodyText)

                    TextField("Notas (ej. sin ajonjolí)", text: $notes, axis: .vertical)
                        .font(SoulTheme.Font.bodyText)
                        .lineLimit(2, reservesSpace: true)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12)
                            .fill(SoulTheme.Color.surface))

                    Button {
                        store.placeOrder(meal: meal, at: whenDate, notes: notes)
                        placed = true
                        dismiss()
                    } label: {
                        Text(placed ? "Pedido enviado ✓" : "Pedir al Room service")
                    }
                    .buttonStyle(SoulPrimaryButtonStyle())
                }
                .padding(SoulTheme.Spacing.lg)
            }
        }
    }
}

struct MacroPill: View {
    let label: String
    let value: Int
    let tint: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(1)
                .foregroundStyle(tint.opacity(0.9))
            Text("\(value)g")
                .font(SoulTheme.Font.card)
                .foregroundStyle(SoulTheme.Color.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(tint.opacity(0.12)))
    }
}

// MARK: - Room service

struct RoomServiceView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                SoulSectionHeader(eyebrow: "Room service",
                                  title: "Tus pedidos",
                                  subtitle: "Lo que has solicitado al Sanctuary.")
                if store.orders.isEmpty {
                    SoulCard {
                        VStack(spacing: 10) {
                            Image(systemName: "tray")
                                .font(.system(size: 30))
                                .foregroundStyle(SoulTheme.Color.primarySoft)
                            Text("Aún no tienes pedidos.")
                                .font(SoulTheme.Font.card)
                                .foregroundStyle(SoulTheme.Color.textPrimary)
                            Text("Explora la cocina del Sanctuary y haz tu primer pedido.")
                                .font(SoulTheme.Font.caption)
                                .foregroundStyle(SoulTheme.Color.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
                ForEach(store.orders) { order in
                    SoulCard {
                        HStack(spacing: 14) {
                            Text(order.meal.emoji).font(.system(size: 34))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(order.meal.name)
                                    .font(SoulTheme.Font.card)
                                    .foregroundStyle(SoulTheme.Color.textPrimary)
                                Text("Para las \(order.scheduledFor.formatted(date: .omitted, time: .shortened))")
                                    .font(SoulTheme.Font.caption)
                                    .foregroundStyle(SoulTheme.Color.textSecondary)
                                if !order.notes.isEmpty {
                                    Text(order.notes)
                                        .font(SoulTheme.Font.caption)
                                        .foregroundStyle(SoulTheme.Color.textSecondary)
                                }
                            }
                            Spacer()
                            SoulChip(text: "En camino",
                                     tint: SoulTheme.Palette.moss)
                        }
                    }
                }
            }
            .padding(SoulTheme.Spacing.lg)
        }
    }
}

// MARK: - Reminders

struct RemindersView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                SoulSectionHeader(eyebrow: "Rutina",
                                  title: "Recordatorios",
                                  subtitle: "Micro-rituales a lo largo del día.")
                ForEach(store.reminders) { reminder in
                    SoulCard {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle().fill(SoulTheme.Palette.cream).frame(width: 42, height: 42)
                                Image(systemName: iconFor(reminder.kind))
                                    .foregroundStyle(SoulTheme.Color.primary)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(reminder.title)
                                    .font(SoulTheme.Font.card)
                                    .foregroundStyle(SoulTheme.Color.textPrimary)
                                Text("\(reminder.kind.rawValue) · \(reminder.time.formatted(date: .omitted, time: .shortened))")
                                    .font(SoulTheme.Font.caption)
                                    .foregroundStyle(SoulTheme.Color.textSecondary)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { reminder.isOn },
                                set: { _ in store.toggleReminder(reminder) }
                            ))
                            .labelsHidden()
                            .tint(SoulTheme.Color.primary)
                        }
                    }
                }
            }
            .padding(SoulTheme.Spacing.lg)
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
}
