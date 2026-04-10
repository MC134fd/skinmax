import SwiftUI
import Observation

@Observable
@MainActor
final class FoodLogSheetViewModel {
    var foodName = ""
    var selectedImage: UIImage?
    var isPreparing = false
    var errorMessage: String?
    var preparedImageData: Data?

    var canAnalyze: Bool {
        !foodName.trimmingCharacters(in: .whitespaces).isEmpty && selectedImage != nil && !isPreparing
    }

    @MainActor
    func prepareForAnalysis() async {
        guard let image = selectedImage else { return }

        isPreparing = true
        errorMessage = nil
        HapticManager.impact(.medium)

        guard let imageData = await ImageProcessor.processForFoodAnalysis(image) else {
            errorMessage = "Failed to process image. Try again."
            isPreparing = false
            return
        }

        // Signal that image is ready — the view will hand off to coordinator
        preparedImageData = imageData
        isPreparing = false
    }

    func removePhoto() {
        selectedImage = nil
    }

    func reset() {
        foodName = ""
        selectedImage = nil
        isPreparing = false
        errorMessage = nil
        preparedImageData = nil
    }
}
