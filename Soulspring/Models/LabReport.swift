import Foundation

/// A biomarker extracted from a lab PDF with its reference interval
/// interpreted into a status.
struct Biomarker: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var value: Double
    var unit: String
    var referenceLow: Double?
    var referenceHigh: Double?
    var category: Category

    enum Category: String, Codable, CaseIterable {
        case metabolic    = "Metabolismo"
        case lipids       = "Lípidos"
        case thyroid      = "Tiroides"
        case vitamins     = "Vitaminas"
        case inflammation = "Inflamación"
        case hormones     = "Hormonas"
        case liver        = "Hígado"
        case kidney       = "Riñón"
        case hematology   = "Hematología"
        case other        = "Otros"
    }

    enum Status: String, Codable {
        case low    = "Bajo"
        case normal = "Óptimo"
        case high   = "Alto"
        case unknown = "—"
    }

    var status: Status {
        if let lo = referenceLow, value < lo { return .low }
        if let hi = referenceHigh, value > hi { return .high }
        if referenceLow != nil || referenceHigh != nil { return .normal }
        return .unknown
    }

    var icon: String { category.icon }
}

extension Biomarker.Category {
    var icon: String {
        switch self {
        case .metabolic:    return "flame.fill"
        case .lipids:       return "drop.triangle.fill"
        case .thyroid:      return "bolt.heart.fill"
        case .vitamins:     return "sun.max.fill"
        case .inflammation: return "allergens"
        case .hormones:     return "waveform.path"
        case .liver:        return "leaf.fill"
        case .kidney:       return "drop.fill"
        case .hematology:   return "heart.circle.fill"
        case .other:        return "cross.case.fill"
        }
    }
}

/// A lab report uploaded by the user. Stores the extracted text, the parsed
/// biomarkers and the AI-generated summary. The original file is kept on
/// disk for later review.
struct LabReport: Identifiable, Hashable, Codable {
    var id = UUID()
    var title: String
    var reportedAt: Date
    var uploadedAt: Date = Date()
    var lab: String
    var markers: [Biomarker]
    var rawText: String
    var aiSummary: String?
    var localFileName: String?        // PDF saved in Documents/

    var outOfRangeCount: Int {
        markers.filter { $0.status == .low || $0.status == .high }.count
    }

    var byCategory: [(Biomarker.Category, [Biomarker])] {
        let grouped = Dictionary(grouping: markers, by: \.category)
        return Biomarker.Category.allCases.compactMap { cat in
            guard let list = grouped[cat], !list.isEmpty else { return nil }
            return (cat, list)
        }
    }
}

// MARK: - Biomarker catalog (for parsing)

/// Metadata used by the parser to find biomarkers in noisy PDF text. Each
/// entry has the spanish + english aliases the lab might use, the unit,
/// the default reference interval (used when the PDF itself doesn't list
/// one) and the category.
struct BiomarkerSpec {
    let canonical: String
    let aliases: [String]
    let unit: String
    let referenceLow: Double?
    let referenceHigh: Double?
    let category: Biomarker.Category
}

