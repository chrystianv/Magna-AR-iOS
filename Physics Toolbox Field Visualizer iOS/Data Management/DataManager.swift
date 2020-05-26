//
//  DataManager.swift
//  Physics Toolbox Field Visualizer iOS
//
//  Created by Tyler Angert on 10/30/19.
//  Copyright © 2019 Vieyra Software. All rights reserved.
//

// A singleton that's used to reference settings and global variables  across the app.
// Also saves to user defaults.

import Foundation

// Delegates for sharing resources across the app.
protocol DataManagerDelegate {
    func setVisualizationType()
    func toggleNumericalValue()
    func toggleScaleVectors()
    func toggleHeatmapVectors()
}

class DataManager {
    
    static let shared = DataManager()
    var delegate:  DataManagerDelegate?
    let preferences = UserDefaults.standard
    
    // MARK: - Settings
    var visualizationType: VisualizationType = .arrow {
        didSet {
            delegate?.setVisualizationType()
        }
    }
    var numericalValueIsVisible: Bool = false {
        didSet {
            delegate?.toggleNumericalValue()
        }
    }
    
    var scaleGraphDisplayed: Bool = false{
        
        didSet {
                delegate?.toggleScaleVectors()
            }
        }
    
    var vectorsAreScaled: Bool = false {
        didSet {
            delegate?.toggleScaleVectors()
        }
    }
    
    var heatmapIsOn: Bool = false {
          didSet {
            delegate?.toggleHeatmapVectors()
          }
      }
    
    func loadSettings() {
        // Load up from user defaults
        if preferences.object(forKey: "visualizationType") != nil {
            DataManager.shared.visualizationType = preferences.integer(forKey: "visualizationType") == 0 ? .arrow : .sphere
        } else {
            print("no visualizationType")
        }
        
        if preferences.object(forKey: "numericalValueIsVisible") != nil {
            DataManager.shared.numericalValueIsVisible = preferences.bool(forKey: "numericalValueIsVisible")
        } else {
          print("no numerical value")
        }
        
        if preferences.object(forKey: "vectorsAreScaled") != nil {
            DataManager.shared.vectorsAreScaled = true
        } else {
          print("no vector scaling value")
        }
    }
    
    func saveSettings() {
        print("Saving settinggs")
        // Save settings and previous state to user defaults.
        preferences.set(DataManager.shared.visualizationType == .arrow ? 0 : 1, forKey: "visualizationType")
        preferences.set(DataManager.shared.numericalValueIsVisible, forKey: "numericalValueIsVisible")
        preferences.set(DataManager.shared.vectorsAreScaled, forKey: "vectorsAreScaled")
    }
}
