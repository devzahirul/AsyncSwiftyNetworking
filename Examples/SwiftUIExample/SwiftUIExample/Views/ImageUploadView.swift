import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#else
import AppKit
typealias PlatformImage = NSImage
#endif
import AsyncSwiftyNetworking

// MARK: - Image Upload View (Multi-Image Upload Demo)

struct ImageUploadView: View {
    @StateObject private var viewModel = ImageUploadViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Selected Images Grid
                    if !viewModel.selectedImages.isEmpty {
                        selectedImagesSection
                    }
                    
                    // Photo Picker
                    photoPickerSection
                    
                    // Upload Progress
                    if viewModel.isUploading {
                        uploadProgressSection
                    }
                    
                    // Success Message
                    if viewModel.uploadSuccess {
                        successSection
                    }
                    
                    // Error Message
                    if let error = viewModel.error {
                        errorSection(error)
                    }
                    
                    // Upload Button
                    if !viewModel.selectedImages.isEmpty && !viewModel.isUploading {
                        uploadButton
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Upload Images")
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.stack.fill")
                .font(.system(size: 50))
                .foregroundStyle(.blue.gradient)
            
            Text("Multi-Image Upload")
                .font(.title2.bold())
            
            Text("Select multiple images and upload them using multipart/form-data")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var selectedImagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Selected Images (\(viewModel.selectedImages.count))")
                    .font(.headline)
                
                Spacer()
                
                Button("Clear All") {
                    viewModel.clearImages()
                }
                .font(.caption)
            }
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80, maximum: 100))
            ], spacing: 8) {
                ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { index, imageData in
                    ZStack(alignment: .topTrailing) {
                        #if canImport(UIKit)
                        if let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        #else
                        if let nsImage = NSImage(data: imageData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        #endif
                        
                        Button {
                            viewModel.removeImage(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white, .red)
                        }
                        .offset(x: 5, y: -5)
                    }
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var photoPickerSection: some View {
        PhotosPicker(
            selection: $viewModel.photoSelection,
            maxSelectionCount: 10,
            matching: .images
        ) {
            Label("Select Photos", systemImage: "photo.on.rectangle.angled")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(12)
        }
        .onChange(of: viewModel.photoSelection) { newValue in
            Task {
                await viewModel.loadSelectedPhotos(from: newValue)
            }
        }
    }
    
    private var uploadProgressSection: some View {
        VStack(spacing: 12) {
            ProgressView(value: viewModel.uploadProgress)
                .progressViewStyle(.linear)
            
            Text("Uploading \(Int(viewModel.uploadProgress * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var successSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)
            
            Text("Upload Successful!")
                .font(.headline)
            
            if !viewModel.uploadedUrls.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Uploaded URLs:")
                        .font(.caption.bold())
                    ForEach(viewModel.uploadedUrls, id: \.self) { url in
                        Text(url)
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func errorSection(_ error: NetworkError) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundStyle(.red)
            
            Text("Upload Failed")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var uploadButton: some View {
        Button {
            Task { await viewModel.uploadImages() }
        } label: {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                Text("Upload \(viewModel.selectedImages.count) Image\(viewModel.selectedImages.count == 1 ? "" : "s")")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
}

// MARK: - Image Upload ViewModel

@MainActor
class ImageUploadViewModel: ObservableObject {
    @Published var photoSelection: [PhotosPickerItem] = []
    @Published var selectedImages: [Data] = []  // Store as Data for cross-platform
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var uploadSuccess = false
    @Published var uploadedUrls: [String] = []
    @Published var error: NetworkError?
    
    private let network = NetworkManager.shared
    
    func loadSelectedPhotos(from items: [PhotosPickerItem]) async {
        selectedImages = []
        
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                selectedImages.append(data)
            }
        }
    }
    
    func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
    }
    
    func clearImages() {
        selectedImages = []
        photoSelection = []
        uploadSuccess = false
        uploadedUrls = []
        error = nil
    }
    
    func uploadImages() async {
        guard !selectedImages.isEmpty else { return }
        
        isUploading = true
        uploadProgress = 0
        uploadSuccess = false
        uploadedUrls = []
        error = nil
        
        do {
            // Create multipart form data
            let formData = MultipartFormData()
            
            // Add description field
            formData.addTextField(name: "description", value: "Uploaded from SwiftUI Example App")
            formData.addTextField(name: "count", value: "\(selectedImages.count)")
            
            // Add each image as a file
            for (index, imageData) in selectedImages.enumerated() {
                // Simulate progress
                uploadProgress = Double(index) / Double(selectedImages.count)
                
                let file = MultipartFormData.FileData(
                    data: imageData,
                    name: "images[]",
                    fileName: "image_\(index + 1).jpg",
                    mimeType: "image/jpeg"
                )
                formData.addFile(file)
            }
            
            // Simulate upload for demo purposes
            try await Task.sleep(nanoseconds: 2_000_000_000)
            uploadProgress = 1.0
            
            // Simulate success response
            uploadedUrls = selectedImages.enumerated().map { index, _ in
                "https://example.com/images/\(UUID().uuidString.prefix(8)).jpg"
            }
            
            uploadSuccess = true
            
        } catch let networkError as NetworkError {
            error = networkError
        } catch {
            self.error = .underlying(error.localizedDescription)
        }
        
        isUploading = false
    }
}

#Preview {
    ImageUploadView()
}
