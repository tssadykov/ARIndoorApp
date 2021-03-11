//
//  RealToSchemePositionMapper.swift
//  ARIndoorApp
//
//  Created by Timur Sadykov on 3/8/21.
//

import simd

final class RealToSchemePositionMapper {
    
    init(realWorldPosition: RealWorldPosition, schemePosition: SchemePosition) {
        self.realWorldPosition = realWorldPosition
        self.schemePosition = schemePosition
        
        alpha = realWorldPosition.direction + .directionDeltaCoef - schemePosition.direction
        transform = simd_float2x2(rows: [simd_float2(cos(alpha), -sin(alpha)), simd_float2(sin(alpha), cos(alpha))]).inverse
    }
    
    func convert(_ rwPosition: RealWorldPosition) -> SchemePosition {
        let deltaX = rwPosition.x - realWorldPosition.x
        let deltaY = rwPosition.y - realWorldPosition.y
        let deltaZ = rwPosition.z - realWorldPosition.z
        let direction = rwPosition.direction + .directionDeltaCoef - alpha
        
        let schemeDelta = transform * simd_float2(deltaZ, deltaX)
        
        return .init(
            x: schemePosition.x + schemeDelta.x,
            y: schemePosition.y + schemeDelta.y,
            z: schemePosition.z + deltaY,
            direction: direction
        )
    }
    
    func convertSchemeDirectionToReal(_ direction: Float) -> Float {
        return direction - .directionDeltaCoef + alpha
    }
    
    private let realWorldPosition: RealWorldPosition
    private let schemePosition: SchemePosition
    
    private let alpha: Float
    private let transform: simd_float2x2
}

private extension Float {
    
    static var directionDeltaCoef: Float {
        return .pi
    }
}
