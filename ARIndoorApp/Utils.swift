//
//  Utils.swift
//  ARIndoorApp
//
//  Created by Timur Sadykov on 2/6/21.
//

import Foundation

@discardableResult
func apply<T>(_ obj: T, block: ((T) -> Void)) -> T {
    block(obj)
    return obj
}

extension Collection {
    
    subscript(safe index: Index) -> Element? {
        if index < endIndex {
            return self[index]
        }
        
        return nil
    }
}
