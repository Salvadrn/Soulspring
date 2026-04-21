import SwiftUI

/// Public view of the chef's Menú del día. Displays hero, course list and
/// an Instagram-style grid pulling from Soul Kitchen's feed. When the user
/// is in chef mode, the "Editar" button unlocks the editor.
struct DailyMenuView: View {
    @EnvironmentObject private var store: AppStore
    @State private var isEditing = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                header
                menuHero
                coursesList
                instagramSection
            }
            .padding(SoulTheme.Spacing.lg)
        }
        .sheet(isPresented: $isEditing) {
            MenuEditorView(menu: store.dailyMenu) { updated in
                store.dailyMenu = updated
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                SoulEyebrow(text: "Menú del día")
                Text("Soul Kitchen")
                    .font(SoulTheme.Font.title)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                Text(formattedDate)
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
            }
            Spacer()
            if store.isChef {
                Button {
                    isEditing = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                        Text("Editar")
                    }
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().stroke(SoulTheme.Color.primary, lineWidth: 1))
                }
            }
        }
    }

    private var formattedDate: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_MX")
        df.dateFormat = "EEEE, d MMMM"
        return df.string(from: store.dailyMenu.date).capitalized
    }

    // MARK: Menu hero

    private var menuHero: some View {
        SoulCard(padding: SoulTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 12) {
                Text(store.dailyMenu.title)
                    .font(SoulTheme.Font.display(26, weight: .regular))
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                Text(store.dailyMenu.headline)
                    .font(SoulTheme.Font.bodyText)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                Text("— \(store.dailyMenu.chefName)")
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.primary)
            }
        }
    }

    // MARK: Courses

    private var coursesList: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(MenuDish.Course.allCases) { course in
                let dishes = store.dailyMenu.dishes.filter { $0.course == course }
                if !dishes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SoulEyebrow(text: course.rawValue)
                        ForEach(dishes) { dish in
                            DishRow(dish: dish)
                        }
                    }
                }
            }
        }
    }

    // MARK: Instagram section

    private var instagramSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    SoulEyebrow(text: "Instagram · \(SoulLinks.foodHandle)")
                    Text("De la huerta a la mesa")
                        .font(SoulTheme.Font.sectionHead)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                }
                Spacer()
                Link(destination: SoulLinks.foodInstagram) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right")
                        Text("Ver perfil")
                    }
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.primary)
                }
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6),
            ], spacing: 6) {
                ForEach(InstagramTile.feed) { tile in
                    Link(destination: SoulLinks.foodInstagram) {
                        InstagramCell(tile: tile)
                    }
                }
            }

            Link(destination: SoulLinks.foodInstagram) {
                HStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                    Text("Seguir a \(SoulLinks.foodHandle)")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                .font(SoulTheme.Font.card)
                .foregroundStyle(SoulTheme.Color.backgroundWarm)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(Capsule().fill(SoulTheme.Gradient.sunset))
            }
        }
    }
}

// MARK: - Dish row

private struct DishRow: View {
    let dish: MenuDish
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .fill(SoulTheme.Palette.cream)
                    .frame(width: 52, height: 52)
                Text(dish.emoji).font(.system(size: 26))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(dish.name)
                    .font(SoulTheme.Font.card)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                Text(dish.description)
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
            .fill(SoulTheme.Color.surface))
        .overlay(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
            .stroke(SoulTheme.Color.divider, lineWidth: 0.5))
    }
}

// MARK: - Instagram cell

private struct InstagramCell: View {
    let tile: InstagramTile
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let url = tile.photoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        gradientFallback
                    }
                }
            } else {
                gradientFallback
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )

            HStack {
                Image(systemName: "camera.fill")
                    .font(.system(size: 9, weight: .bold))
                Text(tile.caption)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .padding(6)
        }
        .aspectRatio(1, contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var gradientFallback: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: tile.gradientHex.0),
                         Color(hex: tile.gradientHex.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing)
            Text(tile.emoji).font(.system(size: 34))
        }
    }
}

// MARK: - Menu editor (chef mode)

