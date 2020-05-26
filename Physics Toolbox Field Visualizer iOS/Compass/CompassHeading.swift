//
//  CompassHeading.swift
//  Physics Toolbox Field Visualizer iOS
//
//  Created by Chrystian Vieyra on 2/23/20.
//  Copyright © 2020 Vieyra Software. All rights reserved.
//

//
//  CompassHeading.swift
//  PhysicsToolboxSensorSuite
//
//  Created by Chrystian Vieyra on 1/22/20.
//  Copyright © 2020 Vieyra Software. All rights reserved.
//


import Foundation
import CoreLocation
import Combine

@available(iOS 13.0, *)
class CompassHeading: NSObject, ObservableObject, CLLocationManagerDelegate {
    var objectWillChange = PassthroughSubject<Void, Never>()
    var degrees: Double = .zero {
        didSet {
            objectWillChange.send()
        }
    }
    
    private let locationManager: CLLocationManager
    
    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        
        self.locationManager.delegate = self
        self.setup()
    }
    
    private func setup() {
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.headingAvailable() {
            self.locationManager.startUpdatingLocation()
            self.locationManager.startUpdatingHeading()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.degrees = -1 * newHeading.magneticHeading
    }
}
