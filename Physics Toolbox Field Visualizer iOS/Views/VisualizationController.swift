//
//  VisualizationController.swift
//  Physics Toolbox Field Visualizer iOS
//
//  Created by Chrystian Vieyra on 1/22/19.
//  Copyright © 2019 Vieyra Software. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import CoreMotion
import CoreLocation
import ReplayKit
import FlexLayout
import PinLayout

/**
 TODO:
 1. Fix message views / alerts
 2. reveal / focus detail on arrow when clicked (increase size of chosen arrrow, and shrink the rest
 3. Fix the ID generation and duplicate arrows
 
 // INITIALIZE -> full screen to calibrate ( move around )
 // NORMAL / MORE LIGHT -> toast and then disable interaction on primary controls.
 //  DEMAGNETIZE -> full screen to calibrate ( move in a figure 8)
 */

class VisualizationController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    var label = UILabel()
    lazy var motionManager = CMMotionManager()
    
    // TODO: Record video
    let kLightThreshold: CGFloat = 500
    
    @IBOutlet weak var sceneView: ARSCNView!

    // MARK: - Secondary UI elements
    // Messaging
    let greetingContainer = UIView()
    let greetingLabel = UILabel()
    let greetingArrow = UIImageView(image: UIImage(named: "Greeting-Arrow"))
    let screenshotFlash = UIView()
    let fullScreenCover = UIView()
    let fullScreenMessage = UILabel()
    let demagnetizeImage = UIImageView(image: UIImage(named: "Demagnetized"))
    let toast = UILabel()
    
    // MARK: - UI elements
    // Contains all of the 2d controls for the UI
    let rootContainer = UIView()

    // Top buttons
    let resetButton = UIButton(type: .custom)
    let moreButton = UIButton(type: .custom)
    let totalFieldLabel = UIButton(type: .custom)
    
      let scaleImage = UIImageView(image: UIImage(named: "scaleAsset"))


    
    // Contains all of the x,y,z labels and elements that can easily be toggled on and off.
    // TODO: Make a toast appear for in app messages below the subvalues container.
    let subValuesContainer = UIView()
    let xValLabel = UIButton()
    let xLabel = UILabel()
    let yValLabel = UIButton()
    let yLabel = UILabel()
    let zValLabel = UIButton()
    let zLabel = UILabel()

    // Bottom buttons
    let screenshotOuterRing = UIView()
    let screenshotButton = UIButton(type: .custom)
    let recordOuterRing = UIView()
    let recordButton = UIButton(type: .custom)
    let compassButton = UIButton(type: .custom)
    
    
    var lightFeedback = UIImpactFeedbackGenerator(style: .light)

    // Mark - main runtime storage
    // Magnet and arrow data
    var vectors: [String: Vector] = [String: Vector]() {
        didSet {
            if vectors.count > 0 {
                greeting(isIn: false)
            }
        }
    }
    
    var compassNodes = [SCNNode]()
    
    // MARK: - State
    var isRecording = false
    var state: RecordingState = .startARSession {
        didSet {
            visualizationViewControllerDidChangeState(state)
        }
    }
    
    let fadedOpacity: CGFloat = 0.4
    var touchIsDisabled = false
    var cameraAllowed = false
    
    // TODO: add back warnings for limits
    var vizWarning: VizualizationWarning? {
        didSet {
            if let warn = vizWarning {
                updateTimer?.invalidate()
                updateTimer = nil
                DispatchQueue.main.async {
                    self.toast.text = warn.recommendation
                    UIView.animate(withDuration: 1.0) {
                        self.toast.alpha = 1
                        if self.greetingContainer.alpha == 1 {
                            self.greetingContainer.alpha = 0
                        }
                        self.screenshotOuterRing.alpha = self.fadedOpacity
                        self.screenshotButton.alpha = self.fadedOpacity
                        self.recordOuterRing.alpha = self.fadedOpacity
                        self.recordButton.alpha = self.fadedOpacity
                        self.compassButton.alpha = self.fadedOpacity
                        self.touchIsDisabled = true
                    }
                }
            } else {
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 1.0) {
                        self.toast.alpha = 0
                        if self.greetingContainer.alpha == 0 {
                            self.greetingContainer.alpha = 1
                        }
                        self.screenshotOuterRing.alpha = 1
                          self.screenshotButton.alpha = 1
                          self.recordOuterRing.alpha = 1
                          self.recordButton.alpha = 1
                          self.compassButton.alpha = 1
                          self.touchIsDisabled = false
                        
                    }
                }
            }
        }
    }
    
    var isDemagnetized = false {
        didSet {
            // trigger full screen
            if isDemagnetized {
                updateTimer?.invalidate()
                updateTimer = nil
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 1.0) {
                        self.fullScreenCover.alpha = 1
                        self.fullScreenMessage.alpha = 1
                        self.rootContainer.alpha = 0.05
                    }
                }
            } else {
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 1.0) {
                          self.fullScreenCover.alpha = 0
                          self.fullScreenMessage.alpha = 0
                          self.rootContainer.alpha = 1
                      }
                  }
            }
        }
    }
    
    // Miscellaneous vars
    var updateTimer: Timer?
    var compassIsPressed = false
    var subValuesAreVisible = false
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Book keeping and permissions
        checkCameraPermission()
        lightFeedback.prepare()
        
        // UI Setup and binding
        DispatchQueue.main.async {
              self.setupUI()
              self.setupUIActions()
              // Greet the user
              self.greeting(isIn: true)
          }
    
        // Prevent the screen from being dimmed after a while.
        UIApplication.shared.isIdleTimerDisabled = true
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Singleton setup
        SensorManager.shared.delegate = self
        SensorManager.shared.start()
        DataManager.shared.delegate = self
            
        // Make sure the application launches in .startARSession state.
        // Entering this state will run() the ARSession.
        updateRecordingState(to: .startARSession)
        
        // Add these initially to the scene and then just turn the alpha on/off.
        for direction in CompassPoints.defaults {
            let s = direction.sphere()
            let t = direction.text()
            compassNodes.append(s)
            compassNodes.append(t)
            sceneView.scene.rootNode.addChildNode(s)
            sceneView.scene.rootNode.addChildNode(t)
        }
        for c in compassNodes {
            c.opacity = 0
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SensorManager.shared.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SensorManager.shared.stop()
    }
    
    // MARK: - Programattic UI
    func setupUI() {
        
        //////////////////////////
        //Main elements
        // Root container
        self.view.addSubview(rootContainer)
        rootContainer.clipsToBounds = true
        rootContainer.backgroundColor = UIColor.clear
        rootContainer.pin.all()
        
        // GLOBAL STYLE PROPERTIES
        let textColor = UIColor.white
        let blurStyle = UIBlurEffect.Style.regular
        
        //////////////////////////////////////////////////////
        //////////////////////////////////////////////////////
        // PROPERTY SETUP CODE
        //////////////////////////////////////////////////////
        //////////////////////////////////////////////////////
        
        // Todo: Make extensions for rounding
        // Components
        // Top buttons
        resetButton.blur(with: blurStyle, alpha: 1.0)
        moreButton.blur(with: blurStyle, alpha: 1.0)
        
        // Bottom buttons
        // base for record button.
        recordOuterRing.blur(with: blurStyle, alpha: 1.0)
        recordOuterRing.layer.borderWidth = 2
        recordOuterRing.layer.borderColor = UIColor.white.cgColor
        
        
        screenshotOuterRing.blur(with: blurStyle, alpha: 1.0)
        screenshotOuterRing.layer.borderWidth = 4
        screenshotOuterRing.layer.borderColor = UIColor.white.cgColor

        
        compassButton.blur(with: blurStyle, alpha: 1.0)
        
        // Top labels
        totalFieldLabel.blur(with: blurStyle, alpha: 1.0)
        totalFieldLabel.layer.cornerRadius = 10
        totalFieldLabel.setTitle("50 μT", for: .normal)
        totalFieldLabel.setTitleColor(textColor, for: .normal)
        totalFieldLabel.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        totalFieldLabel.titleLabel?.textAlignment = .center
        
        // Containers
        // Specific values
        // Initialize visibility to 0
        subValuesContainer.alpha = 0
        
        // X
        xValLabel.blur(with: blurStyle, alpha: 1.0, color: UIColor.red.withAlphaComponent(0.5))
        xValLabel.setTitleColor(textColor, for: .normal)
        xValLabel.setTitle("50", for: .normal)
        xValLabel.titleLabel?.textAlignment = .center
        xValLabel.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        xLabel.textColor = UIColor.white
        xLabel.text = "X"
        xLabel.font = UIFont.systemFont(ofSize: 15, weight: .black)
        xLabel.textAlignment = .center
        
        // Y
        yValLabel.blur(with: blurStyle, alpha: 1.0, color: UIColor.green.withAlphaComponent(0.5))
        yValLabel.setTitleColor(textColor, for: .normal)
        yValLabel.setTitle("50", for: .normal)
        yValLabel.titleLabel?.textAlignment = .center
        yValLabel.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        yLabel.textColor = UIColor.white
        yLabel.text = "Y"
        yLabel.font = UIFont.systemFont(ofSize: 15, weight: .black)
        yLabel.textAlignment = .center
        
        // Z
        zValLabel.blur(with: blurStyle, alpha: 1.0, color: UIColor.blue.withAlphaComponent(0.5))
        zValLabel.setTitleColor(textColor, for: .normal)
        zValLabel.setTitle("50", for: .normal)
        zValLabel.titleLabel?.textAlignment = .center
        zValLabel.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        zLabel.textColor = UIColor.white
        zLabel.text = "Z"
        zLabel.font = UIFont.systemFont(ofSize: 15, weight: .black)
        zLabel.textAlignment = .center
                
        //Greeting stuff
        greetingLabel.text = "Tap anywhere to visualize magnetometer data"
        greetingLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        greetingLabel.textColor = .white
        greetingLabel.numberOfLines = 3
        greetingLabel.textAlignment = .center
        
        // Toast
        // Toast
        toast.roundCorners(amount: 5)
//        toast.blur(with: .dark, alpha: 1.0)
        toast.textColor = UIColor.white
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        toast.textAlignment = .center
        toast.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        toast.alpha = 0
        
        let width = self.view.frame.width
        
        //////////////////////////////////////////////////////
        //////////////////////////////////////////////////////
        // LAYOUT CODE
        //////////////////////////////////////////////////////
        //////////////////////////////////////////////////////
        
        // Add everything together
        rootContainer.flex.alignItems(.center).justifyContent(.spaceBetween).define { (flex) in
            // Initial padding for the entire container
            flex.padding(width*0.15, width*0.1, width*0.1, width*0.1)
            /////////////////////////
            // Top controls
            /////////////////////////
            
            flex.addItem()
                .alignItems(.center)
                .direction(.column)
                .width(100%)
                
                .define({ (flex) in
                    
                    // TOP CONTROLS
                    flex.addItem()
                        .justifyContent(.spaceBetween)
                        .direction(.row)
                        .width(100%)
                        .define({ (flex) in
                            
                            // Settings button
                            flex.addItem(moreButton).size(50)
                            
                            // Labels
                            let labelSize: CGFloat = 50
                            flex.addItem().alignItems(.center).define({ (flex) in
                                // Tottal field label
                                flex.addItem(totalFieldLabel).width(labelSize*2.25).height(labelSize).marginBottom(20)
                                // Value labels
                                subValuesContainer.flex.addItem().direction( .row).alignItems(.stretch).justifyContent(.center).define({ (flex) in
                                    // X Value
                                    flex.addItem().width(labelSize).height(labelSize/1.5).define({ (flex) in
                                        flex.addItem(xValLabel).marginBottom(5)
                                        flex.addItem(xLabel)
                                    })
                                    // Y Value
                                    flex.addItem().width(labelSize).height(labelSize/1.5).marginLeft(10).marginRight(10).define({ (flex) in
                                        flex.addItem(yValLabel).marginBottom(5)
                                        flex.addItem(yLabel)
                                    })
                                    // Z Value
                                    flex.addItem().width(labelSize).height(labelSize/1.5).define({ (flex) in
                                        flex.addItem(zValLabel).marginBottom(5)
                                        flex.addItem(zLabel)
                                    })
                                })
                                // Add it as a container so all the values can easily be toggled on/off.
                                flex.addItem(subValuesContainer)
                            })
                            
                            // Reset button
                            flex.addItem(resetButton).size(50)
                        })
                    
                    // TOAST
                    flex.addItem(toast).width(250).height(50)
                })

            
            ///////////////////////////////////////////
            // GREETING IN THE MIDDLE (Hidden at first)
            ///////////////////////////////////////////
            greetingContainer.flex.alignItems(.center).wrap(.wrap).marginTop(-25).define { (flex) in
                flex.addItem(greetingArrow).marginTop(10)
                flex.addItem(greetingLabel).marginTop(10)
                
              
                
            //    moreButton.addIcon(imageName: "More")
            }
            
            // TODO: slight offset to place back into center
            flex.addItem(greetingContainer)
            
            /////////////////////////
            // Bottom controls
            /////////////////////////
            flex.addItem()
                .width(100%)
                .justifyContent(.spaceBetween)
                .direction(.row)
                .alignItems(.end)
                .define({ (flex) in
                    
                    // Compass on/off
                    flex.addItem(compassButton).size(50)
                    
                    // Screenshot
                    flex.addItem(screenshotOuterRing).size(70)
                    
                    // Record / auto tap
                    flex.addItem(recordOuterRing).size(50)
                })
            
        }
        
        rootContainer.flex.layout(mode: .fitContainer)
        
        //////////////////////////////////////////////////////
        //////////////////////////////////////////////////////
        // POST LAYOUT PROPERTIES
        //////////////////////////////////////////////////////
        //////////////////////////////////////////////////////
        //Add  icons
        // Reset button
        resetButton.round()
        // Offset an extra 1 pixel
        resetButton.addIcon(imageName: "Reset", extraDx: 1, extraDy: 0)
        
        // Add the record button now that its outer ring position was calculated.
        recordOuterRing.addSubview(recordButton)
     //recordButton.backgroundColor = UIColor.red.withAlphaComponent(0.6)
       
        recordButton.setImage(UIImage.init(named: "finger"), for: .normal)
        recordButton.imageEdgeInsets = UIEdgeInsets(top: 7.5, left: 7.5, bottom: 7.5, right: 9.5)
        
        // Initialize the frame
        recordButton.frame = CGRect(x: 0, y: 0, width: recordOuterRing.frame.width * 0.80, height: recordOuterRing.frame.height * 0.80)
        // Center it based on the outer ring
        recordButton.center = CGPoint(x: recordOuterRing.bounds.midX, y: recordOuterRing.bounds.midY)
        recordButton.round()
        recordOuterRing.round()
        
        // Handle the screenshot button
        screenshotOuterRing.addSubview(screenshotButton)
        screenshotButton.backgroundColor = UIColor.white
        // Initialize the frame
        screenshotButton.frame = CGRect(x: 0, y: 0, width: screenshotOuterRing.frame.width * 0.80, height: screenshotOuterRing.frame.height * 0.80)
        // Center it based on the outer ring
        screenshotButton.center = CGPoint(x: screenshotOuterRing.bounds.midX, y: screenshotOuterRing.bounds.midY)
        screenshotButton.round()
        screenshotOuterRing.round()

        
        
        // Handle the reset of the buttons
        moreButton.round()
        moreButton.addIcon(imageName: "More")
        
        recordButton.round()
        
        compassButton.round()
        compassButton.addIcon(imageName: "Compass")
        
        totalFieldLabel.roundCorners(amount: 10)
        xValLabel.roundCorners(amount: 5)
        yValLabel.roundCorners(amount: 5)
        zValLabel.roundCorners(amount: 5)
        
        // SCREENSHOT FLASH
        self.view.addSubview(screenshotFlash)
        screenshotFlash.backgroundColor = UIColor.white
        screenshotFlash.isUserInteractionEnabled = false
        screenshotFlash.alpha = 0
        screenshotFlash.pin.all()
        
        // SCREENSHOT FLASH
        fullScreenCover.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        fullScreenCover.isUserInteractionEnabled = false
        fullScreenCover.alpha = 0
        fullScreenCover.pin.all()

        fullScreenMessage.text = "Your device appears to have magnetized. Move your phone in a figure-8 motion until this message goes away."
        fullScreenMessage.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        fullScreenMessage.textColor = .white
        fullScreenMessage.numberOfLines = 4
        fullScreenMessage.textAlignment = .center
        
        fullScreenMessage.frame = CGRect(x: (width-width*0.75)/2, y: self.view.frame.height/2 - 175, width: width*0.75, height: 200)
        demagnetizeImage.frame = CGRect(x: (width-200)/2, y: self.view.frame.height/2 - 25, width: 200, height: 100)
        
          scaleImage.frame = CGRect(x: (width + 250)/2, y: self.view.frame.height/3 , width: 47, height: 323)
     scaleImage.alpha = 0
   //     scaleImage.alpha = 0.5

        
        
        fullScreenCover.addSubview(fullScreenMessage)
        fullScreenCover.addSubview(demagnetizeImage)
        //fullScreenCover.addSubview(scaleImage)

         self.fullScreenCover.alpha = 1
        self.view.addSubview(fullScreenCover)
        self.view.addSubview(scaleImage)
        
    }
    
    // Do this whenever you restart, up until you notice the count go up
    func greeting(isIn: Bool) {
        if isIn {
            UIView.animate(withDuration: 0.5, animations: {
                self.greetingContainer.alpha = 1
            }) { (_) in
                UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat, .autoreverse], animations: {
                    self.greetingArrow.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                }, completion: nil)
            }
        } else {
            UIView.animate(withDuration: 1.0, animations: {
                self.greetingContainer.alpha = 0
            })
        }
    }
    
    func setupUIActions() {
        // Top buttons and content
        // Reset
        resetButton.addTarget(self, action: #selector(pressDownReset(_:)), for: .touchDown)
        resetButton.addTarget(self, action: #selector(pressUpReset(_:)), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(pressUpReset(_:)), for: .touchDragExit)
        
        // More
        moreButton.addTarget(self, action: #selector(pressDownMore(_:)), for: .touchDown)
        moreButton.addTarget(self, action: #selector(pressUpMore(_:)), for: .touchUpInside)
        moreButton.addTarget(self, action: #selector(pressUpMore(_:)), for: .touchDragExit)

        // Total Field
        totalFieldLabel.addTarget(self, action: #selector(pressTotalFieldLabel(_:)), for: .touchUpInside)
        totalFieldLabel.addTarget(self, action: #selector(pressTotalFieldLabel(_:)), for: .touchDragExit)
        
        
        // Record
        recordButton.addTarget(self, action: #selector(pressDownRecord(_:)), for: .touchDown)
        recordButton.addTarget(self, action: #selector(pressUpRecord(_:)), for: .touchUpInside)
        recordButton.addTarget(self, action: #selector(pressUpRecord(_:)), for: .touchDragExit)
        
        // Screenshot
        screenshotButton.addTarget(self, action: #selector(pressDownScreenshot(_:)), for: .touchDown)
        screenshotButton.addTarget(self, action: #selector(pressUpScreenshot), for: .touchUpInside)
        screenshotButton.addTarget(self, action: #selector(pressUpScreenshot), for: .touchDragExit)

        // Compass
        compassButton.addTarget(self, action: #selector(pressDownCompass(_:)), for: .touchDown)
        compassButton.addTarget(self, action: #selector(pressUpCompass(_:)), for: .touchUpInside)
        compassButton.addTarget(self, action: #selector(pressUpCompass(_:)), for: .touchDragExit)
    }
    
    // Top functions
    // Reset  button
    @objc private func pressDownReset(_ sender: UIButton?) {
        sender?.backgroundColor = UIColor.white
        let icon = (sender!.subviews.filter({$0 is UIImageView })).first as! UIImageView
        icon.transitionImage(newImage: "Reset-Pressed")
    }
    
    @objc private func pressUpReset(_ sender: UIButton?) {
        state = .startARSession
        SensorManager.shared.refresh()
        
        // Remove all nodes from the view and empty out the array
        for v in vectors.values {
            v.parentNode.removeFromParentNode()
        }
        vectors.removeAll()
        
        // Send a message to clear
        sender?.backgroundColor = UIColor.clear
        let icon = (sender!.subviews.filter({$0 is UIImageView })).first as! UIImageView
        icon.transitionImage(newImage: "Reset")
        
        // Also want to reset the rest of the buttons
        pressUpMore(moreButton)
        
        if compassIsPressed {
            pressDownCompass(compassButton)
        }
        
        // TODO: Clean up state handling and management into one central dispatcher...
        // Update the recording state
        updateRecordingState(to: .startARSession)
//        greeting(isIn: true)
    }
    
    // More button
    @objc private func pressDownMore(_ sender: UIButton?) {
        sender?.backgroundColor = .white
        let icon = (sender!.subviews.filter({$0 is UIImageView })).first as! UIImageView
        icon.transitionImage(newImage: "More-Pressed")

        let menu = storyboard!.instantiateViewController(withIdentifier: "settingsContainerController")
        present(menu, animated: true, completion: {
             self.pressUpMore(self.moreButton)
        })
    }
    
    @objc private func pressUpMore(_ sender: UIButton?) {
        sender?.backgroundColor = .clear
        let icon = (sender!.subviews.filter({$0 is UIImageView })).first as! UIImageView
        icon.transitionImage(newImage: "More")
    }
    
    // Total field
    @objc private func pressTotalFieldLabel(_ sender: UIButton?) {
        subValuesAreVisible.toggle()
        if subValuesAreVisible {
            UIView.animate(withDuration: 0.2) {
                self.subValuesContainer.alpha = 1
            }
        } else {
            UIView.animate(withDuration: 0.2) {
                self.subValuesContainer.alpha = 0
            }
        }
    }
        
    // SCREENSHOT / RECORD FUNCTIONS
    @objc private func pressDownRecord(_ sender: UIButton?) {
        // 1. animate recording UI
        lightFeedback.impactOccurred()
        if isRecording {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.25, animations: {
                      self.recordButton.transform = CGAffineTransform.identity
                      self.recordButton.round()
                      self.recordButton.backgroundColor = UIColor.red.withAlphaComponent(0.6)
                  })
            }
        } else {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.35, delay: 0.1, options: .curveEaseOut, animations: {
                    self.recordButton.transform = CGAffineTransform(scaleX: 0.65, y: 0.65)
                    self.recordButton.layer.cornerRadius = 12.5
                    self.recordButton.backgroundColor = UIColor.red.withAlphaComponent(0.8)
                }, completion: nil)
            }
        }
            
        isRecording.toggle()
    }
    
    @objc private func pressUpRecord(_ sender: UIButton?) {
        // 2. start recording data once released
        if isRecording {
            updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (timer) in
                let data = SensorManager.shared.getData()
                self.addVector(with: data, type: DataManager.shared.visualizationType)
            })
        } else {
            updateTimer?.invalidate()
            updateTimer = nil
        }
    }
    
    @objc private func pressDownScreenshot(_ sender: UIButton?) {
        lightFeedback.impactOccurred()
        
        UIView.animate(withDuration: 0.1, animations: {
            self.screenshotButton.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
            self.screenshotFlash.alpha = 0.5
        }) { (completed) in
            UIView.animate(withDuration: 0.1) {
                self.screenshotFlash.alpha = 0
            }
        }
        // Check conditions before saving screen shot (lighting conditions and what not)
        let sourceImage = sceneView.snapshot()
        UIImageWriteToSavedPhotosAlbum(sourceImage, nil, nil, nil)
    }
    
    @objc private func pressUpScreenshot(_ sender: UIButton?) {
        UIView.animate(withDuration: 0.2) {
            self.screenshotButton.transform = CGAffineTransform.identity
        }
    }
        
    // Compass
    @objc private func pressDownCompass(_ sender: UIButton?) {
        compassIsPressed.toggle()
        if compassIsPressed {
            sender?.backgroundColor = .white
            let icon = (sender!.subviews.filter({$0 is UIImageView })).first as! UIImageView
            icon.transitionImage(newImage: "Compass-Pressed")
            UIView.animate(withDuration: 0.2) {
                for c in self.compassNodes {
                    c.opacity = 1
                }
            }
        } else {
            sender?.backgroundColor = .clear
            let icon = (sender!.subviews.filter({$0 is UIImageView })).first as! UIImageView
            icon.transitionImage(newImage: "Compass")
            UIView.animate(withDuration: 0.2) {
                for c in self.compassNodes {
                    c.opacity = 0
                }
            }
        }
    }
    
    @objc private func pressUpCompass(_ sender: UIButton?) {
    }
    
    // MARK: - Primary frame listener
     func session(_ session: ARSession, didUpdate frame: ARFrame) {
         // Go through all of the nodes, calculate their disitance from the current point of view
         // Then adjust the opacity  of the text node (if it's visible)
         // This avoids visual clutter when there are a lot of nodes and encouroages exploration of space
         if DataManager.shared.numericalValueIsVisible {
             guard let POV = sceneView.pointOfView else { return }
             var distance: Float = 0.0
             for v in vectors.values {
                distance = POV.position.distance(from: v.position)
                v.textPlane.opacity = CGFloat(1/(distance*10))
             }
         }
     }
        
    // MARK: - Touch handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !touchIsDisabled {
            // Send events to add arrows and change the UI state
            if !isDemagnetized {
                self.addVector(with: SensorManager.shared.getData(), type: DataManager.shared.visualizationType)
            }
        }
    }
        
    // MARK: - ARKit
    func initializeScene() {
        // Make sure the SCNScene is cleared of any SCNNodes from previous scans.
        sceneView.scene = SCNScene()
        
        // Add lighting for the nodes.
        sceneView.autoenablesDefaultLighting = false
        
        let light = SCNLight()
        light.type = .omni
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(0, 7.5, 0)
        sceneView.scene.rootNode.addChildNode(lightNode)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.environmentTexturing = .automatic
        configuration.isLightEstimationEnabled = true
        
        // CHANGE WORLD ALIGNMENT
        // Android version also only uses gravity at first
        configuration.worldAlignment = .gravity
        
        sceneView.session.run(configuration, options: .resetTracking)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Application lifecycle
    
    @objc func applicationWillResignActive(_ notification: Notification) {
//        messageView.isHidden = true
    }
    
    @objc func applicationDidBecomeActive(_ notification: Notification) {
    }
    
    
    // MARK: - Update TrackingState
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateState(with: camera.trackingState)
        switch camera.trackingState {
        case .notAvailable:
            vizWarning = .notAvailable

        case .limited(let reason):
            vizWarning = .cameraTracking(reason)

        case .normal:
            vizWarning = nil
        }
    }
    
    // MARK: - Update State
    
    func visualizationViewControllerDidChangeState(_ state: RecordingState) {
        switch state {
        case .startARSession:
            print("State: Starting ARSession")
            vizWarning = nil
            initializeScene()
        case .notReady:
            print("State: Not ready to scan")
        case .ready:
            print("State: Ready")
        }
    }
    
    
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
//        guard let frame = sceneView.session.currentFrame else {
//            return
//        }
//        switch state {
//        case .ready:
//            if let lightEstimate = frame.lightEstimate, lightEstimate.ambientIntensity < kLightThreshold {
//                vizWarning = .tooDark
//            }
//        default:
//            break
//        }
    }
    
    func getSceneSpacePosition(inFrontOf node: SCNNode, atDistance distance: Float) -> SCNVector3 {
        let localPosition = SCNVector3(x: 0, y: 0, z: -distance)
        let scenePosition = node.convertPosition(localPosition, to: nil)
        return scenePosition
    }
    
    func addVector(with data: SensorData, type: VisualizationType) {
        
        guard let POV = sceneView.pointOfView else { return }
        if isDemagnetized { return }
        
        // First calculate the nearest grid point
        // Make the size/scale values global constants
        var gridPos = SCNVector3()
        let gridCubeSize: Float = Float(BASE_ARROW_SCALE * 1.25)
        let camPos = getSceneSpacePosition(inFrontOf: POV, atDistance: 0.025)
        
        gridPos.x = Float((round(camPos.x/gridCubeSize) * gridCubeSize).truncate(places: 3))
        gridPos.y = Float((round(camPos.y/gridCubeSize) * gridCubeSize).truncate(places: 3))
        gridPos.z = Float((round(camPos.z/gridCubeSize) * gridCubeSize).truncate(places: 3))
        
        let vector = Vector()
        vector.type = type
        vector.position = gridPos
        vector.setText(text: "\(Int(data.net))")
        vector.data = data
                        
        if !DataManager.shared.numericalValueIsVisible {
            vector.hideText()
        } else {
            vector.showText()
        }
                
        // Original magnetic vector as a simd object
        let mag = SIMD3<Float>(data.x, data.y, data.z)
        
        // You have to take the point of view's transform's orientation.
        let field = POV.simdTransform.orientation.act(mag)
        
        // south calcualted based on worrld orientation
        let south = SIMD3<Float>(0, -1, 0)
        let r1 = simd_quatf(from: south, to: field.normalized())
        let rotation = SCNQuaternion(r1.vector.x, r1.vector.y, r1.vector.z, r1.vector.w)
                
        // this can be much better
        let arrowID = "x:\(gridPos.x)_y:\(gridPos.y)_z:\(gridPos.z)"
        var hue = CGFloat(data.value) * 200 / 255
        
        hue = fmod(hue + CGFloat(220)/360.0, 1.0)
        
          print(hue)
      //  print(data.value * 1000 )
        if((data.value * 1000 ) > 0)
        {
            hue = 0.6507537293278315
        }
        
        if(data.value * 1000 > 55)
              {
                  hue = 0.6407537293278315
              }
        
        if(data.value * 1000 > 65)
              {
                  hue = 0.6307537293278315
              }
        
        if(data.value * 1000 > 75)
              {
                  hue = 0.6207537293278315
              }
        
        if(data.value * 1000 > 85)
              {
                  hue = 0.6107537293278315
              }
        
        if(data.value * 1000 > 95)
              {
                  hue = 0.6007537293278315
              }
        
        if(data.value * 1000 > 105)
              {
                  hue = 0.5907537293278315
              }
        
        if(data.value * 1000 > 115)
              {
                  hue = 0.17226340699040033
              }
        
        if(data.value * 1000 > 135)
                    {
                        hue = 0.16226340699040033
                    }
        
      if(data.value * 1000 > 155)
                       {
                           hue = 0.15226340699040033
                       }
        
        if(data.value * 1000 > 175)
                         {
                             hue = 0.14226340699040033
                         }
        if(data.value * 1000 > 195)
                         {
                             hue = 0.13226340699040033
                         }
        
        if(data.value * 1000 > 235)
                         {
                             hue = 0.049157651016135784
                         }
        if(data.value * 1000 > 275)
                               {
                                   hue = 0.045157651016135784
                               }
        
        if(data.value * 1000 > 315)
                                  {
                                      hue = 0.043157651016135784
                                  }
        
        if(data.value * 1000 > 355)
                                  {
                                      hue = 0.042157651016135784
                                  }
        
        if(data.value * 1000 > 395)
                                        {
                                            hue = 0.041157651016135784
                                        }
        if(data.value * 1000 > 435)
                                               {
                                                   hue = 0.0030263703788808716
                                               }
        
        
        if let currArrow = vectors[arrowID] {
            currArrow.hue = hue
            currArrow.setText(val: Int(SensorManager.shared.net))
            
            let scaleIn = SCNAction.scale(to: BASE_ARROW_SCALE * 2.5, duration: 0.125)
            let scaleOut = SCNAction.scale(to: BASE_ARROW_SCALE * 1.5, duration: 0.125)
            let observedAnimation = SCNAction.sequence([scaleIn, scaleOut])
            
            if !(currArrow.parentNode.rotation == rotation) {
                currArrow.parentNode.rotation = SCNVector4Zero
                currArrow.parentNode.localRotate(by: rotation)
                currArrow.data = data
                currArrow.scale(intensity: DataManager.shared.vectorsAreScaled)
            }
            
            currArrow.parentNode.runAction(observedAnimation)
            
        } else {
            // Add the arrow to the dictionary if it's not found
            vector.hue = hue
            
            let newScaleFactor: CGFloat = BASE_ARROW_SCALE * 1.5
            
            // Initially set the scale to 0 so that it  can animate in once it's added to the scene
            vector.parentNode.scale = SCNVector3Zero
            vector.parentNode.localRotate(by: rotation)
            vector.setText(val: Int(SensorManager.shared.net))
            
            
            vector.textPlane.pivot = SCNMatrix4Rotate(vector.textPlane.pivot, .pi, 0, 1, 0)
            let lookAt = SCNLookAtConstraint(target: sceneView.pointOfView)
            lookAt.isGimbalLockEnabled = true
            vector.textPlane.constraints = [lookAt]
            
            vector.id = arrowID
            vectors[arrowID] = vector
            sceneView.scene.rootNode.addChildNode(vector.parentNode)
            
            // After you add  it to the scene, animate the scale in
            let animateScale = SCNAction.scale(to: newScaleFactor, duration: 0.1)
            vector.scale(intensity: DataManager.shared.vectorsAreScaled)
            vector.parentNode.runAction(animateScale)
            lightFeedback.impactOccurred()
        }
        
    }

    //animation to move vectors slightly up and down
    private func moveUpDown(node: SCNNode) {
        let moveUp = SCNAction.moveBy(x: 0, y: 0.006, z: 0, duration: 0.5)
        moveUp.timingMode = .easeInEaseOut
        let moveDown = SCNAction.moveBy(x: 0, y: -0.006, z: 0, duration: 0.5)
        moveDown.timingMode = .easeInEaseOut
        let moveSequence = SCNAction.sequence([moveUp, moveDown])
        let moveLoop = SCNAction.repeatForever(moveSequence)
        node.runAction(moveLoop)
    }
    
    private func checkCameraPermission() {
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            //already authorized
            cameraAllowed = true
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                if granted {
                    self.cameraAllowed = true
                } else {
                    DispatchQueue.main.async {
                        self.showAlertCameraPermissionMissing()
                        self.cameraAllowed = false
                    }
                }
            })
        }
    }
    
    // MARK: - Alerts
    func showAlertCameraPermissionMissing() {
        showAlert(title: "Camera Permission Missing",
                  message: "The app requires access to the camera to visualize the Magnetic Field in AR.")
    }
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message:
            message, preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default, handler: nil))
        alertController.addAction(UIAlertAction(title: "Settings", style: .cancel) { (_) -> Void in
            UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
        })
        self.present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Recording state
extension VisualizationController {
    
      enum VizualizationWarning {
          case notAvailable
          case cameraTracking(ARCamera.TrackingState.Reason)
          case tooDark
          var recommendation: String? {
              switch self {
              case .cameraTracking(.excessiveMotion):
                  return "Move slower."
              case .cameraTracking(.insufficientFeatures):
                  return "Not enough features in the scene."
              case .cameraTracking(.initializing):
                  return "Initializing visualization."
              case .cameraTracking(.relocalizing):
                  return "Relocalizing AR."
              case .tooDark:
                  return "The scene is too dark."
              case .notAvailable:
                  return "AR not available right now"
              default:
                  return nil
              }
          }
          
      }
    

    enum RecordingState {
        case startARSession
        case notReady
        case ready
    }
    
    func updateRecordingState(to newState: RecordingState) {
        guard let trackingState = sceneView.session.currentFrame?.camera.trackingState else {
            state = .startARSession
            return
        }
        
        switch (newState, trackingState) {
        case (.notReady, .normal):
            state = .ready
        case (.notReady, .limited),
             (.notReady, .notAvailable):
            state = .notReady
        case (.ready, .normal):
            state = .ready
        case (.ready, .limited),
             (.ready, .notAvailable):
            state = .notReady
        default:
            state = newState
        }
    }
    
    func updateState(with trackingState: ARCamera.TrackingState) {
        switch trackingState {
        case .notAvailable, .limited:
            state = .notReady
        case .normal:
            state = .ready
        }
    }
    
}

// MARK: - Sensor updates
extension VisualizationController: SensorManagerDelegate {
    func onUpdate(data: SensorData) {
        // Got demagnetized
//        print(data.net)
        if data.net == 0 {
            isDemagnetized = true
        } else {
            isDemagnetized = false
        }
        
        DispatchQueue.main.async {
            self.xValLabel.setTitle("\(Int(data.x))", for: .normal)
            self.yValLabel.setTitle("\(Int(data.y))", for: .normal)
            self.zValLabel.setTitle("\(Int(data.z))", for: .normal)
            self.totalFieldLabel.setTitle("\(Int(data.net)) µT", for: .normal)
        }
    }
}

// MARK: - Settings updates
extension VisualizationController: DataManagerDelegate {
    func toggleHeatmapVectors() {
        if(!DataManager.shared.heatmapIsOn == true){
            scaleImage.alpha = 0

        }
        else{
            scaleImage.alpha = 0.5

        }

    }
    
    func toggleNumericalValue() {
        DispatchQueue.main.async {
            for v in self.vectors.values {
             v.textPlane.isHidden = !DataManager.shared.numericalValueIsVisible
         }
        }
    }
    
    func setVisualizationType() {
        for v in vectors.values {
             v.type = DataManager.shared.visualizationType
         }
    }
    
    func toggleScaleVectors() {
        print("Vectors are scaled: \(DataManager.shared.vectorsAreScaled)")
        DispatchQueue.main.async {
            for v in self.vectors.values {
                v.scale(intensity: DataManager.shared.vectorsAreScaled)
            }
        }
    }
}
