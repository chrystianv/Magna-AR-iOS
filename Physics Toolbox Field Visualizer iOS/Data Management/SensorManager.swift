//
//  SensorManager.swift
//  Physics Toolbox Field Visualizer iOS
//
//  Created by Chrystian Vieyra on 1/22/19.
//  Copyright © 2019 Vieyra Software. All rights reserved.
//

import UIKit
import CoreMotion

protocol SensorManagerDelegate {
    func onUpdate(data: SensorData)
}

class SensorManager {
    
    // MARK: - Initializing a Singleton
    static let shared = SensorManager()
    var delegate: SensorManagerDelegate?
    
    var isContinuouslyRecording = false
    var x = 0.0
    var y = 0.0
    var z = 0.0
    var net = 0.0
    
    var counter = 0
    var xAvg: [Float] = [0, 0, 0, 0]
    var yAvg: [Float] = [0, 0, 0, 0]
    var zAvg: [Float] = [0, 0, 0, 0]
    var tAvg: [Float] = [0, 0, 0, 0]
    
    var updateInterval: Double = 0.25
    var motionManager = CMMotionManager()
    
    func start() {
        motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xMagneticNorthZVertical, to: OperationQueue.current!, withHandler: {
                       (deviceMotion, error) -> Void in
           if (error == nil) {
               
               if let magField = deviceMotion?.magneticField as CMCalibratedMagneticField? {
                   
                   self.x = magField.field.x
                   self.y = magField.field.y
                   self.z = magField.field.z
                   self.net = sqrt(magField.field.x*magField.field.x + magField.field.y*magField.field.y + magField.field.z*magField.field.z)
                   self.delegate?.onUpdate(data: self.getData())
                
               } else {
                print("No magnetic field")
            }
           } else {
                print("Motion updates didn't work")
            }
        })
    }
    
    
    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    func getData() -> SensorData {
        xAvg[counter] = Float(x)
        yAvg[counter] = Float(y)
        zAvg[counter] = Float(z)
        tAvg[counter] = Float(net)
        
        counter+=1
        
        if(xAvg[3] != 0) {
            x = Double((xAvg[0] + xAvg[1] + xAvg[2] + xAvg[3])/4)
            y = Double((yAvg[0] + yAvg[1] + yAvg[2] + yAvg[3])/4)
            z = Double((zAvg[0] + zAvg[1] + zAvg[2] + zAvg[3])/4)
            net = Double((tAvg[0] + tAvg[1] + tAvg[2] + tAvg[3])/4)
        }
    
        if (counter == 4) {
            counter = 0
        }
        
        let strength = min(1, net / 1000)
        
        return SensorData(
            title: String(format: "%d", Int(net)),
            value: strength,
            radius: 0.0025,
            x: Float(x),
            y: Float(y),
            z: Float(z),
            net: Float(net)
        )
        
    }
    
    func refresh() {
        
    }
}
