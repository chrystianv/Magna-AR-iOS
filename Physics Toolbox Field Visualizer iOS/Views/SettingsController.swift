//
//  SettingsViewController.swift
//  Physics Toolbox Field Visualizer iOS
//
//  Created by Chrystian Vieyra on 12/27/18.
//  Copyright © 2018 Vieyra Software. All rights reserved.
//

import UIKit

class SettingsController: UITableViewController {
        
    
    // MARK: - IBOutlets
    
    
 
    
    
    @IBAction func websiteButton(_ sender: UIButton) {
      if let url = URL(string: "https://www.magna-ar.net/") {
            UIApplication.shared.open(url)
        }
    }
    
    
    @IBAction func magneticIntensityButton(_ sender: UIButton) {
        if let url = URL(string: "https://www.ngdc.noaa.gov/geomag/WMM/data/WMM2015/WMM2015v2_F_MERC.pdf") {
            UIApplication.shared.open(url)
        }
    }
    
    
    @IBAction func magneticFieldInclinationButton(_ sender: UIButton) {
        if let url = URL(string: "https://www.ngdc.noaa.gov/geomag/WMM/data/WMM2015/WMM2015v2_I_MERC.pdf") {
            UIApplication.shared.open(url)
        }
        
    }
    
    
  
    @IBAction func tutorialVideoButton2(_ sender: UIButton) {
        if let url = URL(string: "https://www.youtube.com/watch?v=OEXWNcdImsc&t") {
                         UIApplication.shared.open(url)
                     }
    }
    
    
    @IBOutlet weak var visualizationTypeToggle: UISegmentedControl!
    @IBOutlet weak var showNumericalValueToggle: UISwitch!
    @IBOutlet weak var scaleVectorToggle: UISwitch!
    @IBOutlet weak var emailButton: UIButton! {
        didSet {
            emailButton.layer.cornerRadius = 5
         }
    }
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        load()
        tableView.allowsSelection = false
        tableView.tableFooterView = UIView()
    }
    
    @IBOutlet weak var heatMapToggleOutlet: UISwitch!
    
    @IBAction func heatMapToggleAction(_ sender: UISwitch) {
        DataManager.shared.heatmapIsOn.toggle()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        load()
    }
    
    func load() {
        visualizationTypeToggle.selectedSegmentIndex = DataManager.shared.visualizationType == .arrow ? 0 : 1
        showNumericalValueToggle.isOn = DataManager.shared.numericalValueIsVisible
//        scaleVectorToggle.isOn = DataManager.shared.vectorsAreScaled
        heatMapToggleOutlet.isOn = DataManager.shared.heatmapIsOn
    }
    
    // MARK: - IBActions
    @IBAction func toggleVisualizationType(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            DataManager.shared.visualizationType = .arrow
        } else {
            DataManager.shared.visualizationType = .sphere
        }
    }
    
    @IBAction func toggleScaleVector(_ sender: Any) {
        DataManager.shared.vectorsAreScaled.toggle()

    }
    
    @IBAction func toggleNumericalValue(_ sender: UISwitch) {
        DataManager.shared.numericalValueIsVisible.toggle()
    }
    
    // Secondary actions
    @IBAction func pressDone(_ sender: Any) {
        self.dismiss(animated: true, completion: {
            DataManager.shared.saveSettings()
        })
    }
        
    @IBAction func email(_ sender: Any) {
        let email = "support@vieyrasoftware.net"
        if let url = NSURL(string: "mailto:\(email)") {
         UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
        }
    }
}
