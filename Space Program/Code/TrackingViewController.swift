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
		
		// == Solar System ==
		let sunNode = loadSolarSystem(file:"SolarSystem")
		universeScene.rootNode.addChildNode(sunNode)

		
		/*/ Sun
		// Sol: radius=695,700km
		// Kerbol Sun: GM=1.172e18.
		sun = CelestialBody(orbit: OrbitalElements(semiMajorAxis: 0.0, eccentricity: 0.0), gravitationalConstant: 1e4, radius: 6.957, parent:nil)
		let sunNode = sun!.loadSceneNode(fileName: "Sun.dae", nodeName: "Sun")
		universeScene.rootNode.addChildNode(sunNode)
		
		// Moho / Mercury
		// Mercury: a=57,909,050km, ε=0.205630, inclination=7.005° to ecliptic, radius=2,439.7km
		moho = CelestialBody(orbit: OrbitalElements(semiMajorAxis: 57.909, eccentricity: 0.20536, inclination: 7.005 / 180 * .pi, longitudeOfAscendingNode: 48.331 / 180 * .pi, argumentOfPeriapsis: 29.124 / 180 * .pi, trueAnomalyAtEpoch: 0.0), gravitationalConstant: 100, radius: 2.4397e-2, parent: sun)
		let mohoNode = moho!.createSceneNodeSphere(named: "Moho", color: color(rgbHexValue: "ffbf7b"))
		universeScene.rootNode.addChildNode(mohoNode)
		universeScene.rootNode.addChildNode(moho!.orbitLineNode())

		// Eve / Venus
		// Venus: a=108,208,000km, ε=0.006772, inclination=3.395° to ecliptic, radius=6,051.8km
		// Eve: GM=8.172e12
		eve = CelestialBody(orbit: OrbitalElements(semiMajorAxis: 108.208, eccentricity: 0.006772), gravitationalConstant: 475, radius: 6.0518e-2, parent:sun)
		let eveNode = eve!.loadSceneNode(fileName: "Eve.dae", nodeName: "Eve")
		universeScene.rootNode.addChildNode(eveNode)
		universeScene.rootNode.addChildNode(eve!.orbitLineNode())
		
		// Kerbin / Earth
		// Kerbin: GM=3.5316e12
		// Earth: a=149,598,023km, ε=0.016709, inclination=0.0° to ecliptic, radius=6,371.0km
		kerbin = CelestialBody(orbit: OrbitalElements(semiMajorAxis: 149.6, eccentricity: 0.0), gravitationalConstant: 400, radius: 6.371e-2, parent:sun)
		let kerNode = kerbin!.loadSceneNode(fileName: "Earth.scn", nodeName: "Earth")
		universeScene.rootNode.addChildNode(kerNode)
		universeScene.rootNode.addChildNode(kerbin!.orbitLineNode())
		
		// Mun/Moon
		// Moon: a=384,399km, ε=0.0549, inclination=5.145° to ecliptic, radius=1,737.1km
		mun = CelestialBody(orbit: OrbitalElements(semiMajorAxis: 16.0, eccentricity: 0.0), gravitationalConstant: 6.5138398e10, radius: 1.7371e-2, parent:kerbin)
		let munNode = mun!.loadSceneNode(fileName: "Mun.dae", nodeName: "Mun")
		kerNode.addChildNode(munNode)
		kerNode.addChildNode(mun!.orbitLineNode())
		
		// Duna/Mars
		// Mars: a=227,939,200km, ε=0.0934, inclination=1.850° to ecliptic, radius=3,389.5km
		duna = CelestialBody(orbit: OrbitalElements(semiMajorAxis: 227.939, eccentricity: 0.0934, inclination: 1.85 / 180 * .pi, longitudeOfAscendingNode: 49.558 / 180 * .pi, argumentOfPeriapsis: 286.502 / 180 * .pi, trueAnomalyAtEpoch: 0.0), gravitationalConstant: 200, radius: 3.3895e-2, parent: sun)
		let dunaNode = duna!.createSceneNodeSphere(named: "Duna", color: color(rgbHexValue: "f85139"))
		universeScene.rootNode.addChildNode(dunaNode)
		universeScene.rootNode.addChildNode(duna!.orbitLineNode())
		*/
		
		// Set initial positions
		updateBodies(time: gameState!.universalTime)
		
		/*/ == DEBUG ==
		// Print orbital periods
		let pEve = eve!.orbit.orbitalPeriod(GM: sun!.gravitationalConstant)
		let pKerbin = kerbin!.orbit.orbitalPeriod(GM: sun!.gravitationalConstant)
		let pMun = mun!.orbit.orbitalPeriod(GM: kerbin!.gravitationalConstant)
		print(String(format:"Orbits: Eve=%1.1fs K=%1.1fs Mun=%1.1fs", pEve, pKerbin, pMun))
		// == END DEBUG == */

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
			cameraCtrl.distanceMax = Float(10000.0) // fixed at 10km
			cameraCtrl.addGestureRecognizers(to: sceneView)
			cameraController = cameraCtrl
			setCameraTarget(sun!.sphereOfInfluenceNode!)
			
			// Change camera target with tap
			let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
			tapGesture.numberOfTapsRequired = 1 // 2 taps can make it hard to hit a moving target
			tapGesture.numberOfTouchesRequired = 1
			sceneView.addGestureRecognizer(tapGesture)

		} // end if
	} // end func viewDidLoad()
	
	func loadSolarSystem(file:String) -> SCNNode {
		let info = AppDelegate.readJSON(file: file)!
		let sunInfo = info.first!
		sun = CelestialBody(info:sunInfo)
		return sun!.sphereOfInfluenceNode!
	}
	
	
	@objc func handleTap(_ gesture:UIGestureRecognizer) {
		guard let scnView = sceneView else { return }
		
		let pt = gesture.location(in: scnView)
		var options = [SCNHitTestOption:Any]()
		options[.searchMode] = SCNHitTestSearchMode.all.rawValue
		options[.clipToZRange] = true
		let hitResults = scnView.hitTest(pt, options: options)
		
		for result in hitResults {
			if let nodeName = result.node.name {
				if nodeName.hasSuffix("_Body") {
					if let soiNode = result.node.parent {
						// In order for the camera location to be correct, the camera node must be added to the body's SOI node, which is the body node's parent node.
						setCameraTarget(soiNode)
						break
					}
				} else if nodeName.hasSuffix("_Craft") {
					// For spacecraft, target the node directly
					setCameraTarget(result.node)
					break
				}
			}
			// Ignore other nodes, including orbit lines.
		}
	}
	
	func setCameraTarget(_ node:SCNNode) {
		let r = node.scale.x
		let ctrl = cameraController!
		ctrl.cameraNode.removeFromParentNode()
		node.addChildNode(ctrl.cameraNode)
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
		sun?.updatePosition(atTime: time, recursive: true)
	}

	
}
