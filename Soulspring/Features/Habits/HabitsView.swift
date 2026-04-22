import SwiftUI

struct HabitsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var isAddingHabit = false
    @State private var isShowingGoalSheet = false
    @State private var isShowingInvite = false

    var body: some View {
        NavigationStack {
            ZStack {
                SoulBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: SoulTheme.Spacing.lg) {
                        header
                        RachaHero()

                        goalTuner

                        sharedStreaksSection

                        achievementsCallout

                        giftCardCallout

                        habitsSection
                    }
                    .padding(.horizontal, SoulTheme.Spacing.lg)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isAddingHabit) { AddHabitSheet() }
            .sheet(isPresented: $isShowingInvite) { InviteFriendSheet() }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                SoulEyebrow(text: "Rachas")
                Text("Tus hábitos.")
                    .font(SoulTheme.Font.hero)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                Text("Un día a la vez.")
                    .font(SoulTheme.Font.bodyText)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
            }
            Spacer()
            Button {
                isAddingHabit = true
            } label: {
                ZStack {
                    Circle()
                        .fill(SoulTheme.Gradient.forest)
                        .frame(width: 46, height: 46)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(SoulTheme.Color.backgroundWarm)
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: Goal tuner

    private var goalTuner: some View {
        SoulCard {
            HStack {
                Image(systemName: "target")
                    .font(.system(size: 22))
                    .foregroundStyle(SoulTheme.Color.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Meta diaria para mantener racha")
                        .font(SoulTheme.Font.card)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Text("Cumple al menos \(store.dailyGoalTarget) hábitos al día.")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
                Spacer()
                Stepper(value: Binding(
                    get: { store.dailyGoalTarget },
                    set: { store.dailyGoalTarget = $0 }
                ), in: 1...8) { EmptyView() }
                .labelsHidden()
            }
        }
    }

    // MARK: Shared streaks

    private var sharedStreaksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SoulSectionHeader(
                    eyebrow: "Rachas conjuntas",
                    title: "Con tus amigos",
                    subtitle: "Si alguno falla, la racha cae. Mejor juntos.")
                Spacer()
                Button {
                    isShowingInvite = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                        Text("Invitar")
                    }
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.primary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.sharedStreaks) { shared in
                        SharedStreakCard(shared: shared)
                    }
                    InviteTile { isShowingInvite = true }
                }
                .padding(.trailing, 4)
            }
        }
    }

    // MARK: Achievements callout

    private var achievementsCallout: some View {
        let unlocked = store.unlockedAchievements.count
        let total = Achievement.catalog.count
        return NavigationLink {
            AchievementsView()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(SoulTheme.Color.divider, lineWidth: 4)
                        .frame(width: 50, height: 50)
                    Circle()
                        .trim(from: 0, to: total == 0 ? 0 : Double(unlocked) / Double(total))
                        .stroke(SoulTheme.Palette.gold,
                                style: .init(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 50, height: 50)
                    Image(systemName: "rosette")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(SoulTheme.Palette.gold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mis medallas")
                        .font(SoulTheme.Font.card)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Text("\(unlocked) de \(total) desbloqueadas")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
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
        .buttonStyle(.plain)
        .hapticOnTap()
    }

    // MARK: Gift card callout

    private var giftCardCallout: some View {
        NavigationLink {
            GiftCardView()
        } label: {
            ZStack(alignment: .bottomLeading) {
                // Gift card body
                RoundedRectangle(cornerRadius: SoulTheme.Radius.lg, style: .continuous)
                    .fill(SoulTheme.Gradient.sunset)

                // Subtle texture lines
                ForEach(0..<5, id: \.self) { i in
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 1)
                        .offset(y: CGFloat(i) * 18 - 35)
                }

                // Ribbon decoration
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 110, height: 110)
                        .offset(x: 70, y: -30)
                    Image(systemName: "gift.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(x: 70, y: -30)
                }

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        SoulEyebrow(text: "Para alguien que quieres",
                                    color: .white.opacity(0.85))
                        Text("Regala\nSoulspring")
                            .font(SoulTheme.Font.display(28, weight: .bold))
                            .foregroundStyle(.white)
                            .lineSpacing(2)
                        Text("Una estancia, una experiencia, un día completo.")
                            .font(SoulTheme.Font.caption)
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(SoulTheme.Spacing.lg)
            }
            .frame(height: 165)
            .clipShape(RoundedRectangle(cornerRadius: SoulTheme.Radius.lg, style: .continuous))
            .shadow(color: SoulTheme.Palette.terracotta.opacity(0.35), radius: 16, y: 10)
        }
        .buttonStyle(.plain)
        .hapticOnTap()
    }

    // MARK: Habits list

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoulSectionHeader(
                eyebrow: "Hoy",
                title: "Tus hábitos",
                subtitle: "Toca para marcar. Mantén al menos \(store.dailyGoalTarget) al día.")

            VStack(spacing: 10) {
                ForEach(store.habits) { habit in
                    HabitRow(habit: habit)
                }
            }
        }
    }
}

