import SwiftUI

// MARK: - Custom Plugin Examples

// Example 1: Poll Post Plugin
class PollPostPlugin: FeedItemPlugin {
    let identifier = "poll_post"
    let priority = 80
    
    func canHandle(_ post: Post) -> Bool {
        return post.content.textContent?.contains("#poll") == true ||
               post.content.textContent?.contains("Vote:") == true
    }
    
    func createView(for post: Post, actions: PostActions) -> AnyView {
        return AnyView(
            PollPostView(post: post, actions: actions)
        )
    }
}

struct PollPostView: View {
    let post: Post
    let actions: PostActions
    @State private var selectedOption: Int?
    @State private var pollResults = [0.3, 0.4, 0.2, 0.1] // Mock results
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            PostHeaderView(author: post.author, timestamp: post.timestamp)
            
            // Poll Content
            VStack(alignment: .leading, spacing: 12) {
                if let textContent = post.content.textContent {
                    Text(textContent)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                
                // Poll Options
                VStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        PollOptionView(
                            option: "Option \(index + 1)",
                            percentage: pollResults[index],
                            isSelected: selectedOption == index,
                            onTap: {
                                selectedOption = index
                            }
                        )
                    }
                }
                
                Text("\(Int.random(in: 50...500)) votes")
                    .font(.caption)
                    .foregroundColor(.secondary)
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

struct PollOptionView: View {
    let option: String
    let percentage: Double
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(option)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(percentage * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Example 2: Event Post Plugin
class EventPostPlugin: FeedItemPlugin {
    let identifier = "event_post"
    let priority = 90
    
    func canHandle(_ post: Post) -> Bool {
        return post.content.textContent?.contains("#event") == true ||
               post.content.textContent?.contains("Join us") == true
    }
    
    func createView(for post: Post, actions: PostActions) -> AnyView {
        return AnyView(
            EventPostView(post: post, actions: actions)
        )
    }
}

struct EventPostView: View {
    let post: Post
    let actions: PostActions
    @State private var isAttending = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Event Badge
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.purple)
                    .font(.caption)
                Text("Event")
                    .font(.caption)
                    .foregroundColor(.purple)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Event Content
            VStack(alignment: .leading, spacing: 12) {
                // Header
                PostHeaderView(author: post.author, timestamp: post.timestamp)
                
                // Event Details
                VStack(alignment: .leading, spacing: 8) {
                    if let textContent = post.content.textContent {
                        Text(textContent)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    
                    // Event Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.secondary)
                            Text("Tomorrow at 7:00 PM")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(.secondary)
                            Text("San Francisco, CA")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "person.2")
                                .foregroundColor(.secondary)
                            Text("\(Int.random(in: 10...100)) attending")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                // Attend Button
                Button(action: {
                    isAttending.toggle()
                }) {
                    HStack {
                        Image(systemName: isAttending ? "checkmark" : "plus")
                        Text(isAttending ? "Attending" : "Attend")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isAttending ? Color.green : Color.blue)
                    .cornerRadius(8)
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
        .background(Color.purple.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
}

// Example 3: Product Post Plugin
class ProductPostPlugin: FeedItemPlugin {
    let identifier = "product_post"
    let priority = 85
    
    func canHandle(_ post: Post) -> Bool {
        return post.content.textContent?.contains("#product") == true ||
               post.content.textContent?.contains("$") == true
    }
    
    func createView(for post: Post, actions: PostActions) -> AnyView {
        return AnyView(
            ProductPostView(post: post, actions: actions)
        )
    }
}

struct ProductPostView: View {
    let post: Post
    let actions: PostActions
    @State private var isWishlisted = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Product Badge
            HStack {
                Image(systemName: "bag")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text("Product")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Product Content
            VStack(alignment: .leading, spacing: 12) {
                // Header
                PostHeaderView(author: post.author, timestamp: post.timestamp)
                
                // Product Details
                VStack(alignment: .leading, spacing: 8) {
                    if let textContent = post.content.textContent {
                        Text(textContent)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    
                    // Product Card
                    HStack(spacing: 12) {
                        // Product Image
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                        
                        // Product Info
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Amazing Product")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("$99.99")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            HStack {
                                ForEach(0..<5) { index in
                                    Image(systemName: index < 4 ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                }
                                Text("(\(Int.random(in: 10...500)))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Wishlist Button
                        Button(action: {
                            isWishlisted.toggle()
                        }) {
                            Image(systemName: isWishlisted ? "heart.fill" : "heart")
                                .foregroundColor(isWishlisted ? .red : .gray)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                // Buy Button
                Button(action: {
                    // Handle purchase
                }) {
                    Text("Buy Now")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .cornerRadius(8)
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
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Plugin Registration Example
extension FeedItemPluginManager {
    func registerDefaultPlugins() {
        register(PromotedPostPlugin())
        register(VideoPostPlugin())
        register(LivePostPlugin())
        register(PollPostPlugin())
        register(EventPostPlugin())
        register(ProductPostPlugin())
    }
}

// MARK: - Usage Example
struct PluginExampleView: View {
    @StateObject private var pluginManager = FeedItemPluginManager()
    
    var body: some View {
        VStack {
            Text("Plugin System Example")
                .font(.title)
                .padding()
            
            Text("This demonstrates how to create and register custom plugins for different post types.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Register All Plugins") {
                pluginManager.registerDefaultPlugins()
            }
            .padding()
        }
    }
} 