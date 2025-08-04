# Social Media Feed - MVVM with Combine

A Twitter-like social media feed application built with SwiftUI, demonstrating MVVM architecture, reactive programming with Combine, and advanced iOS development patterns.

## 🏗️ Architecture Overview

This project implements a clean **MVVM (Model-View-ViewModel)** architecture with **Combine** for reactive data binding, ensuring:

- **Clear separation of concerns** between Model, View, and ViewModel
- **Fully testable ViewModels** without UI dependencies
- **Reactive data binding** using Combine publishers
- **Scalable and maintainable** codebase

## 📱 Features

### Core Functionality
- ✅ **Social Media Feed** with posts, images, videos, and links
- ✅ **Pull-to-refresh** functionality
- ✅ **Infinite scrolling** with pagination
- ✅ **Real-time updates** using Combine
- ✅ **Offline functionality** with caching

### UI Components
- ✅ **Reusable feed item components** with modular design
- ✅ **Multiple content types** (text, image, video, link)
- ✅ **Dynamic height calculation** for variable content
- ✅ **Plugin system** for custom feed items
- ✅ **Beautiful and modern UI** with excellent UX

### Advanced Features
- ✅ **Network state monitoring** (online/offline)
- ✅ **Error handling** with retry mechanisms
- ✅ **Loading states** and empty states
- ✅ **Share functionality** for posts
- ✅ **Like and bookmark** interactions

## 🏛️ Project Structure

```
SocialMediaFeed/
├── Models/
│   └── Post.swift                 # Data models and state enums
├── ViewModels/
│   └── FeedViewModel.swift        # Main ViewModel with Combine
├── Views/
│   ├── FeedView.swift             # Main feed view
│   └── Components/
│       └── FeedItemView.swift     # Reusable feed item components
├── Views/Plugins/
│   └── FeedItemPlugin.swift       # Plugin system for custom content
├── Repositories/
│   └── PostRepository.swift       # Data layer with protocols
├── Services/
│   ├── NetworkService.swift       # Network layer
│   └── CacheService.swift         # Caching and offline support
└── SocialMediaFeedApp.swift       # App entry point
```

## 🔧 Technical Implementation

### MVVM Architecture

#### Model Layer
- **Post**: Core data model with different content types
- **User**: User information model
- **PostContent**: Enum for different content types (text, image, video, link)
- **State Enums**: FeedState, NetworkState for state management

#### ViewModel Layer
- **FeedViewModel**: Main ViewModel using `@Published` properties
- **Combine Integration**: Reactive data binding with publishers
- **State Management**: Handles loading, error, and success states
- **Repository Pattern**: Clean data access through protocols

#### View Layer
- **SwiftUI Views**: Modern declarative UI
- **Component Modularity**: Reusable feed item components
- **Plugin System**: Dynamic content rendering

### Combine Integration

```swift
// Reactive data binding
@Published var feedState: FeedState = .idle
@Published var posts: [Post] = []
@Published var networkState: NetworkState = .online

// Publisher chains for data flow
repository.fetchPosts(page: page, limit: pageSize)
    .receive(on: DispatchQueue.main)
    .sink(
        receiveCompletion: { completion in
            // Handle completion
        },
        receiveValue: { posts in
            // Update UI
        }
    )
    .store(in: &cancellables)
```

### Plugin System

The application features a flexible plugin system for custom feed items:

```swift
protocol FeedItemPlugin {
    var identifier: String { get }
    var priority: Int { get }
    func canHandle(_ post: Post) -> Bool
    func createView(for post: Post, actions: PostActions) -> AnyView
}
```

**Built-in Plugins:**
- **PromotedPostPlugin**: Handles sponsored content
- **VideoPostPlugin**: Enhanced video post rendering
- **LivePostPlugin**: Live streaming content

### Offline Support

- **Hybrid Caching**: UserDefaults for small data, file system for large data
- **Network Fallback**: Automatic fallback to cached data when offline
- **Cache Management**: Intelligent cache size management

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd SocialMediaFeed
```

2. Open the project in Xcode:
```bash
open SocialMediaFeed.xcodeproj
```

3. Build and run the project (⌘+R)

### Configuration

The app uses a mock repository by default for demonstration. To connect to a real API:

1. Update `NetworkService.swift` with your API endpoints
2. Replace `MockPostRepository` with `PostRepository` in `FeedViewModel`
3. Configure authentication tokens in `APIEndpoint`

## 🧪 Testing

The architecture is designed for easy testing:

```swift
// Test ViewModel without UI dependencies
class FeedViewModelTests: XCTestCase {
    var viewModel: FeedViewModel!
    var mockRepository: MockPostRepository!
    
    override func setUp() {
        mockRepository = MockPostRepository()
        viewModel = FeedViewModel(repository: mockRepository)
    }
    
    func testLoadPosts() {
        // Test implementation
    }
}
```

## 📊 Performance Features

- **Lazy Loading**: Images and content loaded on-demand
- **Pagination**: Efficient data loading with page-based requests
- **Memory Management**: Proper Combine subscription cleanup
- **Background Processing**: Network requests on background queues

## 🎨 UI/UX Features

- **Modern Design**: Clean, Twitter-inspired interface
- **Smooth Animations**: Fluid transitions and interactions
- **Accessibility**: VoiceOver support and dynamic type
- **Dark Mode**: Full dark mode support
- **Responsive Layout**: Adapts to different screen sizes

## 🔄 State Management

The app handles complex states efficiently:

```swift
enum FeedState: Equatable {
    case idle
    case loading
    case loaded([Post])
    case error(String)
    case refreshing
}
```

## 📱 Supported Content Types

1. **Text Posts**: Simple text content with expand/collapse
2. **Image Posts**: Images with captions and loading states
3. **Video Posts**: Video previews with play controls
4. **Link Posts**: Rich link previews with thumbnails
5. **Live Posts**: Real-time content with viewer counts
6. **Promoted Posts**: Sponsored content with special styling

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming framework
- **MVVM Pattern**: Clean architecture approach
- **iOS Design Guidelines**: Apple's Human Interface Guidelines

---

**Built with ❤️ using SwiftUI and Combine** 