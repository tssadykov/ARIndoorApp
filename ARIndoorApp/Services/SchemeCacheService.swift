//
//  SchemeCacheService.swift
//  ARIndoorApp
//
//  Created by Timur Sadykov on 4/20/21.
//

import Foundation

protocol SchemeCacheService {
    func cache(scheme: Scheme, completion: @escaping ((Bool) -> Void))
    func getScheme(withId id: Int, completion: @escaping ((Scheme?) -> Void))
}

final class SchemeCacheServiceImpl: SchemeCacheService {
    
    func cache(scheme: Scheme, completion: @escaping ((Bool) -> Void)) {
        queue.async {
            let schemes = self.fetchSchemes().filter { $0._id != scheme._id}
            self.cache(schemes: schemes + [scheme], completion: completion)
        }
    }
    
    func getScheme(withId id: Int, completion: @escaping ((Scheme?) -> Void)) {
        queue.async {
            let schemes = self.fetchSchemes()
            
            let scheme = schemes.first(where: { $0._id == id})
            completion(scheme)
        }
    }
    
    private let fileManager = FileManager.default
    private lazy var file: URL = {
        let directoryUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).last!
        let path = directoryUrl.appendingPathComponent("map_schemes")
        
        if !fileManager.fileExists(atPath: path.absoluteString) {
            fileManager.createFile(atPath: path.absoluteString, contents: nil, attributes: nil)
        }
        return path
    }()
    private let queue = DispatchQueue(label: "scheme_cache_service", qos: .userInitiated)
}

private extension SchemeCacheServiceImpl {
    
    private func cache(schemes: [Scheme], completion: ((Bool) -> Void)) {
        do {
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(schemes)
            try encodedData.write(to: self.file)
            completion(true)
        } catch {
            completion(false)
        }
    }
    
    private func fetchSchemes() -> [Scheme] {
        guard let data = fileManager.contents(atPath: file.path) else { return [] }
        
        do {
            let decoder = JSONDecoder()
            let decodedModels = try decoder.decode([Scheme].self, from: data)
            
            return decodedModels
        } catch let error {
            print("********Error occured when fetch transactions: \(error.localizedDescription)")
            assert(false)
            return []
        }
    }
}
