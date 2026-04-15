import SwiftUI

struct FaceScanView: View {
    @State private var viewModel = FaceScanViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    @Environment(AnalysisCoordinator.self) private var coordinator
    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            // Camera preview
            if viewModel.cameraManager.permissionGranted {
                CameraPreviewView(session: viewModel.cameraManager.session)
                    .ignoresSafeArea()
            } else if viewModel.cameraManager.permissionDenied {
                permissionDeniedView
            } else {
                Color.black.ignoresSafeArea()
            }

            // Overlays
            if viewModel.cameraManager.permissionGranted {
                cameraOverlay
            }
        }
        .onAppear {
            viewModel.setupCamera()
        }
        .onDisappear {
            viewModel.tearDown()
        }
        .onChange(of: viewModel.cameraManager.isFaceDetected) { _, detected in
            if detected && viewModel.state == .idle {
                viewModel.state = .faceDetected
            } else if !detected && viewModel.state == .faceDetected {
                viewModel.state = .idle
            }
        }
        .onChange(of: viewModel.state) { _, newState in
            if case .captured(let imageData) = newState {
                // Hand off to coordinator and dismiss back to Home
                coordinator.startFaceScan(
                    imageData: imageData,
                    analysisService: SkinAnalysisService(),
                    dataStore: dataStore
                )
                dismiss()
            } else if case .error = newState {
                // Stay on camera screen for errors during capture
            }
        }
        .statusBarHidden()
    }

    // MARK: - Camera Overlay
    private var cameraOverlay: some View {
        ZStack {
            // Top bar
            VStack {
                HStack {
                    backButton
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()
            }

            // Face guide oval
            faceGuide

            // Bottom controls
            VStack {
                Spacer()
                captureButton
                    .padding(.bottom, 60)
            }
        }
    }

    // MARK: - Back Button
    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .font(SkinmaxFonts.h3())
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
    }

    // MARK: - Face Guide Oval
    private var faceGuide: some View {
        GeometryReader { geo in
            let ovalWidth = geo.size.width * 0.65
            let ovalHeight = ovalWidth * 1.35

            VStack(spacing: 12) {
                ZStack {
                    // Oval guide
                    Ellipse()
                        .stroke(
                            ovalStrokeStyle,
                            style: viewModel.state == .faceDetected || viewModel.state == .capturing
                                ? StrokeStyle(lineWidth: 3)
                                : StrokeStyle(lineWidth: 2, dash: [8, 6])
                        )
                        .frame(width: ovalWidth, height: ovalHeight)
                        .foregroundStyle(ovalColor)

                    // Pulsing glow when capturing
                    if viewModel.state == .capturing {
                        Ellipse()
                            .stroke(SkinmaxColors.coral.opacity(0.4), lineWidth: 6)
                            .frame(width: ovalWidth, height: ovalHeight)
                            .scaleEffect(pulseAnimation ? 1.08 : 1.0)
                            .opacity(pulseAnimation ? 0.0 : 0.6)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                                    pulseAnimation = true
                                }
                            }
                            .onDisappear {
                                pulseAnimation = false
                            }
                    }

                    // Capturing spinner
                    if viewModel.state == .capturing {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
                    }
                }

                // Status text
                Text(viewModel.statusText)
                    .font(SkinmaxFonts.h3())
                    .foregroundStyle(.white.opacity(0.7))

                if !viewModel.subtitleText.isEmpty {
                    Text(viewModel.subtitleText)
                        .font(.gbOverline)
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var ovalColor: Color {
        switch viewModel.state {
        case .faceDetected: return SkinmaxColors.coral
        case .capturing: return SkinmaxColors.peachLight
        case .error: return SkinmaxColors.redAlert
        default: return SkinmaxColors.peachLight.opacity(0.5)
        }
    }

    private var ovalStrokeStyle: some ShapeStyle {
        ovalColor
    }

    // MARK: - Capture Button
    private var captureButton: some View {
        VStack(spacing: 16) {
            if case .error = viewModel.state {
                Button {
                    viewModel.retry()
                } label: {
                    Text("Try Again")
                        .font(SkinmaxFonts.h3())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(SkinmaxColors.coral)
                        .clipShape(Capsule())
                }
            } else {
                Button {
                    Task {
                        await viewModel.captureAndPrepare()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.6), lineWidth: 4)
                            .frame(width: 72, height: 72)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [SkinmaxColors.peachLight, SkinmaxColors.coral],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: SkinmaxColors.coral.opacity(0.4), radius: 8, y: 4)
                    }
                }
                .disabled(viewModel.state == .capturing)
                .opacity(viewModel.state == .capturing ? 0.5 : 1.0)
            }
        }
    }

    // MARK: - Permission Denied
    private var permissionDeniedView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(SkinmaxColors.coral)

                Text("Camera Access Needed")
                    .font(.gbTitleM)
                    .foregroundStyle(.white)

                Text("Skinmax needs your camera to analyze your skin health")
                    .font(.gbBodyM)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                        .font(SkinmaxFonts.h3())
                        .foregroundStyle(SkinmaxColors.darkBrown)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(SkinmaxColors.coral)
                        .clipShape(Capsule())
                }

                Button {
                    dismiss()
                } label: {
                    Text("Go Back")
                        .font(SkinmaxFonts.h3())
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }
}
