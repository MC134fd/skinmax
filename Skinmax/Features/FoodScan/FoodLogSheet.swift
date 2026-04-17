import SwiftUI
import PhotosUI

/// Full-screen Skinmax-branded food scanner. Design A: full-bleed camera with a
/// single floating cream glass panel at the bottom that houses the coaching
/// line, mode pills, zoom toggle, and shutter row.
struct FoodCaptureView: View {
    @State private var viewModel = FoodCaptureViewModel()
    @State private var galleryPick: PhotosPickerItem?
    @State private var toastTask: Task<Void, Never>?

    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    @Environment(AnalysisCoordinator.self) private var coordinator

    var body: some View {
        ZStack {
            backgroundLayer
            overlayLayer
            toastLayer
            loadingLayer
        }
        .statusBarHidden()
        .onAppear {
            viewModel.setupCamera()
        }
        .onDisappear {
            viewModel.tearDown()
            toastTask?.cancel()
        }
        .onChange(of: viewModel.pendingImageData) { _, data in
            guard let data else { return }
            handOffAndDismiss(imageData: data)
        }
        .onChange(of: viewModel.toast) { _, newToast in
            guard newToast != nil else { return }
            scheduleToastDismissal()
        }
        .onChange(of: galleryPick) { _, newItem in
            guard let newItem else { return }
            Task { await loadGallery(newItem) }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.showHelp },
            set: { viewModel.showHelp = $0 }
        )) {
            FoodCameraHelpSheet(mode: viewModel.mode)
                .presentationDetents([.medium])
                .presentationCornerRadius(GlowbiteSpacing.cardCornerRadiusLarge)
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Background Layer

    @ViewBuilder
    private var backgroundLayer: some View {
        if viewModel.cameraManager.permissionGranted {
            FoodCameraPreviewView(session: viewModel.cameraManager.session)
                .ignoresSafeArea()

            // Subtle darken so chrome reads against any lighting condition.
            LinearGradient(
                colors: [Color.black.opacity(0.35), Color.black.opacity(0.0), Color.black.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
        } else if viewModel.cameraManager.permissionDenied {
            permissionDeniedView
        } else {
            GlowbiteColors.darkBrown.ignoresSafeArea()
        }
    }

    // MARK: - Chrome Overlay

    @ViewBuilder
    private var overlayLayer: some View {
        if viewModel.cameraManager.permissionGranted {
            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, GlowbiteSpacing.screenPadding)
                    .padding(.top, 8)

                Spacer(minLength: 0)

                FoodCameraCornerBrackets(mode: viewModel.mode)
                    .animation(.spring(response: 0.45, dampingFraction: 0.8), value: viewModel.mode)

                Spacer(minLength: 0)

                bottomPanel
                    .padding(.horizontal, GlowbiteSpacing.tabBarInset)
                    .padding(.bottom, 12)
            }
        }
    }

    private var topBar: some View {
        HStack {
            FoodCameraGlassIconButton(systemName: "xmark") {
                HapticManager.selection()
                dismiss()
            }
            Spacer()
            FoodCameraGlassIconButton(systemName: "questionmark") {
                viewModel.openHelp()
            }
        }
    }

    private var bottomPanel: some View {
        VStack(spacing: 14) {
            Text(viewModel.mode.coachingText)
                .font(.gbCaption)
                .foregroundStyle(GlowbiteColors.darkBrown)
                .id("coach-\(viewModel.mode.rawValue)")
                .transition(.opacity.combined(with: .move(edge: .bottom)))

            FoodCameraModePillRow(selected: viewModel.mode) { newMode in
                viewModel.selectMode(newMode)
            }

            if viewModel.hasUltraWideLens {
                FoodCameraZoomToggle(zoomLevel: viewModel.zoomLevel) {
                    viewModel.toggleZoom()
                }
                .transition(.scale.combined(with: .opacity))
            }

            shutterRow
                .padding(.top, 2)
        }
        .padding(.horizontal, GlowbiteSpacing.cardPaddingLarge)
        .padding(.top, GlowbiteSpacing.cardPaddingLarge)
        .padding(.bottom, GlowbiteSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadiusLarge, style: .continuous)
                .fill(GlowbiteColors.creamBG.opacity(0.88))
                .background(
                    RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadiusLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .shadow(color: GlowbiteColors.elevatedShadowColor, radius: 20, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadiusLarge, style: .continuous)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
    }

    private var shutterRow: some View {
        HStack {
            FoodCameraFlashButton(isOn: viewModel.isTorchOn) {
                viewModel.toggleTorch()
            }

            Spacer()

            FoodCameraShutterButton(isBusy: viewModel.isProcessing) {
                Task { await viewModel.shutterTapped() }
            }

            Spacer()

            FoodCameraGalleryButton(selection: $galleryPick)
        }
    }

    // MARK: - Loading + Toast Layers

    @ViewBuilder
    private var loadingLayer: some View {
        if viewModel.isProcessing || viewModel.isLoadingPhoto {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: GlowbiteSpacing.sm) {
                ProgressView().tint(.white)
                Text(viewModel.isLoadingPhoto ? "Loading your photo..." : viewModel.mode.loadingText)
                    .font(.gbBodyM)
                    .foregroundStyle(.white)
            }
        }
    }

    @ViewBuilder
    private var toastLayer: some View {
        if let toast = viewModel.toast {
            VStack {
                FoodCameraToast(toast: toast)
                    .padding(.top, 70)
                    .transition(.move(edge: .top).combined(with: .opacity))
                Spacer()
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.toast)
        }
    }

    // MARK: - Permission Denied

    private var permissionDeniedView: some View {
        ZStack {
            GlowbiteColors.creamBG.ignoresSafeArea()

            VStack(spacing: GlowbiteSpacing.md) {
                Text("📸")
                    .font(.system(size: 56))

                Text("Camera access needed")
                    .font(.gbTitleL)
                    .foregroundStyle(GlowbiteColors.darkBrown)

                Text("Skinmax needs your camera to scan what you eat so we can link it to your glow score.")
                    .font(.gbBodyM)
                    .foregroundStyle(GlowbiteColors.warmBrown)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, GlowbiteSpacing.xl)

                VStack(spacing: GlowbiteSpacing.sm) {
                    Button {
                        HapticManager.impact(.medium)
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Open Settings")
                            .font(.gbTitleM)
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, GlowbiteSpacing.xl)
                            .padding(.vertical, 14)
                            .background(
                                Capsule().fill(GlowbiteColors.buttonGradient)
                            )
                            .shadow(color: GlowbiteColors.buttonGlowColor, radius: 12, x: 0, y: 4)
                    }

                    Button {
                        HapticManager.selection()
                        dismiss()
                    } label: {
                        Text("Not now")
                            .font(.gbBodyM)
                            .foregroundStyle(GlowbiteColors.mediumTaupe)
                    }
                }
                .padding(.top, GlowbiteSpacing.sm)
            }
            .padding(GlowbiteSpacing.screenPadding)
        }
    }

    // MARK: - Hand-off + Gallery

    private func handOffAndDismiss(imageData: Data) {
        let mode = viewModel.mode
        viewModel.pendingImageData = nil
        coordinator.startFoodScan(
            imageData: imageData,
            foodName: mode.defaultFoodName,
            mode: mode,
            analysisService: FoodAnalysisService(),
            dataStore: dataStore
        )
        dismiss()
    }

    private func loadGallery(_ item: PhotosPickerItem) async {
        defer { galleryPick = nil }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            viewModel.toast = .error("Couldn't load that photo — try another?")
            HapticManager.notification(.error)
            return
        }
        await viewModel.galleryPicked(image)
    }

    private func scheduleToastDismissal() {
        toastTask?.cancel()
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.6))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.25)) {
                    viewModel.toast = nil
                }
            }
        }
    }
}
