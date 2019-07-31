//
//  ViewController.swift
//  ArkitDemo
//
//  Created by Pratik's on 30/07/19.
//  Copyright © 2019 Pratik's. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import CoreLocation
class ViewController: UIViewController{
    
    //Earthnode
    var earthNode: SCNNode = SCNNode()
    
    //SCNNode Property for Pin Drop
    var PinNode: SCNNode = SCNNode()
    //Sphere shape
    var mySphere:SCNSphere!
    //Geocoder for location
    var geocode:CLGeocoder!
    
    @IBOutlet weak var iLabel: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        iLabel.isHidden = true
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        
        // Create a new scene
       // let scene = SCNScene(named: "art.scnassets/ship.scn")!

        let scene = SCNScene ()
        scene.rootNode.addChildNode(createGlobeNode()!)
        // Set the scene to the view
        sceneView.scene = scene
        
        // set Lighting Estimation Automatic
        self.sceneView.autoenablesDefaultLighting = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        if ARWorldTrackingConfiguration.isSupported{
            let configuration = ARWorldTrackingConfiguration()
            sceneView.debugOptions = SCNDebugOptions.showFeaturePoints
            sceneView.debugOptions = SCNDebugOptions.showLightInfluences
            sceneView.debugOptions = SCNDebugOptions.showCameras
            sceneView.debugOptions = SCNDebugOptions.showBoundingBoxes
            sceneView.debugOptions = SCNDebugOptions.showConstraints
            //sceneView.debugOptions = SCNDebugOptions.showWorldOrigin
            configuration.planeDetection = .horizontal
            sceneView.session.run(configuration, options: ARSession.RunOptions.resetTracking)

        }
        
        
//        let tapGesture = UITapGestureRecognizer (target: self, action: #selector(createSnapShotOnTap(_:)))
//        sceneView.addGestureRecognizer(tapGesture)
        
        
        let doubleTapGesture = UITapGestureRecognizer (target: self, action: #selector(showLocation(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        sceneView.addGestureRecognizer(doubleTapGesture)
        // Run the view's session
    }
    override func viewDidAppear(_ animated: Bool) {

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    
    //Create snapshots()
    @objc func createSnapShotOnTap(_ sender: UITapGestureRecognizer){
        guard let currentFrame = sceneView.session.currentFrame else {
            return
        }
        //click snapshot of ARview
        let imagePlane = SCNPlane (width: sceneView.bounds.width/6000, height:  sceneView.bounds.height/6000)
        let snapshot = sceneView.snapshot()
        snapshot.withHorizontallyFlippedOrientation()
        imagePlane.firstMaterial?.diffuse.contents = snapshot
        imagePlane.firstMaterial?.lightingModel = .constant
        
        //Create Node and add to scene
        let planeNode = SCNNode (geometry: imagePlane)
        sceneView.scene.rootNode.addChildNode (planeNode)
        
        //add node 10 cm front from camera
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -0.01
        planeNode.simdTransform = matrix_multiply(currentFrame.camera.transform, translation)
    }

    func createGlobeNode() -> SCNNode?
    {
        guard let camera = self.sceneView.pointOfView else {
            return nil
        }
        
        //Create Shape from shape Class
        mySphere = SCNSphere(radius: 0.2)
        //for Changing  Globe image and add material
        planetSetupSphere(sphere: mySphere, planetName:"earth")
        
        //add globe to earthnode
        earthNode = SCNNode (geometry: mySphere)
        
        
        // earthNode.position = SCNVector3Make(0, 0.5, 0.5)
        let position = SCNVector3(x: 0, y: 0, z: -0.7)
        earthNode.position = camera.convertPosition(position, to: nil)
        //earthNode.rotation = node.rotation
        return earthNode
        //sceneView.scene.rootNode.addChildNode(earthNode)

        
    }
    func planetSetupSphere(sphere:SCNGeometry ,planetName:NSString) {
        
        
        let earthMaterial = SCNMaterial()
        earthMaterial.diffuse.contents = UIImage (named:"earth")
        earthMaterial.normal.contents = UIImage(named: "normal")
        earthMaterial.specular.contents = UIImage (named:"clouds")
       // earthMaterial.emission.contents =  UIImage (named:"night_lights")
      //  earthMaterial.multiply.contents = UIImage (named:"bump")//UIColor (white: 0.7, alpha: 1.0)
        earthMaterial.shininess        = 1.05
        earthMaterial.normal.intensity = 1.0
        
        sphere.firstMaterial = earthMaterial
        
    }
    

}
extension ViewController:ARSCNViewDelegate{
    // MARK: - ARSCNViewDelegate
    
    
    // Override to create and configure nodes for anchors added to the view's session.
    //    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
    //        let node = SCNNode()
    //
    //        return node
    //    }
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
}
extension ViewController{
    
