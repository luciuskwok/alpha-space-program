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
	
	var theSpacecraft = Spacecraft()
	var universalTime = 0.0
	
	var camera: CraftCamera?
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
				let craftCamera = CraftCamera(camera: cameraNode)
				craftCamera.camera = cameraNode
				craftCamera.vabMode = false
				craftCamera.target = SCNVector3(x:0.0, y:0.0, z:0.0)
				craftCamera.distance = 10.0
				craftCamera.distanceMax = 600.0
				craftCamera.distanceMin = 2.5
				craftCamera.addGestureRecognizers(to: sceneView)
				craftCamera.updateCameraPosition()
				camera = craftCamera
			} else {
				print("[LK] Camera not found.")
			}

			// Testing: Tap gesture recognizer that highlights part in red
			let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
			sceneView.addGestureRecognizer(tapGesture)
		}
		
		// Set up spacecraft
		theSpacecraft.position = DoubleVector3(x: 0.0, y: 0.0, z: -670002.0)
		
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
		if scenePreviousRenderTime != -1.0 {
			let interval = time - scenePreviousRenderTime
			universalTime += interval
			updateCraft(interval: interval)
			updatePlanets(time: universalTime)
		}
		scenePreviousRenderTime = time
	}
	
	func updateCraft(interval:TimeInterval) {
		// Update the craft position and rotation
		theSpacecraft.updatePhysics(interval: interval)
		
		//		let action = SCNAction.rotateBy(x: x, y: y, z: z, duration: interval)
		//		craft?.runAction(action)
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
		let angles = theSpacecraft.pitchRollHeadingAngles()
		let heading = angles.z
		if let ai = attitudeIndicator {
			ai.pitchAngle = CGFloat(angles.x)
			ai.rollAngle = CGFloat(angles.y)
			ai.heading = CGFloat(heading)
		}
		headingReadout?.text = String(format:"%1.0f°", round(degrees(fromRadians:Double(heading))))
		
		// MET: Mission Elapsed Time
		let met = universalTime - theSpacecraft.missionStartTime
		let (metN, metY, metD, metH, metM, metS) = componentsFromTimeInterval(met)
		var metString = ""
		if metY > 0 {
			metString = String(format:"%dY", metY)
		}
		if metD > 0 || metString.count > 0 {
			metString = String(format:"%@ %dd", metString, metD)
		}
		if metH > 0 || metString.count > 0 {
			metString = String(format:"%@ %dh", metString, metH)
		}
		if metM > 0 || metString.count > 0 {
			metString = String(format:"%@ %dm", metString, metM)
		}
		metString = String(format:"%@ %1.0fs", metString, floor(metS))
		if metN < 0 {
			metString = "-" + metString
		}
		METReadout?.text = metString
		
		// UT: Universal Time
		let (_, utY, utD, utH, utM, utS) = componentsFromTimeInterval(universalTime)
		UTCDayReadout?.text = String(format:"Y%d, d%d", utY+1, utD+1)
		UTCTimeReadout?.text = String(format:"%02d:%02d:%02.0f", utH, utM, floor(utS))

	}
	
	func componentsFromTimeInterval(_ interval:Double) -> (sign: Int, year: Int, day: Int, hour: Int, minute: Int, second: Double) {
		var sec = interval
		var sign = 1
		
		if sec < 0.0 {
			sec = -sec
			sign = -1
		}
		
		let min = Int(floor(sec / 60.0))
		let hr = min / 60
		let day = hr / 6
		let year = day / 426
		let secRemainder = sec.truncatingRemainder(dividingBy:60.0)
		
		return (sign, year, day % 426, hr % 6, min % 60, secRemainder)
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
		theSpacecraft.setPitchControl(-1.0)
	}

	@IBAction func pitchDownOn(_ sender: Any?) {
		theSpacecraft.setPitchControl(1.0)
	}
	
	@IBAction func yawLeftOn(_ sender: Any?) {
		theSpacecraft.setYawControl(-1.0)
	}
	
	@IBAction func yawRightOn(_ sender: Any?) {
		theSpacecraft.setYawControl(1.0)
	}
	
	@IBAction func rollLeft(_ sender: Any?) {
		theSpacecraft.setRollControl(1.0)
	}
	
	@IBAction func rollRight(_ sender: Any?) {
		theSpacecraft.setRollControl(-1.0)
	}
	
	@IBAction func rotationControlOff(_ sender: Any?) {
		theSpacecraft.setPitchControl(0.0)
		theSpacecraft.setYawControl(0.0)
		theSpacecraft.setRollControl(0.0)
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
