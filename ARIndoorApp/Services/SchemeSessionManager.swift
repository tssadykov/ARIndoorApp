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
    case changeFloor(Int)
}

final class SchemeSessionManager {
    
    // MARK: - Public Nested Types
    
    enum State {
        case start(startNode: GraphNode)
        case pause(finishNode: GraphNode)
        case route(startNode: GraphNode, targetNodeIndex: Int, finishNode: GraphNode, route: [GraphNode])
        
        var isStart: Bool {
            switch self {
            case .start:
                return true
            default:
                return false
            }
        }
        
        var isPause: Bool {
            switch self {
            case .pause:
                return true
            default:
                return false
            }
        }
        
        var startNode: GraphNode? {
            switch self {
            case .start(let sn), .route(let sn, _, _, _):
                return sn
            case .pause:
                return nil
            }
        }
        
        var finishNode: GraphNode? {
            switch self {
            case .route(_, _, let finishNode, _), .pause(let finishNode):
                return finishNode
            case .start:
                return nil
            }
        }
    }
    
    // MARK: - Public properties
    
    private(set) var currentPosition: SchemePosition
    let scheme: Scheme
    let rooms: [Room]
    
    // MARK: - Constructors
    
    init?(userPosition: RealWorldPosition, qrId: String, scheme: Scheme) {
        guard let startNode = scheme.graph.nodes.first(where: { $0.qrId == qrId }) else { return nil }
        
        self.scheme = scheme
        self.rooms = scheme.floors.flatMap { $0.rooms ?? [] }
        state = .start(startNode: startNode)
        realToSchemePositionMapper = RealToSchemePositionMapper(realWorldPosition: userPosition, schemePosition: startNode.schemePosition)
        schemeGraphRouteCalculator = SchemeGraphRouteCalculator(schemeGraph: scheme.graph)
        currentPosition = startNode.schemePosition
    }
    
    // MARK: - Public Methods
    
    func startRoute(to roomdId: Int64) {
        guard let toNode = scheme.graph.nodes.first(where: { $0.objId == roomdId }) else { return }
        guard state.isStart else { return }
        guard let fromNode = state.startNode else { return }
        
        let currentRoute = schemeGraphRouteCalculator.calculateRoute(fromNode: fromNode, toNode: toNode)
        guard currentRoute.count > 1 else { return }
        
        state = .route(startNode: fromNode, targetNodeIndex: 1, finishNode: toNode, route: currentRoute)
    }
    
    func continueRoute(from qrId: String, userPosition: RealWorldPosition) {
        guard let startNode = scheme.graph.nodes.first(where: { $0.qrId == qrId }) else { return }
        guard state.isPause else { return }
        guard let finishNode = state.finishNode else { return }
        
        realToSchemePositionMapper = RealToSchemePositionMapper(realWorldPosition: userPosition, schemePosition: startNode.schemePosition)
        
        let currentRoute = schemeGraphRouteCalculator.calculateRoute(fromNode: startNode, toNode: finishNode)
        guard currentRoute.count > 1 else {
            state = .start(startNode: startNode)
            return
        }
        
        state = .route(startNode: startNode, targetNodeIndex: 1, finishNode: finishNode, route: currentRoute)
    }
    
    func applyRealWorldPosition(_ position: RealWorldPosition) -> SchemeSessionState? {
        currentPosition = realToSchemePositionMapper.convert(position)
        
        switch state {
        case .route(let startNode, let targetNodeIndex, let finishNode, let route):
            let targetNode = route[targetNodeIndex]
            
            if currentPosition.distanceTo(targetNode.schemePosition) < Static.distanceTreshold {
                
                let nextIndex = targetNodeIndex + 1
                
                if nextIndex < route.count {
                    if targetNode.isFloorMovement && targetNode.floorId != route[nextIndex].floorId {
                        self.state = .pause(finishNode: finishNode)
                        return .changeFloor(Int(route[nextIndex].floorId) + 1) // fix it
                    }
                    self.state = .route(startNode: startNode, targetNodeIndex: nextIndex, finishNode: finishNode, route: route)
                    return applyRealWorldPosition(position)
                } else {
                    self.state = .start(startNode: finishNode)
                    
                    return .finish
                }
            }
            
            return .direction(calculateDirectionToCurrentPosition(targetNode: targetNode, currentPosition: currentPosition))
        default:
            return nil
        }
    }
    
    // MARK: - Private properties
    
    private var state: State
    
    private var realToSchemePositionMapper: RealToSchemePositionMapper
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
    
    var isFloorMovement: Bool {
        switch objType {
        case .elevator, .staircase:
            return true
        case .door, .inRoom, .qr:
            return false
        }
    }
    
    var qrId: String? {
        switch objType {
        case .qr:
            return String(objId)
        default:
            return nil
        }
    }
    
    var schemePosition: SchemePosition {
        return SchemePosition(x: x, y: y, z: z, direction: direction ?? 0.0)
    }
}
