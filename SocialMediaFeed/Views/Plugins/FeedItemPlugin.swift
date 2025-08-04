import SwiftUI

// MARK: - Feed Item Plugin Protocol
protocol FeedItemPlugin {
    var identifier: String { get }
    var priority: Int { get }
    func canHandle(_ post: Post) -> Bool
    func createView(for post: Post, actions: PostActions) -> AnyView
}

// MARK: - Post Actions
struct PostActions {
    let onLike: () -> Void
    let onBookmark: () -> Void
    let onShare: () -> Void
    let onComment: () -> Void
    let onTap: () -> Void
}

// MARK: - Plugin Manager
class FeedItemPluginManager: ObservableObject {
    private var plugins: [FeedItemPlugin] = []
    
    func register(_ plugin: FeedItemPlugin) {
        plugins.append(plugin)
        plugins.sort { $0.priority > $1.priority }
    }
    
    func unregister(_ plugin: FeedItemPlugin) {
        plugins.removeAll { $0.identifier == plugin.identifier }
    }
    
    func getPlugin(for post: Post) -> FeedItemPlugin? {
        return plugins.first { $0.canHandle(post) }
    }
    
    func createView(for post: Post, actions: PostActions) -> AnyView {
        if let plugin = getPlugin(for: post) {
            return plugin.createView(for: post, actions: actions)
        }
        
        // Default view
        return AnyView(
            FeedItemView(
                post: post,
                onLike: actions.onLike,
                onBookmark: actions.onBookmark,
                onShare: actions.onShare,
                onComment: actions.onComment
            )
        )
    }
}

// MARK: - Default Plugins

// MARK: - Promoted Post Plugin
class PromotedPostPlugin: FeedItemPlugin {
    let identifier = "promoted_post"
    let priority = 100
    
    func canHandle(_ post: Post) -> Bool {
        // Check if post is promoted (you can add a promoted flag to Post model)
        return post.author.username.contains("sponsored") || 
               post.content.textContent?.contains("#ad") == true
    }
    
    func createView(for post: Post, actions: PostActions) -> AnyView {
        return AnyView(
            PromotedPostView(post: post, actions: actions)
        )
    }
}

// MARK: - Video Post Plugin
class VideoPostPlugin: FeedItemPlugin {
    let identifier = "video_post"
    let priority = 50
    
    func canHandle(_ post: Post) -> Bool {
        if case .video = post.content {
            return true
        }
        return false
    }
    
    func createView(for post: Post, actions: PostActions) -> AnyView {
        return AnyView(
            VideoPostView(post: post, actions: actions)
        )
    }
}

// MARK: - Live Post Plugin
class LivePostPlugin: FeedItemPlugin {
    let identifier = "live_post"
    let priority = 75
    
    func canHandle(_ post: Post) -> Bool {
        // Check if post is live (you can add a live flag to Post model)
        return post.content.textContent?.contains("#live") == true ||
               post.content.textContent?.contains("🔴 LIVE") == true
    }
    
    func createView(for post: Post, actions: PostActions) -> AnyView {
        return AnyView(
            LivePostView(post: post, actions: actions)
        )
    }
}

// MARK: - Custom Plugin Views

// MARK: - Promoted Post View
struct PromotedPostView: View {
    let post: Post
    let actions: PostActions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Promoted Badge
            HStack {
                Image(systemName: "megaphone.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text("Promoted")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Regular Feed Item
            FeedItemView(
                post: post,
                onLike: actions.onLike,
                onBookmark: actions.onBookmark,
                onShare: actions.onShare,
                onComment: actions.onComment
            )
        }
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Video Post View
struct VideoPostView: View {
    let post: Post
    let actions: PostActions
    @State private var isPlaying = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            PostHeaderView(author: post.author, timestamp: post.timestamp)
            
            // Video Content
            if case .video(let url, let caption, let thumbnail) = post.content {
                VStack(alignment: .leading, spacing: 8) {
                    if let textContent = caption {
                        Text(textContent)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    
                    ZStack {
                        AsyncImage(url: URL(string: thumbnail ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .aspectRatio(16/9, contentMode: .fit)
                        .cornerRadius(8)
                        
                        // Play/Pause Button
                        Button(action: {
                            isPlaying.toggle()
                        }) {
                            Circle()
                                .fill(Color.black.opacity(0.7))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                        .foregroundColor(.white)
                                        .font(.title)
                                )
                        }
                        
                        // Video Duration Badge
                        VStack {
                            HStack {
                                Spacer()
                                Text("2:34") // Mock duration
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(4)
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                }
            }
            
            // Actions
            PostActionsView(
                post: post,
                onLike: actions.onLike,
                onBookmark: actions.onBookmark,
                onShare: actions.onShare,
                onComment: actions.onComment
            )
            
            // Stats
            PostStatsView(post: post)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Live Post View
struct LivePostView: View {
    let post: Post
    let actions: PostActions
    @State private var viewerCount = Int.random(in: 100...5000)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Live Badge
            HStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Text("LIVE")
                    .font(.caption)
                    .foregroundColor(.red)
                    .fontWeight(.bold)
                Text("\(viewerCount) watching")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Regular Feed Item
            FeedItemView(
                post: post,
                onLike: actions.onLike,
                onBookmark: actions.onBookmark,
                onShare: actions.onShare,
                onComment: actions.onComment
            )
        }
        .background(Color.red.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            // Simulate live viewer count updates
            Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                viewerCount += Int.random(in: -50...100)
                viewerCount = max(100, viewerCount)
            }
        }
    }
}

// MARK: - Plugin Extension for Feed View
extension FeedItemView {
    static func createWithPlugin(
        post: Post,
        pluginManager: FeedItemPluginManager,
        onLike: @escaping () -> Void,
        onBookmark: @escaping () -> Void,
        onShare: @escaping () -> Void,
        onComment: @escaping () -> Void
    ) -> AnyView {
        let actions = PostActions(
            onLike: onLike,
            onBookmark: onBookmark,
            onShare: onShare,
            onComment: onComment,
            onTap: {}
        )
        
        return pluginManager.createView(for: post, actions: actions)
    }
} 