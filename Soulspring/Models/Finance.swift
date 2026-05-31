import Foundation
import SwiftUI

/// A single income or expense entry. Transactions coming from in-app
/// Soulspring flows (stays, experiences, gift cards, room service) are
/// created automatically and reference the originating object's id so we
/// can avoid double-counting and offer a deep link back.
struct FinanceTransaction: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var title: String
    var amountMXN: Double            // always positive; sign comes from `type`
    var type: Kind
    var category: FinanceCategory
    var date: Date
    var notes: String = ""
    var source: Source = .manual
    var linkedObjectID: UUID? = nil  // id of StayBooking / Booking / GiftCard / RoomServiceOrder

    enum Kind: String, Codable, CaseIterable, Identifiable {
        case income  = "Ingreso"
        case expense = "Egreso"
        var id: String { rawValue }
    }

    enum Source: String, Codable {
        case manual          = "Manual"
        case soulStay        = "Estancia Soulspring"
        case soulExperience  = "Experiencia Soulspring"
        case soulGiftCard    = "Gift card"
        case soulRoomService = "Room service"
    }

    var signedAmount: Double {
        type == .income ? amountMXN : -amountMXN
    }
}

/// Category taxonomy — covers personal finance plus Soulspring-specific
/// buckets (Bienestar, Gift Soulspring) that make the breakdown more
/// meaningful for this user base.
enum FinanceCategory: String, Codable, CaseIterable, Identifiable {
    // Income
    case salario       = "Salario"
    case inversion     = "Inversiones"
    case freelance     = "Freelance"
    case regaloIn      = "Regalo recibido"
    case otroIngreso   = "Otro ingreso"

    // Expense
    case comida        = "Alimentos"
    case bienestar     = "Bienestar · Soulspring"
    case salud         = "Salud"
    case hogar         = "Hogar"
    case transporte    = "Transporte"
    case entretenimiento = "Entretenimiento"
    case ropa          = "Ropa"
    case viajes        = "Viajes"
    case ahorro        = "Ahorro"
    case giftOut       = "Regalo enviado"
    case otro          = "Otros"

    var id: String { rawValue }

    var isIncome: Bool {
        switch self {
        case .salario, .inversion, .freelance, .regaloIn, .otroIngreso: return true
        default: return false
        }
    }

    var icon: String {
        switch self {
        case .salario:         return "briefcase.fill"
        case .inversion:       return "chart.line.uptrend.xyaxis"
        case .freelance:       return "laptopcomputer"
        case .regaloIn:        return "gift.fill"
        case .otroIngreso:     return "plus.circle"

        case .comida:          return "fork.knife"
        case .bienestar:       return "leaf.fill"
        case .salud:           return "cross.case.fill"
        case .hogar:           return "house.fill"
        case .transporte:      return "car.fill"
        case .entretenimiento: return "sparkles.tv.fill"
        case .ropa:            return "tshirt.fill"
        case .viajes:          return "airplane"
        case .ahorro:          return "banknote.fill"
        case .giftOut:         return "gift"
        case .otro:            return "ellipsis.circle"
        }
    }

    var tintHex: UInt32 {
        switch self {
        case .salario, .freelance, .otroIngreso: return 0x3F5248  // moss
        case .inversion:                         return 0x8FA189  // sage
        case .regaloIn:                          return 0xC9A66B  // gold

        case .comida:          return 0xC68863  // terracotta
        case .bienestar:       return 0x8FA189  // sage
        case .salud:           return 0xB85C5C  // heart
        case .hogar:           return 0x6B4F3B  // earth
        case .transporte:      return 0x9FB4B8  // sky
        case .entretenimiento: return 0xC9A66B  // gold
        case .ropa:            return 0xE8D9C4  // sand
        case .viajes:          return 0x3F5248  // moss
        case .ahorro:          return 0x8FA189  // sage
        case .giftOut:         return 0xC9A66B  // gold
        case .otro:            return 0x6B4F3B  // earth
        }
    }

    static var incomeCategories: [FinanceCategory] {
        allCases.filter(\.isIncome)
    }

