#!/usr/bin/env swift

import Foundation

// MARK: - Demo Models
struct Post: Identifiable, Codable, Equatable {
    let id: UUID
    let author: User
    let content: PostContent
    let timestamp: Date
    let likes: Int
    let comments: Int
    let shares: Int
    var isLiked: Bool
    var isBookmarked: Bool
    
    init(
        id: UUID = UUID(),
        author: User,
        content: PostContent,
        timestamp: Date = Date(),
        likes: Int = 0,
        comments: Int = 0,
        shares: Int = 0,
        isLiked: Bool = false,
        isBookmarked: Bool = false
    ) {
        self.id = id
        self.author = author
        self.content = content
        self.timestamp = timestamp
        self.likes = likes
        self.shares = shares
        self.comments = comments
        self.isLiked = isLiked
        self.isBookmarked = isBookmarked
    }
}

struct User: Identifiable, Codable, Equatable {
    let id: UUID
    let username: String
    let displayName: String
    let avatarURL: String?
    let isVerified: Bool
    
    init(
        id: UUID = UUID(),
        username: String,
        displayName: String,
        avatarURL: String? = nil,
        isVerified: Bool = false
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.isVerified = isVerified
    }
}

enum PostContent: Codable, Equatable {
    case text(String)
    case image(String, caption: String?)
    case video(String, caption: String?, thumbnail: String?)
    case link(String, title: String, description: String?, thumbnail: String?)
    
    var textContent: String? {
        switch self {
        case .text(let text):
            return text
        case .image(_, let caption):
            return caption
        case .video(_, let caption, _):
            return caption
        case .link(_, let title, let description, _):
            return description ?? title
        }
    }
}

// MARK: - Demo Feed ViewModel
class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasError = false
    @Published var errorMessage: String?
    
    private var currentPage = 0
    private let pageSize = 10
    private var hasMorePages = true
    
    init() {
        loadInitialPosts()
    }
    
    func loadInitialPosts() {
        isLoading = true
        currentPage = 0
        hasMorePages = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.posts = self.generateMockPosts()
            self.isLoading = false
        }
    }
    
    func loadMorePosts() {
        guard !isLoadingMore && hasMorePages else { return }
        
        isLoadingMore = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let newPosts = self.generateMockPosts()
            self.posts.append(contentsOf: newPosts)
            self.isLoadingMore = false
            
            // Stop loading more after 3 pages
            if self.currentPage >= 2 {
                self.hasMorePages = false
            }
            self.currentPage += 1
        }
    }
    
    func likePost(_ post: Post) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].isLiked.toggle()
            print("Post \(post.id) liked: \(posts[index].isLiked)")
        }
    }
    
    func bookmarkPost(_ post: Post) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].isBookmarked.toggle()
            print("Post \(post.id) bookmarked: \(posts[index].isBookmarked)")
        }
    }
    
    func retryLoading() {
        hasError = false
        errorMessage = nil
        loadInitialPosts()
    }
    
    private func generateMockPosts() -> [Post] {
        let users = [
            User(username: "john_doe", displayName: "John Doe", isVerified: true),
            User(username: "jane_smith", displayName: "Jane Smith", isVerified: false),
            User(username: "tech_guru", displayName: "Tech Guru", isVerified: true),
            User(username: "design_master", displayName: "Design Master", isVerified: false),
            User(username: "news_anchor", displayName: "News Anchor", isVerified: true)
        ]
        
        let contents: [PostContent] = [
            .text("Just finished building an amazing MVVM app with Combine! The architecture is so clean and testable. #iOS #SwiftUI #MVVM"),
            .image("https://example.com/image1.jpg", caption: "Beautiful sunset at the beach today! 🌅"),
            .video("https://example.com/video1.mp4", caption: "Check out this amazing tutorial!", thumbnail: "https://example.com/thumb1.jpg"),
            .text("The power of reactive programming with Combine is incredible. Real-time updates, clean data flow, and excellent testability."),
            .link("https://example.com/article", title: "Building Scalable iOS Apps", description: "Learn how to build scalable iOS applications using MVVM and Combine", thumbnail: "https://example.com/article-thumb.jpg"),
            .text("Working on a new feature that will revolutionize how users interact with our app. Can't wait to share more details! 🚀"),
            .image("https://example.com/image2.jpg", caption: "Coffee and coding - the perfect combination ☕️💻"),
            .text("Just released version 2.0 of our app! Tons of new features and improvements. Download now and let us know what you think!"),
            .video("https://example.com/video2.mp4", caption: "Behind the scenes of our development process", thumbnail: "https://example.com/thumb2.jpg"),
            .text("The importance of clean architecture cannot be overstated. It makes development faster, testing easier, and maintenance simpler.")
        ]
        
        var posts: [Post] = []
        for i in 0..<10 {
            let user = users[i % users.count]
            let content = contents[i % contents.count]
            let timestamp = Date().addingTimeInterval(-Double(i * 3600)) // Each post 1 hour apart
            
            let post = Post(
                author: user,
                content: content,
                timestamp: timestamp,
                likes: Int.random(in: 0...1000),
                comments: Int.random(in: 0...100),
                shares: Int.random(in: 0...50),
                isLiked: Bool.random(),
                isBookmarked: Bool.random()
            )
            
            posts.append(post)
        }
        
        return posts
    }
}

