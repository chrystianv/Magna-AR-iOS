//
//  SCNVector4+Extensions.swift
//  Physics Toolbox Field Visualizer iOS
//
//  Created by Tyler Angert on 6/12/19.
//  Copyright © 2019 Vieyra Software. All rights reserved.
//

import Foundation
import SceneKit

extension SCNVector4 {
    public func GLK() -> GLKQuaternion {
        return GLKQuaternion(q: (x, y, z, w))
    }
    
    public static func == (lhs: SCNVector4, rhs: SCNVector4) -> Bool {
        return (lhs.x == rhs.x &&
                lhs.y == rhs.y &&
                lhs.z == rhs.z &&
                lhs.w == rhs.w)
    }
    
}
