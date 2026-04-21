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

    struct HeartSample: Identifiable, Hashable {
        let id = UUID()
        let date: Date
        let bpm: Double
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
        async let sl   = todaySleepHours()
        async let srs  = todayHeartRateSeries()

        let (h, rr, v, s, k, sh, series) = await (hr, rhr, hrv, stp, kcal, sl, srs)

        self.heartRate        = h
        self.restingHeartRate = rr
        self.hrv              = v
        self.steps            = Int(s ?? 0)
        self.activeEnergy     = k ?? 0
        self.sleepHours       = sh
        self.heartRateSeries  = series
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
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return 0 }
        let cal = Calendar.current
        let end = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .hour, value: -18, to: end) ?? end
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { continuation in
            let q = HKSampleQuery(sampleType: type,
                                  predicate: predicate,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: nil) { _, results, _ in
                let samples = (results as? [HKCategorySample]) ?? []
                let asleep = samples.filter { sample in
                    HKCategoryValueSleepAnalysis.allAsleepValues.contains(
                        HKCategoryValueSleepAnalysis(rawValue: sample.value) ?? .inBed
                    )
                }
                let seconds = asleep.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                continuation.resume(returning: seconds / 3_600)
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
