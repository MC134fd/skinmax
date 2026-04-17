import SwiftUI
import Observation
import os

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
    private var analysisTask: Task<Void, Never>?
    /// Monotonic ID to detect stale completions after reset/dismiss.
    private var analysisID: UInt64 = 0

    private let log = GlowbiteLog.analysis

    // MARK: - Face Scan

    func startFaceScan(
        imageData: Data,
        analysisService: SkinAnalysisServiceProtocol,
        dataStore: DataStore
    ) {
        cancelAndReset()
        kind = .face
        isActive = true
        phase = .preparing
        setTargetProgress(0.15)

        let runID = analysisID
        log.info("face-\(runID) started, imageSize=\(imageData.count) bytes")

        analysisTask = Task {
            await runFaceAnalysis(imageData: imageData, service: analysisService, dataStore: dataStore, runID: runID)
        }
    }

    private func runFaceAnalysis(
        imageData: Data,
        service: SkinAnalysisServiceProtocol,
        dataStore: DataStore,
        runID: UInt64
    ) async {
        // Phase: uploading
        phase = .uploading
        setTargetProgress(0.35)
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled, analysisID == runID else {
            log.notice("face-\(runID) cancelled at=uploading")
            return
        }

        // Phase: analyzing (bulk of the wait)
        phase = .analyzing
        setTargetProgress(0.85)
        log.info("face-\(runID) requesting analysis")

        do {
            let scan = try await service.analyzeSkin(image: imageData)

            // Guard against stale completion after dismiss/restart
            guard !Task.isCancelled, analysisID == runID else {
                log.notice("face-\(runID) cancelled at=post-analysis (stale write prevented)")
                return
            }

            log.info("face-\(runID) analysis succeeded, glowScore=\(scan.glowScore)")

            // Phase: finalizing
            phase = .finalizing
            setTargetProgress(1.0)
            dataStore.saveSkinScan(scan)

            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled, analysisID == runID else {
                log.notice("face-\(runID) cancelled at=finalizing")
                return
            }

            faceScanResult = scan
            phase = .complete
            progress = 1.0
            stopProgressTimer()
            HapticManager.notification(.success)
            log.info("face-\(runID) complete")
        } catch {
            guard !Task.isCancelled, analysisID == runID else {
                log.notice("face-\(runID) cancelled at=error-path")
                return
            }
            log.error("face-\(runID) failed: \(error.localizedDescription)")
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
        mode: FoodCaptureMode = .photo,
        analysisService: FoodAnalysisServiceProtocol,
        dataStore: DataStore
    ) {
        cancelAndReset()
        kind = .food
        isActive = true
        phase = .preparing
        setTargetProgress(0.15)

        let runID = analysisID
        log.info("food-\(runID) started, imageSize=\(imageData.count) bytes, mode=\(mode.rawValue, privacy: .public)")

        analysisTask = Task {
            await runFoodAnalysis(imageData: imageData, foodName: foodName, mode: mode, service: analysisService, dataStore: dataStore, runID: runID)
        }
    }

    private func runFoodAnalysis(
        imageData: Data,
        foodName: String,
        mode: FoodCaptureMode,
        service: FoodAnalysisServiceProtocol,
        dataStore: DataStore,
        runID: UInt64
    ) async {
        phase = .uploading
        setTargetProgress(0.35)
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled, analysisID == runID else {
            log.notice("food-\(runID) cancelled at=uploading")
            return
        }

        phase = .analyzing
        setTargetProgress(0.85)
        log.info("food-\(runID) requesting analysis")

        do {
            let scan = try await service.analyzeFood(image: imageData, foodName: foodName, mode: mode)

            guard !Task.isCancelled, analysisID == runID else {
                log.notice("food-\(runID) cancelled at=post-analysis (stale write prevented)")
                return
            }

            log.info("food-\(runID) analysis succeeded, score=\(scan.skinImpactScore)")

            phase = .finalizing
            setTargetProgress(1.0)
            dataStore.saveFoodScan(scan)

            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled, analysisID == runID else {
                log.notice("food-\(runID) cancelled at=finalizing")
                return
            }

            foodScanResult = scan
            phase = .complete
            progress = 1.0
            stopProgressTimer()
            HapticManager.notification(.success)
            log.info("food-\(runID) complete")
        } catch {
            guard !Task.isCancelled, analysisID == runID else {
                log.notice("food-\(runID) cancelled at=error-path")
                return
            }
            log.error("food-\(runID) failed: \(error.localizedDescription)")
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
        let id = analysisID
        analysisTask?.cancel()
        analysisTask = nil
        stopProgressTimer()
        isActive = false
        log.info("dismissed, analysisID=\(id)")
    }

    func retry(dataStore: DataStore) {
        // Can't retry without the original data, so just dismiss
        dismiss()
    }

    /// Cancel any in-flight task and reset state for a new analysis.
    private func cancelAndReset() {
        analysisTask?.cancel()
        analysisTask = nil
        stopProgressTimer()
        analysisID &+= 1
        progress = 0
        phase = .preparing
        faceScanResult = nil
        foodScanResult = nil
    }
}
