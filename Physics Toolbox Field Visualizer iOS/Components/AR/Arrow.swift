//
//  Vector.swift
//  Physics Toolbox Field Visualizer iOS
//
//  Created by Tyler Angert on 6/2/19.
//  Copyright © 2019 Vieyra Software. All rights reserved.
//

import Foundation
import ARKit
import SceneKit.ModelIO

// maybe
enum GeometryType {
    case arrow
    case sphere
}

let ARROW_OBJ_URL = "art.scnassets/arrow/sun-dial-arrow"

class Vector {
    
    var node = SCNNode()
    
    // Reset the geometry of the node on settings change
    var geometry: SCNGeometry = SCNGeometry() {
        didSet {
            self.node.geometry = geometry
        }
    }
    
    // Contains the label
    var textNode = SCNNode(geometry: SCNText(string: "", extrusionDepth: 0.01))
    
    // Convenince accessors
    var position: SCNVector3 = SCNVector3() {
        didSet {
            self.node.position = position
        }
    }
    var eulerAngles: SCNVector3 = SCNVector3() {
        didSet {
            self.node.eulerAngles = eulerAngles
        }
    }
    var scale: SCNVector3 = SCNVector3() {
        didSet {
            self.node.scale = scale
        }
    }
    var hue: CGFloat! = 0 {
        didSet {
            self.node.geometry?.firstMaterial!.diffuse.contents = UIColor(hue: hue, saturation: 1, brightness: 1, alpha: 1)
        }
    }
    
    // Other vars
    let scaleFactor: Float = 2
    let arrowModelURL = Bundle.main.url(forResource: ARROW_OBJ_URL, withExtension: "obj")!
    
    init() {
        self.node = nodeForURL(url: arrowModelURL)
        self.node.addChildNode(textNode)
        self.position = SCNVector3Zero
        
        // TODO: Add reflectiveness
//        let material = SCNMaterial()
//        material.lightingModel = .physicallyBased
//        material.roughness.contents = 0.5
//        material.metalness.contents = 0.5
//        self.node.geometry?.firstMaterial = material
    }
    
    func nodeForURL(url: URL) -> SCNNode {
        let asset = MDLAsset(url: url)
        let object = asset.object(at: 0)
        let node = SCNNode(mdlObject: object)
        return node
    }
}
