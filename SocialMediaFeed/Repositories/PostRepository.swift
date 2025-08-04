import Foundation
import Combine

// MARK: - Post Repository Protocol
protocol PostRepositoryProtocol {
    func fetchPosts(page: Int, limit: Int) -> AnyPublisher<[Post], Error>
    func refreshPosts() -> AnyPublisher<[Post], Error>
    func likePost(_ post: Post) -> AnyPublisher<Post, Error>
    func unlikePost(_ post: Post) -> AnyPublisher<Post, Error>
    func bookmarkPost(_ post: Post) -> AnyPublisher<Post, Error>
    func unbookmarkPost(_ post: Post) -> AnyPublisher<Post, Error>
    func savePostsToCache(_ posts: [Post])
    func loadPostsFromCache() -> [Post]
    func clearCache()
}

// MARK: - Post Repository Implementation
class PostRepository: PostRepositoryProtocol {
    private let networkService: NetworkServiceProtocol
    private let cacheService: CacheServiceProtocol
    private let cancellables = Set<AnyCancellable>()
    
    init(networkService: NetworkServiceProtocol = NetworkService(), 
         cacheService: CacheServiceProtocol = CacheService()) {
        self.networkService = networkService
        self.cacheService = cacheService
    }
    
    func fetchPosts(page: Int, limit: Int) -> AnyPublisher<[Post], Error> {
        let endpoint = APIEndpoint.posts(page: page, limit: limit)
        
        return networkService.request(endpoint: endpoint)
            .catch { [weak self] error -> AnyPublisher<[Post], Error> in
                // Fallback to cache if network fails
                if let cachedPosts = self?.loadPostsFromCache(), !cachedPosts.isEmpty {
                    return Just(cachedPosts)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                return Fail(error: error).eraseToAnyPublisher()
            }
            .handleEvents(receiveOutput: { [weak self] posts in
                self?.savePostsToCache(posts)
            })
            .eraseToAnyPublisher()
    }
    
    func refreshPosts() -> AnyPublisher<[Post], Error> {
        return fetchPosts(page: 0, limit: 20)
    }
    
    func likePost(_ post: Post) -> AnyPublisher<Post, Error> {
        let endpoint = APIEndpoint.likePost(post.id)
        
        return networkService.request(endpoint: endpoint)
            .map { _ in
                var updatedPost = post
                updatedPost.isLiked = true
                return updatedPost
            }
            .eraseToAnyPublisher()
    }
    
    func unlikePost(_ post: Post) -> AnyPublisher<Post, Error> {
        let endpoint = APIEndpoint.unlikePost(post.id)
        
        return networkService.request(endpoint: endpoint)
            .map { _ in
                var updatedPost = post
                updatedPost.isLiked = false
                return updatedPost
            }
            .eraseToAnyPublisher()
    }
    
    func bookmarkPost(_ post: Post) -> AnyPublisher<Post, Error> {
        let endpoint = APIEndpoint.bookmarkPost(post.id)
        
        return networkService.request(endpoint: endpoint)
            .map { _ in
                var updatedPost = post
                updatedPost.isBookmarked = true
                return updatedPost
            }
            .eraseToAnyPublisher()
    }
    
    func unbookmarkPost(_ post: Post) -> AnyPublisher<Post, Error> {
        let endpoint = APIEndpoint.unbookmarkPost(post.id)
        
        return networkService.request(endpoint: endpoint)
            .map { _ in
                var updatedPost = post
                updatedPost.isBookmarked = false
                return updatedPost
            }
            .eraseToAnyPublisher()
    }
    
    func savePostsToCache(_ posts: [Post]) {
        cacheService.save(posts, forKey: "cached_posts")
    }
    
    func loadPostsFromCache() -> [Post] {
        return cacheService.load([Post].self, forKey: "cached_posts") ?? []
    }
    
    func clearCache() {
        cacheService.remove(forKey: "cached_posts")
    }
}

// MARK: - Mock Post Repository for Testing
class MockPostRepository: PostRepositoryProtocol {
    private var posts: [Post] = []
    private let delay: TimeInterval
    
    init(delay: TimeInterval = 1.0) {
        self.delay = delay
        generateMockPosts()
    }
    
    func fetchPosts(page: Int, limit: Int) -> AnyPublisher<[Post], Error> {
        let startIndex = page * limit
        let endIndex = min(startIndex + limit, posts.count)
        let pagePosts = Array(posts[startIndex..<endIndex])
        
        return Just(pagePosts)
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func refreshPosts() -> AnyPublisher<[Post], Error> {
        return fetchPosts(page: 0, limit: 20)
    }
    
    func likePost(_ post: Post) -> AnyPublisher<Post, Error> {
        var updatedPost = post
        updatedPost.isLiked = true
        return Just(updatedPost)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func unlikePost(_ post: Post) -> AnyPublisher<Post, Error> {
        var updatedPost = post
        updatedPost.isLiked = false
        return Just(updatedPost)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func bookmarkPost(_ post: Post) -> AnyPublisher<Post, Error> {
        var updatedPost = post
        updatedPost.isBookmarked = true
        return Just(updatedPost)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func unbookmarkPost(_ post: Post) -> AnyPublisher<Post, Error> {
        var updatedPost = post
        updatedPost.isBookmarked = false
        return Just(updatedPost)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func savePostsToCache(_ posts: [Post]) {
        // Mock implementation
    }
    
    func loadPostsFromCache() -> [Post] {
        return posts
    }
    
    func clearCache() {
        posts.removeAll()
    }
    
    private func generateMockPosts() {
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
        
        for i in 0..<50 {
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
    }
} 