import SwiftUI
import UniformTypeIdentifiers
import PDFKit

/// Main list of lab reports. Lets the user upload a new PDF and tap into a
/// report to see parsed biomarkers, reference ranges and the AI summary.
struct LabsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var isPicking = false
    @State private var isImporting = false
    @State private var importMeta = ImportMeta()

    struct ImportMeta {
        var url: URL?
        var title: String = "Estudio de laboratorio"
        var lab: String = ""
        var reportedAt: Date = Date()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                header
                uploadCard
                if store.labReports.isEmpty {
                    emptyState
                } else {
                    ForEach(store.labReports) { report in
                        NavigationLink {
                            LabReportDetailView(report: report)
                        } label: { LabReportCard(report: report) }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(SoulTheme.Spacing.lg)
        }
        .background(SoulBackground())
        .navigationTitle("Laboratorios")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $isPicking,
                      allowedContentTypes: [.pdf],
                      allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                importMeta.url = url
                importMeta.title = url.deletingPathExtension().lastPathComponent
                importMeta.reportedAt = Date()
                isImporting = true
            case .failure:
                break
            }
        }
        .sheet(isPresented: $isImporting) {
            LabImportSheet(meta: $importMeta)
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            SoulEyebrow(text: "Longevidad · Laboratorios")
            Text("Tus marcadores.")
                .font(SoulTheme.Font.title)
                .foregroundStyle(SoulTheme.Color.textPrimary)
            Text("Sube el PDF y lo analizamos. Nuestro equipo médico lo revisa en tu próxima estancia.")
                .font(SoulTheme.Font.caption)
                .foregroundStyle(SoulTheme.Color.textSecondary)
        }
    }

    // MARK: Upload card

    private var uploadCard: some View {
        Button { isPicking = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(SoulTheme.Palette.gold.opacity(0.2)).frame(width: 54, height: 54)
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 24))
                        .foregroundStyle(SoulTheme.Color.primary)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Subir laboratorio")
                        .font(SoulTheme.Font.card)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Text("PDF · 30+ biomarcadores reconocidos")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
                Spacer()
                Image(systemName: "arrow.up.doc.fill")
                    .foregroundStyle(SoulTheme.Color.primary)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                .fill(SoulTheme.Color.surface))
            .overlay(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                .foregroundStyle(SoulTheme.Color.primarySoft))
        }
        .buttonStyle(.plain)
    }

    // MARK: Empty

    private var emptyState: some View {
        SoulCard {
            VStack(spacing: 10) {
                Image(systemName: "tray")
                    .font(.system(size: 30))
                    .foregroundStyle(SoulTheme.Color.primarySoft)
                Text("Aún no tienes estudios cargados.")
                    .font(SoulTheme.Font.card)
                    .foregroundStyle(SoulTheme.Color.textPrimary)
                Text("Sube tu primer PDF. La IA extrae cada marcador y te explica qué significa.")
                    .font(SoulTheme.Font.caption)
                    .foregroundStyle(SoulTheme.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Report card

struct LabReportCard: View {
    let report: LabReport
    var body: some View {
        SoulCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                        .fill(SoulTheme.Palette.cream)
                        .frame(width: 54, height: 54)
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(SoulTheme.Color.primary)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(report.title)
                        .font(SoulTheme.Font.card)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Text("\(report.lab) · \(report.reportedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(SoulTheme.Font.caption)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                    HStack(spacing: 6) {
                        SoulChip(text: "\(report.markers.count) marcadores",
                                 tint: SoulTheme.Palette.moss)
                        if report.outOfRangeCount > 0 {
                            SoulChip(text: "\(report.outOfRangeCount) fuera de rango",
                                     tint: SoulTheme.Palette.heart)
                        }
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SoulTheme.Color.textSecondary)
            }
        }
    }
}

// MARK: - Report detail

struct LabReportDetailView: View {
    @EnvironmentObject private var store: AppStore
    let report: LabReport

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                header
                summaryCard
                if let url = pdfURL {
                    pdfPreview(url: url)
                }
                markersByCategory
            }
            .padding(SoulTheme.Spacing.lg)
        }
        .background(SoulBackground())
        .navigationTitle("Estudio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        store.deleteLab(report)
                    } label: { Label("Eliminar", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
    }

    private var pdfURL: URL? {
        guard let name = report.localFileName else { return nil }
        return LabParser.localURL(for: name)
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            SoulEyebrow(text: report.lab)
            Text(report.title)
                .font(SoulTheme.Font.title)
                .foregroundStyle(SoulTheme.Color.textPrimary)
            Text(report.reportedAt.formatted(date: .abbreviated, time: .omitted))
                .font(SoulTheme.Font.caption)
                .foregroundStyle(SoulTheme.Color.textSecondary)
        }
    }

    // MARK: Summary card

    private var summaryCard: some View {
        SoulCard(padding: SoulTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(SoulTheme.Palette.gold)
                    SoulEyebrow(text: "Lectura Soulspring · IA")
                }

                if let summary = report.aiSummary {
                    Text(summary)
                        .font(SoulTheme.Font.bodyText)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ProgressView("Analizando…")
                        .tint(SoulTheme.Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                }

                HStack(spacing: 8) {
                    SoulChip(text: "\(report.markers.count) marcadores",
                             tint: SoulTheme.Palette.moss)
                    if report.outOfRangeCount > 0 {
                        SoulChip(text: "\(report.outOfRangeCount) fuera de rango",
                                 tint: SoulTheme.Palette.heart)
                    }
                }
            }
        }
    }

    // MARK: PDF preview

    private func pdfPreview(url: URL) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SoulEyebrow(text: "PDF original")
            PDFKitView(url: url)
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: SoulTheme.Radius.md))
                .overlay(RoundedRectangle(cornerRadius: SoulTheme.Radius.md)
                    .stroke(SoulTheme.Color.divider, lineWidth: 0.5))
        }
    }

    // MARK: Markers

    private var markersByCategory: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(report.byCategory, id: \.0) { (cat, markers) in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: cat.icon)
                            .foregroundStyle(SoulTheme.Color.primary)
                        Text(cat.rawValue)
                            .font(SoulTheme.Font.sectionHead)
                            .foregroundStyle(SoulTheme.Color.textPrimary)
                    }
                    ForEach(markers) { marker in
                        MarkerRow(marker: marker)
                    }
                }
            }
        }
    }
}

