import SwiftUI

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Score Card (Dark gradient, big score)
struct ScoreCard: View {
    let score: Double
    let label: String
    let trend: String
    let trendPositive: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(String(format: "%.0f", score))
                .font(.gbDisplayXL)
                .tracking(-1.5)
                .foregroundStyle(GlowbiteColors.coral)

            Text(label.uppercased())
                .font(.gbOverline)
                .foregroundStyle(GlowbiteColors.lightTaupe)
                .tracking(2)

            if !trend.isEmpty {
                Text(trend)
                    .font(.gbCaption)
                    .foregroundStyle(trendPositive ? GlowbiteColors.greenGood : GlowbiteColors.redAlert)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, GlowbiteSpacing.cardPadding)
        .background(
            LinearGradient(
                colors: [GlowbiteColors.darkBrown, GlowbiteColors.warmBrown],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius))
    }
}

// MARK: - Score Ring (gradient stroke, 12pt width)
struct ScoreRing: View {
    let score: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let trackColor: Color
    let showLabel: Bool

    init(score: Double, size: CGFloat = 140, lineWidth: CGFloat = 12, trackColor: Color = GlowbiteColors.softTan, showLabel: Bool = false) {
        self.score = score
        self.size = size
        self.lineWidth = lineWidth
        self.trackColor = trackColor
        self.showLabel = showLabel
    }

    private var progress: Double { min(score / 100.0, 1.0) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    GlowbiteColors.heroGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            if showLabel {
                Text(String(format: "%.0f", score))
                    .font(.custom("Nunito-ExtraBold", size: size * 0.3))
                    .foregroundStyle(GlowbiteColors.darkBrown)
            }
        }
    }
}

// MARK: - Dismissible Insight Card
struct DismissibleInsightCard: View {
    let emoji: String
    let title: String
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(GlowbiteColors.peachWash)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(emoji)
                        .font(.gbTitleM)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.gbTitleM)
                    .foregroundStyle(GlowbiteColors.darkBrown)

                Text(message)
                    .font(.gbBodyM)
                    .foregroundStyle(GlowbiteColors.warmBrown)
                    .lineSpacing(3)
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.gbCaption)
                    .foregroundStyle(GlowbiteColors.lightTaupe)
            }
        }
        .padding(GlowbiteSpacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GlowbiteColors.white)
        .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius))
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
    }
}

// MARK: - Compact Metric Chip (horizontal strip card)
struct MetricChip: View {
    let emoji: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(emoji)
                .font(.gbTitleM)

            Text(value)
                .font(.gbTitleM)
                .foregroundStyle(color)

            Text(label.uppercased())
                .font(.gbOverline)
                .tracking(2.0)
                .foregroundStyle(GlowbiteColors.lightTaupe)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(GlowbiteColors.white)
        .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius))
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
    }
}

// MARK: - Metric Card (white bg, label, value, progress bar)
struct MetricCard: View {
    let label: String
    let value: String
    let progress: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.gbCaption)
                .foregroundStyle(GlowbiteColors.lightTaupe)

            Text(value)
                .font(.gbTitleM)
                .foregroundStyle(GlowbiteColors.darkBrown)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(GlowbiteColors.softTan)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * min(progress, 1.0), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(GlowbiteSpacing.cardPaddingSmall)
        .background(GlowbiteColors.white)
        .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadiusSmall))
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
    }
}

// MARK: - Circle Metric Card (progress ring with traffic light)
struct CircleMetricCard: View {
    let label: String
    let score: Double
    let icon: String
    let size: CGFloat

    init(label: String, score: Double, icon: String = "", size: CGFloat = 80) {
        self.label = label
        self.score = score
        self.icon = icon
        self.size = size
    }

    private var progress: Double { score / 100.0 }
    private var color: Color { GlowbiteColors.trafficLight(for: score) }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(GlowbiteColors.softTan, lineWidth: 6)
                    .frame(width: size, height: size)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))

                Text(String(format: "%.0f", score))
                    .font(.gbTitleM)
                    .foregroundStyle(GlowbiteColors.darkBrown)
            }

            if !icon.isEmpty {
                Text(icon)
                    .font(.gbBodyM)
            }

            Text(label)
                .font(.gbCaption)
                .foregroundStyle(GlowbiteColors.mediumTaupe)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Week Day Strip (native scroll paging, Mon–Sun)
struct WeekDayStrip: View {
    let weeks: [[Date]]
    let currentWeekIndex: Int
    let selectedDate: Date
    let daysWithData: Set<Int>
    let onSelectDay: (Date) -> Void
    let onPageChanged: (Date) -> Void

    @State private var scrollPosition: Int?

