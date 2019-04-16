//
//  CTPanoramaView
//  CTPanoramaView
//
//  Created by Shubham Sharma on 15/04/19.
//  Copyright © 2019 devpoint. All rights reserved.
//

import Cocoa
import SceneKit
import ImageIO

@objc public protocol CTPanoramaCompass {
    func updateUI(rotationAngle: CGFloat, fieldOfViewAngle: CGFloat)
}

@objc public enum CTPanoramaType: Int {
    case cylindrical
    case spherical
}

@objc public class CTPanoramaView: NSView {

    // MARK: Public properties

    @objc public var compass: CTPanoramaCompass?
    @objc public var movementHandler: ((_ rotationAngle: CGFloat, _ fieldOfViewAngle: CGFloat) -> Void)?
    @objc public var panSpeed = CGPoint(x: 0.005, y: 0.005)
    @objc public var startAngle: Float = 0

    @objc public var image: NSImage? {
        didSet {
            panoramaType = panoramaTypeForCurrentImage
        }
    }

    @objc public var overlayView: NSView? {
        didSet {
            replace(overlayView: oldValue, with: overlayView)
        }
    }

    @objc public var panoramaType: CTPanoramaType = .cylindrical {
        didSet {
            createGeometryNode()
            resetCameraAngles()
        }
    }

  

    // MARK: Private properties

    private let radius: CGFloat = 10
    private let sceneView = SCNView()
    private let scene = SCNScene()
    private var geometryNode: SCNNode?
    private var prevLocation = CGPoint.zero
    private var prevBounds = CGRect.zero

    private lazy var cameraNode: SCNNode = {
        let node = SCNNode()
        let camera = SCNCamera()
        node.camera = camera
        return node
    }()

    private lazy var opQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInteractive
        return queue
    }()

    private lazy var fovHeight: CGFloat = {
        return tan(self.yFov/2 * .pi / 180.0) * 2 * self.radius
    }()

    private var startScale = 0.0

    private var xFov: CGFloat {
        return yFov * self.bounds.width / self.bounds.height
    }

    private var yFov: CGFloat {
        get {
            if #available(iOS 11.0, *) {
                return cameraNode.camera?.fieldOfView ?? 0
            } else {
                return CGFloat(cameraNode.camera?.yFov ?? 0)
            }
        }
        set {
            if #available(iOS 11.0, *) {
                cameraNode.camera?.fieldOfView = newValue
            } else {
                cameraNode.camera?.yFov = Double(newValue)
            }
        }
    }

    private var panoramaTypeForCurrentImage: CTPanoramaType {
        if let image = image {
            if image.size.width / image.size.height == 2 {
                return .spherical
            }
        }
        return .cylindrical
    }

    // MARK: Class lifecycle methods

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public convenience init(frame: CGRect, image: NSImage) {
        self.init(frame: frame)
        // Force Swift to call the property observer by calling the setter from a non-init context
        ({ self.image = image })()
    }

 

    private func commonInit() {
        add(view: sceneView)

        scene.rootNode.addChildNode(cameraNode)
        yFov = 80

        sceneView.scene = scene
        sceneView.backgroundColor = NSColor.black

        switchControlMethod( )
     }

    // MARK: Configuration helper methods

    private func createGeometryNode() {
        guard let image = image else {return}

        geometryNode?.removeFromParentNode()

        let material = SCNMaterial()
        material.diffuse.contents = image
        material.diffuse.mipFilter = .nearest
        material.diffuse.magnificationFilter = .nearest
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(-1, 1, 1)
        material.diffuse.wrapS = .repeat
        material.cullMode = .front

        if panoramaType == .spherical {
            let sphere = SCNSphere(radius: radius)
            sphere.segmentCount = 300
            sphere.firstMaterial = material

            let sphereNode = SCNNode()
            sphereNode.geometry = sphere
            geometryNode = sphereNode
        } else {
            let tube = SCNTube(innerRadius: radius, outerRadius: radius, height: fovHeight)
            tube.heightSegmentCount = 50
            tube.radialSegmentCount = 300
            tube.firstMaterial = material

            let tubeNode = SCNNode()
            tubeNode.geometry = tube
            geometryNode = tubeNode
        }
        scene.rootNode.addChildNode(geometryNode!)
    }

    private func replace(overlayView: NSView?, with newOverlayView: NSView?) {
        overlayView?.removeFromSuperview()
        guard let newOverlayView = newOverlayView else {return}
        add(view: newOverlayView)
    }

    private func switchControlMethod() {
        sceneView.gestureRecognizers.removeAll()
        let panGestureRec = NSPanGestureRecognizer(target: self, action: #selector(handlePan(panRec:)))
        sceneView.addGestureRecognizer(panGestureRec)
    }

    private func resetCameraAngles() {
        cameraNode.eulerAngles = SCNVector3Make(0, CGFloat(startAngle), 0)
        self.reportMovement(CGFloat(startAngle), xFov.toRadians(), callHandler: false)
    }

    private func reportMovement(_ rotationAngle: CGFloat, _ fieldOfViewAngle: CGFloat, callHandler: Bool = true) {
        compass?.updateUI(rotationAngle: rotationAngle, fieldOfViewAngle: fieldOfViewAngle)
        if callHandler {
            movementHandler?(rotationAngle, fieldOfViewAngle)
        }
    }

    // MARK: Gesture handling

    @objc private func handlePan(panRec: NSPanGestureRecognizer) {
        if panRec.state == .began {
            prevLocation = CGPoint.zero
        } else if panRec.state == .changed {
            var modifiedPanSpeed = panSpeed

            if panoramaType == .cylindrical {
                modifiedPanSpeed.y = 0 // Prevent vertical movement in a cylindrical panorama
            }

            let location = panRec.translation(in: sceneView)
            let orientation = cameraNode.eulerAngles
            var newOrientation = SCNVector3Make(orientation.x + CGFloat(Float(location.y - prevLocation.y) * Float(modifiedPanSpeed.y)),
                                                orientation.y + CGFloat(Float(location.x - prevLocation.x) * Float(modifiedPanSpeed.x)),
                                                orientation.z)

            
            newOrientation.x = max(min(newOrientation.x, 1.1), -1.1)
            

            cameraNode.eulerAngles = newOrientation
            prevLocation = location

            reportMovement(CGFloat(-cameraNode.eulerAngles.y), xFov.toRadians())
        }
    }
    func zoom(scale x:Double)  {
        let zoom = x
        if startScale == 0 {
            if #available(iOS 11.0, *) {
                startScale = Double(cameraNode.camera?.fieldOfView ?? 0)
            } else {
                startScale = Double(cameraNode.camera?.yFov ?? 0)
            }
            //            startScale = cameraNode.camera!.yFov
        }
        
        let fov = startScale / zoom
        if fov > 20 && fov < 80 {
            if #available(iOS 11.0, *) {
                cameraNode.camera!.fieldOfView = CGFloat(fov)
            } else {
                cameraNode.camera!.yFov = fov
            }
            
        }
        
    }
    var value:Double = 1.0
