//
//  ARSCNView.swift
//  Physics Toolbox Field Visualizer iOS
//
//  Created by Chrystian Vieyra on 1/16/19.
//  Copyright © 2019 Vieyra Software. All rights reserved.
//

import SceneKit
import ARKit

extension ARSCNView {
    func realWorldVector(screenPosition: CGPoint) -> SCNVector3? {
        let results = self.hitTest(screenPosition, types: [.featurePoint])
        guard let result = results.first else { return nil }
        return SCNVector3.positionFromTransform(result.worldTransform)
    }
}
