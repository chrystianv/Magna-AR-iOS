//
import Foundation
import ARKit
import SceneKit.ModelIO

//let ARROW_OBJ_URL = "art.scnassets/arrow/sun-dial-arrow"
let ARROW_OBJ_URL = "art.scnassets/arrow/arrow"

enum VisualizationType {
    case arrow
    case sphere
}

class Vector {
    
    // Primary node. This will either be an arrow or sphere depnding on the tpye
    var parentNode = SCNNode()
    var currentNode: SCNNode!
    var data: SensorData!
    
    var type: VisualizationType = .arrow {
        didSet {
            if type == .arrow {
               currentNode = arrowNode
               arrowNode.isHidden = false
               sphereNode.isHidden = true
           } else {
               currentNode = sphereNode
               arrowNode.isHidden = true
               sphereNode.isHidden = false
           }
            
        // Make sure to reset the hue
        currentNode.geometry?.firstMaterial!.diffuse.contents = UIColor(hue: hue, saturation: 1, brightness: 1, alpha: 1)
            
        let offset: Float = type == .arrow ? 0.8 : 0.4
            textPlane.position = SCNVector3(currentNode.position.x + 0.6*offset, currentNode.position.y + 2*offset, currentNode.position.z)

        }
    }
        
    var textPlane = SCNNode()
    let textLabel = UIButton(type: .custom)
    var textPlaneGeometry = SCNPlane(width: 0.67, height: 0.33)

    var id: String! {
        didSet {
            self.parentNode.name? = id
        }
    }
    
    // Other convenience accessors
    var position: SCNVector3 = SCNVector3() {
        didSet {
            self.parentNode.position = position
        }
    }
    
    var eulerAngles: SCNVector3 = SCNVector3() {
        didSet {
            self.parentNode.eulerAngles = eulerAngles
        }
    }
    
    var scale: SCNVector3 = SCNVector3() {
        didSet {
            self.parentNode.scale = scale
        }
    }
    
    var hue: CGFloat! = 0 {
        didSet {
            currentNode.geometry?.firstMaterial!.diffuse.contents = UIColor(hue: hue, saturation: 1, brightness: 1, alpha: 1)
        }
    }
    
    // Other vars
    final let baseScale: CGFloat = BASE_ARROW_SCALE
    let scaleFactor: Float = 2
    let arrowModelURL = Bundle.main.url(forResource: ARROW_OBJ_URL, withExtension: "obj")!
    
    var arrowNode =  SCNNode()
    var sphereNode  = SCNNode()
    
    init() {
        arrowNode = nodeForURL(url: arrowModelURL)
        arrowNode.geometry?.firstMaterial?.specular.contents = UIColor.white
        
        sphereNode =  SCNNode(geometry: SCNSphere(radius: 0.2))
        sphereNode.geometry?.firstMaterial?.specular.contents = UIColor.white

        position = SCNVector3Zero
        
        // Add initial conditions
        if type == .arrow {
            currentNode = arrowNode
            arrowNode.isHidden = false
            sphereNode.isHidden = true
        } else {
            currentNode = sphereNode
            arrowNode.isHidden = true
            sphereNode.isHidden = false
        }
        
        // Add both nodes and toggle their visibility based on the type
        parentNode.addChildNode(sphereNode)
        parentNode.addChildNode(arrowNode)

        textPlaneGeometry.cornerRadius = 0.1
        textPlaneGeometry.firstMaterial?.isDoubleSided = true
        
        textLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        textLabel.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        textLabel.layer.cornerRadius = 10
        textLabel.setTitle("50 μT", for: .normal)
        textLabel.setTitleColor(UIColor.black, for: .normal)
        textLabel.titleLabel?.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        textLabel.titleLabel?.textAlignment = .center
        textPlaneGeometry.firstMaterial?.diffuse.contents = textLabel
        
        let offset: Float = 1
        textPlane.position = SCNVector3(currentNode.position.x, currentNode.position.y + 2*offset, currentNode.position.z)
        textPlaneGeometry.firstMaterial?.lightingModel = SCNMaterial.LightingModel.constant
        textPlane.geometry = textPlaneGeometry
        parentNode.addChildNode(textPlane)
    }
    
    func nodeForURL(url: URL) -> SCNNode {
        let asset = MDLAsset(url: url)
        let object = asset.object(at: 0)
        let node = SCNNode(mdlObject: object)
        return node
    }
}

// MARK: - Convenience methods
extension Vector {
    func toggleText() {
        textPlane.isHidden.toggle()
    }
    
    func showText() {
        textPlane.isHidden = false
    }
    
    func hideText() {
        textPlane.isHidden = true
    }
    
    func setText<T: Comparable>(val: T) {
        DispatchQueue.main.async {
            self.textLabel.setTitle("\(val) μT", for: .normal)
        }
    }
    
    func setText(text: String) {
        DispatchQueue.main.async {
            self.textLabel.setTitle(text, for: .normal)
        }
    }
    
    // scales length of the arrow by the intensity of the field
    func scale(intensity: Bool) {
        let scaleFactor = asIntensity(net: data.net) * 6 + 1
        if intensity {
            if DataManager.shared.visualizationType == .arrow {
                currentNode.scale.y = scaleFactor
            } else {
                let scaleVector = SCNVector3(-scaleFactor,-scaleFactor,-scaleFactor)
                currentNode.scale = scaleVector
            }
        } else {
            currentNode.scale.y = 1
        }
    }
    
    // helper functions copied from android project
    func asIntensity(net: Float) -> Float {
        let ranged = net - 250; // changes focused about 500
        let sigmoidal = Float(1 / (1 + exp(-(ranged / 100)))) // TODO adjust to fit usual magnets
        return max(min(sigmoidal, 1), 0);
    }
}
