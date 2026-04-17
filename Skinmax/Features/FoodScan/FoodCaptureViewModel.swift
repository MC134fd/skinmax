import SwiftUI

enum FoodCaptureToast: Identifiable, Equatable {
    case error(String)
    case info(String)

    var id: String {
        switch self {
        case .error(let m): return "err-" + m
        case .info(let m):  return "inf-" + m
        }
    }

    var message: String {
        switch self {
        case .error(let m), .info(let m): return m
        }
    }
}

/// Owns all state and logic for the food camera. Views read from this VM and
/// send intents back as method calls — no business logic in SwiftUI.
@Observable
@MainActor
final class FoodCaptureViewModel {
    // MARK: - UI State
    var mode: FoodCaptureMode = .photo
    var isProcessing = false
    var isLoadingPhoto = false
    var toast: FoodCaptureToast?
    var showHelp = false

    // MARK: - Dependencies (owned)
    let cameraManager = FoodCameraManager()

    /// Image data ready for hand-off to the AnalysisCoordinator. The view
    /// observes this and triggers the coordinator + dismiss when set.
    var pendingImageData: Data?

    // MARK: - Derived
    var zoomLevel: CGFloat { cameraManager.zoomLevel }
    var hasUltraWideLens: Bool { cameraManager.hasUltraWideLens }
    var isTorchOn: Bool { cameraManager.isTorchOn }

    // MARK: - Lifecycle

    func setupCamera() {
        cameraManager.requestPermission()
    }

    func tearDown() {
        cameraManager.stopSession()
    }

    // MARK: - Mode

    func selectMode(_ newMode: FoodCaptureMode) {
        guard newMode != mode else { return }
        HapticManager.selection()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            mode = newMode
        }
    }

    // MARK: - Zoom & Torch

    func toggleZoom() {
        guard hasUltraWideLens else { return }
        let next: CGFloat = zoomLevel >= 1.0 ? 0.5 : 1.0
        HapticManager.selection()
        cameraManager.setZoom(next)
    }

    func toggleTorch() {
        HapticManager.selection()
        cameraManager.toggleTorch()
    }

    // MARK: - Capture

    func shutterTapped() async {
        guard !isProcessing else { return }
        HapticManager.impact(.medium)

        guard let image = await cameraManager.capturePhoto() else {
            toast = .error("Couldn't capture that one — try again?")
            HapticManager.notification(.error)
            return
        }

        await processAndHandOff(image)
    }

    func galleryPicked(_ image: UIImage) async {
        isLoadingPhoto = true
        defer { isLoadingPhoto = false }
        HapticManager.impact(.medium)
        await processAndHandOff(image)
    }

    // MARK: - Help

    func openHelp() {
        HapticManager.selection()
        showHelp = true
    }

    // MARK: - Internals

    private func processAndHandOff(_ image: UIImage) async {
        isProcessing = true
        guard let data = await ImageProcessor.processForFoodAnalysis(image) else {
            isProcessing = false
            toast = .error("Couldn't prepare that photo — try another?")
            HapticManager.notification(.error)
            return
        }
        HapticManager.notification(.success)
        // Surface to the view, which will forward to AnalysisCoordinator and dismiss.
        pendingImageData = data
    }
}
