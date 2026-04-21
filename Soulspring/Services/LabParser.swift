import Foundation
import PDFKit

/// Extracts raw text from a lab PDF and parses common Mexican / English
/// biomarker patterns into `Biomarker` values.
///
/// Works entirely on-device (no network). The AI layer (see
/// `LabAIService`) is optional: it takes the raw text and the parsed
/// markers and produces a narrative summary through Claude.
enum LabParser {

    // MARK: - Public entry point

    static func ingestPDF(at url: URL,
                          title: String = "Estudio de laboratorio",
                          lab: String = "Desconocido",
                          reportedAt: Date = Date()) -> LabReport? {
        guard let doc = PDFDocument(url: url) else { return nil }
        let text = extractText(doc)
        let markers = parseBiomarkers(from: text)
        let fileName = copyIntoDocuments(url: url)

        return LabReport(
            title: title,
            reportedAt: reportedAt,
            lab: lab,
            markers: markers,
            rawText: text,
            aiSummary: nil,
            localFileName: fileName
        )
    }

    // MARK: - Text extraction

    static func extractText(_ doc: PDFDocument) -> String {
        var out = ""
        for i in 0..<doc.pageCount {
            if let page = doc.page(at: i), let str = page.string {
                out += str + "\n"
            }
        }
        return out
    }

    // MARK: - Biomarker parsing

    static func parseBiomarkers(from text: String) -> [Biomarker] {
        let cleanText = normalize(text)
        var found: [Biomarker] = []
        var seenCanonicals: Set<String> = []

        for spec in BiomarkerCatalog.all {
            guard !seenCanonicals.contains(spec.canonical) else { continue }
            if let marker = scan(spec: spec, in: cleanText) {
                found.append(marker)
                seenCanonicals.insert(spec.canonical)
            }
        }
        return found
    }

    /// Lowercases, removes accents, collapses whitespace so aliases match
    /// regardless of source formatting.
    private static func normalize(_ input: String) -> String {
        let folded = input
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "es"))
            .lowercased()
        return folded.replacingOccurrences(of: "\\s+",
                                           with: " ",
                                           options: .regularExpression)
    }

    /// For each alias, search for `alias ... number [unit]`. Also tries to
    /// capture an inline reference range ("70 - 99").
    private static func scan(spec: BiomarkerSpec, in text: String) -> Biomarker? {
        let normalizedAliases = spec.aliases.map { alias in
            alias.folding(options: .diacriticInsensitive, locale: Locale(identifier: "es"))
                .lowercased()
        }

        for alias in normalizedAliases {
            // e.g. "glucosa ... 92 mg/dl ... 70 - 99"
            let pattern =
                "\(NSRegularExpression.escapedPattern(for: alias))" +
                "[^\\d\\-]{0,40}" +                         // words/colons/spaces
                "(?<value>\\d{1,4}(?:[.,]\\d{1,3})?)" +     // the value
                "(?:\\s*[a-zµ/%·³⁺]{0,10})?" +              // unit (skipped)
                "(?:[^\\d]{0,30}" +                         // optional range separator
                "(?<low>\\d{1,4}(?:[.,]\\d{1,3})?)\\s*[-–a]\\s*" +
                "(?<high>\\d{1,4}(?:[.,]\\d{1,3})?))?"

            guard let regex = try? NSRegularExpression(pattern: pattern,
                                                       options: [.caseInsensitive]) else {
                continue
            }
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            guard let match = regex.firstMatch(in: text, options: [], range: range) else {
                continue
            }

            let rawValue = substring(for: "value", in: match, text: text)
            guard let value = numeric(rawValue) else { continue }

            let low  = numeric(substring(for: "low",  in: match, text: text)) ?? spec.referenceLow
            let high = numeric(substring(for: "high", in: match, text: text)) ?? spec.referenceHigh

            return Biomarker(
                name: spec.canonical,
                value: value,
                unit: spec.unit,
                referenceLow: low,
                referenceHigh: high,
                category: spec.category
            )
        }
        return nil
    }

    private static func substring(for group: String,
                                  in match: NSTextCheckingResult,
                                  text: String) -> String? {
        let range = match.range(withName: group)
        guard range.location != NSNotFound,
              let r = Range(range, in: text) else { return nil }
        return String(text[r])
    }

    private static func numeric(_ s: String?) -> Double? {
        guard let s, !s.isEmpty else { return nil }
        return Double(s.replacingOccurrences(of: ",", with: "."))
    }

    // MARK: - File persistence

    @discardableResult
    private static func copyIntoDocuments(url: URL) -> String? {
        let fm = FileManager.default
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dest = docs.appendingPathComponent("labs/\(UUID().uuidString).pdf")
        try? fm.createDirectory(at: dest.deletingLastPathComponent(),
                                withIntermediateDirectories: true)

        let needsAccess = url.startAccessingSecurityScopedResource()
        defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            if fm.fileExists(atPath: dest.path) {
                try fm.removeItem(at: dest)
            }
            try fm.copyItem(at: url, to: dest)
            return dest.lastPathComponent
        } catch {
            return nil
        }
    }

    static func localURL(for fileName: String) -> URL? {
        guard let docs = FileManager.default.urls(for: .documentDirectory,
                                                  in: .userDomainMask).first else { return nil }
        return docs.appendingPathComponent("labs/\(fileName)")
    }
}
