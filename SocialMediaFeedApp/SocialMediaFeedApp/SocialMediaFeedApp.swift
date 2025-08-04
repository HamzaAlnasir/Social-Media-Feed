import SwiftUI
import Combine
import UserNotifications

@main
struct SocialMediaFeedApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var notificationManager = NotificationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(notificationManager)
                .onAppear {
                    notificationManager.requestPermission()
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        if authManager.isAuthenticated {
            MainTabView()
        } else {
            AuthenticationView()
        }
    }
}

// MARK: - Authentication
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Simulate checking for existing session
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isAuthenticated = false
        }
    }
    
    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if email.contains("@") && password.count >= 6 {
                self.currentUser = User(
                    id: UUID(),
                    username: email.components(separatedBy: "@").first ?? "user",
                    displayName: "Demo User",
                    avatarURL: "person.circle.fill",
                    isVerified: true,
                    followersCount: 1234,
                    followingCount: 567
                )
                self.isAuthenticated = true
            } else {
                self.errorMessage = "Invalid credentials"
            }
            self.isLoading = false
        }
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
    }
}

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 20) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Social Media Feed")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Sign in to continue")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Created by Hamza Alnasir™")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 10)
                }
                
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Button(action: {
                    authManager.signIn(email: email, password: password)
                }) {
                    HStack {
                        if authManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Sign In")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(authManager.isLoading)
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Feed")
                }
                .tag(0)
            
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(1)
            
            CreatePostView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Create")
                }
                .tag(2)
            
            NotificationsView()
                .tabItem {
                    Image(systemName: "bell.fill")
                    Text("Notifications")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
    }
}

// MARK: - Real-time Feed Updates
class RealTimeFeedManager: ObservableObject {
    @Published var posts: [Post] = []
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        startRealTimeUpdates()
    }
    
    private func startRealTimeUpdates() {
        // Simulate real-time updates every 5-15 seconds
        timer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 5...15), repeats: true) { _ in
            self.addNewPost()
        }
    }
    
    private func addNewPost() {
        let newPost = Post(
            id: UUID(),
            author: User(
                id: UUID(),
                username: "user\(Int.random(in: 1...100))",
                displayName: "User \(Int.random(in: 1...100))",
                avatarURL: "person.circle.fill",
                isVerified: Bool.random(),
                followersCount: Int.random(in: 10...10000),
                followingCount: Int.random(in: 5...500)
            ),
            content: PostContent.text("Just posted something new! #socialmedia #swiftui"),
            timestamp: Date(),
            likes: Int.random(in: 0...500),
            comments: Int.random(in: 0...100),
            shares: Int.random(in: 0...50),
            isLiked: false,
            isBookmarked: false
        )
        
        DispatchQueue.main.async {
            self.posts.insert(newPost, at: 0)
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

// MARK: - Search Functionality
class SearchManager: ObservableObject {
    @Published var searchResults: [Post] = []
    @Published var userResults: [User] = []
    @Published var isSearching = false
    @Published var searchText = ""
    
    private var searchCancellable: AnyCancellable?
    private let allPosts: [Post]
    private let allUsers: [User]
    
    init(posts: [Post], users: [User]) {
        self.allPosts = posts
        self.allUsers = users
        
        // Debounced search
        searchCancellable = $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                self?.performSearch(searchText)
            }
    }
    
    private func performSearch(_ query: String) {
        guard !query.isEmpty else {
            searchResults = []
            userResults = []
            return
        }
        
        isSearching = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let lowercasedQuery = query.lowercased()
            
            // Search posts
            self.searchResults = self.allPosts.filter { post in
                post.content.textContent?.lowercased().contains(lowercasedQuery) == true ||
                post.author.username.lowercased().contains(lowercasedQuery) ||
                post.author.displayName.lowercased().contains(lowercasedQuery)
            }
            
            // Search users
            self.userResults = self.allUsers.filter { user in
                user.username.lowercased().contains(lowercasedQuery) ||
                user.displayName.lowercased().contains(lowercasedQuery)
            }
            
            self.isSearching = false
        }
    }
}

