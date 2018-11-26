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
	var cameraTargetBody: CelestialBody?

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
		sun = loadSolarSystem(file:"SolarSystem")
		
		// Add scene nodes for each body recursively
		sun!.addSceneNodesRecursively(rootNode: universeScene.rootNode, parentNode: universeScene.rootNode)
		
		// Sun
		// Modify the model properties specially for the sun.
		let sunBody = sun!.bodyNode
		sunBody.castsShadow = false
		let sunMaterial = sunBody.geometry!.firstMaterial!
		sunMaterial.lightingModel = .constant
		
		// Add an omni light for the sun.
		let sunLight = SCNLight()
		sunLight.type = .omni
		sunLight.color = UIColor.white
		sunLight.intensity = 2000.0 // 2x normal
		sunLight.temperature = 5000 // K
		sunLight.attenuationStartDistance = 0.0
		sunLight.attenuationEndDistance = 0.0
		sunLight.attenuationFalloffExponent = 0.0
		sunLight.shadowRadius = 10.0
		sun!.sphereOfInfluenceNode.light = sunLight
		
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
			let sunRadius = sun!.bodyRadius
			let cameraCtrl = CameraController(camera: cameraNode)
			cameraCtrl.vabMode = false
			cameraCtrl.target = SCNVector3(x:0.0, y:0.0, z:0.0)
			cameraCtrl.distance = Float(sunRadius * 24.0)
			cameraCtrl.distanceMax = Float(10000.0) // fixed at 10km
			cameraCtrl.addGestureRecognizers(to: sceneView)
			cameraController = cameraCtrl
			setCameraTarget(sun!.sphereOfInfluenceNode)
			
			// For testing, set the camera target to Pluto
			if let pluto = universeScene.rootNode.childNode(withName: "Pluto_Body", recursively: true) {
				setCameraTarget(pluto)
			}
			
			// Change camera target with tap
			let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
			tapGesture.numberOfTapsRequired = 1 // 2 taps can make it hard to hit a moving target
			tapGesture.numberOfTouchesRequired = 1
			sceneView.addGestureRecognizer(tapGesture)

		} // end if
	} // end func viewDidLoad()
	
	func loadSolarSystem(file:String) -> CelestialBody {
		let info = AppDelegate.readJSON(file: file)!
		let sunInfo = info.first!
		return CelestialBody(info:sunInfo)
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
				if nodeName.hasSuffix("_Body") || nodeName.hasSuffix("_Craft") {
					setCameraTarget(result.node)
					break
				}
			}
			// Ignore other nodes, including orbit lines.
		}
	}
	
	func setCameraTarget(_ node:SCNNode) {
		// In order for the camera location to be correct, the camera node must be added to the body's SOI node, which is the body node's parent node.
		var r = Float(1.0)
		var targetNode = node
		if let name = node.name, name.hasSuffix("_Body") {
			r = node.scale.x
			if node.parent != nil {
				targetNode = node.parent!
			}
			
			// Store the CelestialBody associated with this node
			if sun?.bodyNode == node {
				cameraTargetBody = sun
			} else if let body = sun?.child(withBodyNode: node, recursive: true) {
				cameraTargetBody = body
			}
			print("Camera target is", cameraTargetBody?.name ?? "nil")
		}
		updateBodies(time: gameState!.universalTime)
		
		let ctrl = cameraController!
		ctrl.cameraNode.removeFromParentNode()
		targetNode.addChildNode(ctrl.cameraNode)
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
		var offset = simd_double3()
		if let body = cameraTargetBody {
			offset = -body.position
		}
		sun?.updatePositionRecursively(atTime: time, universeOffset:offset)
	}

	
}
