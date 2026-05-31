import SwiftUI

/// Send a SoulSpring gift card to someone. The recipient gets an email with
/// a redeem code that can be applied at check-in or to any experience.
struct GiftCardView: View {
    @EnvironmentObject private var store: AppStore

    @State private var amount: Int = 2_500
    @State private var design: GiftCard.Design = .dawn
    @State private var recipientName = ""
    @State private var recipientEmail = ""
    @State private var message = "Con cariño, para que te regales un día de Soulspring."
    @State private var sent: GiftCard? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                header
                previewCard
                amountPicker
                designPicker
                recipientCard
                sendButton
                if !store.giftCards.isEmpty { historySection }
            }
            .padding(SoulTheme.Spacing.lg)
        }
        .background(SoulBackground())
        .navigationTitle("Tarjeta de regalo")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $sent) { card in
            GiftCardSuccessSheet(card: card)
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            SoulEyebrow(text: "Regala Soulspring")
            Text("Un gesto con raíces.")
                .font(SoulTheme.Font.title)
                .foregroundStyle(SoulTheme.Color.textPrimary)
            Text("El monto se acredita como saldo para estancias, experiencias o Soul Kitchen.")
                .font(SoulTheme.Font.caption)
                .foregroundStyle(SoulTheme.Color.textSecondary)
        }
    }

    // MARK: Preview

    private var previewCard: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: SoulTheme.Radius.lg)
                .fill(gradient(for: design))
            Image(systemName: "leaf.fill")
                .font(.system(size: 120))
                .foregroundStyle(.white.opacity(0.08))
                .offset(x: 180, y: -30)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SOULSPRING")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(3)
                        Text("Tarjeta de regalo")
                            .font(SoulTheme.Font.display(22, weight: .regular))
                    }
                    Spacer()
                    Image(systemName: "gift.fill")
                        .font(.system(size: 26))
                }
                Spacer()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Monto")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.5)
                            .opacity(0.8)
                        Text("$\(amount) MXN")
                            .font(SoulTheme.Font.display(34, weight: .semibold))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Para")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.5)
                            .opacity(0.8)
                        Text(recipientName.isEmpty ? "—" : recipientName)
                            .font(SoulTheme.Font.card)
                    }
                }
            }
            .foregroundStyle(.white)
            .padding(SoulTheme.Spacing.lg)
        }
        .frame(height: 210)
        .shadow(color: SoulTheme.Palette.earth.opacity(0.25), radius: 18, y: 10)
    }

    // MARK: Amount

    private var amountPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            SoulEyebrow(text: "Monto")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(GiftCard.amountOptions, id: \.self) { value in
                        Button { amount = value } label: {
                            Text("$\(value)")
                                .font(SoulTheme.Font.card)
                                .foregroundStyle(amount == value
                                                 ? SoulTheme.Color.backgroundWarm
                                                 : SoulTheme.Color.textPrimary)
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(
                                    Capsule().fill(amount == value
                                                   ? AnyShapeStyle(SoulTheme.Gradient.forest)
                                                   : AnyShapeStyle(SoulTheme.Color.surface)))
                                .overlay(Capsule().stroke(SoulTheme.Color.divider, lineWidth: 0.5))
                        }
                    }
                }
            }
        }
    }

    // MARK: Design

    private var designPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            SoulEyebrow(text: "Diseño")
            HStack(spacing: 10) {
                ForEach(GiftCard.Design.allCases) { d in
                    Button { design = d } label: {
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(gradient(for: d))
                                .frame(width: 58, height: 40)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(design == d ? SoulTheme.Color.primary : .clear,
                                                lineWidth: 2)
                                )
                            Text(d.rawValue)
                                .font(SoulTheme.Font.caption)
                                .foregroundStyle(SoulTheme.Color.textSecondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: Recipient

    private var recipientCard: some View {
        SoulCard {
            VStack(alignment: .leading, spacing: 10) {
                SoulEyebrow(text: "Destinatario")
                TextField("Nombre", text: $recipientName)
                    .font(SoulTheme.Font.bodyText)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10)
                        .fill(SoulTheme.Palette.cream.opacity(0.6)))
                TextField("Correo electrónico", text: $recipientEmail)
                    .font(SoulTheme.Font.bodyText)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10)
                        .fill(SoulTheme.Palette.cream.opacity(0.6)))

                SoulEyebrow(text: "Mensaje")
                TextField("", text: $message, axis: .vertical)
                    .font(SoulTheme.Font.bodyText)
                    .lineLimit(3, reservesSpace: true)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10)
                        .fill(SoulTheme.Palette.cream.opacity(0.6)))
            }
        }
    }

    // MARK: Send

    private var sendButton: some View {
        Button {
            guard !recipientName.isEmpty && !recipientEmail.isEmpty else { return }
            let card = store.sendGiftCard(
                to: recipientName,
                email: recipientEmail,
                amount: amount,
                message: message,
                design: design
            )
            sent = card
        } label: {
            Text("Enviar regalo · $\(amount) MXN")
        }
        .buttonStyle(SoulPrimaryButtonStyle())
        .disabled(recipientName.isEmpty || recipientEmail.isEmpty)
        .opacity(recipientName.isEmpty || recipientEmail.isEmpty ? 0.5 : 1)
    }

    // MARK: History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SoulSectionHeader(eyebrow: "Enviadas",
                              title: "Tus regalos",
                              subtitle: nil)
            ForEach(store.giftCards) { card in
                SoulCard {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(gradient(for: card.design))
                            .frame(width: 38, height: 26)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(card.recipientName)
                                .font(SoulTheme.Font.card)
                                .foregroundStyle(SoulTheme.Color.textPrimary)
                            Text(card.redeemCode)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(SoulTheme.Color.textSecondary)
                        }
                        Spacer()
                        Text("$\(card.amountMXN)")
                            .font(SoulTheme.Font.card)
                            .foregroundStyle(SoulTheme.Color.primary)
                    }
                }
            }
        }
    }

    private func gradient(for design: GiftCard.Design) -> LinearGradient {
        switch design {
        case .dawn:   return SoulTheme.Gradient.dawn
        case .forest: return SoulTheme.Gradient.forest
        case .sunset: return SoulTheme.Gradient.sunset
        case .breath: return SoulTheme.Gradient.breath
        }
    }
}