struct MarkerRow: View {
    let marker: Biomarker

    private var tint: Color {
        switch marker.status {
        case .low:    return SoulTheme.Palette.sky
        case .high:   return SoulTheme.Palette.heart
        case .normal: return SoulTheme.Palette.moss
        case .unknown:return SoulTheme.Palette.earth
        }
    }

    var body: some View {
        SoulCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(marker.name)
                        .font(SoulTheme.Font.card)
                        .foregroundStyle(SoulTheme.Color.textPrimary)
                    Spacer()
                    SoulChip(text: marker.status.rawValue, tint: tint)
                }
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(valueString)
                        .font(SoulTheme.Font.display(26, weight: .semibold))
                        .foregroundStyle(tint)
                    Text(marker.unit)
                        .font(SoulTheme.Font.unit)
                        .foregroundStyle(SoulTheme.Color.textSecondary)
                }
                if marker.referenceLow != nil || marker.referenceHigh != nil {
                    referenceBar
                }
            }
        }
    }

    private var valueString: String {
        marker.value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", marker.value)
            : String(format: "%.2f", marker.value)
    }

    private var referenceBar: some View {
        let lo = marker.referenceLow ?? (marker.value - marker.value * 0.4)
        let hi = marker.referenceHigh ?? (marker.value + marker.value * 0.4)
        let span = max(hi - lo, 0.001)
        let padding = span * 0.3
        let totalLo = lo - padding
        let totalHi = hi + padding
        let position = max(0, min(1, (marker.value - totalLo) / (totalHi - totalLo)))

        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(SoulTheme.Palette.sand).frame(height: 6)
                Capsule()
                    .fill(SoulTheme.Palette.moss.opacity(0.5))
                    .frame(
                        width: geo.size.width * ((hi - lo) / (totalHi - totalLo)),
                        height: 6)
                    .offset(x: geo.size.width * ((lo - totalLo) / (totalHi - totalLo)))
                Circle()
                    .fill(tint)
                    .frame(width: 12, height: 12)
                    .offset(x: geo.size.width * position - 6, y: 0)
            }
        }
        .frame(height: 12)
        .padding(.top, 4)
    }
}

// MARK: - PDFKit wrapper

struct PDFKitView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = PDFDocument(url: url)
        view.autoScales = true
        view.backgroundColor = .clear
        return view
    }
    func updateUIView(_ uiView: PDFView, context: Context) {}
}

// MARK: - Import sheet

struct LabImportSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Binding var meta: LabsView.ImportMeta
    @State private var isAnalyzing = false

    var body: some View {
        NavigationStack {
            ZStack {
                SoulTheme.Color.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: SoulTheme.Spacing.md) {
                        SoulSectionHeader(
                            eyebrow: "Nuevo estudio",
                            title: "Confirma los datos",
                            subtitle: "Antes de analizar con IA.")

                        SoulCard {
                            VStack(alignment: .leading, spacing: 12) {
                                field(label: "Título", text: $meta.title,
                                      placeholder: "Ej. Check-up anual")
                                field(label: "Laboratorio", text: $meta.lab,
                                      placeholder: "Chopo, Azteca, Salud Digna…")
                                DatePicker("Fecha del estudio",
                                           selection: $meta.reportedAt,
                                           displayedComponents: .date)
                                    .font(SoulTheme.Font.bodyText)
                            }
                        }

                        Button {
                            guard let url = meta.url else { return }
                            isAnalyzing = true
                            Task {
                                _ = await store.importLab(pdfURL: url,
                                                          title: meta.title,
                                                          lab: meta.lab,
                                                          reportedAt: meta.reportedAt)
                                isAnalyzing = false
                                dismiss()
                            }
                        } label: {
                            HStack {
                                if isAnalyzing {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(isAnalyzing ? "Analizando…" : "Analizar con IA")
                            }
                        }
                        .buttonStyle(SoulPrimaryButtonStyle())
                        .disabled(isAnalyzing)

                        Text("Tu PDF se guarda cifrado en este dispositivo. El análisis usa Claude si está configurado; de lo contrario, un analizador local.")
                            .font(.system(size: 11))
                            .foregroundStyle(SoulTheme.Color.textSecondary)
                            .padding(.horizontal, 4)
                    }
                    .padding(SoulTheme.Spacing.lg)
                }
            }
            .navigationTitle("Subir PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }.tint(SoulTheme.Color.primary)
                }
            }
        }
    }

    private func field(label: String,
                       text: Binding<String>,
                       placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1)
                .foregroundStyle(SoulTheme.Color.textSecondary)
            TextField(placeholder, text: text)
                .font(SoulTheme.Font.bodyText)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10)
                    .fill(SoulTheme.Palette.cream.opacity(0.6)))
        }
    }
}
