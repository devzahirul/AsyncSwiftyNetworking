import SwiftUI
import AsyncSwiftyNetworking

// MARK: - Posts View (GET Request Demo)

struct PostsView: View {
    @StateObject private var viewModel = PostsViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    ProgressView("Loading posts...")
                } else if let error = viewModel.error {
                    ErrorView(error: error) {
                        Task { await viewModel.loadPosts() }
                    }
                } else {
                    postsList
                }
            }
            .navigationTitle("Posts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await viewModel.loadPosts() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .task {
                await viewModel.loadPosts()
            }
        }
    }
    
    private var postsList: some View {
        List {
            ForEach(viewModel.posts) { post in
                PostRow(post: post)
            }
            .onDelete { indexSet in
                Task {
                    for index in indexSet {
                        await viewModel.deletePost(viewModel.posts[index])
                    }
                }
            }
            
            // Pagination
            if viewModel.hasMorePages {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .task {
                    await viewModel.loadMorePosts()
                }
            }
        }
        .refreshable {
            await viewModel.loadPosts()
        }
    }
}

// MARK: - Post Row

struct PostRow: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.title)
                .font(.headline)
                .lineLimit(2)
            
            Text(post.body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            
            HStack {
                Label("User \(post.userId)", systemImage: "person.circle")
                Spacer()
                if let date = post.createdAt {
                    Text(date)
                }
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Posts ViewModel

@MainActor
class PostsViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var error: NetworkError?
    @Published var currentPage = 1
    @Published var hasMorePages = true
    
    private let network = NetworkManager.shared
    
    func loadPosts() async {
        isLoading = true
        error = nil
        currentPage = 1
        
        do {
            // GET Request - The mock session handles routing and returns mock data
            let response: PostsListResponse = try await network.client.request(
                API.Posts.list,
                baseUrl: network.baseURL
            )
            
            posts = response.posts
            hasMorePages = posts.count >= 20
            
        } catch let networkError as NetworkError {
            error = networkError
        } catch {
            self.error = NetworkError.from(error as? URLError ?? URLError(.unknown))
        }
        
        isLoading = false
    }
    
    func loadMorePosts() async {
        guard !isLoading, hasMorePages else { return }
        
        currentPage += 1
        isLoading = true
        
        do {
            let pagination = PaginationParams(page: currentPage, pageSize: 20)
            let response: PaginatedResponse<Post> = try await network.client.requestPaginated(
                API.Posts.list,
                baseUrl: network.baseURL,
                pagination: pagination
            )
            
            posts.append(contentsOf: response.data)
            hasMorePages = response.hasNextPage
            
        } catch {
            // Ignore pagination errors
        }
        
        isLoading = false
    }
    
    func deletePost(_ post: Post) async {
        do {
            // DELETE Request
            let _: EmptyResponse = try await network.client.request(
                API.Posts.delete(id: post.id),
                baseUrl: network.baseURL
            )
            
            posts.removeAll { $0.id == post.id }
            
        } catch {
            // Handle delete error
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let error: NetworkError
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: errorIcon)
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            
            Text(errorTitle)
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
    
    var errorIcon: String {
        switch error {
        case .noConnection: return "wifi.slash"
        case .timeout: return "clock.badge.exclamationmark"
        case .serverError: return "server.rack"
        default: return "exclamationmark.triangle"
        }
    }
    
    var errorTitle: String {
        switch error {
        case .noConnection: return "No Connection"
        case .timeout: return "Request Timeout"
        case .serverError: return "Server Error"
        default: return "Something Went Wrong"
        }
    }
}

#Preview {
    PostsView()
}
