import SwiftUI
import PhotosUI

/// Camera-first food capture. Embeds camera directly — no intermediate screen.
/// Gallery button overlaid for picking from camera roll.
struct FoodCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    @Environment(AnalysisCoordinator.self) private var coordinator
    @State private var isProcessing = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isLoadingPhoto = false

    var body: some View {
        ZStack {
            ImagePicker(
                sourceType: .camera,
                onCapture: { image in
                    Task {
                        await processAndAnalyze(image)
                    }
                },
                onCancel: {
                    dismiss()
                }
            )
            .ignoresSafeArea()

            // Gallery button — bottom-leading, above native camera controls
            if !isProcessing && !isLoadingPhoto {
                VStack {
                    Spacer()
                    HStack {
                        galleryButton
                        Spacer()
                    }
                    .padding(.leading, 20)
                    .padding(.bottom, 160)
                }
            }

            if isProcessing || isLoadingPhoto {
                Color.black.opacity(0.4).ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                    Text(isLoadingPhoto ? "Loading photo..." : "Processing your meal...")
                        .font(.gbBodyM)
                        .foregroundStyle(.white)
                }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task { await loadAndProcess(newItem) }
        }
    }

    // MARK: - Gallery Button

    private var galleryButton: some View {
        PhotosPicker(
            selection: $selectedPhotoItem,
            matching: .images
        ) {
            HStack(spacing: 6) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 16, weight: .semibold))
                Text("Gallery")
                    .font(.gbCaption)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
    }

    // MARK: - Photo Loading

    private func loadAndProcess(_ item: PhotosPickerItem) async {
        isLoadingPhoto = true
        HapticManager.impact(.medium)

        defer {
            isLoadingPhoto = false
            selectedPhotoItem = nil
        }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else {
            HapticManager.notification(.error)
            return
        }

        await processAndAnalyze(uiImage)
    }

    // MARK: - Shared Processing

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
