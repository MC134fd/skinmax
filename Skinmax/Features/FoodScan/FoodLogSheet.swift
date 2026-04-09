import SwiftUI
import PhotosUI

struct FoodLogSheet: View {
    @State private var viewModel = FoodLogSheetViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    @Environment(AnalysisCoordinator.self) private var coordinator
    @State private var showCamera = false
    @State private var photosPickerItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Log a Meal")
                        .font(SkinmaxFonts.h2())
                        .foregroundStyle(SkinmaxColors.darkBrown)
                        .padding(.top, 8)

                    foodNameField
                    photoSection

                    if viewModel.selectedImage != nil {
                        photoThumbnail
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(SkinmaxFonts.caption())
                            .foregroundStyle(SkinmaxColors.redAlert)
                    }

                    analyzeButton
                }
                .padding(.horizontal, SkinmaxSpacing.screenPadding)
                .padding(.bottom, 30)
            }
            .background(SkinmaxColors.creamBG.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(SkinmaxColors.mutedTan)
                    }
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera, selectedImage: $viewModel.selectedImage)
        }
        .onChange(of: photosPickerItem) { _, newItem in
            if let newItem {
                Task { @MainActor in
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.selectedImage = image
                        HapticManager.impact(.light)
                    }
                }
            }
        }
        .onChange(of: viewModel.preparedImageData) { _, imageData in
            if let imageData {
                // Hand off to coordinator and dismiss
                coordinator.startFoodScan(
                    imageData: imageData,
                    foodName: viewModel.foodName,
                    analysisService: FoodAnalysisService(),
                    dataStore: dataStore
                )
                dismiss()
            }
        }
    }

    // MARK: - Food Name Field
    private var foodNameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("What did you eat?")
                .font(SkinmaxFonts.caption())
                .foregroundStyle(SkinmaxColors.mutedTan)

            TextField("e.g. Salmon bowl, Pizza...", text: $viewModel.foodName)
                .font(SkinmaxFonts.body())
                .foregroundStyle(SkinmaxColors.darkBrown)
                .padding(14)
                .background(SkinmaxColors.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(SkinmaxColors.lightTan, lineWidth: 1)
                )
        }
    }

    // MARK: - Photo Section
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Add a photo")
                .font(SkinmaxFonts.caption())
                .foregroundStyle(SkinmaxColors.mutedTan)

            HStack(spacing: 10) {
                Button {
                    showCamera = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                        Text("Take Photo")
                    }
                    .font(SkinmaxFonts.h3())
                    .foregroundStyle(SkinmaxColors.darkBrown)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(SkinmaxColors.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(SkinmaxColors.lightTan, lineWidth: 1)
                    )
                }

                PhotosPicker(selection: $photosPickerItem, matching: .images) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.fill")
                        Text("Choose Photo")
                    }
                    .font(SkinmaxFonts.h3())
                    .foregroundStyle(SkinmaxColors.darkBrown)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(SkinmaxColors.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(SkinmaxColors.lightTan, lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - Photo Thumbnail
    private var photoThumbnail: some View {
        ZStack(alignment: .topTrailing) {
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                viewModel.removePhoto()
                photosPickerItem = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
            }
            .padding(8)
        }
    }

    // MARK: - Analyze Button
    private var analyzeButton: some View {
        Button {
            Task {
                await viewModel.prepareForAnalysis()
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isPreparing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Analyze with AI \u{2728}")
                }
            }
            .font(.custom("Nunito-SemiBold", size: 14))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(SkinmaxColors.coral)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .opacity(viewModel.canAnalyze ? 1.0 : 0.5)
        }
        .disabled(!viewModel.canAnalyze)
    }
}
