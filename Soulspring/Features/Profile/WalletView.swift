import SwiftUI
import CoreImage.CIFilterBuiltins
import UIKit

/// Digital membership wallet. Scanned at check-in in the Sanctuary and
/// affiliated clinics. Shows:
///  • member QR (encodes member ID + active booking code)
///  • active stay / upcoming bookings
///  • saved payment method (future: auto-charge at check-in)
///  • history
struct WalletView: View {
    @EnvironmentObject private var store: AppStore
    @State private var isShowingPayment = false
    @State private var isShowingPassNotice = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                header
                membershipCard
                appleWalletButton
                profilePanel
                upcomingCard
                paymentCard
                historySection
            }
            .padding(SoulTheme.Spacing.lg)
        }
        .background(SoulBackground())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Wallet")
                    .font(SoulTheme.Font.sectionHead)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
            }
        }
        .sheet(isPresented: $isShowingPayment) { PaymentSheet() }
        .alert("Apple Wallet", isPresented: $isShowingPassNotice) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text("Para agregar tu pase a Apple Wallet necesitamos tu Pass Type ID Certificate de Apple Developer (pass.mx.soulspring.app). Una vez configurado, generamos el .pkpass firmado en el servidor y lo agregamos automáticamente.")
        }
    }

    // MARK: Apple Wallet CTA

    private var appleWalletButton: some View {
        Button {
            isShowingPassNotice = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "wallet.bifold.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Agregar al Apple Wallet")
                        .font(SoulTheme.Font.body(15, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Tu pase Soulspring siempre a la mano")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .fill(Color.black)
            )
        }
        .buttonStyle(.plain)
        .hapticOnTap()
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            SoulEyebrow(text: "Identidad")
            Text("Tu llave al Sanctuary.")
                .font(SoulTheme.Font.title)
                .foregroundStyle(SoulTheme.Color.textPrimary)
        }
    }

    // MARK: Membership card (QR)

    private var membershipCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: SoulTheme.Radius.lg)
                .fill(SoulTheme.Gradient.forest)
                .shadow(color: SoulTheme.Palette.moss.opacity(0.35), radius: 22, y: 12)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SOULSPRING")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(3)
                            .foregroundStyle(.white.opacity(0.85))
                        Text("Membership")
                            .font(SoulTheme.Font.display(22, weight: .regular))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.white.opacity(0.9))
                }

                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        field("Titular", store.profile.name.isEmpty ? "Invitado" : store.profile.name)
                        field("Plan", store.profile.membershipTier.rawValue)
                        field("ID", store.wallet.memberID)
                    }
                    Spacer()
                    QRCodeImage(string: qrPayload)
                        .frame(width: 110, height: 110)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.white))
                }

                Text("Muestra este QR al check-in para acceso y cobro automático.")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(SoulTheme.Spacing.lg)
        }
        .frame(height: 250)
    }

    private func field(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(SoulTheme.Font.card)
                .foregroundStyle(.white)
        }
    }

    private var qrPayload: String {
        var parts = ["soulspring://", "mid=\(store.wallet.memberID)"]
        if let stay = store.activeStay {
            parts.append("stay=\(stay.confirmationCode)")
        }
        return parts.joined(separator: "&")
    }

    // MARK: Profile panel (lo que ven cuando te escanean)

    private var profilePanel: some View {
        SoulCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SoulEyebrow(text: "Perfil")
                    Spacer()
                    NavigationLink {
                        MemberProfileEditor()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                            Text("Editar")
                        }
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.primary)
                    }
                }

                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(SoulTheme.Gradient.forest).frame(width: 54, height: 54)
                        Text(initials)
                            .font(SoulTheme.Font.display(20, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.profile.name.isEmpty ? "Invitado" : store.profile.name)
                            .font(SoulTheme.Font.card)
                            .foregroundStyle(SoulTheme.Color.textPrimary)
                        if !store.profile.handle.isEmpty {
                            Text(store.profile.handle)
                                .font(SoulTheme.Font.caption)
                                .foregroundStyle(SoulTheme.Color.textSecondary)
                        }
                        Text("Miembro desde \(store.profile.memberSince.formatted(.dateTime.month(.abbreviated).year()))")
                            .font(.system(size: 11))
                            .foregroundStyle(SoulTheme.Color.textSecondary)
                    }
                    Spacer()
                }

                SoulDivider()

                VStack(alignment: .leading, spacing: 10) {
                    profileRow(icon: "envelope", label: "Correo",
                               value: store.profile.email.isEmpty ? "—" : store.profile.email)
                    profileRow(icon: "phone", label: "Teléfono",
                               value: store.profile.phone.isEmpty ? "—" : store.profile.phone)
                    profileRow(icon: "figure.walk", label: "Actividad",
                               value: store.profile.activity.rawValue)
                    profileRow(icon: "sparkles", label: "Intención",
                               value: store.profile.goal.isEmpty ? "—" : store.profile.goal)
                }

                SoulDivider()

                VStack(alignment: .leading, spacing: 6) {
                    SoulEyebrow(text: "Intereses")
                    FlowLayout(spacing: 6) {
                        if store.profile.interests.isEmpty {
                            Text("Ninguno").font(SoulTheme.Font.caption)
                                .foregroundStyle(SoulTheme.Color.textSecondary)
                        }
                        ForEach(Array(store.profile.interests)) { i in
                            HStack(spacing: 5) {
                                Image(systemName: i.icon)
                                Text(i.rawValue)
                            }
                            .font(SoulTheme.Font.caption)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Capsule().fill(SoulTheme.Palette.cream))
                            .foregroundStyle(SoulTheme.Color.primary)
                        }
                    }
                }

                SoulDivider()

                VStack(alignment: .leading, spacing: 10) {
                    SoulEyebrow(text: "Info clínica · visible para el staff")
                    profileRow(icon: "cross.case", label: "Alergias",
                               value: store.profile.allergies.isEmpty ? "—" : store.profile.allergies)
                    profileRow(icon: "exclamationmark.triangle", label: "Notas",
                               value: store.profile.clinicalNotes.isEmpty ? "—" : store.profile.clinicalNotes)
                    profileRow(icon: "person.crop.circle.badge.exclamationmark",
                               label: "Emergencia",
                               value: formattedEmergency)
                }
            }
        }
    }

    private var initials: String {
        let parts = store.profile.name.split(separator: " ")
        let f = parts.first?.first.map(String.init) ?? "S"
        let l = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (f + l).uppercased()
    }

    private var formattedEmergency: String {
        let n = store.profile.emergencyContactName
        let p = store.profile.emergencyContactPhone
        if n.isEmpty && p.isEmpty { return "—" }
        return [n, p].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    private func profileRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SoulTheme.Color.primary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                Text(value)
                    .font(SoulTheme.Font.bodyText)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: Upcoming

    private var upcomingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SoulSectionHeader(eyebrow: "Próximamente",
                              title: "Tus reservaciones",
                              subtitle: nil)
            if let stay = store.activeStay {
                upcomingRow(
                    icon: "bed.double.fill",
                    title: "Estancia \(stay.tier.rawValue)",
                    subtitle: "\(stay.checkIn.formatted(date: .abbreviated, time: .omitted)) → \(stay.checkOut.formatted(date: .abbreviated, time: .omitted))",
                    code: stay.confirmationCode)
            }
            let futureExps = store.bookings
                .filter { $0.status == .confirmed && $0.slotDate > Date() }
                .sorted { $0.slotDate < $1.slotDate }
            ForEach(futureExps.prefix(4)) { b in
                upcomingRow(
                    icon: "sparkles",
                    title: b.experience.name,
                    subtitle: b.slotDate.formatted(date: .abbreviated, time: .shortened),
                    code: b.confirmationCode)
            }
            if store.activeStay == nil && futureExps.isEmpty {
                SoulCard {
                    Text("Aún no tienes reservaciones. Entra a la pestaña Santuario → Reservar.")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func upcomingRow(icon: String, title: String, subtitle: String, code: String) -> some View {
        SoulCard {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(SoulTheme.Palette.cream).frame(width: 42, height: 42)
                    Image(systemName: icon).foregroundStyle(SoulTheme.Color.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(SoulTheme.Font.card)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Text(subtitle)
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
                Spacer()
                Text(code)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(SoulTheme.Color.primary)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(SoulTheme.Palette.gold.opacity(0.2)))
            }
        }
    }

    // MARK: Payment

    private var paymentCard: some View {
        SoulCard {
            VStack(alignment: .leading, spacing: 12) {
                SoulEyebrow(text: "Método de pago")
                if let pm = store.wallet.paymentMethod {
                    HStack(spacing: 12) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(SoulTheme.Color.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(pm.brand.rawValue) •••• \(pm.last4)")
                                .font(SoulTheme.Font.card)
                                .foregroundStyle(SoulTheme.Color.textPrimary)
                            Text("\(pm.holder) · Vence \(String(format: "%02d", pm.expMonth))/\(pm.expYear % 100)")
                                .font(SoulTheme.Font.caption)
                                .foregroundStyle(SoulTheme.Color.textSecondary)
                        }
                        Spacer()
                        Button("Cambiar") { isShowingPayment = true }
                            .font(SoulTheme.Font.caption)
                            .foregroundStyle(SoulTheme.Color.primary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Agrega una tarjeta para cobro automático al check-in.")
                            .font(SoulTheme.Font.bodyText)
                            .foregroundStyle(SoulTheme.Color.textSecondary)
                        Button { isShowingPayment = true } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Agregar tarjeta")
                            }
                        }
                        .buttonStyle(SoulSecondaryButtonStyle())
                    }
                }
            }
        }
    }

    // MARK: History

    private var historySection: some View {
        let past = store.bookings.filter { $0.slotDate <= Date() }
            .sorted { $0.slotDate > $1.slotDate }
        return Group {
            if !past.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    SoulSectionHeader(eyebrow: "Historial",
                                      title: "Tus visitas",
                                      subtitle: nil)
                    ForEach(past.prefix(5)) { b in
                        SoulCard {
                            HStack(spacing: 12) {
                                Text(b.experience.emoji).font(.system(size: 22))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(b.experience.name)
                                        .font(SoulTheme.Font.card)
                                        .foregroundStyle(SoulTheme.Color.textPrimary)
                                    Text(b.slotDate.formatted(date: .abbreviated, time: .shortened))
                                        .font(SoulTheme.Font.caption)
                                        .foregroundStyle(SoulTheme.Color.textSecondary)
                                }
                                Spacer()
                                SoulChip(text: b.status.rawValue, tint: SoulTheme.Palette.moss)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Member profile editor

struct MemberProfileEditor: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                group("Identidad") {
                    field("Nombre completo", text: binding(\.name))
                    field("Handle", text: binding(\.handle), placeholder: "@tunombre")
                    field("Correo", text: binding(\.email), kb: .emailAddress)
                    field("Teléfono", text: binding(\.phone), kb: .phonePad)
                }
                group("Estilo de vida") {
                    Picker("Rango de edad", selection: binding(\.age)) {
                        ForEach(AgeBracket.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Actividad", selection: binding(\.activity)) {
                        ForEach(ActivityLevel.allCases) { Text($0.rawValue).tag($0) }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        SoulEyebrow(text: "Intención")
                        TextField("Lo que persigues ahora", text: binding(\.goal), axis: .vertical)
                            .font(SoulTheme.Font.bodyText)
                            .lineLimit(2, reservesSpace: true)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10)
                                .fill(SoulTheme.Palette.cream.opacity(0.6)))
                    }
                }
                group("Información clínica") {
                    field("Alergias", text: binding(\.allergies))
                    field("Notas clínicas", text: binding(\.clinicalNotes))
                    field("Contacto de emergencia", text: binding(\.emergencyContactName))
                    field("Teléfono de emergencia",
                          text: binding(\.emergencyContactPhone), kb: .phonePad)
                }
            }
            .padding(SoulTheme.Spacing.lg)
        }
        .background(SoulBackground())
        .navigationTitle("Editar perfil")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func binding<T>(_ keyPath: WritableKeyPath<UserProfile, T>) -> Binding<T> {
        Binding(get: { store.profile[keyPath: keyPath] },
                set: { store.profile[keyPath: keyPath] = $0 })
    }

    @ViewBuilder
    private func group<Content: View>(_ title: String,
                                      @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SoulEyebrow(text: title)
            SoulCard {
                VStack(alignment: .leading, spacing: 10) {
                    content()
                }
            }
        }
    }

    private func field(_ label: String,
                       text: Binding<String>,
                       placeholder: String = "",
                       kb: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1)
                .foregroundStyle(SoulTheme.Color.textSecondary)
            TextField(placeholder.isEmpty ? label : placeholder, text: text)
                .keyboardType(kb)
                .font(SoulTheme.Font.bodyText)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10)
                    .fill(SoulTheme.Palette.cream.opacity(0.6)))
        }
    }
}

