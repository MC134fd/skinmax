import Foundation
import SwiftData
import Observation

@Observable
final class DataStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Save
    func saveSkinScan(_ scan: SkinScan) {
        let cached = CachedSkinScan(from: scan)
        modelContext.insert(cached)
        try? modelContext.save()
    }

    func saveFoodScan(_ scan: FoodScan) {
        let cached = CachedFoodScan(from: scan)
        modelContext.insert(cached)
        try? modelContext.save()
    }

    // MARK: - Skin Scan Queries
    func latestSkinScan() -> SkinScan? {
        var descriptor = FetchDescriptor<CachedSkinScan>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let results = (try? modelContext.fetch(descriptor)) ?? []
        return results.first?.toSkinScan()
    }

    func skinScans(for date: Date) -> [SkinScan] {
        let (start, end) = dayRange(for: date)
        let predicate = #Predicate<CachedSkinScan> { scan in
            scan.date >= start && scan.date < end
        }
        let descriptor = FetchDescriptor<CachedSkinScan>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        return results.map { $0.toSkinScan() }
    }

    func skinScans(last days: Int) -> [SkinScan] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = #Predicate<CachedSkinScan> { scan in
            scan.date >= startDate
        }
        let descriptor = FetchDescriptor<CachedSkinScan>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date)]
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        return results.map { $0.toSkinScan() }
    }

    // MARK: - Food Scan Queries
    func foodScans(for date: Date) -> [FoodScan] {
        let (start, end) = dayRange(for: date)
        let predicate = #Predicate<CachedFoodScan> { scan in
            scan.date >= start && scan.date < end
        }
        let descriptor = FetchDescriptor<CachedFoodScan>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        return results.map { $0.toFoodScan() }
    }

    func foodScans(last days: Int) -> [FoodScan] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = #Predicate<CachedFoodScan> { scan in
            scan.date >= startDate
        }
        let descriptor = FetchDescriptor<CachedFoodScan>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date)]
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        return results.map { $0.toFoodScan() }
    }

    func allFoodScans(from startDate: Date, to endDate: Date) -> [FoodScan] {
        let predicate = #Predicate<CachedFoodScan> { scan in
            scan.date >= startDate && scan.date < endDate
        }
        let descriptor = FetchDescriptor<CachedFoodScan>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date)]
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        return results.map { $0.toFoodScan() }
    }

    // MARK: - Computed
    func averageFoodScore(for date: Date) -> Double? {
        let scans = foodScans(for: date)
        guard !scans.isEmpty else { return nil }
        return scans.map(\.skinImpactScore).reduce(0, +) / Double(scans.count)
    }

    func dailyFoodScores(last days: Int) -> [(date: Date, avgScore: Double)] {
        let calendar = Calendar.current
        var results: [(date: Date, avgScore: Double)] = []
        for i in (0..<days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            if let avg = averageFoodScore(for: date) {
                results.append((date: calendar.startOfDay(for: date), avgScore: avg))
            }
        }
        return results
    }

    func dailySkinScores(last days: Int) -> [(date: Date, score: Double)] {
        let calendar = Calendar.current
        var results: [(date: Date, score: Double)] = []
        for i in (0..<days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let scans = skinScans(for: date)
            if let latest = scans.first {
                results.append((date: calendar.startOfDay(for: date), score: latest.glowScore))
            }
        }
        return results
    }

    func todayFoodCount() -> Int {
        foodScans(for: Date()).count
    }

    // MARK: - All Skin Scans
    func allSkinScans() -> [SkinScan] {
        let descriptor = FetchDescriptor<CachedSkinScan>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        return results.map { $0.toSkinScan() }
    }

    func totalSkinScans() -> Int {
        let descriptor = FetchDescriptor<CachedSkinScan>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    func totalFoodScans() -> Int {
        let descriptor = FetchDescriptor<CachedFoodScan>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Delete
    func deleteSkinScan(id: UUID) {
        let predicate = #Predicate<CachedSkinScan> { scan in
            scan.id == id
        }
        let descriptor = FetchDescriptor<CachedSkinScan>(predicate: predicate)
        if let results = try? modelContext.fetch(descriptor) {
            for item in results { modelContext.delete(item) }
            try? modelContext.save()
        }
    }

    func deleteAllData() {
        do {
            try modelContext.delete(model: CachedSkinScan.self)
            try modelContext.delete(model: CachedFoodScan.self)
            try modelContext.save()
        } catch {}
    }

    // MARK: - Streak
    func calculateStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()

        for _ in 0..<365 {
            let skinScansForDay = skinScans(for: checkDate)
            let foodScansForDay = foodScans(for: checkDate)
            if !skinScansForDay.isEmpty || !foodScansForDay.isEmpty {
                streak += 1
            } else {
                break
            }
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }

    // MARK: - First Activity Date
    func firstActivityDate() -> Date? {
        var descriptor = FetchDescriptor<CachedSkinScan>(
            sortBy: [SortDescriptor(\.date)]
        )
        descriptor.fetchLimit = 1
        let skinDate = (try? modelContext.fetch(descriptor))?.first?.date

        var foodDescriptor = FetchDescriptor<CachedFoodScan>(
            sortBy: [SortDescriptor(\.date)]
        )
        foodDescriptor.fetchLimit = 1
        let foodDate = (try? modelContext.fetch(foodDescriptor))?.first?.date

        switch (skinDate, foodDate) {
        case (let s?, let f?): return min(s, f)
        case (let s?, nil): return s
        case (nil, let f?): return f
        default: return nil
        }
    }

    // MARK: - Helpers
    private func dayRange(for date: Date) -> (Date, Date) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }
}
