//
//  GameViewController.swift
//  Space Program
//
//  Created by Lucius Kwok on 10/30/18.
//  Copyright © 2018 Felt Tip Inc. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController, SCNSceneRendererDelegate {
	
	@IBOutlet weak var sceneView: SCNView?
	
	@IBOutlet weak var escapeButton: UIButton?
	
	@IBOutlet weak var altitudeReadout: UILabel?
	@IBOutlet weak var altitudeUnitsLabel: UILabel?

	@IBOutlet weak var METReadout: UILabel?
	@IBOutlet weak var UTCDayReadout: UILabel?
	@IBOutlet weak var UTCTimeReadout: UILabel?

	@IBOutlet weak var velocityReadout: UILabel?
	@IBOutlet weak var velocityCaption: UILabel?
	@IBOutlet weak var headingReadout: UILabel?

	@IBOutlet weak var fullThrottleButton: UIButton?
	@IBOutlet weak var cutThrottleButton: UIButton?

	@IBOutlet weak var attitudeIndicator: AttitudeIndicatorView?

	@IBOutlet weak var RCSButton: UIButton?
	@IBOutlet weak var SASButton: UIButton?

	@IBOutlet weak var pitchUpButton: UIButton?
	@IBOutlet weak var pitchDownButton: UIButton?
	@IBOutlet weak var yawLeftButton: UIButton?
	@IBOutlet weak var yawRightButton: UIButton?
	@IBOutlet weak var rollLeftButton: UIButton?
	@IBOutlet weak var rollRightButton: UIButton?
	
	var gameState:GameState?
	var theSpacecraft = Spacecraft()
	var cameraController: CameraController?
	var craft: SCNNode?
	var earth: SCNNode?

	// Other variables
	let buttonGreenlightBackgroundColor = UIColor(hue: 135.0/360.0, saturation: 0.67, brightness: 1.0, alpha: 0.67)
	let buttonNormalBackgroundColor = UIColor(white: 1.0, alpha: 0.67)

	let numberFormatter = NumberFormatter()
	let userInterfaceUpdateInterval = 1.0/15.0
	var userInterfaceUpdateTimer:Timer?
	
	var scenePreviousRenderTime = -1.0
	
	// MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = SCNScene(named: "Scene.scnassets/Universe.scn")!
		
		// Add Earth and scale and position it
		let earthScene = SCNScene(named: "Scene.scnassets/Earth.scn")!
		let earthNode = earthScene.rootNode.childNode(withName: "Earth", recursively: true)!
		scene.rootNode.addChildNode(earthNode)
		let earthRadius = Float(600000)
		earthNode.scale = SCNVector3(earthRadius, earthRadius, earthRadius)
		earthNode.position = SCNVector3(x:0.0, y:0.0, z:-(70002 + earthRadius))
		earth = earthNode

		// Add craft from CMD-1
		if let craftScene = SCNScene(named: "Scene.scnassets/CMD-1.dae") {
			if let craftNode = craftScene.rootNode.childNode(withName: "Craft", recursively: true) {
				scene.rootNode.addChildNode(craftNode)
				theSpacecraft.sceneNode = craftNode
				theSpacecraft.updatePhysicsBody()
			}
		}
		
		// Add space skybox
		scene.background.contents = [
			UIImage(named:"space_skybox_right"),
			UIImage(named:"space_skybox_left"),
			UIImage(named:"space_skybox_up"),
			UIImage(named:"space_skybox_down"),
			UIImage(named:"space_skybox_front"),
			UIImage(named:"space_skybox_back")
		]
		
		// == SceneView ==
		if let sceneView = sceneView {
			sceneView.scene = scene
			sceneView.delegate = self
			sceneView.rendersContinuously = true
			sceneView.allowsCameraControl = false
			sceneView.showsStatistics = true
			sceneView.backgroundColor = UIColor.black
			
			// Set up camera
			if let cameraNode = scene.rootNode.childNode(withName: "Camera", recursively: true) {
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

			// Testing: Tap gesture recognizer that highlights part in red
			let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
			sceneView.addGestureRecognizer(tapGesture)
		}
		
		// Set up spacecraft
		theSpacecraft.position = simd_double3(x: 0.0, y: 0.0, z: -670002.0)
		
		// Number formatter
		numberFormatter.numberStyle = .decimal
		
		// UI Update Loop
		startUserInterfaceUpdateTimer()
		theSpacecraft.missionHasStarted = true
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		navigationController?.isNavigationBarHidden = true
		updateButtonStates()
	}
	
	override var shouldAutorotate: Bool {
		return true
	}
	
	override var prefersStatusBarHidden: Bool {
		return true
	}
	
	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		if UIDevice.current.userInterfaceIdiom == .phone {
			return .allButUpsideDown
		} else {
			return .all
		}
	}
	
	// MARK: - SceneKit
	
	func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		// Skip physics updates in initial frame, in order to get an accurate system time.
		if let gameState = gameState {
			if scenePreviousRenderTime != -1.0 {
				let interval = time - scenePreviousRenderTime
				gameState.universalTime += interval
				updateCraft(interval: interval)
				updatePlanets(time: gameState.universalTime)
			}
		}
		scenePreviousRenderTime = time
	}
	
	func updateCraft(interval:TimeInterval) {
		// Update the craft position and rotation
		theSpacecraft.updatePhysics(interval: interval)
	}
	
	func updatePlanets(time:TimeInterval) {
		//let earthSecondsPerDay = Double(6 * 60 * 60)
		let earthSecondsPerDay = Double(40 * 60) // Fast rotation for testing
		let earthRotation = (time / earthSecondsPerDay + 1.0).truncatingRemainder(dividingBy: 1.0)
		let earthAngle = Float(-earthRotation * 2.0 * .pi)
		earth?.eulerAngles = SCNVector3(x:0, y:earthAngle, z:0)
	}
	
	// MARK: - Update UI
	
	func updateReadouts() {
		// Altitude
		let roundedAltitude = round(theSpacecraft.altitude())
		if roundedAltitude > 999999 {
			let altKm = roundedAltitude / 1000.0
			let decimals = (altKm >= 10000.0) ? 0 : 1
			numberFormatter.maximumFractionDigits = decimals
			numberFormatter.minimumFractionDigits = decimals
			altitudeReadout?.text = numberFormatter.string(from: roundedAltitude/1000.0 as NSNumber)
			altitudeUnitsLabel?.text = "km"
		} else {
			numberFormatter.maximumFractionDigits = 0
			numberFormatter.minimumFractionDigits = 0
			altitudeReadout?.text = numberFormatter.string(from: roundedAltitude as NSNumber)
			altitudeUnitsLabel?.text = "m"
		}
		
		// Velocity
		numberFormatter.maximumFractionDigits = 1
		numberFormatter.minimumFractionDigits = 1
		velocityReadout?.text = numberFormatter.string(from: theSpacecraft.velocityScalar() as NSNumber)
		
		// Orientation
		// Up should always be the vector away from the center of the planet being orbited.
		attitudeIndicator?.orientation = theSpacecraft.orientation()
		let degreeHeading = degrees(fromRadians: theSpacecraft.heading())
		headingReadout?.text = String(format:"%1.0f°", round(degreeHeading))
		
		// Mission Elapsed Time and Universal Time
		if let gameState = gameState {
			METReadout?.text = gameState.elapsedTimeString(since: theSpacecraft.missionStartTime)
			let (utDate, utTime) = gameState.universalTimeString()
			UTCDayReadout?.text = utDate
			UTCTimeReadout?.text = utTime
		}
	}
	
	func updateButtonStates() {
		if theSpacecraft.enableRCS {
			RCSButton?.backgroundColor = buttonGreenlightBackgroundColor
		} else {
			RCSButton?.backgroundColor = buttonNormalBackgroundColor
		}
		
		if theSpacecraft.enableSAS {
			SASButton?.backgroundColor = buttonGreenlightBackgroundColor
		} else {
			SASButton?.backgroundColor = buttonNormalBackgroundColor
		}
	}
	
	func degrees(fromRadians: Double) -> Double {
		return (fromRadians / (2 * .pi) + 1.0).truncatingRemainder(dividingBy: 1.0) * 360.0
	}
	
	// MARK: - UI Update Loop
	
	func startUserInterfaceUpdateTimer() {
		let interval = userInterfaceUpdateInterval
		userInterfaceUpdateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { _ in
			// Update UI only. Physics is updated in the renderer(_:updateAtTime)
			self.updateReadouts()
		})
	}
	
	func stopUserInterfaceUpdateTimer() {
		userInterfaceUpdateTimer?.invalidate()
		userInterfaceUpdateTimer = nil
	}
	
	// MARK: - Handle Buttons
	
	@IBAction func handleEscape(_ sender: Any?) {
		// Pause physics while in pause menu.
		sceneView?.pause(nil)
		stopUserInterfaceUpdateTimer()
		
		let alert = UIAlertController(title: "Paused", message: nil, preferredStyle: .actionSheet)
		
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
			// Resume physics
			self?.scenePreviousRenderTime = -1.0
			self?.sceneView?.play(nil)
			self?.startUserInterfaceUpdateTimer()
		}))
		
		alert.addAction(UIAlertAction(title: "Space Center", style: .default, handler: { [weak self] _ in
			// Go back to Space Center
			self?.navigationController?.popViewController(animated: true)
		}))
		
		present(alert, animated: true, completion: nil)
	}

	@IBAction func fullThrottle(_ sender: Any?) {
	}

	@IBAction func cutThrottle(_ sender: Any?) {
	}
	
	@IBAction func toggleRCS(_ sender: Any?) {
		theSpacecraft.toggleRCS()
		updateButtonStates()
	}
	
	@IBAction func toggleSAS(_ sender: Any?) {
		theSpacecraft.toggleSAS()
		updateButtonStates()
	}
	
	@IBAction func pitchUpOn(_ sender: Any?) {
		theSpacecraft.pilotControls.x = -1.0
	}

	@IBAction func pitchDownOn(_ sender: Any?) {
		theSpacecraft.pilotControls.x = 1.0
	}
	
	@IBAction func yawLeftOn(_ sender: Any?) {
		theSpacecraft.pilotControls.z = -1.0
	}
	
	@IBAction func yawRightOn(_ sender: Any?) {
		theSpacecraft.pilotControls.z = 1.0
	}
	
	@IBAction func rollLeft(_ sender: Any?) {
		theSpacecraft.pilotControls.y = -1.0
	}
	
	@IBAction func rollRight(_ sender: Any?) {
		theSpacecraft.pilotControls.y = 1.0
	}
	
	@IBAction func rotationControlOff(_ sender: Any?) {
		theSpacecraft.pilotControls = float3()
		if theSpacecraft.enableSAS {
			theSpacecraft.clearAllForces()
		}
	}
	

	// MARK: - Gestures
	
	@objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
		guard let scnView = sceneView else { return }
		
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = UIColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
        }
    }
    

}