// MARK: - Demo Feed Item View
struct FeedItemView {
    let post: Post
    let onLike: () -> Void
    let onBookmark: () -> Void
    let onShare: () -> Void
    let onComment: () -> Void
    
    func display() {
        print("\n" + "="*50)
        print("📱 POST")
        print("="*50)
        
        // Header
        print("👤 \(post.author.displayName)\(post.author.isVerified ? " ✓" : "")")
        print("   @\(post.author.username)")
        print("   📅 \(formatDate(post.timestamp))")
        print()
        
        // Content
        if let textContent = post.content.textContent {
            print("📝 \(textContent)")
            print()
        }
        
        // Content type indicator
        switch post.content {
        case .image:
            print("🖼️  [IMAGE POST]")
        case .video:
            print("🎥 [VIDEO POST]")
        case .link:
            print("🔗 [LINK POST]")
        default:
            break
        }
        print()
        
        // Actions
        print("❤️  \(post.likes) likes")
        print("💬 \(post.comments) comments")
        print("📤 \(post.shares) shares")
        print("   Liked: \(post.isLiked ? "Yes" : "No")")
        print("   Bookmarked: \(post.isBookmarked ? "Yes" : "No")")
        print()
        
        // Action buttons
        print("Actions: [Like] [Comment] [Share] [Bookmark]")
        print("="*50)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Demo Plugin System
protocol FeedItemPlugin {
    var identifier: String { get }
    var priority: Int { get }
    func canHandle(_ post: Post) -> Bool
    func displayPost(_ post: Post, actions: PostActions)
}

struct PostActions {
    let onLike: () -> Void
    let onBookmark: () -> Void
    let onShare: () -> Void
    let onComment: () -> Void
}

class FeedItemPluginManager {
    private var plugins: [FeedItemPlugin] = []
    
    func register(_ plugin: FeedItemPlugin) {
        plugins.append(plugin)
        plugins.sort { $0.priority > $1.priority }
    }
    
    func getPlugin(for post: Post) -> FeedItemPlugin? {
        return plugins.first { $0.canHandle(post) }
    }
    
    func displayPost(_ post: Post, actions: PostActions) {
        if let plugin = getPlugin(for: post) {
            plugin.displayPost(post, actions: actions)
        } else {
            // Default display
            let feedItem = FeedItemView(
                post: post,
                onLike: actions.onLike,
                onBookmark: actions.onBookmark,
                onShare: actions.onShare,
                onComment: actions.onComment
            )
            feedItem.display()
        }
    }
}

// MARK: - Demo Plugins
class PromotedPostPlugin: FeedItemPlugin {
    let identifier = "promoted_post"
    let priority = 100
    
    func canHandle(_ post: Post) -> Bool {
        return post.author.username.contains("sponsored") || 
               post.content.textContent?.contains("#ad") == true
    }
    
    func displayPost(_ post: Post, actions: PostActions) {
        print("\n" + "="*50)
        print("📢 PROMOTED POST")
        print("="*50)
        print("💰 This is a sponsored post")
        print()
        
        let feedItem = FeedItemView(
            post: post,
            onLike: actions.onLike,
            onBookmark: actions.onBookmark,
            onShare: actions.onShare,
            onComment: actions.onComment
        )
        feedItem.display()
    }
}

class VideoPostPlugin: FeedItemPlugin {
    let identifier = "video_post"
    let priority = 50
    
    func canHandle(_ post: Post) -> Bool {
        if case .video = post.content {
            return true
        }
        return false
    }
    
    func displayPost(_ post: Post, actions: PostActions) {
        print("\n" + "="*50)
        print("🎬 VIDEO POST")
        print("="*50)
        print("▶️  [PLAY VIDEO]")
        print("⏱️  Duration: 2:34")
        print()
        
        let feedItem = FeedItemView(
            post: post,
            onLike: actions.onLike,
            onBookmark: actions.onBookmark,
            onShare: actions.onShare,
            onComment: actions.onComment
        )
        feedItem.display()
    }
}

class LivePostPlugin: FeedItemPlugin {
    let identifier = "live_post"
    let priority = 75
    
    func canHandle(_ post: Post) -> Bool {
        return post.content.textContent?.contains("#live") == true ||
               post.content.textContent?.contains("🔴 LIVE") == true
    }
    
    func displayPost(_ post: Post, actions: PostActions) {
        print("\n" + "="*50)
        print("🔴 LIVE POST")
        print("="*50)
        print("📺 LIVE NOW - \(Int.random(in: 100...5000)) watching")
        print("⏰ Started 15 minutes ago")
        print()
        
        let feedItem = FeedItemView(
            post: post,
            onLike: actions.onLike,
            onBookmark: actions.onBookmark,
            onShare: actions.onShare,
            onComment: actions.onComment
        )
        feedItem.display()
    }
}

// MARK: - Demo Runner
class SocialMediaFeedDemo {
    private let viewModel = FeedViewModel()
    private let pluginManager = FeedItemPluginManager()
    
    init() {
        setupPlugins()
    }
    
    private func setupPlugins() {
        pluginManager.register(PromotedPostPlugin())
        pluginManager.register(VideoPostPlugin())
        pluginManager.register(LivePostPlugin())
    }
    
    func run() {
        print("🚀 Social Media Feed Demo - MVVM with Combine")
        print("="*60)
        print()
        
        // Wait for initial posts to load
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.displayFeed()
        }
        
        // Keep the demo running
        RunLoop.main.run()
    }
    
    private func displayFeed() {
        print("📱 Loading Social Media Feed...")
        print()
        
        for post in viewModel.posts {
            let actions = PostActions(
                onLike: { self.viewModel.likePost(post) },
                onBookmark: { self.viewModel.bookmarkPost(post) },
                onShare: { print("📤 Shared post \(post.id)") },
                onComment: { print("💬 Commented on post \(post.id)") }
            )
            
            pluginManager.displayPost(post, actions: actions)
            
            // Simulate user interaction
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        print("\n" + "="*60)
        print("✅ Demo completed! This demonstrates:")
        print("   • MVVM Architecture with Combine")
        print("   • Plugin System for different post types")
        print("   • Reactive data binding")
        print("   • Modular UI components")
        print("   • Clean separation of concerns")
        print("="*60)
        
        exit(0)
    }
}

// MARK: - String Extension for demo formatting
extension String {
    static func *(string: String, count: Int) -> String {
        return String(repeating: string, count: count)
    }
}

// MARK: - Run Demo
let demo = SocialMediaFeedDemo()
demo.run() 