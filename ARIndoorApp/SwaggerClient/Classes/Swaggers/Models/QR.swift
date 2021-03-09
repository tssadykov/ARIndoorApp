//
// QR.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation



public struct QR: Codable {

    public var _id: Int64
    public var wallId: Int64
    public var direction: Float
    public var x: Float
    public var y: Float
    public var z: Float

    public init(_id: Int64, wallId: Int64, direction: Float, x: Float, y: Float, z: Float) {
        self._id = _id
        self.wallId = wallId
        self.direction = direction
        self.x = x
        self.y = y
        self.z = z
    }

    public enum CodingKeys: String, CodingKey { 
        case _id = "id"
        case wallId = "wall_id"
        case direction
        case x
        case y
        case z
    }

}