struct MenuEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State var menu: DailyMenu
    let onSave: (DailyMenu) -> Void

    @State private var newDishName = ""
    @State private var newDishDescription = ""
    @State private var newDishCourse: MenuDish.Course = .principal
    @State private var newDishEmoji = "🌿"

    private let emojiOptions = ["🍅", "🐟", "🥗", "🍲", "🍞", "🍵", "🥣",
                                 "🥑", "🌿", "🍋", "🫘", "🍫", "🍄", "🫖", "🥒"]

    var body: some View {
        NavigationStack {
            ZStack {
                SoulTheme.Color.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                        header
                        dishesEditor
                        addDishSection
                    }
                    .padding(SoulTheme.Spacing.lg)
                }
            }
            .navigationTitle("Modo Chef")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .tint(SoulTheme.Color.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Publicar") {
                        onSave(menu)
                        dismiss()
                    }
                    .tint(SoulTheme.Color.primary)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: Header fields

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoulCard {
                VStack(alignment: .leading, spacing: 12) {
                    field(label: "Título del menú", text: $menu.title,
                          placeholder: "Ej. Domingo de raíces")
                    field(label: "Frase del día", text: $menu.headline,
                          placeholder: "Una línea poética")
                    field(label: "Chef que firma", text: $menu.chefName,
                          placeholder: "Chef Isa Mendoza")
                    DatePicker("Fecha", selection: $menu.date, displayedComponents: .date)
                        .font(SoulTheme.Font.bodyText)
                }
            }
        }
    }

    private func field(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            SoulEyebrow(text: label)
            TextField(placeholder, text: text)
                .font(SoulTheme.Font.bodyText)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(SoulTheme.Palette.cream.opacity(0.6)))
        }
    }

    // MARK: Dishes editor

    private var dishesEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            SoulSectionHeader(eyebrow: "Platillos",
                              title: "Lo que servimos hoy",
                              subtitle: "Toca la X para eliminar.")
            ForEach(menu.dishes) { dish in
                HStack(spacing: 12) {
                    Text(dish.emoji).font(.system(size: 26))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dish.name)
                            .font(SoulTheme.Font.card)
                            .foregroundStyle(SoulTheme.Color.textPrimary)
                        Text("\(dish.course.rawValue) · \(dish.description)")
                            .font(SoulTheme.Font.caption)
                            .foregroundStyle(SoulTheme.Color.textSecondary)
                            .lineLimit(2)
                    }
                    Spacer()
                    Button {
                        menu.dishes.removeAll { $0.id == dish.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(SoulTheme.Color.textSecondary)
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .fill(SoulTheme.Color.surface))
                .overlay(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .stroke(SoulTheme.Color.divider, lineWidth: 0.5))
            }
        }
    }

    // MARK: Add dish

    private var addDishSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoulSectionHeader(eyebrow: "Nuevo platillo",
                              title: "Añadir al menú",
                              subtitle: nil)

            SoulCard {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Tiempo", selection: $newDishCourse) {
                        ForEach(MenuDish.Course.allCases) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    .pickerStyle(.segmented)

                    field(label: "Nombre", text: $newDishName,
                          placeholder: "Ej. Gazpacho de tomate")
                    VStack(alignment: .leading, spacing: 4) {
                        SoulEyebrow(text: "Descripción")
                        TextField("Ingredientes clave e intención del platillo.",
                                  text: $newDishDescription, axis: .vertical)
                            .font(SoulTheme.Font.bodyText)
                            .lineLimit(2, reservesSpace: true)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12)
                                .fill(SoulTheme.Palette.cream.opacity(0.6)))
                    }

                    SoulEyebrow(text: "Emoji")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(emojiOptions, id: \.self) { emoji in
                                Button { newDishEmoji = emoji } label: {
                                    Text(emoji)
                                        .font(.system(size: 26))
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle().fill(
                                                newDishEmoji == emoji
                                                ? SoulTheme.Palette.gold.opacity(0.3)
                                                : SoulTheme.Palette.cream
                                            )
                                        )
                                }
                            }
                        }
                    }

                    Button {
                        guard !newDishName.isEmpty else { return }
                        menu.dishes.append(MenuDish(
                            name: newDishName,
                            description: newDishDescription,
                            course: newDishCourse,
                            emoji: newDishEmoji
                        ))
                        newDishName = ""
                        newDishDescription = ""
                        newDishEmoji = "🌿"
                    } label: {
                        Text("Añadir platillo")
                    }
                    .buttonStyle(SoulPrimaryButtonStyle())
                }
            }
        }
    }
}