    @objc func showLocation(_ sender: UITapGestureRecognizer) {
        
        
        
        let location = sender.location(in: sceneView)
        // 1
        let hitResults = sceneView.hitTest(location, options:nil )
        // 2
        if hitResults.count > 0 {
            //            // 3
            let result = hitResults.first!
            //            // 4
            
            self.PinNode = GetPinNode()
            // Position the hit where the user clicked
            self.PinNode.position = result.localCoordinates
            
            // Calcualte how to rotate the pin so that it points in the
            // same direction as the surface normal at that location.
            let pinDirection = GLKVector3Make(0.0, 1.0, 0.0);
            let normal       = SCNVector3ToGLKVector3(result.localNormal);
            
            let rotationAxis = GLKVector3CrossProduct(pinDirection, normal);
            let cosAngle     = GLKVector3DotProduct(pinDirection, normal);
            
            let rotation = GLKVector4MakeWithVector3(rotationAxis, acos(cosAngle));
            self.PinNode.rotation = SCNVector4FromGLKVector4(rotation);
            
            // Use the texture coordinate to approximate a location
            let textureCoordinate = result.textureCoordinates(withMappingChannel: 0)
            let location = coordinateFromPoint(point: textureCoordinate)
            
            CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
                print(location)
                let place = placemarks?.first
                print(place ?? "no place ")
                
                var placeName = place?.country;
                
                if (!(placeName != nil))
                {
                    placeName = place?.ocean;
                }
                
                if (!(placeName != nil))
                {
                    placeName = place?.inlandWater;
                }
                print(placeName ?? "no place ")
                 self.iLabel.isHidden = false
                
                 self.iLabel.text = placeName ?? "Unknown"
                
            })
            
            
        }
        
    }
    func coordinateFromPoint(point:CGPoint) -> CLLocation {
        let u = point.x;
        let v = point.y;
        
        let lat:CLLocationDegrees  = CLLocationDegrees((0.5-v) * CGFloat( 180.0));
        let lon:CLLocationDegrees  = CLLocationDegrees((u-0.5)*CGFloat(360.0));
        
        return CLLocation (latitude: lat, longitude: lon);
    }
    func geocoder() -> CLGeocoder {
        if (!(self.geocode != nil)) {
            self.geocode = CLGeocoder ()
        }
        return self.geocode;
    }
    
    func GetPinNode () -> SCNNode {
        
        // Create a pin with a red head just like the bars in Chapter 3
        // (a pin node that hold both the body node and the head node)
        
        
        let bodyHeight:CGFloat = 0.010
        let bodyRadius:CGFloat = 0.010
        let headRadius:CGFloat = 0.0150
        
        // Create a cylinder and a sphere
        let body = SCNCylinder (radius: bodyRadius, height: bodyHeight)
        let head   = SCNSphere (radius: headRadius)
        
        // Create and assign the two materials
        let headMaterial = SCNMaterial ()
        let bodyMaterial = SCNMaterial ()
        
        headMaterial.diffuse.contents = UIColor.blue
        //  headMaterial.emission.contents = UIColor (colorLiteralRed: 0.2, green: 0.0, blue: 0.0, alpha: 1.0)
        headMaterial.specular.contents = UIColor .white
        head.firstMaterial = headMaterial;
        
        bodyMaterial.specular.contents = UIColor .white
        //bodyMaterial.emission.contents = UIColor (colorLiteralRed: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        bodyMaterial.shininess = 1.0;
        body.firstMaterial = bodyMaterial;
        
        // Create and position the two nodes
        let bodyNode = SCNNode (geometry: body)
        bodyNode.position = SCNVector3Make(0, Float(bodyHeight/0.02), 0.0)
        let headNode = SCNNode (geometry: head)
        headNode.position = SCNVector3Make(0, Float(bodyHeight), 0.0);
        
        // Add them both to the pin node
        let pinNode = SCNNode ()
        pinNode .addChildNode(bodyNode)
        pinNode .addChildNode(headNode)
        
        // Add to the earth
        earthNode .addChildNode(pinNode)
        self.PinNode = pinNode;
        
        
        
        return self.PinNode;
    }
}
