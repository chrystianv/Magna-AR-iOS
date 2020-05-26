//
//  SCNQuaternion+Extensions.swift
//  Physics Toolbox Field Visualizer iOS
//
//  Created by Tyler Angert on 6/10/19.
//  Copyright © 2019 Vieyra Software. All rights reserved.
//

import Foundation
import SceneKit

extension SCNQuaternion {
    public static func * (lhs: SCNQuaternion, rhs: SCNQuaternion) -> SCNQuaternion {
        
        /*
         // Manual calculation
         let x = lhs.x * rhs.w + lhs.y * rhs.z - lhs.z * rhs.y + lhs.w * rhs.x
         let y = -lhs.x * rhs.z + lhs.y * rhs.w + lhs.z * rhs.x + lhs.w * rhs.y
         let z = lhs.x * rhs.y - lhs.y * rhs.x + lhs.z * rhs.w + lhs.w * rhs.z
         let w = -lhs.x * rhs.x - lhs.y * rhs.y - lhs.z * rhs.z + lhs.w * rhs.w
         let result = SCNQuaternion(x: x, y: y, z: z, w: w)
         */
        
        // This uses the GLK convencience methods
        return (lhs.GLK() * rhs.GLK()).SCN()
    }
        
    public static func fromEuler(roll: Float, pitch: Float, yaw: Float) -> SCNQuaternion {
        let cy = cos(yaw * 0.5)
        let sy = sin(yaw * 0.5)
        
        // cosine pitch, sine pitch
        let cp = cos(pitch * 0.5)
        let sp = sin(pitch * 0.5)
        
        // cosine roll, sine roll
        let cr = cos(roll * 0.5)
        let sr = sin(roll * 0.5)
        
        var q = SCNQuaternion()
        q.x = sr * cp * cy - cr * sp * sy
        q.y = cr * sp * cy + sr * cp * sy
        q.z = cr * cp * sy - sr * sp * cy
        q.w = cr * cp * cy + sr * sp * sy
        return q
    }
}
