import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var health: HealthKitManager
    @State private var isShowingMembership = false

    private var unlockedCount: Int { store.unlockedAchievements.count }
    private var totalAchievements: Int { Achievement.catalog.count }

    var body: some View {
        NavigationStack {
            ZStack {
                SoulBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: SoulTheme.Spacing.lg) {
                        identityCard
                        walletShortcut
                        interestsCard
                        membershipCard
                        actionsCard
                    }
                    .padding(.horizontal, SoulTheme.Spacing.lg)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isShowingMembership) { MembershipSheet() }
        }
    }

    // MARK: Identity

    private var identityCard: some View {
        SoulCard(padding: SoulTheme.Spacing.lg) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(SoulTheme.Gradient.forest)
                        .frame(width: 72, height: 72)
                    Text(initials)
                        .font(SoulTheme.Font.display(26, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    SoulEyebrow(text: store.auth.isGuest ? "Modo invitado" : "Miembro")
                    Text(store.profile.name.isEmpty ? "Invitado" : store.profile.name)
                        .font(SoulTheme.Font.title)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Text("\(store.profile.age.rawValue) · \(store.profile.activity.rawValue)")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
                Spacer()
            }
        }
    }

    private var initials: String {
        let parts = store.profile.name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? "S"
        let last  = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }

    // MARK: Wallet shortcut

    private var walletShortcut: some View {
        NavigationLink {
            WalletView()
        } label: {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: SoulTheme.Radius.lg)
                    .fill(SoulTheme.Gradient.forest)
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SOULSPRING").font(.system(size: 10, weight: .bold))
                            .tracking(2.5).foregroundStyle(.white.opacity(0.85))
                        Text("Wallet")
                            .font(SoulTheme.Font.display(24, weight: .regular))
                            .foregroundStyle(.white)
                        Text("Tu membresía, perfil y QR de check-in.")
                            .font(SoulTheme.Font.caption)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(SoulTheme.Spacing.lg)
            }
            .frame(height: 128)
            .shadow(color: SoulTheme.Palette.moss.opacity(0.3), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
            .hapticOnTap()
    }

    // MARK: Interests

    private var interestsCard: some View {
        SoulCard {
            VStack(alignment: .leading, spacing: 12) {
                SoulSectionHeader(eyebrow: "Intereses",
                                  title: "Tu camino",
                                  subtitle: "Adaptamos las recomendaciones a ti.")
                FlowLayout(spacing: 8) {
                    ForEach(Array(store.profile.interests)) { interest in
                        HStack(spacing: 6) {
                            Image(systemName: interest.icon)
                            Text(interest.rawValue)
                        }
                        .font(SoulTheme.Font.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(SoulTheme.Palette.cream))
                        .foregroundStyle(SoulTheme.Color.primary)
                    }
                }
                if store.profile.interests.isEmpty {
                    Text("Aún no eliges intereses.")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
                if !store.profile.goal.isEmpty {
                    SoulDivider()
                    SoulEyebrow(text: "Tu intención")
                    Text("“\(store.profile.goal)”")
                        .font(SoulTheme.Font.display(18, weight: .regular))
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                }
            }
        }
    }

    // MARK: Membership

    private var membershipCard: some View {
        let tier = store.profile.membershipTier
        return Button { isShowingMembership = true } label: {
            SoulCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        SoulEyebrow(text: "Plan de estancia")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(SoulTheme.Color.textSecondary)
                    }
                    Text(tier.rawValue)
                        .font(SoulTheme.Font.title)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("$\(tier.nightlyCostMXN)")
                            .font(SoulTheme.Font.display(34, weight: .semibold))
                            .foregroundStyle(SoulTheme.Color.primary)
                        Text("MXN / noche")
                            .font(SoulTheme.Font.unit)
                            .foregroundStyle(SoulTheme.Color.textSecondary)
                    }
                    Text(tier.tagline)
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(tier.includes, id: \.self) { perk in
                            HStack(spacing: 8) {
                                Image(systemName: "leaf.fill")
                                    .foregroundStyle(SoulTheme.Palette.moss)
                                Text(perk)
                                    .font(SoulTheme.Font.caption)
                                    .foregroundStyle(SoulTheme.Color.textSecondary)
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
            .hapticOnTap()
    }

    // MARK: Actions

    private var actionsCard: some View {
        VStack(spacing: 10) {
            NavigationLink {
                SoulChatView()
            } label: {
                actionRow(icon: "sparkles",
                          title: "Chat con Soul",
                          subtitle: "Tu coach de bienestar",
                          tint: SoulTheme.Palette.terracotta)
            }
            NavigationLink {
                AudioLibraryView()
            } label: {
                actionRow(icon: "headphones",
                          title: "Biblioteca de audios",
                          subtitle: "Meditaciones, yoga nidra, breathwork",
                          tint: SoulTheme.Palette.lilac)
            }
            NavigationLink {
                AchievementsView()
            } label: {
                actionRow(icon: "rosette",
                          title: "Mis medallas",
                          subtitle: "\(unlockedCount) de \(totalAchievements) desbloqueadas",
                          tint: SoulTheme.Palette.gold)
            }
            NavigationLink {
                MoodPatternsView()
            } label: {
                actionRow(icon: "chart.line.uptrend.xyaxis",
                          title: "Mood + patrones",
                          subtitle: store.moodLog.isEmpty
                            ? "Empieza tu primer check-in"
                            : "\(store.moodLog.count) check-ins guardados",
                          tint: SoulTheme.Palette.sky)
            }
            NavigationLink {
                FinancesView()
            } label: {
                actionRow(icon: "chart.pie.fill",
                          title: "Finanzas",
                          subtitle: "Ingresos, egresos y presupuestos",
                          tint: SoulTheme.Palette.moss)
            }
            NavigationLink {
                GiftCardView()
            } label: {
                actionRow(icon: "gift.fill",
                          title: "Regalar Soulspring",
                          subtitle: "Envía una tarjeta de regalo",
                          tint: SoulTheme.Palette.terracotta)
            }
            NavigationLink {
                MemberProfileEditor()
            } label: {
                actionRow(icon: "person.text.rectangle",
                          title: "Editar mi perfil",
                          subtitle: "Contacto, intereses, alergias")
            }
            Link(destination: SoulLinks.foodInstagram) {
                actionRow(icon: "camera.fill", title: "Instagram Soul Kitchen",
                          subtitle: SoulLinks.foodHandle)
            }
            Button {
                Task { await health.requestAuthorization() }
            } label: {
                actionRow(icon: "heart.text.square",
                          title: "Conectar Apple Health",
                          subtitle: health.isAuthorized ? "Sincronizado" : "Permitir acceso")
            }
            if store.isChef {
                actionRow(icon: "fork.knife.circle.fill",
                          title: "Modo Chef activo",
                          subtitle: "Puedes editar el Menú del día",
                          tint: SoulTheme.Palette.terracotta)
            }
            Button {
                store.signOut()
            } label: {
                actionRow(icon: "arrow.right.square",
                          title: store.auth.isGuest ? "Crear una cuenta" : "Cerrar sesión",
                          subtitle: store.auth.isGuest ? "Guarda tu progreso" : "",
                          tint: SoulTheme.Palette.heart)
            }
        }
    }

    private func actionRow(icon: String,
                           title: String,
                           subtitle: String,
                           tint: Color = SoulTheme.Palette.moss) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(tint.opacity(0.12)).frame(width: 42, height: 42)
                Image(systemName: icon).foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SoulTheme.Font.card)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
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

// MARK: - Membership sheet

struct MembershipSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                SoulBackground()
                ScrollView {
                    VStack(spacing: SoulTheme.Spacing.md) {
                        SoulSectionHeader(eyebrow: "Planes de estancia",
                                          title: "Elige tu plan",
                                          subtitle: "Precio por noche. Todos los planes incluyen la app.")
                        ForEach(MembershipTier.allCases) { tier in
                            TierCard(tier: tier,
                                     isCurrent: store.profile.membershipTier == tier) {
                                store.profile.membershipTier = tier
                                dismiss()
                            }
                        }
                    }
                    .padding(SoulTheme.Spacing.lg)
                }
            }
            .navigationTitle("")
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

