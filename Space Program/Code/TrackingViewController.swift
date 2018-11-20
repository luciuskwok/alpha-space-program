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
	var sunNode:SCNNode?
	var eveNode:SCNNode?
	var kerbinNode:SCNNode?
	var munNode:SCNNode?

	// Constants
	let sunRadius = Double(10.0) // Double(261.6e6) // 261,600 km
	let kerbinRadius = Double(4.0) // Double(600e3) // 600 km
	let kerbinSemiMajorAxis = Double(40.0) // Double(13599840256) // 13,599,840,256 m
	let munRadius = Double(1.08) // Double(200e3) // 200 km
	let munSemiMajorAxis = Double(4.0) // Double(12e6) // 12,000 km
	let eveRadius = Double(2.0) // Double(700e3) // 700 km
	let eveSemiMajorAxis = Double(20.0) // Double(9832684) // 9,832,684 m

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
		
		// Get Sun node
		let sunScene = SCNScene(named: "Scene.scnassets/Sun.dae")!
		let aSunNode = sunScene.rootNode.childNode(withName: "Sun", recursively: true)!
		universeScene.rootNode.addChildNode(aSunNode)
		aSunNode.scale = SCNVector3(sunRadius, sunRadius, sunRadius)
		aSunNode.position = SCNVector3(x:0.0, y:0.0, z:0.0)
		sunNode = aSunNode
		
		// Get Kerbin/Earth node
		let earthScene = SCNScene(named: "Scene.scnassets/Earth.scn")!
		let anEarthNode = earthScene.rootNode.childNode(withName: "Earth", recursively: true)!
		universeScene.rootNode.addChildNode(anEarthNode)
		anEarthNode.scale = SCNVector3(kerbinRadius, kerbinRadius, kerbinRadius)
		anEarthNode.position = SCNVector3(x:Float(kerbinSemiMajorAxis), y:0.0, z:0.0)
		kerbinNode = anEarthNode
		
		// Get Mun node
		let munScene = SCNScene(named: "Scene.scnassets/Mun.dae")!
		let aMunNode = munScene.rootNode.childNode(withName: "Mun", recursively: true)!
		universeScene.rootNode.addChildNode(aMunNode)
		aMunNode.scale = SCNVector3(munRadius, munRadius, munRadius)
		aMunNode.position = SCNVector3(x:Float(kerbinSemiMajorAxis - munSemiMajorAxis), y:0.0, z:0.0)
		munNode = aMunNode

		// Get Eve node
		let eveScene = SCNScene(named: "Scene.scnassets/Eve.dae")!
		let anEveNode = eveScene.rootNode.childNode(withName: "Eve", recursively: true)!
		universeScene.rootNode.addChildNode(anEveNode)
		anEveNode.scale = SCNVector3(eveRadius, eveRadius, eveRadius)
		anEveNode.position = SCNVector3(x:Float(eveSemiMajorAxis), y:0.0, z:0.0)
		eveNode = anEveNode
		
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
				cameraCtrl.distance = Float(sunRadius * 8.0)
				cameraCtrl.distanceMax = Float(sunRadius * 1000.0)
				cameraCtrl.distanceMin = Float(sunRadius * 4.0)
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
