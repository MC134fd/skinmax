import SwiftUI

// MARK: - Score Card (Dark gradient, big score)
struct ScoreCard: View {
    let score: Double
    let label: String
    let trend: String
    let trendPositive: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(String(format: "%.0f", score))
                .font(SkinmaxFonts.scoreDisplay())
                .foregroundStyle(SkinmaxColors.coral)

            Text(label.uppercased())
                .font(SkinmaxFonts.caption())
                .foregroundStyle(SkinmaxColors.mutedTan)
                .tracking(1.5)

            if !trend.isEmpty {
                Text(trend)
                    .font(SkinmaxFonts.small())
                    .foregroundStyle(trendPositive ? SkinmaxColors.greenGood : SkinmaxColors.redAlert)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, SkinmaxSpacing.cardPadding)
        .background(
            LinearGradient(
                colors: [SkinmaxColors.darkSurface, SkinmaxColors.darkMid],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
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
                .font(SkinmaxFonts.caption())
                .foregroundStyle(SkinmaxColors.mutedTan)

            Text(value)
                .font(SkinmaxFonts.h3())
                .foregroundStyle(SkinmaxColors.darkBrown)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(SkinmaxColors.lightTan)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * min(progress, 1.0), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(SkinmaxSpacing.cardPaddingSmall)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadiusSmall))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
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
    private var color: Color { SkinmaxColors.trafficLight(for: score) }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(SkinmaxColors.lightTan, lineWidth: 6)
                    .frame(width: size, height: size)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))

                Text(String(format: "%.0f", score))
                    .font(SkinmaxFonts.h2())
                    .foregroundStyle(SkinmaxColors.darkBrown)
            }

            if !icon.isEmpty {
                Text(icon)
                    .font(.system(size: 14))
            }

            Text(label)
                .font(SkinmaxFonts.caption())
                .foregroundStyle(SkinmaxColors.warmGray)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Tag Pill
struct TagPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(SkinmaxFonts.small())
            .foregroundStyle(SkinmaxColors.coral)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(SkinmaxColors.peachWash)
            .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.tagCornerRadius))
    }
}

// MARK: - Action Button (coral gradient, full width)
struct ActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SkinmaxFonts.h3())
                .foregroundStyle(SkinmaxColors.darkBrown)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [SkinmaxColors.coral, SkinmaxColors.peachLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.buttonCornerRadius))
        }
    }
}

// MARK: - Ghost Button
struct GhostButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SkinmaxFonts.h3())
                .foregroundStyle(SkinmaxColors.coral)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(SkinmaxColors.white)
                .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.buttonCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: SkinmaxSpacing.buttonCornerRadius)
                        .stroke(SkinmaxColors.coral, lineWidth: 1.5)
                )
        }
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let emoji: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji)
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(SkinmaxFonts.h3())
                    .foregroundStyle(SkinmaxColors.darkBrown)

                Text(message)
                    .font(SkinmaxFonts.body())
                    .foregroundStyle(SkinmaxColors.warmGray)
                    .lineSpacing(3)
            }
        }
        .padding(SkinmaxSpacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Glass Tab Bar
struct GlassTabBar: View {
    @Binding var selectedTab: TabItem
    @Binding var showScanPopup: Bool
    @Namespace private var tabAnimation

    var body: some View {
        HStack(spacing: 10) {
            // Tab bar with 3 tabs
            HStack(spacing: 0) {
                ForEach(TabItem.allCases, id: \.self) { tab in
                    Button {
                        HapticManager.selection()
                        showScanPopup = false
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.systemIcon)
                                .font(.system(size: 20))
                            Text(tab.title)
                                .font(SkinmaxFonts.tabLabel())
                        }
                        .foregroundStyle(selectedTab == tab ? SkinmaxColors.coral : SkinmaxColors.mutedTan)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selectedTab == tab {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color(hex: "F4C7B0").opacity(0.35))
                                        .matchedGeometryEffect(id: "activeTab", in: tabAnimation)
                                }
                            }
                        )
                        .contentShape(Rectangle())
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: SkinmaxSpacing.tabBarCornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: SkinmaxSpacing.tabBarCornerRadius)
                            .fill(Color.white.opacity(0.45))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: SkinmaxSpacing.tabBarCornerRadius)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 15, x: 0, y: 4)
            )

            // Floating scan circle
            Button {
                HapticManager.impact(.medium)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showScanPopup.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [SkinmaxColors.peachLight, SkinmaxColors.coral],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: SkinmaxColors.coral.opacity(0.35), radius: 8, x: 0, y: 4)

                    Image(systemName: "camera.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(showScanPopup ? 45 : 0))
                }
            }
        }
        .padding(.horizontal, SkinmaxSpacing.tabBarInset)
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
            Color(hex: "3A2A24").opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
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
                            Text("🧑")
                                .font(.system(size: 32))
                            Text("Scan Face")
                                .font(SkinmaxFonts.h3())
                                .foregroundStyle(SkinmaxColors.darkBrown)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(SkinmaxColors.peachWash.opacity(0.7))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
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
                            Text("🍽")
                                .font(.system(size: 32))
                            Text("Log Food")
                                .font(SkinmaxFonts.h3())
                                .foregroundStyle(SkinmaxColors.darkBrown)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(SkinmaxColors.greenGood.opacity(0.15))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, SkinmaxSpacing.screenPadding)
                .padding(.bottom, 90)
            }
        }
        .transition(.opacity)
    }
}