struct TierCard: View {
    let tier: MembershipTier
    let isCurrent: Bool
    let onPick: () -> Void

    var body: some View {
        Button(action: onPick) {
            SoulCard(padding: SoulTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(tier.rawValue)
                            .font(SoulTheme.Font.title)
                            .foregroundStyle(SoulTheme.Color.textPrimary)
                        Spacer()
                        if isCurrent {
                            SoulChip(text: "Tu plan", tint: SoulTheme.Palette.moss)
                        }
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("$\(tier.nightlyCostMXN)")
                            .font(SoulTheme.Font.display(40, weight: .semibold))
                            .foregroundStyle(SoulTheme.Color.primary)
                        Text("MXN / noche")
                            .font(SoulTheme.Font.unit)
                            .foregroundStyle(SoulTheme.Color.textSecondary)
                    }
                    Text(tier.tagline)
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(tier.includes, id: \.self) { perk in
                            HStack(spacing: 8) {
                                Image(systemName: "leaf.fill")
                                    .foregroundStyle(SoulTheme.Palette.moss)
                                Text(perk)
                                    .font(SoulTheme.Font.bodyText)
                                    .foregroundStyle(SoulTheme.Color.textPrimary)
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
            .hapticOnTap()
    }
}

// MARK: - Flow layout for chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var width: CGFloat = 0
        var height: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if lineWidth + size.width > maxWidth {
                width = max(width, lineWidth)
                height += lineHeight + spacing
                lineWidth = size.width + spacing
                lineHeight = size.height
            } else {
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
        }
        width = max(width, lineWidth)
        height += lineHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y),
                       proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
