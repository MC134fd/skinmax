import SwiftUI
import PhotosUI

// MARK: - Top Glass Buttons

/// Small frosted-glass circle used for the top-left close and top-right help.
struct FoodCameraGlassIconButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: GlowbiteColors.subtleShadowColor, radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Corner Brackets

/// Animated corner-bracket frame that reshapes as the user switches modes.
struct FoodCameraCornerBrackets: View {
    let mode: FoodCaptureMode

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width * mode.bracketWidthFactor
            let height = width / mode.bracketAspect
            let clampedHeight = min(height, geo.size.height * 0.55)
            let clampedWidth = clampedHeight * mode.bracketAspect

            ZStack {
                CornerBracketShape()
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .frame(width: clampedWidth, height: clampedHeight)
                    .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
    }
}

/// Four L-shaped corner pieces. Each leg is ~18pt long, radiused corners.
private struct CornerBracketShape: Shape {
    func path(in rect: CGRect) -> Path {
        let legLength: CGFloat = 22
        let r: CGFloat = 14 // corner radius of the inset brackets

        var path = Path()

        // Top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + legLength))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r),
                    radius: r,
                    startAngle: .degrees(180),
                    endAngle: .degrees(270),
                    clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + legLength, y: rect.minY))

        // Top-right
        path.move(to: CGPoint(x: rect.maxX - legLength, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
                    radius: r,
                    startAngle: .degrees(270),
                    endAngle: .degrees(0),
                    clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + legLength))

        // Bottom-right
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - legLength))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
                    radius: r,
                    startAngle: .degrees(0),
                    endAngle: .degrees(90),
                    clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX - legLength, y: rect.maxY))

        // Bottom-left
        path.move(to: CGPoint(x: rect.minX + legLength, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
                    radius: r,
                    startAngle: .degrees(90),
                    endAngle: .degrees(180),
                    clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - legLength))

        return path
    }
}

// MARK: - Mode Pill Row

struct FoodCameraModePillRow: View {
    let selected: FoodCaptureMode
    let onSelect: (FoodCaptureMode) -> Void
    @Namespace private var pillNamespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(FoodCaptureMode.allCases) { mode in
                Button {
                    onSelect(mode)
                } label: {
                    Text(mode.shortTitle)
                        .font(.gbCaption)
                        .foregroundStyle(selected == mode ? Color.white : GlowbiteColors.warmBrown)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background {
                            if selected == mode {
                                Capsule()
                                    .fill(GlowbiteColors.buttonGradient)
                                    .matchedGeometryEffect(id: "modePill", in: pillNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule().fill(Color.white.opacity(0.7))
        )
    }
}

// MARK: - Zoom Toggle

struct FoodCameraZoomToggle: View {
    let zoomLevel: CGFloat
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            zoomPill(label: ".5x", isActive: zoomLevel < 1.0)
            zoomPill(label: "1x", isActive: zoomLevel >= 1.0)
        }
        .padding(3)
        .background(Capsule().fill(Color.black.opacity(0.4)))
        .onTapGesture { onToggle() }
    }

    private func zoomPill(label: String, isActive: Bool) -> some View {
        Text(label)
            .font(.gbOverline)
            .foregroundStyle(isActive ? GlowbiteColors.darkBrown : Color.white)
            .frame(minWidth: 32, minHeight: 22)
            .padding(.horizontal, 6)
            .background {
                if isActive {
                    Capsule().fill(Color.white)
                }
            }
    }
}

// MARK: - Shutter Button

/// Signature Skinmax capture button: coral-gradient ring around a white core.
struct FoodCameraShutterButton: View {
    let isBusy: Bool
    let action: () -> Void

    var body: some View {
        Button {
            guard !isBusy else { return }
            action()
        } label: {
            ZStack {
                Circle()
                    .stroke(GlowbiteColors.buttonGradient, lineWidth: 4)
                    .frame(width: 78, height: 78)

                Circle()
                    .fill(Color.white)
                    .frame(width: 64, height: 64)
                    .shadow(color: GlowbiteColors.buttonGlowColor, radius: 14, x: 0, y: 6)

                if isBusy {
                    ProgressView()
                        .tint(GlowbiteColors.coral)
                }
            }
        }
        .buttonStyle(ShutterPressStyle())
        .disabled(isBusy)
        .opacity(isBusy ? 0.7 : 1.0)
    }
}

private struct ShutterPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Flash Button

struct FoodCameraFlashButton: View {
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isOn ? "bolt.fill" : "bolt.slash.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isOn ? GlowbiteColors.sunnyButter : Color.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(
                    Circle().stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Gallery Button

struct FoodCameraGalleryButton: View {
    @Binding var selection: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selection, matching: .images) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
        }
    }
}

// MARK: - Help Bottom Sheet

struct FoodCameraHelpSheet: View {
    let mode: FoodCaptureMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: GlowbiteSpacing.md) {
            HStack {
                Text("How to scan ✨")
                    .font(.gbTitleM)
                    .foregroundStyle(GlowbiteColors.darkBrown)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(GlowbiteColors.lightTaupe)
                        .frame(width: 28, height: 28)
                        .background(GlowbiteColors.softTan, in: Circle())
                }
                .buttonStyle(.plain)
            }

            tipRow(
                emoji: "🍽",
                title: "Photo mode",
                body: "Frame your whole plate. Good light helps — the brighter, the better."
            )
            tipRow(
                emoji: "🔎",
                title: "Barcode mode",
                body: "Line up the barcode inside the brackets. We'll read the digits and match the product."
            )
            tipRow(
                emoji: "🧾",
                title: "Label mode",
                body: "Fit the full nutrition label in the frame — we'll read every line."
            )

            Spacer(minLength: 0)
        }
        .padding(.horizontal, GlowbiteSpacing.screenPadding)
        .padding(.top, GlowbiteSpacing.lg)
        .padding(.bottom, GlowbiteSpacing.xl)
        .background(GlowbiteColors.creamBG)
    }

    private func tipRow(emoji: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: GlowbiteSpacing.md) {
            Text(emoji)
                .font(.system(size: 22))
                .frame(width: 40, height: 40)
                .background(GlowbiteColors.peachWash, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.gbTitleM)
                    .foregroundStyle(GlowbiteColors.darkBrown)
                Text(body)
                    .font(.gbBodyM)
                    .foregroundStyle(GlowbiteColors.warmBrown)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Error Toast

struct FoodCameraToast: View {
    let toast: FoodCaptureToast

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint)
            Text(toast.message)
                .font(.gbBodyM)
                .foregroundStyle(GlowbiteColors.darkBrown)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius, style: .continuous)
                .fill(Color.white)
                .shadow(color: GlowbiteColors.elevatedShadowColor, radius: 16, x: 0, y: 6)
        )
        .padding(.horizontal, GlowbiteSpacing.screenPadding)
    }

    private var icon: String {
        switch toast {
        case .error: return "exclamationmark.circle.fill"
        case .info:  return "sparkles"
        }
    }

    private var tint: Color {
        switch toast {
        case .error: return GlowbiteColors.redAlert
        case .info:  return GlowbiteColors.coral
        }
    }
}
