import SwiftUI
import Observation

enum FaceScanState: Equatable {
    case idle
    case faceDetected
    case capturing
    case processing
    case complete(SkinScan)
    case error(String)

    static func == (lhs: FaceScanState, rhs: FaceScanState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.faceDetected, .faceDetected),
             (.capturing, .capturing), (.processing, .processing):
            return true
        case (.complete(let a), .complete(let b)):
            return a.id == b.id
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
    var scanResult: SkinScan?

    let cameraManager = CameraManager()
    private let analysisService: SkinAnalysisServiceProtocol

    init(analysisService: SkinAnalysisServiceProtocol = SkinAnalysisService()) {
        self.analysisService = analysisService
    }

    var statusText: String {
        switch state {
        case .idle: return "Position your face"
        case .faceDetected: return "Hold still..."
        case .capturing: return "Capturing..."
        case .processing: return "Analyzing your skin..."
        case .complete: return "Done!"
        case .error(let msg): return msg
        }
    }

    var subtitleText: String {
        switch state {
        case .idle: return "Good lighting for best results"
        case .faceDetected: return "Tap the button to capture"
        case .processing: return "This takes a few seconds"
        default: return ""
        }
    }

    func setupCamera() {
        cameraManager.requestPermission()
    }

    func captureAndAnalyze() async {
        state = .capturing
        HapticManager.impact(.medium)

        guard let image = await cameraManager.capturePhoto() else {
            state = .error("Failed to capture photo. Try again.")
            return
        }

        state = .processing

        guard let imageData = await ImageProcessor.processForAnalysis(image) else {
            state = .error("Failed to process image. Try again.")
            return
        }

        do {
            let scan = try await analysisService.analyzeSkin(image: imageData)
            scanResult = scan
            state = .complete(scan)
            HapticManager.notification(.success)
        } catch let error as SkinAnalysisError {
            state = .error(error.errorDescription ?? "Unknown error")
        } catch {
            state = .error("Analysis failed. Try again with better lighting.")
        }
    }

    func retry() {
        state = .idle
        scanResult = nil
    }

    func tearDown() {
        cameraManager.stopSession()
    }
}
