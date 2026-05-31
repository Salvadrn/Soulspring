import Foundation
import HealthKit
import SwiftUI

/// Bridges Apple Health (and, by extension, Apple Watch data) into the app.
///
/// Asks the user for read access to heart rate, HRV, resting HR, steps,
/// energy burned and sleep analysis, then exposes them as observable
/// properties for any view to consume.
@MainActor
final class HealthKitManager: ObservableObject {

    // MARK: Published state

    @Published var isAuthorized: Bool = false
    @Published var heartRate: Double?            // current bpm
    @Published var restingHeartRate: Double?     // bpm
    @Published var hrv: Double?                  // ms
    @Published var steps: Int = 0
    @Published var activeEnergy: Double = 0      // kcal
    @Published var sleepHours: Double = 0
    @Published var heartRateSeries: [HeartSample] = []
    @Published var sleepStages: SleepBreakdown = .empty

    struct HeartSample: Identifiable, Hashable {
        let id = UUID()
        let date: Date
        let bpm: Double
    }

    struct SleepBreakdown: Hashable {
        var deepMinutes: Double
        var remMinutes: Double
        var coreMinutes: Double
        var awakeMinutes: Double

        var totalAsleep: Double { deepMinutes + remMinutes + coreMinutes }
        var totalInBed: Double  { totalAsleep + awakeMinutes }
        func share(_ minutes: Double) -> Double {
            totalInBed > 0 ? minutes / totalInBed : 0
        }
        static let empty = SleepBreakdown(deepMinutes: 0, remMinutes: 0,
                                          coreMinutes: 0, awakeMinutes: 0)
    }

    // MARK: Internals

    private let store = HKHealthStore()
    private var isSimulated: Bool { !HKHealthStore.isHealthDataAvailable() }

    private var readTypes: Set<HKObjectType> {
        var set: Set<HKObjectType> = []
        if let hr   = HKObjectType.quantityType(forIdentifier: .heartRate) { set.insert(hr) }
        if let rhr  = HKObjectType.quantityType(forIdentifier: .restingHeartRate) { set.insert(rhr) }
        if let hrv  = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) { set.insert(hrv) }
        if let st   = HKObjectType.quantityType(forIdentifier: .stepCount) { set.insert(st) }
        if let kcal = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { set.insert(kcal) }
        if let sl   = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { set.insert(sl) }
        return set
    }

    // MARK: Public API

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            loadSimulatedData()
            return
        }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            await refreshAll()
        } catch {
            isAuthorized = false
            loadSimulatedData()
        }
    }

    func refreshAll() async {
        if isSimulated {
            loadSimulatedData()
            return
        }
        async let hr   = latestQuantity(.heartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let rhr  = latestQuantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let hrv  = latestQuantity(.heartRateVariabilitySDNN, unit: HKUnit.secondUnit(with: .milli))
        async let stp  = todaySumQuantity(.stepCount, unit: .count())
        async let kcal = todaySumQuantity(.activeEnergyBurned, unit: .kilocalorie())
        async let sl    = todaySleepHours()
        async let srs   = todayHeartRateSeries()
        async let stg   = todaySleepStages()

        let (h, rr, v, s, k, sh, series, stages) = await (hr, rhr, hrv, stp, kcal, sl, srs, stg)

        self.heartRate        = h
        self.restingHeartRate = rr
        self.hrv              = v
        self.steps            = Int(s ?? 0)
        self.activeEnergy     = k ?? 0
        self.sleepHours       = sh
        self.heartRateSeries  = series
        self.sleepStages      = stages
    }

    // MARK: Private query helpers

    private func latestQuantity(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: id) else { return nil }
        return await withCheckedContinuation { continuation in
            let sort = [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            let q = HKSampleQuery(sampleType: type, predicate: nil,
                                  limit: 1, sortDescriptors: sort) { _, results, _ in
                let value = (results?.first as? HKQuantitySample)?
                    .quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            store.execute(q)
        }
    }

    private func todaySumQuantity(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: id) else { return nil }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { continuation in
            let q = HKStatisticsQuery(quantityType: type,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, stats, _ in
                continuation.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit))
            }
            store.execute(q)
        }
    }

    private func todayHeartRateSeries() async -> [HeartSample] {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRate) else { return [] }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let unit = HKUnit.count().unitDivided(by: .minute())
        return await withCheckedContinuation { continuation in
            let sort = [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]
            let q = HKSampleQuery(sampleType: type,
                                  predicate: predicate,
                                  limit: 500,
                                  sortDescriptors: sort) { _, results, _ in
                let samples = (results as? [HKQuantitySample] ?? []).map {
                    HeartSample(date: $0.endDate, bpm: $0.quantity.doubleValue(for: unit))
                }
                continuation.resume(returning: samples)
            }
            store.execute(q)
        }
    }

    private func todaySleepHours() async -> Double {
        let stages = await todaySleepStages()
        return stages.totalAsleep / 60
    }

    private func todaySleepStages() async -> SleepBreakdown {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return .empty
        }
        let cal = Calendar.current
        let end = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .hour, value: -18, to: end) ?? end
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())

        return await withCheckedContinuation { continuation in
            let q = HKSampleQuery(sampleType: type,
                                  predicate: predicate,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: nil) { _, results, _ in
                var deep = 0.0, rem = 0.0, core = 0.0, awake = 0.0
                for case let s as HKCategorySample in (results ?? []) {
                    let minutes = s.endDate.timeIntervalSince(s.startDate) / 60
                    switch HKCategoryValueSleepAnalysis(rawValue: s.value) {
                    case .asleepDeep:            deep += minutes
                    case .asleepREM:             rem  += minutes
                    case .asleepCore, .asleep:   core += minutes
                    case .awake:                 awake += minutes
                    default:                     break
                    }
                }
                continuation.resume(returning: SleepBreakdown(
                    deepMinutes: deep, remMinutes: rem,
                    coreMinutes: core, awakeMinutes: awake))
            }
            store.execute(q)
        }
    }

    // MARK: Simulated data

    private func loadSimulatedData() {
        heartRate        = 68
        restingHeartRate = 58
        hrv              = 62
        steps            = 7_420
        activeEnergy     = 412
        sleepHours       = 7.4
        heartRateSeries  = Self.makeMockSeries()
        sleepStages      = SleepBreakdown(
            deepMinutes: 92,
            remMinutes: 108,
            coreMinutes: 242,
            awakeMinutes: 14)
        isAuthorized     = false
    }

    static func makeMockSeries() -> [HeartSample] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        return (0..<96).map { i in            // 96 samples, every 15 minutes
            let t = cal.date(byAdding: .minute, value: i * 15, to: start)!
            let base = 62.0
            let wave = sin(Double(i) / 6.0) * 10
            let spike = (i % 24 == 0) ? 18.0 : 0
            let noise = Double.random(in: -3...3)
            return HeartSample(date: t, bpm: base + wave + spike + noise)
        }
    }
}
