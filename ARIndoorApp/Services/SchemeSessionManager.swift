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
    
    // MARK: - Public properties
    
    private(set) var currentPosition: SchemePosition
    let scheme: Scheme
    
    // MARK: - Constructors
    
    init?(userPosition: RealWorldPosition, qrId: String, scheme: Scheme) {
        guard let graph = scheme.graph else { return nil }
        guard let startNode = graph.nodes.first(where: { $0.qrId == qrId }) else { return nil }
        
        self.scheme = scheme
        fromNode = startNode
        realToSchemePositionMapper = RealToSchemePositionMapper(realWorldPosition: userPosition, schemePosition: startNode.schemePosition)
        schemeGraphRouteCalculator = SchemeGraphRouteCalculator(schemeGraph: graph)
        currentPosition = startNode.schemePosition
    }
    
    // MARK: - Public Methods
    
    func startRoute(to roomdId: Int64) {
        guard let toNode = scheme.graph?.nodes.first(where: { $0.objId == roomdId }) else { return }
        
        self.currentRoute = schemeGraphRouteCalculator.calculateRoute(fromNode: fromNode, toNode: toNode)
        targetNode = currentRoute?[safe: 1]
        if targetNode != nil {
            targetNodeIndex = 1
        }
    }
    
    func applyRealWorldPosition(_ position: RealWorldPosition) -> SchemeSessionState? {
        currentPosition = realToSchemePositionMapper.convert(position)
        guard let targetNode = targetNode else { return nil }
        
        if currentPosition.distanceTo(targetNode.schemePosition) < Static.distanceTreshold {
            fromNode = targetNode
            guard let currentRoute = currentRoute else { assert(false); return nil }
            guard let targetNodeIndex = targetNodeIndex else { assert(false); return nil }
            
            let nextIndex = targetNodeIndex + 1
            
            if let nextNode = currentRoute[safe: nextIndex] {
                self.targetNodeIndex = nextIndex
                self.targetNode = nextNode
                return applyRealWorldPosition(position)
            } else {
                self.targetNode = nil
                self.targetNodeIndex = nil
                self.currentRoute = nil
                
                return .finish
            }
        }
        
        return .direction(calculateDirectionToCurrentPosition(targetNode: targetNode, currentPosition: currentPosition))
    }
    
    // MARK: - Private properties
    
    private var fromNode: GraphNode
    private var targetNode: GraphNode?
    private var targetNodeIndex: Int?
    private var currentRoute: [GraphNode]?
    
    private let realToSchemePositionMapper: RealToSchemePositionMapper
    private let schemeGraphRouteCalculator: SchemeGraphRouteCalculator
}

private extension SchemeSessionManager {
    
    // MARK: - Private Nested Types
    
    private enum Static {
        static let distanceTreshold: Float = 1.0
    }
    
    // MARK: - Private Methods
    
    private func calculateDirectionToCurrentPosition(targetNode: GraphNode, currentPosition: SchemePosition) -> Float {
        if targetNode.x == currentPosition.x {
            let dir: Float = (targetNode.y > currentPosition.y ? 1.0 : -1.0) * .pi / 2.0
            return realToSchemePositionMapper.convertSchemeDirectionToReal(dir)
        }
        
        let isSecondQuarter = (targetNode.y > currentPosition.y) && (targetNode.x < currentPosition.x)
        let isThirdQuarter = (targetNode.y < currentPosition.y) && (targetNode.x < currentPosition.x)
        
        let routeTan = (targetNode.y - currentPosition.y) / (targetNode.x - currentPosition.x)
        
        let alpha = atan(routeTan)
        let routeDir: Float = {
            if isSecondQuarter || isThirdQuarter {
                return .pi + alpha
            }
            
            return alpha
        }()
        
        return realToSchemePositionMapper.convertSchemeDirectionToReal(routeDir)
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
