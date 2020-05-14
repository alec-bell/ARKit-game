//
//  ViewController.swift
//  ARGame
//
//  Created by Alec Bell on 5/13/20.
//  Copyright © 2020 Alec Bell. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var tapToStartNode: SCNNode?
    var foundSurface = false
    var hasTappedToStart = false
    
    var directionalLightNode: SCNNode?
    var container: SCNNode!
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Return if player has not started the game yet
        guard !hasTappedToStart else { return }
        
        // Run hitTest to get potential position to place "Tap to start" image
        let hitTest = self.sceneView.hitTest(CGPoint(x: self.view.frame.midX, y: self.view.frame.midY), types: .featurePoint)
        guard let result = hitTest.first else { return }
        let translation = SCNMatrix4(result.worldTransform)
        let position = SCNVector3Make(translation.m41, translation.m42, translation.m43)
        
        if tapToStartNode == nil {
            // Create 15cm x 15cm plane with "Tap to start" image
            let plane = SCNPlane(width: 0.15, height: 0.15)
            plane.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/taptostart.png")
            plane.firstMaterial?.isDoubleSided = true
            
            // Create node for plane with "Tap to start" image to be attached to the scene
            tapToStartNode = SCNNode(geometry: plane)
            tapToStartNode?.eulerAngles.x = -.pi * 0.5
            self.sceneView.scene.rootNode.addChildNode(self.tapToStartNode!)
            foundSurface = true
        }
        
        // Update node with "Tap to start" image with new position
        self.tapToStartNode?.position = position
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !hasTappedToStart {
            // Return if surface for "Tap to start" image hasn't been found
            guard foundSurface else { return }
            
            // Get position of "Tap to start" image
            let tapToStartPosition = tapToStartNode!.position
            
            // Get rid of the "Tap to start" image
            tapToStartNode?.removeFromParentNode()
            
            // Get the container with the blocks, floor, and lighting
            container = sceneView.scene.rootNode.childNode(withName: "container", recursively: false)!
            
            // Place container where the "Tap to start" image was and unhide it
            container.position = tapToStartPosition
            container.isHidden = false
            
            // Get the lighting for appropriate adjustments later
            directionalLightNode = container.childNode(withName: "directional", recursively: false)
            
            hasTappedToStart = true
        } else {
            // Return if can't get currentFrame from session
            guard let frame = sceneView.session.currentFrame else { return }
            
            let camMatrix = SCNMatrix4(frame.camera.transform)
            
            // Define the force vector at which the balls will be emitted
            let direction = SCNVector3Make(-camMatrix.m31 * 5.0, -camMatrix.m32 * 10.0, -camMatrix.m33 * 5.0)
            let position = SCNVector3Make(camMatrix.m41, camMatrix.m42, camMatrix.m43)
            
            // Create a spherical geometry and make it red
            let ball = SCNSphere(radius: 0.1)
            ball.firstMaterial?.diffuse.contents = UIColor.red
            ball.firstMaterial?.emission.contents = UIColor.red
            
            // Assign the geometry to a new "ball" node
            let ballNode = SCNNode(geometry: ball)
            
            // Set its position equal to the camera position
            ballNode.position = position
            
            // Add a physics body that moves and detects collisions
            ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            ballNode.physicsBody?.categoryBitMask = 3
            ballNode.physicsBody?.contactTestBitMask = 1
            
            // Add to scene
            sceneView.scene.rootNode.addChildNode(ballNode)
            
            // Remove after 10 seconds
            ballNode.runAction(SCNAction.sequence([SCNAction.wait(duration: 10.0), SCNAction.removeFromParentNode()]))
            
            // Apply the force in the direction of the camera
            ballNode.physicsBody?.applyForce(direction, asImpulse: true) //6
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard hasTappedToStart else { return }
        
        // Get an estimate for the lighting and apply it to the directional light
        guard let lightEstimate = frame.lightEstimate else { return }
        directionalLightNode?.light?.intensity = lightEstimate.ambientIntensity
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/scene.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
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
