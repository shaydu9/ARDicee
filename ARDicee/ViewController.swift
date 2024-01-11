//
//  ViewController.swift
//  ARDicee
//
//  Created by Shay Dubrovsky on 29/12/2023.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var diceArray = [SCNNode]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.autoenablesDefaultLighting = true
        sceneView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    @IBAction func rollAgain(_ sender: UIBarButtonItem) {
        rollAll()
    }
    
    @IBAction func removeAllDice(_ sender: UIBarButtonItem) {
        if !diceArray.isEmpty {
            for dice in diceArray {
                dice.removeFromParentNode()
            }
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func placeDice(columns: (simd_float4, simd_float4, simd_float4, simd_float4)) {
        let diceScene = SCNScene(named: "art.scnassets/diceCollada_scn.scn")!
        
        if let diceNode = diceScene.rootNode.childNode(withName: "Dice", recursively: true) {
        
            diceNode.position = SCNVector3(
                columns.3.x,
                columns.3.y + diceNode.boundingSphere.radius,
                columns.3.z)
            diceArray.append(diceNode)
        
            sceneView.scene.rootNode.addChildNode(diceNode)
            roll(dice: diceNode)
        }
    }
    func rollAll() {
        if !diceArray.isEmpty {
            for dice in diceArray {
                roll(dice: dice)
            }
        }
    }
    
    func roll(dice: SCNNode) {
        let randomX = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
        let randomZ = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
        
        dice.runAction(SCNAction.rotateBy(
            x: CGFloat(randomX * 10),
            y: 0,
            z: CGFloat(randomZ * 10),
            duration: 0.5))
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        rollAll()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: sceneView)
            if #available(iOS 13, macOS 13, *) {
                guard let raycastQuery = sceneView.raycastQuery(from: touchLocation, allowing: .existingPlaneGeometry, alignment: .horizontal) else {return}
                let hitTestResults = sceneView.session.raycast(raycastQuery)
                if let hitResult = hitTestResults.first {
                    placeDice(columns: hitResult.worldTransform.columns)
                }
            } else {
                let touchResults = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
                if let hitResult = touchResults.first {
                    placeDice(columns: hitResult.worldTransform.columns)
                }
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        
        let planeNode = createPlane(with: planeAnchor)

        node.addChildNode(planeNode)
    }
    
    func createPlane(with planeAnchor: ARPlaneAnchor) -> SCNNode {
        let plane = SCNPlane(
            width: CGFloat(planeAnchor.planeExtent.width),
            height: CGFloat(planeAnchor.planeExtent.height))
        let planeNode = SCNNode()
        planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        let gridMaterial = SCNMaterial()
        gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
        plane.materials = [gridMaterial]
        planeNode.geometry = plane
        
        return planeNode
    }
}



