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

    var allWeeks: [[Date]] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysSinceMonday = (weekday + 5) % 7
        guard let currentMonday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: today) else { return [] }

        var weeks: [[Date]] = []
        for weeksBack in (0..<52).reversed() {
            guard let monday = calendar.date(byAdding: .weekOfYear, value: -weeksBack, to: currentMonday) else { continue }
            let week = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
            weeks.append(week)
        }
        return weeks
    }

    var currentWeekIndex: Int {
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysSinceMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: calendar.startOfDay(for: selectedDate)) else {
            return allWeeks.count - 1
        }
        return allWeeks.firstIndex { week in
            guard let weekMonday = week.first else { return false }
            return calendar.isDate(weekMonday, inSameDayAs: monday)
        } ?? allWeeks.count - 1
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
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysSinceMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: calendar.startOfDay(for: selectedDate)) else { return [] }
        var result = Set<Int>()
        for i in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: i, to: monday) else { continue }
            if !dataStore.foodScans(for: day).isEmpty {
                result.insert(calendar.component(.day, from: day))
            }
        }
        return result
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
