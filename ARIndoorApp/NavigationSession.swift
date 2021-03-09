//
//  NavigationSession.swift
//  ARIndoorApp
//
//  Created by Timur Sadykov on 1/30/21.
//

import Foundation
import simd

struct Point {
    let x: Double
    let y: Double
}

final class NavigationSessionImpl {
    
    init(startPoint: Point) {
        self.startPoint = startPoint
        self.currentPoint = startPoint
    }
    
    func applyCameraTransform(_ transform: simd_float4x4) {
        
    }
    
    private var currentPoint: Point
    private let startPoint: Point
}