struct SearchView: View {
    @StateObject private var searchManager: SearchManager
    @State private var selectedFilter = 0
    
    init() {
        let mockPosts = FeedViewModel().generateMockPosts()
        let mockUsers = mockPosts.map { $0.author }
        _searchManager = StateObject(wrappedValue: SearchManager(posts: mockPosts, users: mockUsers))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search posts, users, or hashtags...", text: $searchManager.searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    Text("All").tag(0)
                    Text("Posts").tag(1)
                    Text("Users").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                if searchManager.isSearching {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchManager.searchText.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Search for posts, users, or hashtags")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        if selectedFilter == 0 || selectedFilter == 1 {
                            Section("Posts") {
                                ForEach(searchManager.searchResults) { post in
                                    FeedItemView(post: post, onLike: {}, onBookmark: {}, onShare: {}, onComment: {})
                                        .listRowInsets(EdgeInsets())
                                }
                            }
                        }
                        
                        if selectedFilter == 0 || selectedFilter == 2 {
                            Section("Users") {
                                ForEach(searchManager.userResults) { user in
                                    UserRowView(user: user)
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Search - Hamza Alnasir™")
        }
    }
}

struct UserRowView: View {
    let user: User
    
    var body: some View {
        HStack {
            Image(systemName: user.avatarURL)
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                HStack {
                    Text(user.displayName)
                        .fontWeight(.semibold)
                    
                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Follow") {
                // Follow action
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Content Creation
class PostCreationManager: ObservableObject {
    @Published var postText = ""
    @Published var selectedImage: UIImage?
    @Published var isCreating = false
    @Published var showImagePicker = false
    
    func createPost() {
        guard !postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isCreating = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Post creation logic would go here
            self.postText = ""
            self.selectedImage = nil
            self.isCreating = false
        }
    }
}

struct CreatePostView: View {
    @StateObject private var postManager = PostCreationManager()
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationView {
            VStack {
                // Post composer
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: authManager.currentUser?.avatarURL ?? "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(authManager.currentUser?.displayName ?? "User")
                                .fontWeight(.semibold)
                            Text("What's happening?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    TextEditor(text: $postManager.postText)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    if let image = postManager.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                    }
                    
                    HStack {
                        Button(action: {
                            postManager.showImagePicker = true
                        }) {
                            Image(systemName: "photo")
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            postManager.createPost()
                        }) {
                            Text("Post")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(postManager.postText.isEmpty ? Color.gray : Color.blue)
                                .cornerRadius(20)
                        }
                        .disabled(postManager.postText.isEmpty || postManager.isCreating)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Create Post - Hamza Alnasir™")
            .sheet(isPresented: $postManager.showImagePicker) {
                ImagePicker(selectedImage: $postManager.selectedImage)
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Push Notifications
class NotificationManager: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    @Published var unreadCount = 0
    
    init() {
        requestPermission()
        generateMockNotifications()
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("Notification permission granted")
                }
            }
        }
    }
    
    private func generateMockNotifications() {
        let mockNotifications = [
            NotificationItem(id: UUID(), type: .like, message: "John Doe liked your post", timestamp: Date().addingTimeInterval(-300), isRead: false),
            NotificationItem(id: UUID(), type: .comment, message: "Jane Smith commented on your post", timestamp: Date().addingTimeInterval(-600), isRead: false),
            NotificationItem(id: UUID(), type: .follow, message: "New follower: @techuser", timestamp: Date().addingTimeInterval(-1800), isRead: true),
            NotificationItem(id: UUID(), type: .mention, message: "You were mentioned by @developer", timestamp: Date().addingTimeInterval(-3600), isRead: true)
        ]
        
        notifications = mockNotifications
        unreadCount = mockNotifications.filter { !$0.isRead }.count
    }
    
    func markAsRead(_ notification: NotificationItem) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
            unreadCount = notifications.filter { !$0.isRead }.count
        }
    }
}

struct NotificationItem: Identifiable {
    let id: UUID
    let type: NotificationType
    let message: String
    let timestamp: Date
    var isRead: Bool
}

enum NotificationType {
    case like, comment, follow, mention
    
    var icon: String {
        switch self {
        case .like: return "heart.fill"
        case .comment: return "message.fill"
        case .follow: return "person.badge.plus"
        case .mention: return "at"
        }
    }
    
    var color: Color {
        switch self {
        case .like: return .red
        case .comment: return .blue
        case .follow: return .green
        case .mention: return .orange
        }
    }
}

struct NotificationsView: View {
    @StateObject private var notificationManager = NotificationManager()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(notificationManager.notifications) { notification in
                    NotificationRowView(notification: notification) {
                        notificationManager.markAsRead(notification)
                    }
                }
            }
            .navigationTitle("Notifications - Hamza Alnasir™")
            .navigationBarItems(trailing: 
                Text("\(notificationManager.unreadCount)")
                    .font(.caption)
                    .padding(6)
                    .background(notificationManager.unreadCount > 0 ? Color.red : Color.clear)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            )
        }
    }
}

struct NotificationRowView: View {
    let notification: NotificationItem
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notification.type.icon)
                .foregroundColor(notification.type.color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.message)
                    .font(.subheadline)
                    .fontWeight(notification.isRead ? .regular : .semibold)
                
