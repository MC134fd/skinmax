import SwiftUI
import Observation

enum FaceScanState: Equatable {
    case idle
    case faceDetected
    case capturing
    case captured(Data) // Image data ready for analysis
    case error(String)

    static func == (lhs: FaceScanState, rhs: FaceScanState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.faceDetected, .faceDetected),
             (.capturing, .capturing):
            return true
        case (.captured(let a), .captured(let b)):
            return a == b
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

@Observable
final class FaceScanViewModel {
    var state: FaceScanState = .idle

    let cameraManager = CameraManager()

    var statusText: String {
        switch state {
        case .idle: return "Position your face"
        case .faceDetected: return "Hold still..."
        case .capturing: return "Capturing..."
        case .captured: return "Done!"
        case .error(let msg): return msg
        }
    }

    var subtitleText: String {
        switch state {
        case .idle: return "Good lighting for best results"
        case .faceDetected: return "Tap the button to capture"
        case .capturing: return "Processing your photo..."
        default: return ""
        }
    }

    func setupCamera() {
        cameraManager.requestPermission()
    }

    func captureAndPrepare() async {
        state = .capturing
        HapticManager.impact(.medium)

        guard let image = await cameraManager.capturePhoto() else {
            state = .error("Failed to capture photo. Try again.")
            return
        }

        guard let imageData = await ImageProcessor.processForAnalysis(image) else {
            state = .error("Failed to process image. Try again.")
            return
        }

        // Hand off image data — the view will pass it to AnalysisCoordinator
        state = .captured(imageData)
    }

    func retry() {
        state = .idle
    }

    func tearDown() {
        cameraManager.stopSession()
    }
}
