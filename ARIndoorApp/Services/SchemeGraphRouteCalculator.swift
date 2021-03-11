//
//  SchemeGraphRouteCalculator.swift
//  ARIndoorApp
//
//  Created by Timur Sadykov on 3/11/21.
//

import Foundation

final class SchemeGraphRouteCalculator {
    
    init(schemeGraph: SchemeGraph) {
        self.schemeGraph = schemeGraph
        
        let nodes = schemeGraph.nodes
        
        var graph = [[Float]](repeating: [Float](repeating: 0.0, count: nodes.count), count: nodes.count)
        
        for edge in schemeGraph.edges {
            guard let nodeFrom = nodes.firstIndex(where: { $0._id == edge.node1Id }) else { assert(false); continue }
            guard let nodeTo = nodes.firstIndex(where: { $0._id == edge.node2Id }) else { assert(false); continue }
            
            graph[nodeFrom][nodeTo] = edge.weight
            graph[nodeTo][nodeFrom] = edge.weight
        }
        
        self.graph = graph
    }
    
    func calculateRoute(fromNode: GraphNode, toNode: GraphNode) -> [GraphNode] {
        let nodes = schemeGraph.nodes
        guard let fromNodeIndex = nodes.firstIndex(where: { $0._id == fromNode._id }) else { assert(false); return [] }
        guard let toNodeIndex = nodes.firstIndex(where: { $0._id == toNode._id }) else { assert(false); return [] }
        
        
        var distances = [Float](repeating: .greatestFiniteMagnitude, count: nodes.count)
        var visits = [Bool](repeating: false, count: nodes.count)
        
        distances[fromNodeIndex] = 0.0
        
        var minIndex = -1
        
        repeat {
            minIndex = -1
            var min = Float.greatestFiniteMagnitude
            
            for i in (0..<nodes.count) {
                if !visits[i] && distances[i] < min {
                    min = distances[i]
                    minIndex = i
                }
            }
            
            if minIndex != -1 {
                for i in (0..<nodes.count) {
                    if graph[minIndex][i] > 0 {
                        let temp = min + graph[minIndex][i]
                        if temp < distances[i] {
                            distances[i] = temp
                        }
                    }
                }
                
                visits[minIndex] = true
            }
            
        } while minIndex != -1
        
        var visitedNodes = [Int]()
        visitedNodes.append(toNodeIndex)
        var weight = distances[toNodeIndex]
        var currentNode = toNodeIndex
        
        while currentNode != fromNodeIndex {
            for i in (0..<nodes.count) {
                if graph[i][currentNode] != 0 {
                    let temp = weight - graph[i][currentNode]
                    
                    if temp == distances[i] {
                        weight = temp
                        currentNode = i
                        visitedNodes.append(i)
                    }
                }
            }
        }
        
        
        return visitedNodes.reversed().map { nodes[$0] }
    }
    
    private let graph: [[Float]]
    private let schemeGraph: SchemeGraph
}
