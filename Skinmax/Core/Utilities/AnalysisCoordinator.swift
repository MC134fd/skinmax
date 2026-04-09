import SwiftUI
import Observation

enum AnalysisKind {
    case face
    case food
}

enum AnalysisPhase: Equatable {
    case preparing
    case uploading
    case analyzing
    case finalizing
    case complete
    case error(String)

    var label: String {
        switch self {
        case .preparing: return "Preparing image..."
        case .uploading: return "Sending to AI..."
        case .analyzing: return "Analyzing..."
        case .finalizing: return "Finishing up..."
        case .complete: return "Complete"
        case .error: return "Something went wrong"
        }
    }
}

@Observable
@MainActor
final class AnalysisCoordinator {
    var isActive = false
    var kind: AnalysisKind = .face
    var phase: AnalysisPhase = .preparing
    var progress: Double = 0

    // Results
    var faceScanResult: SkinScan?
    var foodScanResult: FoodScan?

    private var progressTimer: Timer?
    private var targetProgress: Double = 0

    // MARK: - Face Scan

    func startFaceScan(
        imageData: Data,
        analysisService: SkinAnalysisServiceProtocol,
        dataStore: DataStore
    ) {
        reset()
        kind = .face
        isActive = true
        phase = .preparing
        setTargetProgress(0.15)

        Task {
            await runFaceAnalysis(imageData: imageData, service: analysisService, dataStore: dataStore)
        }
    }

    private func runFaceAnalysis(
        imageData: Data,
        service: SkinAnalysisServiceProtocol,
        dataStore: DataStore
    ) async {
        // Phase: uploading
        phase = .uploading
        setTargetProgress(0.35)
        try? await Task.sleep(for: .milliseconds(300))

        // Phase: analyzing (bulk of the wait)
        phase = .analyzing
        setTargetProgress(0.85)

        do {
            print("[AnalysisCoordinator] Sending \(imageData.count) bytes for face analysis...")
            let scan = try await service.analyzeSkin(image: imageData)
            print("[AnalysisCoordinator] Face analysis succeeded! Glow score: \(scan.glowScore)")

            // Phase: finalizing
            phase = .finalizing
            setTargetProgress(1.0)
            dataStore.saveSkinScan(scan)

            try? await Task.sleep(for: .milliseconds(400))

            faceScanResult = scan
            phase = .complete
            progress = 1.0
            stopProgressTimer()
            HapticManager.notification(.success)
        } catch {
            print("[AnalysisCoordinator] Face analysis error: \(error)")
            let message = (error as? SkinAnalysisError)?.errorDescription ?? "Analysis failed. Please try again."
            phase = .error(message)
            stopProgressTimer()
            HapticManager.notification(.error)
        }
    }

    // MARK: - Food Scan

    func startFoodScan(
        imageData: Data,
        foodName: String,
        analysisService: FoodAnalysisServiceProtocol,
        dataStore: DataStore
    ) {
        reset()
        kind = .food
        isActive = true
        phase = .preparing
        setTargetProgress(0.15)

        Task {
            await runFoodAnalysis(imageData: imageData, foodName: foodName, service: analysisService, dataStore: dataStore)
        }
    }

    private func runFoodAnalysis(
        imageData: Data,
        foodName: String,
        service: FoodAnalysisServiceProtocol,
        dataStore: DataStore
    ) async {
        phase = .uploading
        setTargetProgress(0.35)
        try? await Task.sleep(for: .milliseconds(300))

        phase = .analyzing
        setTargetProgress(0.85)

        do {
            print("[AnalysisCoordinator] Sending \(imageData.count) bytes for food analysis...")
            let scan = try await service.analyzeFood(image: imageData, foodName: foodName)
            print("[AnalysisCoordinator] Food analysis succeeded! Score: \(scan.skinImpactScore)")

            phase = .finalizing
            setTargetProgress(1.0)
            dataStore.saveFoodScan(scan)

            try? await Task.sleep(for: .milliseconds(400))

            foodScanResult = scan
            phase = .complete
            progress = 1.0
            stopProgressTimer()
            HapticManager.notification(.success)
        } catch {
            print("[AnalysisCoordinator] Food analysis error: \(error)")
            let message = (error as? FoodAnalysisError)?.errorDescription ?? "Couldn't analyze this food, try again."
            phase = .error(message)
            stopProgressTimer()
            HapticManager.notification(.error)
        }
    }

    // MARK: - Progress Simulation

    private func setTargetProgress(_ target: Double) {
        targetProgress = target
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let remaining = self.targetProgress - self.progress
                if remaining > 0.005 {
                    self.progress += remaining * 0.08
                } else {
                    self.progress = self.targetProgress
                    self.stopProgressTimer()
                }
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    // MARK: - Actions

    func dismiss() {
        stopProgressTimer()
        isActive = false
    }

    func retry(dataStore: DataStore) {
        // Can't retry without the original data, so just dismiss
        dismiss()
    }

    private func reset() {
        stopProgressTimer()
        progress = 0
        phase = .preparing
        faceScanResult = nil
        foodScanResult = nil
    }
}
