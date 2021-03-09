//
//  URLPerformer.swift
//  ARIndoorApp
//
//  Created by Timur Sadykov on 3/6/21.
//

import Foundation

enum URLPerformerTask {
    case openScheme(schemeId: Int, qrId: String)
}

protocol URLPerformer {
    func perform(url: String) -> URLPerformerTask?
}

final class URLPerformerImpl: URLPerformer {
    
    func perform(url: String) -> URLPerformerTask? {
        guard url.starts(with: "arindoorapp://?") else { return nil }
        
        let url = url.replacingOccurrences(of: "arindoorapp://?", with: "")
        let params = url.split(separator: "&").map({ String($0) })
        
        var schemeId: Int?
        var qrId: String?
        
        for param in params {
            if param.starts(with: "schemeid="), schemeId == nil {
                schemeId = Int(param.replacingOccurrences(of: "schemeid=", with: ""))
            } else if param.starts(with: "qrid="), qrId == nil {
                qrId = param.replacingOccurrences(of: "qrid=", with: "")
            }
        }
        
        if let schemeId = schemeId, let qrId = qrId {
            return .openScheme(schemeId: schemeId, qrId: qrId)
        }
        
        return nil
    }
}