                Text(notification.timestamp.timeAgoDisplay())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - User Profile
struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 15) {
                        Image(systemName: authManager.currentUser?.avatarURL ?? "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 5) {
                            Text(authManager.currentUser?.displayName ?? "User")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if authManager.currentUser?.isVerified == true {
                                HStack {
                                    Text("@\(authManager.currentUser?.username ?? "user")")
                                        .foregroundColor(.secondary)
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                }
                            } else {
                                Text("@\(authManager.currentUser?.username ?? "user")")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Stats
                        HStack(spacing: 30) {
                            VStack {
                                Text("\(authManager.currentUser?.followersCount ?? 0)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Followers")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(authManager.currentUser?.followingCount ?? 0)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Following")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    
                    // Profile Tabs
                    Picker("Content", selection: $selectedTab) {
                        Text("Posts").tag(0)
                        Text("Likes").tag(1)
                        Text("Bookmarks").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Content based on selected tab
                    switch selectedTab {
                    case 0:
                        ProfilePostsView()
                    case 1:
                        ProfileLikesView()
                    case 2:
                        ProfileBookmarksView()
                    default:
                        EmptyView()
                    }
                }
            }
            .navigationTitle("Profile - Hamza Alnasir™")
            .navigationBarItems(trailing: 
                Button("Sign Out") {
                    authManager.signOut()
                }
                .foregroundColor(.red)
            )
        }
    }
}

struct ProfilePostsView: View {
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(FeedViewModel().generateMockPosts().prefix(5)) { post in
                FeedItemView(post: post, onLike: {}, onBookmark: {}, onShare: {}, onComment: {})
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
        }
    }
}

struct ProfileLikesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No liked posts yet")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ProfileBookmarksView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bookmark")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No bookmarked posts yet")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Enhanced Feed View with Real-time Updates
struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @StateObject private var realTimeManager = RealTimeFeedManager()
    @EnvironmentObject var notificationManager: NotificationManager
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(realTimeManager.posts.isEmpty ? viewModel.posts : realTimeManager.posts) { post in
                            FeedItemView(
                                post: post,
                                onLike: {
                                    viewModel.toggleLike(for: post)
                                    // Simulate notification
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        notificationManager.unreadCount += 1
                                    }
                                },
                                onBookmark: { viewModel.toggleBookmark(for: post) },
                                onShare: { viewModel.sharePost(post) },
                                onComment: { viewModel.commentOnPost(post) }
                            )
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                    }
                }
                .refreshable {
                    await viewModel.refreshFeed()
                }
                
                if viewModel.feedState == .loading {
                    LoadingView()
                }
            }
            .navigationTitle("Feed - Hamza Alnasir™")
            .navigationBarItems(trailing: 
                HStack {
                    Button(action: {
                        // Simulate new notification
                        notificationManager.unreadCount += 1
                    }) {
                        Image(systemName: "bell")
                            .overlay(
                                Text("\(notificationManager.unreadCount)")
                                    .font(.caption2)
                                    .padding(4)
                                    .background(notificationManager.unreadCount > 0 ? Color.red : Color.clear)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -8)
                            )
                    }
                }
            )
        }
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
    
    init(id: UUID = UUID(), author: User, content: PostContent, timestamp: Date = Date(), likes: Int, comments: Int, shares: Int, isLiked: Bool = false, isBookmarked: Bool = false) {
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
    let avatarURL: String
    let isVerified: Bool
    let followersCount: Int
    let followingCount: Int
}