// MARK: - QR

struct QRCodeImage: View {
    let string: String
    private let ctx = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        if let img = generate() {
            Image(uiImage: img)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            Color.gray
        }
    }

    private func generate() -> UIImage? {
        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cg = ctx.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

// MARK: - Payment sheet (stub for future Stripe / Apple Pay)

struct PaymentSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var holder = ""
    @State private var number = ""
    @State private var expMonth = ""
    @State private var expYear = ""
    @State private var cvv = ""
    @State private var brand: PaymentMethod.Brand = .visa

    var body: some View {
        NavigationStack {
            ZStack {
                SoulTheme.Color.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                        SoulSectionHeader(
                            eyebrow: "Tarjeta",
                            title: "Cobro automático al check-in",
                            subtitle: "Tus datos se guardarán cifrados. Integración real con Stripe pronto.")

                        SoulCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Picker("Marca", selection: $brand) {
                                    ForEach(PaymentMethod.Brand.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                                }
                                .pickerStyle(.segmented)

                                textField("Nombre del titular", text: $holder)
                                textField("Número de tarjeta", text: $number, kb: .numberPad)
                                HStack(spacing: 8) {
                                    textField("MM", text: $expMonth, kb: .numberPad)
                                    textField("AAAA", text: $expYear, kb: .numberPad)
                                    textField("CVV", text: $cvv, kb: .numberPad)
                                }
                            }
                        }

                        Button {
                            let last4 = String(number.suffix(4))
                            let pm = PaymentMethod(
                                brand: brand,
                                last4: last4.isEmpty ? "0000" : last4,
                                holder: holder.isEmpty ? "SoulSpring" : holder,
                                expMonth: Int(expMonth) ?? 12,
                                expYear: Int(expYear) ?? 2030
                            )
                            store.attachPayment(pm)
                            dismiss()
                        } label: {
                            Text("Guardar tarjeta")
                        }
                        .buttonStyle(SoulPrimaryButtonStyle())
                    }
                    .padding(SoulTheme.Spacing.lg)
                }
            }
            .navigationTitle("Nueva tarjeta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }.tint(SoulTheme.Color.primary)
                }
            }
        }
    }

    private func textField(_ placeholder: String,
                           text: Binding<String>,
                           kb: UIKeyboardType = .default) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(kb)
            .font(SoulTheme.Font.bodyText)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10)
                .fill(SoulTheme.Palette.cream.opacity(0.6)))
    }
}
