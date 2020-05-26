//
//  GLKQuaternion+Extensions.swift
//  Physics Toolbox Field Visualizer iOS
//
//  Created by Tyler Angert on 6/12/19.
//  Copyright © 2019 Vieyra Software. All rights reserved.
//

import Foundation
import SceneKit

extension GLKQuaternion {
    public static func * (lhs: GLKQuaternion, rhs: GLKQuaternion) -> GLKQuaternion {
        return GLKQuaternionMultiply(lhs, rhs)
    }
    
    public static func fromEuler(roll: Float, pitch: Float, yaw: Float) -> GLKQuaternion {
        let cy = cos(yaw * 0.5)
        let sy = sin(yaw * 0.5)
        
        // cosine pitch, sine pitch
        let cp = cos(pitch * 0.5)
        let sp = sin(pitch * 0.5)
        
        // cosine roll, sine roll
        let cr = cos(roll * 0.5)
        let sr = sin(roll * 0.5)
        
        var q = GLKQuaternion()
        q.x = sr * cp * cy - cr * sp * sy
        q.y = cr * sp * cy + sr * cp * sy
        q.z = cr * cp * sy - sr * sp * cy
        q.w = cr * cp * cy + sr * sp * sy
        return q
    }
    
    func SCN() -> SCNQuaternion {
        return SCNQuaternion(self.x, self.y, self.z, self.w)
    }
    
    func inverted() -> GLKQuaternion {
        return GLKQuaternionInvert(self)
    }
}