enum PostContent: Codable, Equatable {
    case text(String)
    case image(String)
    case video(String)
    case link(String, String)
    
    var textContent: String? {
        switch self {
        case .text(let text): return text
        case .image(let text): return text
        case .video(let text): return text
        case .link(let text, _): return text
        }
    }
}

enum FeedState: Equatable {
    case idle, loading, loaded([Post]), error(String), refreshing
    
    static func == (lhs: FeedState, rhs: FeedState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.refreshing, .refreshing):
            return true
        case (.loaded(let lhsPosts), .loaded(let rhsPosts)):
            return lhsPosts == rhsPosts
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

enum NetworkState {
    case online, offline, connecting
}

// MARK: - ViewModel
@MainActor
class FeedViewModel: ObservableObject {
    @Published var feedState: FeedState = .idle
    @Published var networkState: NetworkState = .online
    @Published var posts: [Post] = []
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    
    private var currentPage = 0
    private var hasMorePages = true
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadInitialPosts()
    }
    
    func loadInitialPosts() {
        guard case .idle = feedState else { return }
        feedState = .loading
        currentPage = 0
        hasMorePages = true
        loadPosts(page: currentPage)
    }
    
    private func loadPosts(page: Int) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let newPosts = self.generateMockPosts()
            
            if page == 0 {
                self.posts = newPosts
                self.feedState = .loaded(newPosts)
            } else {
                self.posts.append(contentsOf: newPosts)
                self.feedState = .loaded(self.posts)
            }
            
            self.currentPage = page
            self.hasMorePages = page < 3 // Limit to 3 pages for demo
        }
    }
    
    func refreshFeed() async {
        feedState = .refreshing
        currentPage = 0
        hasMorePages = true
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let newPosts = generateMockPosts()
        posts = newPosts
        feedState = .loaded(newPosts)
    }
    
    func loadMorePosts() {
        guard hasMorePages && !isLoadingMore else { return }
        isLoadingMore = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let newPosts = self.generateMockPosts()
            self.posts.append(contentsOf: newPosts)
            self.currentPage += 1
            self.hasMorePages = self.currentPage < 3
            self.isLoadingMore = false
        }
    }
    
    func toggleLike(for post: Post) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].isLiked.toggle()
        }
    }
    
    func toggleBookmark(for post: Post) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].isBookmarked.toggle()
        }
    }
    
    func sharePost(_ post: Post) {
        // Share functionality
        print("Sharing post: \(post.id)")
    }
    
    func commentOnPost(_ post: Post) {
        // Comment functionality
        print("Commenting on post: \(post.id)")
    }
    
    func generateMockPosts() -> [Post] {
        let users = [
            User(id: UUID(), username: "john_doe", displayName: "John Doe", avatarURL: "person.circle.fill", isVerified: true, followersCount: 1234, followingCount: 567),
            User(id: UUID(), username: "jane_smith", displayName: "Jane Smith", avatarURL: "person.circle.fill", isVerified: false, followersCount: 890, followingCount: 234),
            User(id: UUID(), username: "tech_guru", displayName: "Tech Guru", avatarURL: "person.circle.fill", isVerified: true, followersCount: 5678, followingCount: 123),
            User(id: UUID(), username: "design_master", displayName: "Design Master", avatarURL: "person.circle.fill", isVerified: false, followersCount: 2345, followingCount: 456)
        ]
        
        let contents = [
            PostContent.text("Just finished building this amazing social media app with SwiftUI and MVVM architecture! 🚀 #iOS #SwiftUI #MVVM"),
            PostContent.text("The Combine framework makes reactive programming so elegant. Love how it handles data binding seamlessly! 💻"),
            PostContent.text("Working on real-time updates and push notifications. The user experience is going to be incredible! 📱"),
            PostContent.text("Authentication, search, and content creation - this app has it all! Building the future of social media. 🌟"),
            PostContent.text("The plugin system allows for such flexible content types. Promoted posts, videos, live streams - endless possibilities! 🎯"),
            PostContent.link("Check out this amazing article about iOS development", "https://example.com"),
            PostContent.text("User profiles with followers, following, and personalized content. The social aspect is coming together beautifully! 👥"),
            PostContent.text("Push notifications for likes, comments, and mentions. Users will never miss important interactions! 🔔")
        ]
        
        return (0..<8).map { index in
            Post(
                author: users[index % users.count],
                content: contents[index % contents.count],
                timestamp: Date().addingTimeInterval(-Double(index * 3600)),
                likes: Int.random(in: 10...500),
                comments: Int.random(in: 2...100),
                shares: Int.random(in: 1...50),
                isLiked: Bool.random(),
                isBookmarked: Bool.random()
            )
        }
    }
}

