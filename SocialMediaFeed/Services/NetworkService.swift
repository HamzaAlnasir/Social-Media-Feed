import Foundation
import Combine

// MARK: - Network Service Protocol
protocol NetworkServiceProtocol {
    func request<T: Codable>(endpoint: APIEndpoint) -> AnyPublisher<T, Error>
    func request(endpoint: APIEndpoint) -> AnyPublisher<Data, Error>
}

// MARK: - Network Service Implementation
class NetworkService: NetworkServiceProtocol {
    private let session: URLSession
    private let baseURL = "https://api.socialmediafeed.com/v1"
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func request<T: Codable>(endpoint: APIEndpoint) -> AnyPublisher<T, Error> {
        return request(endpoint: endpoint)
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func request(endpoint: APIEndpoint) -> AnyPublisher<Data, Error> {
        guard let url = URL(string: baseURL + endpoint.path) else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.headers
        
        if let body = endpoint.body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .mapError { NetworkError.requestFailed($0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - API Endpoint
enum APIEndpoint {
    case posts(page: Int, limit: Int)
    case likePost(UUID)
    case unlikePost(UUID)
    case bookmarkPost(UUID)
    case unbookmarkPost(UUID)
    
    var path: String {
        switch self {
        case .posts(let page, let limit):
            return "/posts?page=\(page)&limit=\(limit)"
        case .likePost(let id):
            return "/posts/\(id)/like"
        case .unlikePost(let id):
            return "/posts/\(id)/unlike"
        case .bookmarkPost(let id):
            return "/posts/\(id)/bookmark"
        case .unbookmarkPost(let id):
            return "/posts/\(id)/unbookmark"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .posts:
            return .GET
        case .likePost, .bookmarkPost:
            return .POST
        case .unlikePost, .unbookmarkPost:
            return .DELETE
        }
    }
    
    var headers: [String: String] {
        var headers = ["Content-Type": "application/json"]
        
        // Add authentication header if needed
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        return headers
    }
    
    var body: [String: Any]? {
        switch self {
        case .posts, .likePost, .unlikePost, .bookmarkPost, .unbookmarkPost:
            return nil
        }
    }
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

// MARK: - Network Error
enum NetworkError: LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingFailed:
            return "Failed to decode response"
        }
    }
} 