    private let calendar = Calendar.current

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
                    weekRow(week)
                        .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrollPosition)
        .onAppear {
            scrollPosition = currentWeekIndex
        }
        .onChange(of: currentWeekIndex) { _, newIndex in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                scrollPosition = newIndex
            }
        }
        .onChange(of: scrollPosition) { _, newIndex in
            if let index = newIndex, index >= 0, index < weeks.count,
               let firstDay = weeks[index].first {
                onPageChanged(firstDay)
            }
        }
        .frame(height: 64)
    }

    // MARK: - Week Row

    private func weekRow(_ weekDays: [Date]) -> some View {
        HStack(spacing: 6) {
            ForEach(weekDays, id: \.self) { date in
                let dayNum = calendar.component(.day, from: date)
                let hasData = daysWithData.contains(dayNum)
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let isToday = calendar.isDateInToday(date)
                let isFuture = calendar.startOfDay(for: date) > calendar.startOfDay(for: Date())

                Button {
                    onSelectDay(date)
                } label: {
                    VStack(spacing: 4) {
                        Text(dayAbbreviation(date))
                            .font(.gbOverline)
                            .tracking(2.0)

                        Text("\(dayNum)")
                            .font(.gbBodyM)

                        Circle()
                            .fill(GlowbiteColors.coral)
                            .frame(width: 4, height: 4)
                            .opacity(hasData ? 1 : 0)
                    }
                    .foregroundStyle(
                        isSelected ? .white :
                        isFuture ? GlowbiteColors.lightTaupe.opacity(0.5) :
                        GlowbiteColors.warmBrown
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? GlowbiteColors.coral : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isToday && !isSelected ? GlowbiteColors.coral.opacity(0.5) : Color.clear,
                                style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                            )
                    )
                }
                .disabled(isFuture)
            }
        }
    }

    private func dayAbbreviation(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
}

// MARK: - Tag Pill (fully rounded)
struct TagPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.gbCaption)
            .foregroundStyle(GlowbiteColors.coral)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(GlowbiteColors.peachWash.opacity(0.5))
            .clipShape(Capsule())
    }
}

// MARK: - Action Button (coral gradient pill with glow)
struct ActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.impact(.medium)
            action()
        } label: {
            Text(title)
                .font(.gbTitleM)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(GlowbiteColors.buttonGradient)
                .clipShape(Capsule())
                .shadow(color: GlowbiteColors.buttonGlowColor, radius: 16, x: 0, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Ghost Button (peach outlined pill)
struct GhostButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.gbTitleM)
                .foregroundStyle(GlowbiteColors.coral)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(GlowbiteColors.peachWash.opacity(0.3))
                )
                .overlay(
                    Capsule()
                        .stroke(GlowbiteColors.coral, lineWidth: 1.5)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let emoji: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(GlowbiteColors.peachWash)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(emoji)
                        .font(.gbTitleM)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.gbTitleM)
                    .foregroundStyle(GlowbiteColors.darkBrown)

                Text(message)
                    .font(.gbBodyM)
                    .foregroundStyle(GlowbiteColors.warmBrown)
                    .lineSpacing(3)
            }
        }
        .padding(GlowbiteSpacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GlowbiteColors.white)
        .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius))
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
    }
}

// MARK: - Tab Item
enum TabItem: Int, CaseIterable {
    case home, analytics, account

    var title: String {
        switch self {
        case .home: return "Home"
        case .analytics: return "Analytics"
        case .account: return "Account"
        }
    }

    var systemIcon: String {
        switch self {
        case .home: return "house.fill"
        case .analytics: return "chart.bar.fill"
        case .account: return "person.fill"
        }
    }
}

// MARK: - Scan Popup Overlay
struct ScanPopupOverlay: View {
    @Binding var isPresented: Bool
    var onScanFace: () -> Void
    var onLogFood: () -> Void

    var body: some View {
        ZStack {
            GlowbiteColors.darkBrown.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        isPresented = false
                    }
                }

            VStack {
                Spacer()

                HStack(spacing: 14) {
                    // Scan Face bubble
                    Button {
                        HapticManager.impact(.light)
                        isPresented = false
                        onScanFace()
                    } label: {
                        VStack(spacing: 8) {
                            Text("\u{1F9D1}")
                                .font(.gbDisplayL)
                                .tracking(-1.0)
                            Text("Scan Face")
                                .font(.gbTitleM)
                                .foregroundStyle(GlowbiteColors.darkBrown)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius)
                                        .fill(GlowbiteColors.peachWash.opacity(0.7))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius)
                                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                )
                        )
                    }

                    // Log Food bubble
                    Button {
                        HapticManager.impact(.light)
                        isPresented = false
                        onLogFood()
                    } label: {
                        VStack(spacing: 8) {
                            Text("\u{1F37D}")
                                .font(.gbDisplayL)
                                .tracking(-1.0)
                            Text("Log Food")
                                .font(.gbTitleM)
                                .foregroundStyle(GlowbiteColors.darkBrown)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius)
                                        .fill(GlowbiteColors.greenGood.opacity(0.15))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius)
                                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, GlowbiteSpacing.screenPadding)
                .padding(.bottom, 110)
            }
        }
        .transition(.opacity)
    }
}
