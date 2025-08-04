import XCTest
import Combine
@testable import SocialMediaFeed

class FeedViewModelTests: XCTestCase {
    var viewModel: FeedViewModel!
    var mockRepository: MockPostRepository!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockPostRepository(delay: 0.1)
        viewModel = FeedViewModel(repository: mockRepository)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.feedState, .idle)
        XCTAssertTrue(viewModel.posts.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.hasError)
        XCTAssertNil(viewModel.errorText)
    }
    
    // MARK: - Loading Tests
    
    func testLoadInitialPosts() {
        let expectation = XCTestExpectation(description: "Posts loaded")
        
        viewModel.$feedState
            .dropFirst() // Skip initial state
            .sink { state in
                if case .loaded(let posts) = state {
                    XCTAssertFalse(posts.isEmpty)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.loadInitialPosts()
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testLoadingState() {
        let expectation = XCTestExpectation(description: "Loading state")
        
        viewModel.$feedState
            .dropFirst()
            .sink { state in
                if case .loading = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.loadInitialPosts()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() {
        // Create a repository that always fails
        let failingRepository = MockPostRepository(delay: 0.1)
        let failingViewModel = FeedViewModel(repository: failingRepository)
        
        let expectation = XCTestExpectation(description: "Error state")
        
        failingViewModel.$feedState
            .dropFirst()
            .sink { state in
                if case .error = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        failingViewModel.loadInitialPosts()
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Like/Unlike Tests
    
    func testLikePost() {
        let expectation = XCTestExpectation(description: "Post liked")
        
        // First load some posts
        viewModel.loadInitialPosts()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let firstPost = self.viewModel.posts.first else {
                XCTFail("No posts available")
                return
            }
            
            let originalLikeState = firstPost.isLiked
            
            self.viewModel.$posts
                .dropFirst()
                .sink { posts in
                    if let updatedPost = posts.first(where: { $0.id == firstPost.id }) {
                        XCTAssertEqual(updatedPost.isLiked, !originalLikeState)
                        expectation.fulfill()
                    }
                }
                .store(in: &self.cancellables)
            
            self.viewModel.likePost(firstPost)
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testBookmarkPost() {
        let expectation = XCTestExpectation(description: "Post bookmarked")
        
        // First load some posts
        viewModel.loadInitialPosts()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let firstPost = self.viewModel.posts.first else {
                XCTFail("No posts available")
                return
            }
            
            let originalBookmarkState = firstPost.isBookmarked
            
            self.viewModel.$posts
                .dropFirst()
                .sink { posts in
                    if let updatedPost = posts.first(where: { $0.id == firstPost.id }) {
                        XCTAssertEqual(updatedPost.isBookmarked, !originalBookmarkState)
                        expectation.fulfill()
                    }
                }
                .store(in: &self.cancellables)
            
            self.viewModel.bookmarkPost(firstPost)
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    // MARK: - Refresh Tests
    
    func testRefreshPosts() {
        let expectation = XCTestExpectation(description: "Posts refreshed")
        
        viewModel.$feedState
            .dropFirst()
            .sink { state in
                if case .refreshing = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.refreshPosts()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Network State Tests
    
    func testNetworkStateUpdates() {
        let expectation = XCTestExpectation(description: "Network state updated")
        
        viewModel.$networkState
            .dropFirst()
            .sink { state in
                XCTAssertTrue([.online, .offline, .connecting].contains(state))
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 35.0) // Wait for network state change
    }
    
    // MARK: - Computed Properties Tests
    
    func testComputedProperties() {
        // Test when posts are empty
        XCTAssertTrue(viewModel.posts.isEmpty)
        XCTAssertEqual(viewModel.emptyStateMessage, "No posts available. Pull to refresh.")
        
        // Test canLoadMore when not loading
        XCTAssertTrue(viewModel.canLoadMore)
        
        // Test when loading more
        viewModel.isLoadingMore = true
        XCTAssertFalse(viewModel.canLoadMore)
    }
    
    // MARK: - Pagination Tests
    
    func testLoadMorePosts() {
        let expectation = XCTestExpectation(description: "More posts loaded")
        
        // First load initial posts
        viewModel.loadInitialPosts()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let initialCount = self.viewModel.posts.count
            
            self.viewModel.$posts
                .dropFirst()
                .sink { posts in
                    if posts.count > initialCount {
                        expectation.fulfill()
                    }
                }
                .store(in: &self.cancellables)
            
            self.viewModel.loadMorePosts()
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
}

// MARK: - Mock Repository Tests

class MockPostRepositoryTests: XCTestCase {
    var repository: MockPostRepository!
    
    override func setUp() {
        super.setUp()
        repository = MockPostRepository(delay: 0.1)
    }
    
    override func tearDown() {
        repository = nil
        super.tearDown()
    }
    
    func testMockRepositoryGeneratesPosts() {
        let expectation = XCTestExpectation(description: "Posts generated")
        
        repository.fetchPosts(page: 0, limit: 10)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { posts in
                    XCTAssertFalse(posts.isEmpty)
                    XCTAssertLessThanOrEqual(posts.count, 10)
                    expectation.fulfill()
                }
            )
            .store(in: &Set<AnyCancellable>())
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testMockRepositoryPagination() {
        let expectation = XCTestExpectation(description: "Pagination works")
        
        repository.fetchPosts(page: 0, limit: 5)
            .flatMap { firstPage -> AnyPublisher<[Post], Error> in
                XCTAssertEqual(firstPage.count, 5)
                return self.repository.fetchPosts(page: 1, limit: 5)
            }
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { secondPage in
                    XCTAssertEqual(secondPage.count, 5)
                    expectation.fulfill()
                }
            )
            .store(in: &Set<AnyCancellable>())
        
        wait(for: [expectation], timeout: 3.0)
    }
} 