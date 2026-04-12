import Foundation
import Observation

@Observable
@MainActor
final class FoodLogViewModel {
    var selectedDate: Date = .now
    var selectedMonth: Date = .now
    var dataStore: DataStore?

    private let calendar = Calendar.current

    var foodScansForSelectedDate: [FoodScan] {
        dataStore?.foodScans(for: selectedDate) ?? []
    }

    var averageScore: Double? {
        dataStore?.averageFoodScore(for: selectedDate)
    }

    var monthDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth) else { return [] }
        let count = calendar.dateComponents([.day], from: monthInterval.start, to: monthInterval.end).day ?? 0
        return (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: monthInterval.start) }
    }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    var selectedDayName: String {
        if calendar.isDateInToday(selectedDate) { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: selectedDate)
    }

    func daysWithData(in month: Date) -> Set<Int> {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let dataStore else { return [] }
        let scans = dataStore.allFoodScans(from: monthInterval.start, to: monthInterval.end)
        return Set(scans.map { calendar.component(.day, from: $0.createdAt) })
    }

    func previousMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) else { return }
        selectedMonth = newMonth
        selectedDate = preservedDate(in: newMonth)
    }

    func nextMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) else { return }
        let newComps = calendar.dateComponents([.year, .month], from: newMonth)
        let nowComps = calendar.dateComponents([.year, .month], from: Date())
        if (newComps.year!, newComps.month!) > (nowComps.year!, nowComps.month!) { return }
        selectedMonth = newMonth
        selectedDate = preservedDate(in: newMonth)
    }

    func selectDay(_ date: Date) {
        let today = calendar.startOfDay(for: Date())
        guard calendar.startOfDay(for: date) <= today else { return }
        selectedDate = date
        selectedMonth = date
    }

    // MARK: - Private Helpers

    private func preservedDate(in month: Date) -> Date {
        let targetDay = calendar.component(.day, from: selectedDate)
        let range = calendar.range(of: .day, in: .month, for: month)!
        let clampedDay = min(targetDay, range.upperBound - 1)
        var comps = calendar.dateComponents([.year, .month], from: month)
        comps.day = clampedDay
        let date = calendar.date(from: comps)!
        let today = calendar.startOfDay(for: Date())
        return date > today ? today : date
    }
}