    static var expenseCategories: [FinanceCategory] {
        allCases.filter { !$0.isIncome }
    }
}

/// A monthly budget cap for a given expense category. Absence of an entry
/// means "no budget".
struct MonthlyBudget: Codable, Equatable {
    var limits: [FinanceCategory: Double] = [:]

    func limit(for category: FinanceCategory) -> Double? {
        limits[category]
    }
}

// MARK: - Reporting

/// Aggregations over a set of transactions. Pure functions so tests and
/// views can share them.
enum FinanceReport {
    static func filter(_ txs: [FinanceTransaction], in month: Date) -> [FinanceTransaction] {
        let cal = Calendar.current
        return txs.filter { cal.isDate($0.date, equalTo: month, toGranularity: .month) }
    }

    static func totals(_ txs: [FinanceTransaction]) -> (income: Double, expense: Double) {
        var income = 0.0, expense = 0.0
        for t in txs {
            if t.type == .income { income += t.amountMXN }
            else                 { expense += t.amountMXN }
        }
        return (income, expense)
    }

    static func byCategory(_ txs: [FinanceTransaction], type: FinanceTransaction.Kind) -> [(FinanceCategory, Double)] {
        let filtered = txs.filter { $0.type == type }
        let grouped = Dictionary(grouping: filtered, by: \.category)
            .mapValues { $0.reduce(0.0) { $0 + $1.amountMXN } }
        return grouped.sorted { $0.value > $1.value }
    }

    /// Daily expense totals for a month — used by the trend chart.
    static func dailyExpenses(_ txs: [FinanceTransaction], in month: Date) -> [(Date, Double)] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: month),
              let anchor = cal.date(from: cal.dateComponents([.year, .month], from: month)) else {
            return []
        }
        return range.compactMap { day -> (Date, Double)? in
            guard let date = cal.date(byAdding: .day, value: day - 1, to: anchor) else { return nil }
            let dayTxs = txs.filter {
                $0.type == .expense && cal.isDate($0.date, inSameDayAs: date)
            }
            let total = dayTxs.reduce(0.0) { $0 + $1.amountMXN }
            return (date, total)
        }
    }

    /// Sample seed so the Finanzas tab looks alive on first launch (guest
    /// mode). Six weeks back, a mix of incomes and expenses.
    static func sampleTransactions(now: Date = Date()) -> [FinanceTransaction] {
        let cal = Calendar.current
        func t(_ daysAgo: Int, _ title: String, _ amount: Double,
               _ type: FinanceTransaction.Kind, _ cat: FinanceCategory,
               _ source: FinanceTransaction.Source = .manual) -> FinanceTransaction {
            FinanceTransaction(
                title: title,
                amountMXN: amount,
                type: type,
                category: cat,
                date: cal.date(byAdding: .day, value: -daysAgo, to: now) ?? now,
                source: source
            )
        }
        return [
            t(1,  "Super orgánico",          680,   .expense, .comida),
            t(2,  "Yoga restaurativo",       600,   .expense, .bienestar, .soulExperience),
            t(4,  "Uber semana",             420,   .expense, .transporte),
            t(5,  "Gasolina",                950,   .expense, .transporte),
            t(6,  "Cena con amigos",       1_200,   .expense, .entretenimiento),
            t(8,  "Quincena",             24_500,   .income,  .salario),
            t(9,  "Baño de contraste",       900,   .expense, .bienestar, .soulExperience),
            t(11, "Medicamentos",            380,   .expense, .salud),
            t(13, "Dividendos",             1_240,  .income,  .inversion),
            t(14, "Café Raíz",               165,   .expense, .comida),
            t(18, "Masaje tejidos profundos",1_500, .expense, .bienestar, .soulExperience),
            t(22, "Freelance diseño",      8_000,   .income,  .freelance),
            t(24, "Renta",                12_000,   .expense, .hogar),
            t(27, "Gift card a mamá",      2_500,   .expense, .giftOut, .soulGiftCard),
            t(30, "Quincena",             24_500,   .income,  .salario),
        ]
    }
}
