//
//  CSVExporter.swift
//  Physics Toolbox Field Visualizer iOS
//
//  Created by Chrystian Vieyra on 10/9/18.
//  Copyright © 2018 Vieyra Software. All rights reserved.
//

import Foundation
import UIKit

class CSVExporter {
    
    var fileName = "sensor.csv"
    var path: URL?
    
    var CSVData: String = ""
    
    init() {
        setup()
    }
    
    init(withFileName fileName: String) {
        self.fileName = fileName
        setup()
    }
    
    private func setup() {
        self.path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(self.fileName)
        
    }
    
    func addToCSVData(_ data: String) {
        CSVData.append(data)
        CSVData.append("\n")
        //   print(CSVData)
    }
    
    func storeCSVData() -> URL? {
        do {
            try self.CSVData.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
            return path!
        } catch {
            print("Failed to create file")
            print("\(error)")
            return nil
        }
        
    }
    
    func eraseCSVData() {
        CSVData = ""
    }
    
}
