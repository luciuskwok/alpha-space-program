//
//  TrackingViewController.swift
//  Space Program
//
//  Created by Lucius Kwok on 11/19/18.
//  Copyright © 2018 Felt Tip Inc. All rights reserved.
//

import UIKit
import SceneKit


class TrackingViewController: UIViewController, SCNSceneRendererDelegate {
	
	@IBOutlet weak var sceneView: SCNView?

	var gameState:GameState?
	var cameraController: CameraController?
	
	// MARK: -
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Load "Universe.scn" scene
		let universeScene = SCNScene(named: "Scene.scnassets/Universe.scn")!

		// Add space skybox
		universeScene.background.contents = [
			UIImage(named:"space_skybox_right"),
			UIImage(named:"space_skybox_left"),
			UIImage(named:"space_skybox_up"),
			UIImage(named:"space_skybox_down"),
			UIImage(named:"space_skybox_front"),
			UIImage(named:"space_skybox_back")
		]

		if let sceneView = sceneView {
			// Configure scene view
			sceneView.scene = universeScene
			sceneView.delegate = self
			sceneView.rendersContinuously = true
			sceneView.allowsCameraControl = false
			sceneView.showsStatistics = false
			sceneView.backgroundColor = UIColor.black

			// Set up camera
			if let cameraNode = universeScene.rootNode.childNode(withName: "Camera", recursively: true) {
				let cameraCtrl = CameraController(camera: cameraNode)
				cameraCtrl.camera = cameraNode
				cameraCtrl.vabMode = false
				cameraCtrl.target = SCNVector3(x:0.0, y:0.0, z:0.0)
				cameraCtrl.distance = 10.0
				cameraCtrl.distanceMax = 600.0
				cameraCtrl.distanceMin = 2.5
				cameraCtrl.addGestureRecognizers(to: sceneView)
				cameraCtrl.updateCameraPosition()
				cameraController = cameraCtrl
			} else {
				print("[LK] Camera not found.")
			}


			// end func viewDidLoad()
		}
		
		
	}

}
