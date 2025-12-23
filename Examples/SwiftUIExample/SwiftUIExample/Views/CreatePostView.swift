import SwiftUI
import AsyncSwiftyNetworking

// MARK: - Create Post View (POST Request Demo)

struct CreatePostView: View {
    @StateObject private var viewModel = CreatePostViewModel()
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, body
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Post Title", text: $viewModel.title)
                        .focused($focusedField, equals: .title)
                    
                    TextEditor(text: $viewModel.body)
                        .focused($focusedField, equals: .body)
                        .frame(minHeight: 150)
                } header: {
                    Text("New Post")
                } footer: {
                    Text("This demonstrates a POST request to create a new resource.")
                }
                
                // Success Message
                if viewModel.showSuccess {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Post created successfully!")
                        }
                        
                        if let createdPost = viewModel.createdPost {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ID: \(createdPost.id)")
                                Text("Title: \(createdPost.title)")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Error Message
                if let error = viewModel.error {
                    Section {
                        Text(error.localizedDescription)
                            .foregroundStyle(.red)
                    }
                }
                
                // Submit Button
                Section {
                    Button {
                        focusedField = nil
                        Task { await viewModel.createPost() }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("Create Post")
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isFormInvalid || viewModel.isLoading)
                }
                
                // Reset Button
                if viewModel.showSuccess || viewModel.error != nil {
                    Section {
                        Button("Create Another") {
                            viewModel.reset()
                        }
                    }
                }
            }
            .navigationTitle("Create Post")
        }
    }
}

// MARK: - Create Post ViewModel

@MainActor
class CreatePostViewModel: ObservableObject {
    @Published var title = ""
    @Published var body = ""
    @Published var isLoading = false
    @Published var error: NetworkError?
    @Published var showSuccess = false
    @Published var createdPost: PostResponse?
    
    private let network = NetworkManager.shared
    
    var isFormInvalid: Bool {
        title.trimmingCharacters(in: .whitespaces).isEmpty ||
        body.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    func createPost() async {
        isLoading = true
        error = nil
        showSuccess = false
        
        do {
            // POST Request - Create a new post
            let response: PostResponse = try await network.client.request(
                API.Posts.create(title: title, body: body),
                baseUrl: network.baseURL
            )
            
            createdPost = response
            showSuccess = true
            
            // Clear form
            title = ""
            body = ""
            
        } catch let networkError as NetworkError {
            error = networkError
        } catch {
            self.error = .underlying(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func reset() {
        title = ""
        body = ""
        error = nil
        showSuccess = false
        createdPost = nil
    }
}

#Preview {
    CreatePostView()
}
