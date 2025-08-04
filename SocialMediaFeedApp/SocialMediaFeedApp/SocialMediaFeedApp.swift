import SwiftUI

@main
struct SocialMediaFeedApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        FeedView()
    }
}

// MARK: - Models
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
        self.comments = comments
        self.shares = shares
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

// MARK: - ViewModel
@MainActor
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
        }
    }
    
    func bookmarkPost(_ post: Post) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].isBookmarked.toggle()
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

// MARK: - Views
struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    
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
                            FeedItemView(post: post, viewModel: viewModel)
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
                        if !viewModel.posts.isEmpty {
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
                    viewModel.loadInitialPosts()
                }
                
                // Loading overlay
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    LoadingView()
                }
            }
            .navigationTitle("Social Media Feed")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct FeedItemView: View {
    let post: Post
    let viewModel: FeedViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            PostHeaderView(author: post.author, timestamp: post.timestamp)
            
            // Content
            PostContentView(content: post.content)
            
            // Actions
            PostActionsView(
                post: post,
                onLike: { viewModel.likePost(post) },
                onBookmark: { viewModel.bookmarkPost(post) }
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

struct PostHeaderView: View {
    let author: User
    let timestamp: Date
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(author.displayName.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.gray)
                )
            
            // User Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(author.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if author.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                
                Text("@\(author.username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Timestamp
            Text(timestamp.timeAgoDisplay())
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct PostContentView: View {
    let content: PostContent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Text Content
            if let textContent = content.textContent {
                Text(textContent)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            // Media Content
            switch content {
            case .image:
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
                
            case .video:
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "play.fill")
                            .foregroundColor(.white)
                            .font(.title)
                    )
                
            case .link:
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(.blue)
                    Text("Link Preview")
                        .foregroundColor(.blue)
                    Spacer()
                }
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
            default:
                EmptyView()
            }
        }
    }
}

struct PostActionsView: View {
    let post: Post
    let onLike: () -> Void
    let onBookmark: () -> Void
    
    var body: some View {
        HStack(spacing: 24) {
            // Like Button
            Button(action: onLike) {
                HStack(spacing: 4) {
                    Image(systemName: post.isLiked ? "heart.fill" : "heart")
                        .foregroundColor(post.isLiked ? .red : .gray)
                    Text("\(post.likes)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Comment Button
            HStack(spacing: 4) {
                Image(systemName: "message")
                    .foregroundColor(.gray)
                Text("\(post.comments)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Share Button
            HStack(spacing: 4) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.gray)
                Text("\(post.shares)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Bookmark Button
            Button(action: onBookmark) {
                Image(systemName: post.isBookmarked ? "bookmark.fill" : "bookmark")
                    .foregroundColor(post.isBookmarked ? .blue : .gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct PostStatsView: View {
    let post: Post
    
    var body: some View {
        HStack(spacing: 16) {
            if post.likes > 0 {
                Text("\(post.likes) likes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if post.comments > 0 {
                Text("\(post.comments) comments")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if post.shares > 0 {
                Text("\(post.shares) shares")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

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

// MARK: - Extensions
extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
} 