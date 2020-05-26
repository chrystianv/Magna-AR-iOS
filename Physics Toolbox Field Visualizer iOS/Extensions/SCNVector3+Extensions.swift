//
//  SCNVector3.swift
//  Physics Toolbox Field Visualizer iOS
//
//  Created by Chrystian Vieyra on 1/16/19.
//  Copyright © 2019 Vieyra Software. All rights reserved.
//

import ARKit

extension SCNVector3 {
    
    public static func - (l: SCNVector3, r: SCNVector3) -> SCNVector3 {
        return SCNVector3(l.x - r.x, l.y - r.y, l.z - r.z)
    }
    
    public static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
        return SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
    
    func distance(from vector: SCNVector3) -> Float {
        let distanceX = self.x - vector.x
        let distanceY = self.y - vector.y
        let distanceZ = self.z - vector.z
        return sqrtf((distanceX * distanceX) + (distanceY * distanceY) + (distanceZ * distanceZ))
    }
    
    func line(to vector: SCNVector3, color: UIColor = .white) -> SCNNode {
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [self, vector])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        let geometry = SCNGeometry(sources: [source], elements: [element])
        geometry.firstMaterial?.diffuse.contents = color
        let node = SCNNode(geometry: geometry)
        return node
    }
    
    func length() -> Float {
        return sqrtf(x * x + y * y + z * z)
    }
    
    /**
     * Normalizes the vector described by the SCNVector3 to length 1.0 and returns
     * the result as a new SCNVector3.
     */
    func normalized() -> SCNVector3 {
        let l = self.length()
        return SCNVector3(self.x / l, self.y / l, self.z / l)
    }
    
    func offset(from vector: SCNVector3) -> SCNVector3 {
        return SCNVector3(self.x-vector.x, self.y-vector.y, self.z-vector.z)
    }
    
    public static func SCNVector3DotProduct(left: SCNVector3, right: SCNVector3) -> Float {
        return left.x * right.x + left.y * right.y + left.z * right.z
    }
    
    public static func SCNVector3CrossProduct(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(left.y * right.z - left.z * right.y, left.z * right.x - left.x * right.z, left.x * right.y - left.y * right.x)
    }
    
}

extension SCNVector3: Equatable {
    public static func ==(lhs: SCNVector3, rhs: SCNVector3) -> Bool {
        return (lhs.x == rhs.x) && (lhs.y == rhs.y) && (lhs.z == rhs.z)
    }
}
