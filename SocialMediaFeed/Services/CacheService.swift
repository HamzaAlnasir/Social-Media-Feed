import Foundation

// MARK: - Cache Service Protocol
protocol CacheServiceProtocol {
    func save<T: Codable>(_ object: T, forKey key: String)
    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T?
    func remove(forKey key: String)
    func clearAll()
    func hasData(forKey key: String) -> Bool
}

// MARK: - Cache Service Implementation
class CacheService: CacheServiceProtocol {
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    
    func save<T: Codable>(_ object: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(object)
            userDefaults.set(data, forKey: key)
        } catch {
            print("Failed to save object for key \(key): \(error)")
        }
    }
    
    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Failed to load object for key \(key): \(error)")
            return nil
        }
    }
    
    func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
    func clearAll() {
        let domain = Bundle.main.bundleIdentifier!
        userDefaults.removePersistentDomain(forName: domain)
    }
    
    func hasData(forKey key: String) -> Bool {
        return userDefaults.object(forKey: key) != nil
    }
}

// MARK: - File Cache Service for Large Data
class FileCacheService: CacheServiceProtocol {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("SocialMediaFeed")
        
        try? fileManager.createDirectory(at: cacheDirectory, 
                                       withIntermediateDirectories: true, 
                                       attributes: nil)
    }
    
    func save<T: Codable>(_ object: T, forKey key: String) {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        
        do {
            let data = try JSONEncoder().encode(object)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save object to file for key \(key): \(error)")
        }
    }
    
    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Failed to load object from file for key \(key): \(error)")
            return nil
        }
    }
    
    func remove(forKey key: String) {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        try? fileManager.removeItem(at: fileURL)
    }
    
    func clearAll() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, 
                                                              includingPropertiesForKeys: nil)
            for fileURL in contents {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Failed to clear cache directory: \(error)")
        }
    }
    
    func hasData(forKey key: String) -> Bool {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        return fileManager.fileExists(atPath: fileURL.path)
    }
}

// MARK: - Hybrid Cache Service
class HybridCacheService: CacheServiceProtocol {
    private let userDefaultsCache: CacheServiceProtocol
    private let fileCache: CacheServiceProtocol
    
    init() {
        self.userDefaultsCache = CacheService()
        self.fileCache = FileCacheService()
    }
    
    func save<T: Codable>(_ object: T, forKey key: String) {
        // Use file cache for large data, user defaults for small data
        if shouldUseFileCache(for: object) {
            fileCache.save(object, forKey: key)
        } else {
            userDefaultsCache.save(object, forKey: key)
        }
    }
    
    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        // Try user defaults first, then file cache
        if let object = userDefaultsCache.load(type, forKey: key) {
            return object
        }
        return fileCache.load(type, forKey: key)
    }
    
    func remove(forKey key: String) {
        userDefaultsCache.remove(forKey: key)
        fileCache.remove(forKey: key)
    }
    
    func clearAll() {
        userDefaultsCache.clearAll()
        fileCache.clearAll()
    }
    
    func hasData(forKey key: String) -> Bool {
        return userDefaultsCache.hasData(forKey: key) || fileCache.hasData(forKey: key)
    }
    
    private func shouldUseFileCache<T>(for object: T) -> Bool {
        // Use file cache for arrays with more than 10 items or large objects
        if let array = object as? [Any] {
            return array.count > 10
        }
        
        // Estimate object size by encoding it
        do {
            let data = try JSONEncoder().encode(object)
            return data.count > 1024 * 1024 // 1MB threshold
        } catch {
            return false
        }
    }
} 