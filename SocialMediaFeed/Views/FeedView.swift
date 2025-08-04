import SwiftUI

// MARK: - Feed View
struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @StateObject private var pluginManager = FeedItemPluginManager()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Posts
                        ForEach(viewModel.posts) { post in
                            FeedItemView.createWithPlugin(
                                post: post,
                                pluginManager: pluginManager,
                                onLike: {
                                    viewModel.likePost(post)
                                },
                                onBookmark: {
                                    viewModel.bookmarkPost(post)
                                },
                                onShare: {
                                    sharePost(post)
                                },
                                onComment: {
                                    // Handle comment action
                                }
                            )
                            .onAppear {
                                // Trigger infinite scrolling
                                if post.id == viewModel.posts.last?.id {
                                    viewModel.loadMorePosts()
                                }
                            }
                        }
                        
                        // Loading indicator
                        if viewModel.isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        }
                        
                        // End of feed indicator
                        if !viewModel.canLoadMore && !viewModel.posts.isEmpty {
                            HStack {
                                Spacer()
                                Text("You're all caught up!")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding()
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .refreshable {
                    await refreshFeed()
                }
                
                // Loading overlay
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    LoadingView()
                }
                
                // Error overlay
                if viewModel.hasError && viewModel.posts.isEmpty {
                    ErrorView(
                        message: viewModel.errorText ?? "Something went wrong",
                        onRetry: viewModel.retryLoading
                    )
                }
                
                // Empty state
                if viewModel.posts.isEmpty && !viewModel.isLoading && !viewModel.hasError {
                    EmptyStateView(
                        message: viewModel.emptyStateMessage,
                        onRefresh: viewModel.retryLoading
                    )
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Handle settings or menu
                    }) {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            setupPlugins()
            if viewModel.posts.isEmpty {
                viewModel.loadInitialPosts()
            }
        }
    }
    
    // MARK: - Private Methods
    private func setupPlugins() {
        pluginManager.register(PromotedPostPlugin())
        pluginManager.register(VideoPostPlugin())
        pluginManager.register(LivePostPlugin())
    }
    
    private func refreshFeed() async {
        await withCheckedContinuation { continuation in
            viewModel.refreshPosts()
            // Simulate async completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                continuation.resume()
            }
        }
    }
    
    private func sharePost(_ post: Post) {
        let text = "Check out this post by \(post.author.displayName)!"
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading posts...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Oops!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let message: String
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No Posts Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: onRefresh) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Network Status View
struct NetworkStatusView: View {
    let networkState: NetworkState
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(networkState == .online ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(networkStateText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var networkStateText: String {
        switch networkState {
        case .online:
            return "Online"
        case .offline:
            return "Offline"
        case .connecting:
            return "Connecting..."
        }
    }
}

// MARK: - Preview
struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
} 