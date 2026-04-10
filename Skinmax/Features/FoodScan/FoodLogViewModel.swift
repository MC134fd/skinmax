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
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekInterval.start) }
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
        // Jump to first day of that month
        if let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: newMonth)) {
            selectedDate = firstDay
        }
    }

    func nextMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) else { return }
        // Don't allow future months
        if newMonth > Date() { return }
        selectedMonth = newMonth
        if let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: newMonth)) {
            selectedDate = min(firstDay, Date())
        }
    }

    func selectDay(_ date: Date) {
        guard date <= Date() else { return }
        selectedDate = date
        selectedMonth = date
    }

    func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }

    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    func isFuture(_ date: Date) -> Bool {
        date > Date()
    }

    func dayAbbreviation(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    func dayNumber(_ date: Date) -> String {
        "\(calendar.component(.day, from: date))"
    }
}
