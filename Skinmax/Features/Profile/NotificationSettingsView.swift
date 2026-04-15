import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @AppStorage("notif_morning_scan") private var morningScan = true
    @AppStorage("notif_meal_log") private var mealLog = true
    @AppStorage("notif_weekly_summary") private var weeklySummary = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 2) {
                toggleRow(
                    icon: "🌅",
                    title: "Morning Scan Reminder",
                    subtitle: "9:00 AM",
                    isOn: $morningScan
                )
                Divider().foregroundStyle(SkinmaxColors.softTan)
                toggleRow(
                    icon: "🍽",
                    title: "Meal Log Reminder",
                    subtitle: "12:00 PM, 6:00 PM",
                    isOn: $mealLog
                )
                Divider().foregroundStyle(SkinmaxColors.softTan)
                toggleRow(
                    icon: "📊",
                    title: "Weekly Summary",
                    subtitle: "Every Sunday at 10:00 AM",
                    isOn: $weeklySummary
                )
            }
            .background(SkinmaxColors.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: SkinmaxColors.cardShadowColor, radius: 12, x: 0, y: 4)
            .padding(.horizontal, SkinmaxSpacing.screenPadding)
            .padding(.top, 16)
        }
        .background(SkinmaxColors.creamBG.ignoresSafeArea())
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: morningScan) { _, enabled in
            updateNotifications()
            if enabled { requestPermission() }
        }
        .onChange(of: mealLog) { _, enabled in
            updateNotifications()
            if enabled { requestPermission() }
        }
        .onChange(of: weeklySummary) { _, enabled in
            updateNotifications()
            if enabled { requestPermission() }
        }
    }

    private func toggleRow(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(icon).font(.system(size: 18))
                    Text(title)
                        .font(.gbBodyM)
                        .foregroundStyle(SkinmaxColors.darkBrown)
                }
                Text(subtitle)
                    .font(.gbCaption)
                    .foregroundStyle(SkinmaxColors.lightTaupe)
                    .padding(.leading, 30)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .tint(SkinmaxColors.coral)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    private func updateNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        if morningScan {
            scheduleNotification(id: "morning_scan", title: "Time for your scan!", body: "Take a quick selfie to track your skin health.", hour: 9)
        }
        if mealLog {
            scheduleNotification(id: "meal_lunch", title: "Log your lunch!", body: "Snap a photo of your meal to track skin impact.", hour: 12)
            scheduleNotification(id: "meal_dinner", title: "Log your dinner!", body: "Don't forget to log your evening meal.", hour: 18)
        }
        if weeklySummary {
            var components = DateComponents()
            components.weekday = 1 // Sunday
            components.hour = 10
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let content = UNMutableNotificationContent()
            content.title = "Your Weekly Summary"
            content.body = "Check out how your skin changed this week!"
            content.sound = .default
            let request = UNNotificationRequest(identifier: "weekly_summary", content: content, trigger: trigger)
            center.add(request)
        }
    }

    private func scheduleNotification(id: String, title: String, body: String, hour: Int) {
        var components = DateComponents()
        components.hour = hour
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
