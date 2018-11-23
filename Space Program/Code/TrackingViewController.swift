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
		let sunScene = SCNScene(named: "Scene.scnassets/Sun.dae")!
		let sunNode = sunScene.rootNode.childNode(withName: "Sun", recursively: true)!
		universeScene.rootNode.addChildNode(sunNode)
		sun = CelestialBody(orbit: OrbitalElements(semiMajorAxis: 0.0, eccentricity: 0.0), gravitationalConstant: 1.172e18, radius: 10.0, sceneNode: sunNode)
		sunNode.position = SCNVector3(x:0.0, y:0.0, z:0.0)
		
		// Get Kerbin/Earth node
		let earthScene = SCNScene(named: "Scene.scnassets/Earth.scn")!
		let earthNode = earthScene.rootNode.childNode(withName: "Earth", recursively: true)!
		universeScene.rootNode.addChildNode(earthNode)
		kerbin = CelestialBody(orbit: OrbitalElements(semiMajorAxis: 150.0, eccentricity: 0.0), gravitationalConstant: 3.5316e12, radius: 4.0, sceneNode: earthNode)
		earthNode.position = SCNVector3(x:150.0, y:0.0, z:0.0)
		
		// Kerbin orbit line
		let kerbinOrbitNode = orbitLineNode(orbit: kerbin!.orbit)
		universeScene.rootNode.addChildNode(kerbinOrbitNode)
		
		// Get Mun node
		let munScene = SCNScene(named: "Scene.scnassets/Mun.dae")!
		let munNode = munScene.rootNode.childNode(withName: "Mun", recursively: true)!
		universeScene.rootNode.addChildNode(munNode)
		mun = CelestialBody(orbit: OrbitalElements(semiMajorAxis: 8.0, eccentricity: 0.0), gravitationalConstant: 6.5138398e10, radius: 1.08, sceneNode: munNode)
		munNode.position = SCNVector3(x:142.0, y:0.0, z:0.0)

		// Get Eve node
		let eveScene = SCNScene(named: "Scene.scnassets/Eve.dae")!
		let eveNode = eveScene.rootNode.childNode(withName: "Eve", recursively: true)!
		universeScene.rootNode.addChildNode(eveNode)
		eve = CelestialBody(orbit: OrbitalElements(semiMajorAxis: 100.0, eccentricity: 0.0625), gravitationalConstant: 8.172e12, radius: 2.0, sceneNode: eveNode)
		eveNode.position = SCNVector3(x:100.0, y:0.0, z:0.0)
		
		// Eve orbit line
		let eveOrbitNode = orbitLineNode(orbit: eve!.orbit)
		universeScene.rootNode.addChildNode(eveOrbitNode)
		
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
				let sunRadius = sun!.radius
				let cameraCtrl = CameraController(camera: cameraNode)
				cameraCtrl.camera = cameraNode
				cameraCtrl.vabMode = false
				cameraCtrl.target = SCNVector3(x:0.0, y:0.0, z:0.0)
				cameraCtrl.distance = Float(sunRadius * 24.0)
				cameraCtrl.distanceMax = Float(sunRadius * 1000.0)
				cameraCtrl.distanceMin = Float(sunRadius * 4.0)
				cameraCtrl.addGestureRecognizers(to: sceneView)
				cameraCtrl.updateCameraPosition()
				cameraController = cameraCtrl
			} else {
				print("[LK] Camera not found.")
			}
			
		} // end if
	} // end func viewDidLoad()

	// MARK: - SceneKit
	
	func orbitLineNode(orbit:OrbitalElements) -> SCNNode {
		let flatCoords = orbit.orbitPathCoordinates(divisions: 180)
		var geoCoords = [SCNVector3]()
		var geoElements = [SCNGeometryElement]()
		var index = Int16(0)
		for coord in flatCoords {
			geoCoords.append (SCNVector3 (x:Float(coord.x), y:0.0, z:Float(coord.y) ) )
			if index > 0 {
				geoElements.append (SCNGeometryElement(indices: [index-1, index], primitiveType: .line) )
			}
			index += 1
		}
		let vertexSource = SCNGeometrySource(vertices: geoCoords)
		let orbitGeometry = SCNGeometry(sources: [vertexSource], elements: geoElements)
		
		let orbitMaterial = orbitGeometry.firstMaterial!
		orbitMaterial.fillMode = .lines
		orbitMaterial.isDoubleSided = true
		orbitMaterial.lightingModel = .constant
		
		return SCNNode(geometry: orbitGeometry)
	}
	
	func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		// Skip physics updates in initial frame, in order to get an accurate system time.
		if let gameState = gameState {
			if scenePreviousRenderTime != -1.0 {
				let interval = time - scenePreviousRenderTime
				gameState.universalTime += interval
				//updateCraft(interval: interval)
				//updatePlanets(time: gameState.universalTime)
			}
		}
		scenePreviousRenderTime = time
	} // end func renderer

	
}
