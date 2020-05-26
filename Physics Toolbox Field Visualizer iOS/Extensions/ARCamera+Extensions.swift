//
//  ARCamera+Extensions.swift
//  Physics Toolbox Field Visualizer iOS
//
//  Created by Chrystian Vieyra on 1/22/19.
//  Copyright © 2019 Vieyra Software. All rights reserved.
//

import UIKit
import ARKit

extension ARCamera.TrackingState {
    var recommendation: String {
        switch self {
        case .notAvailable:
            return ""
        case .limited(.excessiveMotion):
            return ""
        case .limited(.insufficientFeatures):
            return ""
        case .limited(.initializing):
            return ""
        case .limited(.relocalizing):
            return ""
        default:
            return ""
        }
    }
    
    var presentationString: String {
        switch self {
        case .notAvailable:
            return "TRACKING UNAVAILABLE"
        case .normal:
            return "TRACKING NORMAL"
        case .limited(.excessiveMotion):
            return "TRACKING LIMITED\nExcessive motion"
        case .limited(.insufficientFeatures):
            return "TRACKING LIMITED\nLow detail"
        case .limited(.initializing):
            return "Initializing"
        case .limited(.relocalizing):
            return "Recovering from interruption"
        default:
            return "Unavailable"
        }
    }
}
