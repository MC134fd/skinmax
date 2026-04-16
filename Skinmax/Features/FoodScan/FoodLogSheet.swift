import SwiftUI

/// Camera-first food capture. Opens camera immediately; on capture, processes
/// the image and hands off to AnalysisCoordinator with a fallback name.
struct FoodCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    @Environment(AnalysisCoordinator.self) private var coordinator
    @State private var capturedImage: UIImage?
    @State private var showCamera = true
    @State private var isProcessing = false

    var body: some View {
        ZStack {
            GlowbiteColors.creamBG.ignoresSafeArea()

            if isProcessing {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(GlowbiteColors.coral)
                    Text("Processing your meal...")
                        .font(.gbBodyM)
                        .foregroundStyle(GlowbiteColors.mediumTaupe)
                }
            }
        }
        .sheet(isPresented: $showCamera, onDismiss: {
            // Camera dismissed without capturing — exit the flow
            if capturedImage == nil {
                dismiss()
            }
        }) {
            ImagePicker(sourceType: .camera, selectedImage: $capturedImage)
                .ignoresSafeArea()
        }
        .onChange(of: capturedImage) { _, image in
            guard let image else { return }
            Task {
                await processAndAnalyze(image)
            }
        }
    }

    private func processAndAnalyze(_ image: UIImage) async {
        isProcessing = true
        HapticManager.impact(.medium)

        guard let imageData = await ImageProcessor.processForFoodAnalysis(image) else {
            isProcessing = false
            dismiss()
            return
        }

        coordinator.startFoodScan(
            imageData: imageData,
            foodName: "Meal",
            analysisService: FoodAnalysisService(),
            dataStore: dataStore
        )
        dismiss()
    }
}
