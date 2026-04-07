import SwiftUI

struct FaceScanView: View {
    @State private var viewModel = FaceScanViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showResult = false
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
        .fullScreenCover(isPresented: $showResult) {
            if let scan = viewModel.scanResult {
                FaceScanResultView(scan: scan)
            }
        }
        .onChange(of: viewModel.state) { _, newState in
            if case .complete = newState {
                showResult = true
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
        VStack(spacing: 12) {
            ZStack {
                // Oval guide
                Ellipse()
                    .stroke(
                        ovalStrokeStyle,
                        style: viewModel.state == .faceDetected || viewModel.state == .processing
                            ? StrokeStyle(lineWidth: 3)
                            : StrokeStyle(lineWidth: 2, dash: [8, 6])
                    )
                    .frame(width: 170, height: 220)
                    .foregroundStyle(ovalColor)

                // Pulsing glow when processing
                if viewModel.state == .processing {
                    Ellipse()
                        .stroke(SkinmaxColors.coral.opacity(0.4), lineWidth: 6)
                        .frame(width: 170, height: 220)
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

                // Processing spinner
                if viewModel.state == .processing {
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
                    .font(.custom("Nunito-Regular", size: 10))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
    }

    private var ovalColor: Color {
        switch viewModel.state {
        case .faceDetected: return SkinmaxColors.coral
        case .processing: return SkinmaxColors.peachLight
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
                        await viewModel.captureAndAnalyze()
                    }
                } label: {
                    ZStack {
                        // Outer ring
                        Circle()
                            .stroke(.white.opacity(0.6), lineWidth: 4)
                            .frame(width: 72, height: 72)

                        // Inner coral gradient
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
                .disabled(viewModel.state == .processing || viewModel.state == .capturing)
                .opacity(viewModel.state == .processing ? 0.5 : 1.0)
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
                    .font(SkinmaxFonts.h2())
                    .foregroundStyle(.white)

                Text("Skinmax needs your camera to analyze your skin health")
                    .font(SkinmaxFonts.body())
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