// MARK: - Habit row

struct HabitRow: View {
    @EnvironmentObject private var store: AppStore
    let habit: Habit

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .fill(Color(hex: habit.colorHex).opacity(0.20))
                    .frame(width: 52, height: 52)
                Image(systemName: habit.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(Color(hex: habit.colorHex))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(SoulTheme.Font.card)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                HStack(spacing: 6) {
                    Text(habit.cue)
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                    if habit.streak > 0 {
                        RachaPill(days: habit.streak, isAlive: true)
                    }
                }
            }

            Spacer()

            Button {
                withAnimation(.spring(duration: 0.3)) { store.toggleHabit(habit) }
            } label: {
                ZStack {
                    Circle()
                        .stroke(SoulTheme.Color.primary, lineWidth: 1.5)
                        .frame(width: 32, height: 32)
                    if habit.isDoneToday {
                        Circle()
                            .fill(SoulTheme.Gradient.forest)
                            .frame(width: 32, height: 32)
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(SoulTheme.Color.backgroundWarm)
                    }
                }
            }
            .buttonStyle(.plain)
            .hapticOnTap()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                .fill(SoulTheme.Color.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                .stroke(SoulTheme.Color.divider, lineWidth: 0.5)
        )
        .contextMenu {
            Button(role: .destructive) {
                store.deleteHabit(habit)
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }
}

// MARK: - Shared streak card

struct SharedStreakCard: View {
    @EnvironmentObject private var store: AppStore
    let shared: SharedStreak

    var body: some View {
        let youMet = store.streak.isGoalMetToday
        let alive  = SharedStreakEngine.isAlive(shared, youMetToday: youMet)

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(hex: shared.friend.avatarColorHex))
                        .frame(width: 38, height: 38)
                    Text(shared.friend.initials)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(shared.friend.name)
                        .font(SoulTheme.Font.card)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Text(shared.friend.handle)
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
            }

            RachaFlame(days: shared.currentStreak, size: 64, isAlive: alive)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)

            HStack(spacing: 8) {
                Circle()
                    .fill(alive ? SoulTheme.Palette.moss : SoulTheme.Palette.heart)
                    .frame(width: 8, height: 8)
                Text(statusText(alive: alive, shared: shared))
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(width: 220, height: 210)
        .background(
            RoundedRectangle(cornerRadius: SoulTheme.Radius.lg)
                .fill(SoulTheme.Color.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: SoulTheme.Radius.lg)
                .stroke(SoulTheme.Color.divider, lineWidth: 0.5)
        )
    }

    private func statusText(alive: Bool, shared: SharedStreak) -> String {
        switch shared.status {
        case .pending: return "Invitación enviada"
        case .broken:  return "Racha rota — reinicia hoy"
        case .active:
            if alive {
                return "Los dos en pie hoy"
            } else if !shared.friendMetToday {
                return "\(shared.friend.name.split(separator: " ").first ?? "Tu amigo") aún no cumple hoy"
            } else {
                return "Te faltan hábitos hoy"
            }
        }
    }
}

// MARK: - Invite tile

struct InviteTile: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(SoulTheme.Palette.sand)
                        .frame(width: 54, height: 54)
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 22))
                        .foregroundStyle(SoulTheme.Color.primary)
                }
                Text("Invitar a un amigo")
                    .font(SoulTheme.Font.card)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Mantengan la racha juntos")
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(14)
            .frame(width: 180, height: 210)
            .background(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.lg)
                    .fill(SoulTheme.Palette.cream)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.lg)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1.2, dash: [4, 4]))
                    .foregroundStyle(SoulTheme.Color.primarySoft)
            )
        }
        .buttonStyle(.plain)
            .hapticOnTap()
    }
}

