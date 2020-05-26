//
//  float3+Extensions.swift
//  Physics Toolbox Field Visualizer iOS
//
//  Created by Tyler Angert on 10/15/19.
//  Copyright © 2019 Vieyra Software. All rights reserved.
//

import Foundation
import SceneKit

extension float3 {
    func length() -> Float {
        return sqrtf(x * x + y * y + z * z)
    }
    
    /**
     * Normalizes the vector described by the SCNVector3 to length 1.0 and returns
     * the result as a new SCNVector3.
     */
    
    func normalized() -> float3 {
        let len = self.length()
        return float3(self.x / len, self.y / len, self.z / len)
    }
}