// MARK: - Views
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
            PostHeaderView(author: post.author, timestamp: post.timestamp)
            PostContentView(content: post.content, isExpanded: $isExpanded, contentHeight: $contentHeight)
            PostActionsView(post: post, onLike: onLike, onBookmark: onBookmark, onShare: onShare, onComment: onComment)
            PostStatsView(post: post)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct PostHeaderView: View {
    let author: User
    let timestamp: Date
    
    var body: some View {
        HStack {
            Image(systemName: author.avatarURL)
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(author.displayName)
                        .fontWeight(.semibold)
                    
                    if author.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                
                Text("@\(author.username) • \(timestamp.timeAgoDisplay())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct PostContentView: View {
    let content: PostContent
    @Binding var isExpanded: Bool
    @Binding var contentHeight: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch content {
            case .text(let text):
                Text(text)
                    .lineLimit(isExpanded ? nil : 3)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }
                
                if text.count > 100 && !isExpanded {
                    Button("Show more") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded = true
                        }
                    }
                    .foregroundColor(.blue)
                    .font(.caption)
                }
                
            case .image(let text):
                VStack(alignment: .leading, spacing: 8) {
                    Text(text)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                }
                
            case .video(let text):
                VStack(alignment: .leading, spacing: 8) {
                    Text(text)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "play.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                        )
                }
                
            case .link(let text, let url):
                VStack(alignment: .leading, spacing: 8) {
                    Text(text)
                    
                    Link(destination: URL(string: url) ?? URL(string: "https://example.com")!) {
                        HStack {
                            Image(systemName: "link")
                            Text(url)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}

struct PostActionsView: View {
    let post: Post
    let onLike: () -> Void
    let onBookmark: () -> Void
    let onShare: () -> Void
    let onComment: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: onLike) {
                HStack(spacing: 4) {
                    Image(systemName: post.isLiked ? "heart.fill" : "heart")
                        .foregroundColor(post.isLiked ? .red : .secondary)
                    Text("\(post.likes)")
                        .font(.caption)
                }
            }
            
            Button(action: onComment) {
                HStack(spacing: 4) {
                    Image(systemName: "message")
                        .foregroundColor(.secondary)
                    Text("\(post.comments)")
                        .font(.caption)
                }
            }
            
            Button(action: onShare) {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.secondary)
                    Text("\(post.shares)")
                        .font(.caption)
                }
            }
            
            Spacer()
            
            Button(action: onBookmark) {
                Image(systemName: post.isBookmarked ? "bookmark.fill" : "bookmark")
                    .foregroundColor(post.isBookmarked ? .blue : .secondary)
            }
        }
        .foregroundColor(.secondary)
    }
}

struct PostStatsView: View {
    let post: Post
    
    var body: some View {
        HStack {
            Text("\(post.likes) likes • \(post.comments) comments • \(post.shares) shares")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top)
        }
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