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
	var scenePreviousRenderTime = -1.0
	var cameraController: CameraController?
	
	var sun: CelestialBody?
	var kerbin: CelestialBody?
	var mun: CelestialBody?
	var eve: CelestialBody?

	// MARK: -
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// TEST
		OrbitalElements.runTest()
		
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
		
		// Set up solar system
		
		// Get Sun node
		sun = CelestialBody(orbit: OrbitalElements(semiMajorAxis: 0.0, eccentricity: 0.0), gravitationalConstant: 1e4, radius: 10.0, parent:nil)
		// Sun's actual GM in KSP should be 1.172e18.
		let sunNode = sun!.loadSceneNode(fileName: "Sun.dae", nodeName: "Sun")
		universeScene.rootNode.addChildNode(sunNode)
		
		// Get Kerbin/Earth node
		kerbin = CelestialBody(orbit: OrbitalElements(semiMajorAxis: 150.0, eccentricity: 0.0), gravitationalConstant: 2e3, radius: 4.0, parent:sun)
		// Kerbin's GM should be 3.5316e12
		let kerNode = kerbin!.loadSceneNode(fileName: "Earth.scn", nodeName: "Earth")
		universeScene.rootNode.addChildNode(kerNode)
		
		// Kerbin orbit line
		let kerOrbitNode = kerbin!.orbitLineNode()
		universeScene.rootNode.addChildNode(kerOrbitNode)
		
		// Get Mun node
		mun = CelestialBody(orbit: OrbitalElements(semiMajorAxis: 8.0, eccentricity: 0.0), gravitationalConstant: 6.5138398e10, radius: 1.08, parent:kerbin)
		let munNode = mun!.loadSceneNode(fileName: "Mun.dae", nodeName: "Mun")
		kerNode.addChildNode(munNode)

		// Mun orbit line
		let munOrbitNode = mun!.orbitLineNode()
		kerNode.addChildNode(munOrbitNode)

		// Get Eve node
		eve = CelestialBody(orbit: OrbitalElements(semiMajorAxis: 100.0, eccentricity: 0.75), gravitationalConstant: 8.172e12, radius: 2.0, parent:sun)
		let eveNode = eve!.loadSceneNode(fileName: "Eve.dae", nodeName: "Eve")
		universeScene.rootNode.addChildNode(eveNode)
		
		// Eve orbit line
		let eveOrbitNode = eve!.orbitLineNode()
		universeScene.rootNode.addChildNode(eveOrbitNode)
		
		// Set initial positions
		updateBodies(time: gameState!.universalTime)
		
		// == DEBUG ==
		// Print orbital periods
		let pEve = eve!.orbit.orbitalPeriod(GM: sun!.gravitationalConstant)
		let pKerbin = kerbin!.orbit.orbitalPeriod(GM: sun!.gravitationalConstant)
		let pMun = mun!.orbit.orbitalPeriod(GM: kerbin!.gravitationalConstant)
		print(String(format:"Orbits: Eve=%1.1fs K=%1.1fs Mun=%1.1fs", pEve, pKerbin, pMun))
		
		if let sceneView = sceneView {
			// Configure scene view
			sceneView.scene = universeScene
			sceneView.delegate = self
			sceneView.rendersContinuously = true
			sceneView.allowsCameraControl = false
			sceneView.showsStatistics = false
			sceneView.backgroundColor = UIColor.black

			// Set up camera
			let cameraNode = universeScene.rootNode.childNode(withName: "Camera", recursively: true)!
			let sunRadius = sun!.radius
			let cameraCtrl = CameraController(camera: cameraNode)
			cameraCtrl.vabMode = false
			cameraCtrl.target = SCNVector3(x:0.0, y:0.0, z:0.0)
			cameraCtrl.distance = Float(sunRadius * 24.0)
			cameraCtrl.addGestureRecognizers(to: sceneView)
			cameraController = cameraCtrl
			setCameraTarget(sun!.sphereOfInfluenceNode!)
			
			// Change camera target with double-tap
			let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
			//tapGesture.
			sceneView.addGestureRecognizer(tapGesture)

		} // end if
	} // end func viewDidLoad()
	
	@objc func handleTap(_ gesture:UIGestureRecognizer) {
		guard let scnView = sceneView else { return }
		
		let pt = gesture.location(in: scnView)
		// options [.clipToRange:true, .searchMode:closest]
		let hitResults = scnView.hitTest(pt, options: [:])
		if hitResults.count > 0 {
			let node = hitResults.first!.node
			setCameraTarget(node)
		}
	}
	
	func setCameraTarget(_ node:SCNNode) {
		let r = node.scale.x
		let ctrl = cameraController!
		ctrl.cameraNode.removeFromParentNode()
		node.addChildNode(ctrl.cameraNode)
		ctrl.distanceMax = Float(r * 1000.0)
		ctrl.distanceMin = Float(r * 4.0)
		if ctrl.distance < ctrl.distanceMin {
			ctrl.distance = ctrl.distanceMin
		}
		ctrl.updateCameraPosition()
	}

	// MARK: - SceneKit
	
	func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		// Skip physics updates in initial frame, in order to get an accurate system time.
		if let gameState = gameState {
			if scenePreviousRenderTime != -1.0 {
				let interval = time - scenePreviousRenderTime
				gameState.universalTime += interval
				//updateCraft(interval: interval)
				updateBodies(time: gameState.universalTime)
			}
		}
		scenePreviousRenderTime = time
	} // end func renderer
	
	func updateBodies(time:Double) {
		eve?.updatePosition(atTime:time)
		kerbin?.updatePosition(atTime:time)
		mun?.updatePosition(atTime:time)
	}

	
}
