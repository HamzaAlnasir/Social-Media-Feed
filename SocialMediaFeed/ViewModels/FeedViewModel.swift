import Foundation
import Combine
import SwiftUI

// MARK: - Feed ViewModel
@MainActor
class FeedViewModel: ObservableObject {
    // MARK: - Published Properties (View Binding)
    @Published var feedState: FeedState = .idle
    @Published var networkState: NetworkState = .online
    @Published var posts: [Post] = []
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let repository: PostRepositoryProtocol
    private let networkMonitor: NetworkMonitorProtocol
    private var cancellables = Set<AnyCancellable>()
    private var currentPage = 0
    private let pageSize = 20
    private var hasMorePages = true
    
    // MARK: - Initialization
    init(repository: PostRepositoryProtocol = MockPostRepository(), 
         networkMonitor: NetworkMonitorProtocol = NetworkMonitor()) {
        self.repository = repository
        self.networkMonitor = networkMonitor
        
        setupBindings()
        setupNetworkMonitoring()
    }
    
    // MARK: - Public Methods
    func loadInitialPosts() {
        guard case .idle = feedState else { return }
        
        feedState = .loading
        currentPage = 0
        hasMorePages = true
        
        loadPosts(page: currentPage)
    }
    
    func refreshPosts() {
        feedState = .refreshing
        currentPage = 0
        hasMorePages = true
        
        loadPosts(page: currentPage)
    }
    
    func loadMorePosts() {
        guard !isLoadingMore && hasMorePages && networkState == .online else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        loadPosts(page: currentPage)
    }
    
    func likePost(_ post: Post) {
        let publisher = post.isLiked ? 
            repository.unlikePost(post) : 
            repository.likePost(post)
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        self.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] updatedPost in
                    self?.updatePost(updatedPost)
                }
            )
            .store(in: &cancellables)
    }
    
    func bookmarkPost(_ post: Post) {
        let publisher = post.isBookmarked ? 
            repository.unbookmarkPost(post) : 
            repository.bookmarkPost(post)
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        self.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] updatedPost in
                    self?.updatePost(updatedPost)
                }
            )
            .store(in: &cancellables)
    }
    
    func retryLoading() {
        errorMessage = nil
        loadInitialPosts()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Monitor feed state changes
        $feedState
            .sink { [weak self] state in
                switch state {
                case .loaded(let posts):
                    self?.posts = posts
                case .error(let message):
                    self?.errorMessage = message
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.networkStatePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.networkState, on: self)
            .store(in: &cancellables)
    }
    
    private func loadPosts(page: Int) {
        repository.fetchPosts(page: page, limit: pageSize)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.handleLoadCompletion(completion, page: page)
                },
                receiveValue: { [weak self] newPosts in
                    self?.handleNewPosts(newPosts, page: page)
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleNewPosts(_ newPosts: [Post], page: Int) {
        if page == 0 {
            // Initial load or refresh
            posts = newPosts
            feedState = .loaded(newPosts)
        } else {
            // Load more
            posts.append(contentsOf: newPosts)
            feedState = .loaded(posts)
        }
        
        hasMorePages = newPosts.count == pageSize
        isLoadingMore = false
    }
    
    private func handleLoadCompletion(_ completion: Subscribers.Completion<Error>, page: Int) {
        isLoadingMore = false
        
        switch completion {
        case .finished:
            break
        case .failure(let error):
            if page == 0 {
                feedState = .error(error.localizedDescription)
            } else {
                errorMessage = error.localizedDescription
                currentPage -= 1 // Revert page increment
            }
        }
    }
    
    private func updatePost(_ updatedPost: Post) {
        if let index = posts.firstIndex(where: { $0.id == updatedPost.id }) {
            posts[index] = updatedPost
            feedState = .loaded(posts)
        }
    }
}

// MARK: - Network Monitor Protocol
protocol NetworkMonitorProtocol {
    var networkStatePublisher: AnyPublisher<NetworkState, Never> { get }
}

// MARK: - Network Monitor Implementation
class NetworkMonitor: NetworkMonitorProtocol {
    private let networkStateSubject = CurrentValueSubject<NetworkState, Never>(.online)
    
    var networkStatePublisher: AnyPublisher<NetworkState, Never> {
        networkStateSubject.eraseToAnyPublisher()
    }
    
    init() {
        // In a real app, you would use Network framework to monitor connectivity
        // For demo purposes, we'll simulate network state changes
        simulateNetworkChanges()
    }
    
    private func simulateNetworkChanges() {
        // Simulate network state changes every 30 seconds
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                let states: [NetworkState] = [.online, .offline, .connecting]
                let randomState = states.randomElement() ?? .online
                self?.networkStateSubject.send(randomState)
            }
            .store(in: &Set<AnyCancellable>())
    }
}

// MARK: - Feed ViewModel Extensions
extension FeedViewModel {
    var isRefreshing: Bool {
        if case .refreshing = feedState {
            return true
        }
        return false
    }
    
    var isLoading: Bool {
        if case .loading = feedState {
            return true
        }
        return false
    }
    
    var hasError: Bool {
        if case .error = feedState {
            return true
        }
        return false
    }
    
    var errorText: String? {
        if case .error(let message) = feedState {
            return message
        }
        return errorMessage
    }
    
    var canLoadMore: Bool {
        return hasMorePages && !isLoadingMore && networkState == .online
    }
    
    var emptyStateMessage: String {
        switch networkState {
        case .offline:
            return "You're offline. Check your connection and try again."
        case .connecting:
            return "Connecting to network..."
        case .online:
            return "No posts available. Pull to refresh."
        }
    }
} 