//    var zoomingFlag = false
    override public func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
//        if zoomingFlag {
//            return
//        }
//        zoomingFlag = true
        
            if event.deltaY > 0 && value >= 1.0 && value < 4.0 {
                 value += 0.1
//                var countx = 0.00
//                for i in 1...10 {
//                    countx += 0.01
//                    value += countx
//                    value = Double(String(format: "%.2f", value))!
//                    zoom(scale: value   )
//                }
                
                
//                var count = 0
//                var timer = Timer.scheduledTimer(withTimeInterval: 0.050, repeats: true){ t in
//                    count += 1
//                    if count >= 10 {
//                        t.invalidate()
//                        self.zoomingFlag = false
//                    }
//                    countx += 0.01
//                    self.value += countx
//                    self.value = Double(String(format: "%.2f", self.value))!
//                    print(self.value)
//                    self.zoom(scale: self.value   )
//                }
                
            }
            if event.deltaY < 0 && value > 1.0 && value <= 4.0 {
                value -= 0.1
            }
       
            print(value)
            value = Double(String(format: "%.2f", value))!
            zoom(scale: value)
    }
    /*@objc func handlePinch(pinchRec: UIPinchGestureRecognizer) {
        if pinchRec.numberOfTouches != 2 {
            return
        }

        let zoom = Double(pinchRec.scale)
        switch pinchRec.state {
        case .began:
            startScale = cameraNode.camera!.yFov
        case .changed:
            let fov = startScale / zoom
            if fov > 20 && fov < 80 {
                cameraNode.camera!.yFov = fov
            }
        default:
            break
        }
    }*/
 
    /*public override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size.width != prevBounds.size.width || bounds.size.height != prevBounds.size.height {
            sceneView.setNeedsDisplay()
            reportMovement(CGFloat(-cameraNode.eulerAngles.y), xFov.toRadians(), callHandler: false)
        }
    }*/
}


private extension NSView {
    func add(view: NSView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        let views = ["view": view]
        let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "|[view]|", options: [], metrics: nil, views: views)    //swiftlint:disable:this line_length
        let vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: views)  //swiftlint:disable:this line_length
        self.addConstraints(hConstraints)
        self.addConstraints(vConstraints)
    }
}

private extension FloatingPoint {
    func toDegrees() -> Self {
        return self * 180 / .pi
    }

    func toRadians() -> Self {
        return self * .pi / 180
    }
}
