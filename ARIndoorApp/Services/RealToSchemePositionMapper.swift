//
//  RealToSchemePositionMapper.swift
//  ARIndoorApp
//
//  Created by Timur Sadykov on 3/8/21.
//

import Foundation

final class RealToSchemePositionMapper {
    
    init(realWorldPosition: RealWorldPosition, schemePosition: SchemePosition) {
        self.realWorldPosition = realWorldPosition
        self.schemePosition = schemePosition
    }
    
    func convert(_ rwPosition: RealWorldPosition) -> SchemePosition {
        let deltaX = rwPosition.x - realWorldPosition.x
        let deltaY = rwPosition.y - realWorldPosition.y
        let deltaZ = rwPosition.z - realWorldPosition.z
        let deltaDir = rwPosition.direction - realWorldPosition.direction
        return .init(
            x: schemePosition.x + deltaX,
            y: schemePosition.y + deltaY,
            z: schemePosition.z + deltaZ,
            direction: schemePosition.direction + deltaDir
        )
    }
    
    private let realWorldPosition: RealWorldPosition
    private let schemePosition: SchemePosition
}