// MARK: - Sheets

struct AddHabitSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var cue = ""
    @State private var icon = "leaf.fill"
    @State private var colorHex: UInt32 = 0x8FA189

    private let icons = ["leaf.fill", "drop.fill", "figure.run", "wind",
                         "moon.stars.fill", "sparkles", "flame.fill",
                         "fork.knife", "heart.fill", "sun.max.fill"]
    private let colors: [UInt32] = [0x8FA189, 0x3F5248, 0xC68863,
                                     0xC9A66B, 0x6B4F3B, 0x9FB4B8, 0xB85C5C]

    var body: some View {
        NavigationStack {
            ZStack {
                SoulTheme.Color.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        TextField("Nombre del hábito", text: $title)
                            .font(SoulTheme.Font.bodyText)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14)
                                .fill(SoulTheme.Color.surface))

                        TextField("Cuándo lo harás (ej. al despertar)", text: $cue)
                            .font(SoulTheme.Font.bodyText)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14)
                                .fill(SoulTheme.Color.surface))

                        SoulEyebrow(text: "Icono")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(icons, id: \.self) { iconName in
                                    Button { icon = iconName } label: {
                                        Image(systemName: iconName)
                                            .font(.system(size: 22))
                                            .frame(width: 48, height: 48)
                                            .foregroundStyle(icon == iconName
                                                             ? SoulTheme.Color.backgroundWarm
                                                             : SoulTheme.Color.primary)
                                            .background(
                                                Circle()
                                                    .fill(icon == iconName
                                                          ? AnyShapeStyle(SoulTheme.Gradient.forest)
                                                          : AnyShapeStyle(SoulTheme.Color.surface))
                                            )
                                    }
                                }
                            }
                        }

                        SoulEyebrow(text: "Color")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HStack(spacing: 10) {
                            ForEach(colors, id: \.self) { c in
                                Circle()
                                    .fill(Color(hex: c))
                                    .frame(width: 34, height: 34)
                                    .overlay(
                                        Circle()
                                            .stroke(SoulTheme.Color.primary,
                                                    lineWidth: colorHex == c ? 2 : 0))
                                    .onTapGesture { colorHex = c }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Button {
                            store.addHabit(title: title.isEmpty ? "Nuevo hábito" : title,
                                           cue: cue,
                                           icon: icon,
                                           colorHex: colorHex)
                            dismiss()
                        } label: {
                            Text("Guardar hábito")
                        }
                        .buttonStyle(SoulPrimaryButtonStyle())
                        .padding(.top, 10)
                    }
                    .padding(SoulTheme.Spacing.lg)
                }
            }
            .navigationTitle("Nuevo hábito")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .tint(SoulTheme.Color.primary)
                }
            }
        }
    }
}

struct InviteFriendSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var handle = ""

    var body: some View {
        NavigationStack {
            ZStack {
                SoulTheme.Color.background.ignoresSafeArea()
                VStack(spacing: SoulTheme.Spacing.lg) {
                    VStack(spacing: 6) {
                        RachaFlame(days: 0, size: 72, isAlive: false)
                            .padding(.top, 20)
                        Text("Invita a un amigo")
                            .font(SoulTheme.Font.title)
                            .foregroundStyle(SoulTheme.Color.textPrimary)
                        Text("Mantengan la racha juntos. Si alguno de los dos rompe su meta, la racha conjunta se reinicia.")
                            .font(SoulTheme.Font.bodyText)
                            .foregroundStyle(SoulTheme.Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, SoulTheme.Spacing.lg)
                    }

                    SoulCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SoulEyebrow(text: "Handle o correo")
                            TextField("@amigo", text: $handle)
                                .font(SoulTheme.Font.bodyText)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                    }
                    .padding(.horizontal, SoulTheme.Spacing.lg)

                    Button { dismiss() } label: { Text("Enviar invitación") }
                        .buttonStyle(SoulPrimaryButtonStyle())
                        .padding(.horizontal, SoulTheme.Spacing.lg)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .tint(SoulTheme.Color.primary)
                }
            }
        }
    }
}

