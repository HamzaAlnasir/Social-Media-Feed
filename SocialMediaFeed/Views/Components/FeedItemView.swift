import SwiftUI

// MARK: - Feed Item View
struct FeedItemView: View {
    let post: Post
    let onLike: () -> Void
    let onBookmark: () -> Void
    let onShare: () -> Void
    let onComment: () -> Void
    
    @State private var isExpanded = false
    @State private var contentHeight: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            PostHeaderView(author: post.author, timestamp: post.timestamp)
            
            // Content
            PostContentView(
                content: post.content,
                isExpanded: $isExpanded,
                contentHeight: $contentHeight
            )
            
            // Actions
            PostActionsView(
                post: post,
                onLike: onLike,
                onBookmark: onBookmark,
                onShare: onShare,
                onComment: onComment
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

// MARK: - Post Header View
struct PostHeaderView: View {
    let author: User
    let timestamp: Date
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AsyncImage(url: URL(string: author.avatarURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text(String(author.displayName.prefix(1)))
                            .font(.headline)
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
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

// MARK: - Post Content View
struct PostContentView: View {
    let content: PostContent
    @Binding var isExpanded: Bool
    @Binding var contentHeight: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Text Content
            if let textContent = content.textContent {
                Text(textContent)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(isExpanded ? nil : 3)
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }
            
            // Media Content
            switch content {
            case .image(let url, _):
                AsyncImage(url: URL(string: url)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(8)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(16/9, contentMode: .fit)
                        .cornerRadius(8)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        )
                }
                
            case .video(let url, _, let thumbnail):
                VideoPreviewView(videoURL: url, thumbnailURL: thumbnail)
                
            case .link(_, let title, let description, let thumbnail):
                LinkPreviewView(
                    title: title,
                    description: description,
                    thumbnailURL: thumbnail
                )
                
            default:
                EmptyView()
            }
            
            // Expand/Collapse Button
            if let textContent = content.textContent, textContent.count > 150 {
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Text(isExpanded ? "Show less" : "Show more")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Video Preview View
struct VideoPreviewView: View {
    let videoURL: String
    let thumbnailURL: String?
    
    var body: some View {
        ZStack {
            AsyncImage(url: URL(string: thumbnailURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .aspectRatio(16/9, contentMode: .fit)
            .cornerRadius(8)
            
            // Play Button
            Circle()
                .fill(Color.black.opacity(0.7))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                )
        }
    }
}

// MARK: - Link Preview View
struct LinkPreviewView: View {
    let title: String
    let description: String?
    let thumbnailURL: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if let thumbnailURL = thumbnailURL {
                    AsyncImage(url: URL(string: thumbnailURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(6)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    if let description = description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Post Actions View
struct PostActionsView: View {
    let post: Post
    let onLike: () -> Void
    let onBookmark: () -> Void
    let onShare: () -> Void
    let onComment: () -> Void
    
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
            Button(action: onComment) {
                HStack(spacing: 4) {
                    Image(systemName: "message")
                        .foregroundColor(.gray)
                    Text("\(post.comments)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Share Button
            Button(action: onShare) {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.gray)
                    Text("\(post.shares)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
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

// MARK: - Post Stats View
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

// MARK: - Date Extension
extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - Preview
struct FeedItemView_Previews: PreviewProvider {
    static var previews: some View {
        let mockPost = Post(
            author: User(username: "john_doe", displayName: "John Doe", isVerified: true),
            content: .text("This is a sample post with some text content that might be longer than expected and need to be truncated or expanded based on user interaction."),
            likes: 42,
            comments: 12,
            shares: 5
        )
        
        FeedItemView(
            post: mockPost,
            onLike: {},
            onBookmark: {},
            onShare: {},
            onComment: {}
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
} 