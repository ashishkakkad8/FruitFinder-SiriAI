import SwiftUI
import PhotosUI
import ImageIO

struct FruitPhotoView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: Image?
    @State private var identifiedFruit = ""
    @State private var isAnalyzing = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Group {
                    if let selectedImage {
                        selectedImage
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: 320)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                    } else {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.thinMaterial)
                            .frame(height: 320)
                            .overlay {
                                ContentUnavailableView(
                                    "Choose a Fruit Photo",
                                    systemImage: "photo",
                                    description: Text("Pick a photo and Fruit Finder will identify it on-device.")
                                )
                            }
                    }
                }

                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Choose Photo", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if !identifiedFruit.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Identified Fruit", systemImage: "sparkles")
                            .font(.headline)

                        Text(identifiedFruit)
                            .font(.largeTitle.bold())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                }

                if isAnalyzing {
                    ProgressView("Identifying fruit…")
                        .frame(maxWidth: .infinity)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .navigationTitle("Photo Finder")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPhoto) { _, newItem in
            guard let newItem else { return }
            Task {
                await loadAndAnalyze(newItem)
            }
        }
    }

    private func loadAndAnalyze(_ item: PhotosPickerItem) async {
        isAnalyzing = true
        errorMessage = nil
        identifiedFruit = ""
        defer { isAnalyzing = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw FruitAIError.invalidImage
            }

            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                throw FruitAIError.invalidImage
            }

            selectedImage = Image(decorative: cgImage, scale: 1)

            if #available(iOS 27.0, *) {
                identifiedFruit = try await FruitAIService.identifyFruit(in: cgImage)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
