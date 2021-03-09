//
//  BuildingSchemeService.swift
//  ARIndoorApp
//
//  Created by Timur Sadykov on 3/6/21.
//

import Foundation

protocol BuildingSchemeService {
    func loadScheme(for schemeId: Int, completion: @escaping ((Result<Scheme, Error>) -> Void))
}

final class BuildingSchemeServiceImpl: BuildingSchemeService {
    
    func loadScheme(for schemeId: Int, completion: @escaping ((Result<Scheme, Error>) -> Void)) {
        SchemeAPI.getSchemeById(schemeId: Int64(schemeId)) { scheme, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else if let scheme = scheme {
                    completion(.success(scheme))
                } else {
                    completion(.failure(NSError()))
                }
            }
        }
    }
}