enum BiomarkerCatalog {
    static let all: [BiomarkerSpec] = [
        // Metabolismo
        .init(canonical: "Glucosa en ayuno",
              aliases: ["glucosa", "glucose", "glucosa en ayuno", "glucosa basal"],
              unit: "mg/dL", referenceLow: 70, referenceHigh: 99, category: .metabolic),
        .init(canonical: "Hemoglobina glucosilada",
              aliases: ["hemoglobina glucosilada", "hba1c", "a1c", "hemoglobina a1c"],
              unit: "%", referenceLow: 4.0, referenceHigh: 5.6, category: .metabolic),
        .init(canonical: "Insulina en ayuno",
              aliases: ["insulina", "insulin"],
              unit: "µUI/mL", referenceLow: 2.6, referenceHigh: 10, category: .metabolic),

        // Lípidos
        .init(canonical: "Colesterol total",
              aliases: ["colesterol total", "colesterol", "cholesterol"],
              unit: "mg/dL", referenceLow: nil, referenceHigh: 200, category: .lipids),
        .init(canonical: "HDL",
              aliases: ["hdl", "colesterol hdl"],
              unit: "mg/dL", referenceLow: 40, referenceHigh: nil, category: .lipids),
        .init(canonical: "LDL",
              aliases: ["ldl", "colesterol ldl"],
              unit: "mg/dL", referenceLow: nil, referenceHigh: 100, category: .lipids),
        .init(canonical: "Triglicéridos",
              aliases: ["triglicéridos", "trigliceridos", "triglycerides"],
              unit: "mg/dL", referenceLow: nil, referenceHigh: 150, category: .lipids),

        // Tiroides
        .init(canonical: "TSH",
              aliases: ["tsh", "hormona estimulante de tiroides"],
              unit: "mUI/L", referenceLow: 0.4, referenceHigh: 4.0, category: .thyroid),
        .init(canonical: "T4 libre",
              aliases: ["t4 libre", "free t4", "ft4"],
              unit: "ng/dL", referenceLow: 0.8, referenceHigh: 1.8, category: .thyroid),
        .init(canonical: "T3 libre",
              aliases: ["t3 libre", "free t3", "ft3"],
              unit: "pg/mL", referenceLow: 2.3, referenceHigh: 4.2, category: .thyroid),

        // Vitaminas
        .init(canonical: "Vitamina D",
              aliases: ["vitamina d", "25-oh", "25 oh vitamina d", "25(oh)d"],
              unit: "ng/mL", referenceLow: 30, referenceHigh: 100, category: .vitamins),
        .init(canonical: "Vitamina B12",
              aliases: ["vitamina b12", "b12", "cobalamina"],
              unit: "pg/mL", referenceLow: 300, referenceHigh: 900, category: .vitamins),
        .init(canonical: "Ferritina",
              aliases: ["ferritina", "ferritin"],
              unit: "ng/mL", referenceLow: 30, referenceHigh: 200, category: .vitamins),

        // Inflamación
        .init(canonical: "PCR ultra sensible",
              aliases: ["proteína c reactiva", "proteina c reactiva", "hs-crp", "pcr", "crp"],
              unit: "mg/L", referenceLow: nil, referenceHigh: 1.0, category: .inflammation),
        .init(canonical: "Homocisteína",
              aliases: ["homocisteína", "homocisteina", "homocysteine"],
              unit: "µmol/L", referenceLow: nil, referenceHigh: 10, category: .inflammation),

        // Hormonas
        .init(canonical: "Cortisol matutino",
              aliases: ["cortisol", "cortisol am"],
              unit: "µg/dL", referenceLow: 6, referenceHigh: 18, category: .hormones),
        .init(canonical: "Testosterona total",
              aliases: ["testosterona", "testosterone"],
              unit: "ng/dL", referenceLow: 280, referenceHigh: 1100, category: .hormones),
        .init(canonical: "DHEA-S",
              aliases: ["dhea", "dhea-s", "dhea sulfate"],
              unit: "µg/dL", referenceLow: 80, referenceHigh: 560, category: .hormones),

        // Hígado
        .init(canonical: "ALT",
              aliases: ["alt", "tgp", "alanino aminotransferasa"],
              unit: "U/L", referenceLow: nil, referenceHigh: 40, category: .liver),
        .init(canonical: "AST",
              aliases: ["ast", "tgo", "aspartato aminotransferasa"],
              unit: "U/L", referenceLow: nil, referenceHigh: 40, category: .liver),
        .init(canonical: "GGT",
              aliases: ["ggt", "gamma gt"],
              unit: "U/L", referenceLow: nil, referenceHigh: 50, category: .liver),

        // Riñón
        .init(canonical: "Creatinina",
              aliases: ["creatinina", "creatinine"],
              unit: "mg/dL", referenceLow: 0.6, referenceHigh: 1.2, category: .kidney),
        .init(canonical: "Urea",
              aliases: ["urea", "bun", "nitrógeno ureico"],
              unit: "mg/dL", referenceLow: 10, referenceHigh: 40, category: .kidney),

        // Hematología
        .init(canonical: "Hemoglobina",
              aliases: ["hemoglobina", "hgb", "hb"],
              unit: "g/dL", referenceLow: 12, referenceHigh: 17, category: .hematology),
        .init(canonical: "Glóbulos blancos",
              aliases: ["leucocitos", "glóbulos blancos", "white blood cells", "wbc"],
              unit: "10³/µL", referenceLow: 4.0, referenceHigh: 11.0, category: .hematology),
        .init(canonical: "Plaquetas",
              aliases: ["plaquetas", "platelets"],
              unit: "10³/µL", referenceLow: 150, referenceHigh: 450, category: .hematology),
    ]
}
