import SwiftUI
import Observation

@Observable
final class FoodLogSheetViewModel {
    var foodName = ""
    var selectedImage: UIImage?
    var isAnalyzing = false
    var errorMessage: String?
    var result: FoodScan?

    private let analysisService: FoodAnalysisServiceProtocol

    init(analysisService: FoodAnalysisServiceProtocol = FoodAnalysisService()) {
        self.analysisService = analysisService
    }

    var canAnalyze: Bool {
        !foodName.trimmingCharacters(in: .whitespaces).isEmpty && selectedImage != nil && !isAnalyzing
    }

    func analyze() async {
        guard let image = selectedImage else { return }

        isAnalyzing = true
        errorMessage = nil
        HapticManager.impact(.medium)

        guard let imageData = await ImageProcessor.processForAnalysis(image) else {
            errorMessage = "Failed to process image. Try again."
            isAnalyzing = false
            return
        }

        do {
            let scan = try await analysisService.analyzeFood(image: imageData, foodName: foodName)
            result = scan
        } catch let error as FoodAnalysisError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Couldn't analyze this food, try a clearer photo."
        }

        isAnalyzing = false
    }

    func removePhoto() {
        selectedImage = nil
    }

    func reset() {
        foodName = ""
        selectedImage = nil
        isAnalyzing = false
        errorMessage = nil
        result = nil
    }
}
