//
//  SchemeSessionManager.swift
//  ARIndoorApp
//
//  Created by Timur Sadykov on 3/8/21.
//

import Foundation

struct RealWorldPosition {
    let x: Float
    let y: Float
    let z: Float
    let direction: Float
}

struct SchemePosition {
    let x: Float
    let y: Float
    let z: Float
    let direction: Float
    
    func distanceTo(_ sp: SchemePosition) -> Float {
        let squaredDistance = (sp.x - x) * (sp.x - x) + (sp.y - y) * (sp.y - y) + (sp.z - z) * (sp.z - z)
        return sqrt(squaredDistance)
    }
}

enum SchemeSessionState {
    case finish
    case direction(Float)
}

final class SchemeSessionManager {
    
    private(set) var fromNode: GraphNode
    private(set) var toNode: GraphNode?
    let scheme: Scheme
    
    init?(userPosition: RealWorldPosition, qrId: String, scheme: Scheme) {
        guard let graph = scheme.graph else { return nil }
        guard let startNode = graph.nodes.first(where: { $0.qrId == qrId }) else { return nil }
        
        self.scheme = scheme
        fromNode = startNode
        realToSchemePositionMapper = RealToSchemePositionMapper(realWorldPosition: userPosition, schemePosition: startNode.schemePosition)
        currentPosition = startNode.schemePosition
    }
    
    func startRoute(to roomdId: Int64) {
        guard let toNode = scheme.graph?.nodes.first(where: { $0.objId == roomdId }) else { return }
        
        self.toNode = toNode
    }
    
    func applyRealWorldPosition(_ position: RealWorldPosition) -> SchemeSessionState? {
        currentPosition = realToSchemePositionMapper.convert(position)
        guard let toNode = toNode else { return nil }
        
        if currentPosition.distanceTo(toNode.schemePosition) < Static.distanceTreshold {
            return .finish
        }
        
        if toNode.x == currentPosition.x {
            let dir: Float = (toNode.y > currentPosition.y ? 1.0 : -1.0) * .pi / 2.0
            return .direction(realToSchemePositionMapper.convertSchemeDirectionToReal(dir))
        }
        
        let isSecondQuarter = (toNode.y > currentPosition.y) && (toNode.x < currentPosition.x)
        let isThirdQuarter = (toNode.y < currentPosition.y) && (toNode.x < currentPosition.x)
        
        let routeTan = (toNode.y - currentPosition.y) / (toNode.x - currentPosition.x)
        
        let alpha = atan(routeTan)
        let routeDir: Float = {
            if isSecondQuarter || isThirdQuarter {
                return .pi + alpha
            }
            
            return alpha
        }()
        
        return .direction(realToSchemePositionMapper.convertSchemeDirectionToReal(routeDir))
    }
    
    var currentPosition: SchemePosition
    private let realToSchemePositionMapper: RealToSchemePositionMapper
}

private extension SchemeSessionManager {
    
    private enum Static {
        static let distanceTreshold: Float = 1.0
    }
    
}

private extension GraphNode {
    
    var qrId: String? {
        switch objType {
        case .qr:
            return String(objId)
        default:
            return nil
        }
    }
    
    var schemePosition: SchemePosition {
        return SchemePosition(x: x, y: y, z: z, direction: direction!)
    }
}
