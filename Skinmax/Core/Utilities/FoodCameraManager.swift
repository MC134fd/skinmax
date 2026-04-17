import AVFoundation
import UIKit

/// Rear-camera AVFoundation wrapper for the food scanner. Sibling of
/// `CameraManager` (which is front-camera + face detection). Handles permission,
/// session lifecycle, photo capture, zoom, and torch.
@Observable
final class FoodCameraManager: NSObject, @unchecked Sendable {
    var isSessionRunning = false
    var permissionGranted = false
    var permissionDenied = false
    var isTorchOn = false

    /// Virtual (wide + ultra-wide) zoom level selector.
    /// `0.5` engages the ultra-wide, `1.0` engages the wide.
    var zoomLevel: CGFloat = 1.0

    /// Whether the current device actually has an ultra-wide lens, so the UI
    /// can hide / show the `.5x` pill accordingly.
    var hasUltraWideLens: Bool = false

    let session = AVCaptureSession()

    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.skinmax.foodcamera")
    private var currentInput: AVCaptureDeviceInput?
    private var photoContinuation: CheckedContinuation<UIImage?, Never>?

    // MARK: - Permission

    func requestPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.permissionGranted = true
                        self?.setupSession()
                    } else {
                        self?.permissionDenied = true
                    }
                }
            }
        default:
            permissionDenied = true
        }
    }

    // MARK: - Session Setup

    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            guard let device = Self.bestRearCamera() else {
                self.session.commitConfiguration()
                return
            }

            let hasUW = Self.deviceHasUltraWide(device)
            DispatchQueue.main.async { self.hasUltraWideLens = hasUW }

            guard let input = try? AVCaptureDeviceInput(device: device) else {
                self.session.commitConfiguration()
                return
            }

            if self.session.canAddInput(input) {
                self.session.addInput(input)
                self.currentInput = input
            }

            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }

            self.session.commitConfiguration()
            self.applyZoom(self.zoomLevel)
            self.startSession()
        }
    }

    /// Prefers a virtual triple / dual camera when available (so we can toggle
    /// between `.5x` and `1x` just by changing `videoZoomFactor`), otherwise
    /// falls back to the plain wide lens.
    private static func bestRearCamera() -> AVCaptureDevice? {
        if let triple = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) {
            return triple
        }
        if let dualWide = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
            return dualWide
        }
        if let dual = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
            return dual
        }
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }

    private static func deviceHasUltraWide(_ device: AVCaptureDevice) -> Bool {
        // Virtual cameras that include the ultra-wide report a minimum available
        // zoom factor below 1.0 via `virtualDeviceSwitchOverVideoZoomFactors`.
        let type = device.deviceType
        return type == .builtInTripleCamera || type == .builtInDualWideCamera
    }

    // MARK: - Session Control

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = true
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = false
            }
        }
    }

    // MARK: - Photo Capture

    func capturePhoto() async -> UIImage? {
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(returning: nil)
                    return
                }
                self.photoContinuation?.resume(returning: nil)
                self.photoContinuation = continuation
                let settings = AVCapturePhotoSettings()
                if self.photoOutput.supportedFlashModes.contains(.auto) {
                    settings.flashMode = .auto
                }
                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    // MARK: - Zoom

    /// Switch between `.5x` and `1x` on dual/triple virtual cameras. On single-
    /// lens devices this is a no-op.
    func setZoom(_ level: CGFloat) {
        zoomLevel = level
        sessionQueue.async { [weak self] in
            self?.applyZoom(level)
        }
    }

    private func applyZoom(_ level: CGFloat) {
        guard let device = currentInput?.device else { return }
        do {
            try device.lockForConfiguration()
            // On virtual cameras with UW, factor 1.0 = UW (0.5x), 2.0 = wide (1x).
            // On plain wide-only devices, 1.0 = wide (1x) and we can't go lower.
            let factor: CGFloat
            if hasUltraWideLens {
                factor = level >= 1.0 ? 2.0 : 1.0
            } else {
                factor = 1.0
            }
            let clamped = max(device.minAvailableVideoZoomFactor,
                              min(device.maxAvailableVideoZoomFactor, factor))
            device.videoZoomFactor = clamped
            device.unlockForConfiguration()
        } catch {
            // Silently ignore — zoom is a nicety, not a blocker.
        }
    }

    // MARK: - Torch

    var isTorchAvailable: Bool {
        currentInput?.device.hasTorch ?? false
    }

    func toggleTorch() {
        guard let device = currentInput?.device, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            if device.torchMode == .on {
                device.torchMode = .off
                DispatchQueue.main.async { self.isTorchOn = false }
            } else {
                try device.setTorchModeOn(level: 1.0)
                DispatchQueue.main.async { self.isTorchOn = true }
            }
            device.unlockForConfiguration()
        } catch {
            // Ignore — torch is optional.
        }
    }
}

// MARK: - Photo Capture Delegate
extension FoodCameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard let data = photo.fileDataRepresentation(),
                  let image = UIImage(data: data) else {
                self.photoContinuation?.resume(returning: nil)
                self.photoContinuation = nil
                return
            }
            self.photoContinuation?.resume(returning: image)
            self.photoContinuation = nil
        }
    }
}
