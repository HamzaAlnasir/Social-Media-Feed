import Foundation
import SwiftUI

// MARK: - Post Model
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

// MARK: - User Model
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

// MARK: - Post Content Types
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
    
    var hasMedia: Bool {
        switch self {
        case .text:
            return false
        case .image, .video, .link:
            return true
        }
    }
}

// MARK: - Feed State
enum FeedState: Equatable {
    case idle
    case loading
    case loaded([Post])
    case error(String)
    case refreshing
}

// MARK: - Network State
enum NetworkState: Equatable {
    case online
    case offline
    case connecting
} 