// MARK: - Success sheet

struct GiftCardSuccessSheet: View {
    let card: GiftCard
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            SoulTheme.Gradient.dawn.ignoresSafeArea()
            VStack(spacing: SoulTheme.Spacing.lg) {
                Spacer(minLength: 40)
                ZStack {
                    Circle().fill(SoulTheme.Gradient.forest).frame(width: 88, height: 88)
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                }

                Text("Regalo enviado")
                    .font(SoulTheme.Font.title)
                    .foregroundStyle(SoulTheme.Color.textPrimary)

                Text("\(card.recipientName) recibirá la tarjeta con un mensaje tuyo y el código de canje.")
                    .font(SoulTheme.Font.bodyText)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SoulTheme.Spacing.lg)

                SoulCard(padding: SoulTheme.Spacing.lg) {
                    VStack(spacing: 6) {
                        SoulEyebrow(text: "Código")
                        Text(card.redeemCode)
                            .font(SoulTheme.Font.display(22, weight: .semibold))
                            .foregroundStyle(SoulTheme.Color.primary)
                            .tracking(2)
                    }
                }
                .padding(.horizontal, SoulTheme.Spacing.lg)

                Spacer()

                Button { dismiss() } label: { Text("Listo") }
                    .buttonStyle(SoulPrimaryButtonStyle())
                    .padding(.horizontal, SoulTheme.Spacing.lg)
                    .padding(.bottom, SoulTheme.Spacing.lg)
            }
        }
    }
}
