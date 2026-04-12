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

    var weekDays: [Date] {
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysSinceMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: calendar.startOfDay(for: selectedDate)) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
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

    func daysWithData() -> Set<Int> {
        guard let dataStore else { return [] }
        var result = Set<Int>()
        for day in weekDays {
            if !dataStore.foodScans(for: day).isEmpty {
                result.insert(calendar.component(.day, from: day))
            }
        }
        return result
    }

    func previousWeek() {
        guard let newDate = calendar.date(byAdding: .day, value: -7, to: selectedDate) else { return }
        selectedDate = newDate
        selectedMonth = newDate
    }

    func nextWeek() {
        guard let newDate = calendar.date(byAdding: .day, value: 7, to: selectedDate) else { return }
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: newDate)
        if target > today {
            let weekday = calendar.component(.weekday, from: newDate)
            let daysSinceMonday = (weekday + 5) % 7
            guard let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: target) else { return }
            if monday > today { return }
            selectedDate = today
        } else {
            selectedDate = newDate
        }
        selectedMonth = selectedDate
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
