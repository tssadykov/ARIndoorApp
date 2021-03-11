//
//  Math.swift
//  ARIndoorApp
//
//  Created by Timur Sadykov on 3/8/21.
//

import Foundation
import simd

final class Math {
    static func radiansToDegrees(radians: Float) -> Int {
        return Int((180 * radians) / Float.pi + 180)
    }

    static func euclideanDistance(p1: simd_float3, p2: simd_float3) -> Float {
        return simd_distance(p1, p2)
    }


    // MARK: - Rotation

    static func rotateAroundX(matrix: simd_float4x4, angle: Float) -> simd_float4x4 {
        return matrix * makeRotationMatrixAroundX(angle: angle)
    }

    static func rotateAroundY(matrix: simd_float4x4, angle: Float) -> simd_float4x4 {
        return matrix * makeRotationMatrixAroundY(angle: angle)
    }

    static func rotateAroundZ(matrix: simd_float4x4, angle: Float) -> simd_float4x4 {
        return matrix * makeRotationMatrixAroundZ(angle: angle)
    }

    private static func makeRotationMatrixAroundX(angle: Float) -> simd_float4x4 {
        let rows = [
            simd_float4(1, 0, 0, 0),
            simd_float4(0, cos(angle), -sin(angle), 0),
            simd_float4(0, sin(angle), cos(angle), 0),
            simd_float4(0, 0, 0, 1)
        ]

        return float4x4(rows: rows)
    }

    private static func makeRotationMatrixAroundY(angle: Float) -> simd_float4x4 {
        let rows = [
            simd_float4(cos(angle), 0, sin(angle), 0),
            simd_float4(0, 1, 0, 0),
            simd_float4(-sin(angle), 0, cos(angle), 0),
            simd_float4(0, 0, 0, 1)
        ]

        return float4x4(rows: rows)
    }

    private static func makeRotationMatrixAroundZ(angle: Float) -> simd_float4x4 {
        let rows = [
            simd_float4( cos(angle), -sin(angle), 0, 0),
            simd_float4(sin(angle), cos(angle), 0, 0),
            simd_float4( 0,          0,          1, 0),
            simd_float4( 0,          0,          0, 1)
        ]

        return float4x4(rows: rows)
    }
}

extension Float {
    
    func removeRadiansPeriod() -> Float {
        var value = self
        
        while (abs(value) >= 2.0 * .pi) {
            if value > 0 {
                value -= 2.0 * .pi
            } else {
                value += 2.0 * .pi
            }
        }
        
        return value
    }
}
