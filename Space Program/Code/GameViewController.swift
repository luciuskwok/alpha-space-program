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

	@IBOutlet weak var RCSButton: UIButton?
	@IBOutlet weak var SASButton: UIButton?

	@IBOutlet weak var pitchUpButton: UIButton?
	@IBOutlet weak var pitchDownButton: UIButton?
	@IBOutlet weak var yawLeftButton: UIButton?
	@IBOutlet weak var yawRightButton: UIButton?
	@IBOutlet weak var rollLeftButton: UIButton?
	@IBOutlet weak var rollRightButton: UIButton?
	
	// Variables for spacecraft state, which should probably be moved into the Spacecraft object.
	var enableRCS = false
	var enableSAS = true
	var throttle = 1.0
	var altitude = 70002.0
	var velocityVectors:[Double] = [2287.0, 0.0, 0.0]
	var angularVelocity:[Double] = [0.0, 0.0, 0.0]
	var angularAcceleration:[Double] = [0.0, 0.0, 0.0]
	var universalTime = 0.0
	var missionStartTime = 0.0
	var missionHasStarted = false
	
	var camera: CraftCamera?
	var craft:SCNNode?
	var earth:SCNNode?

	// Other variables
	let buttonGreenlightBackgroundColor = UIColor(hue: 135.0/360.0, saturation: 0.67, brightness: 1.0, alpha: 0.67)
	let buttonNormalBackgroundColor = UIColor(white: 1.0, alpha: 0.67)

	let numberFormatter = NumberFormatter()
	let userInterfaceUpdateInterval = 1.0/15.0
	var userInterfaceUpdateTimer:Timer?
	
	// MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = SCNScene(named: "Scene.scnassets/Universe.scn")!
		
		// Get the earth and camera
		earth = scene.rootNode.childNode(withName: "Earth", recursively: true)

		// Add craft from CMD-1
		if let craftScene = SCNScene(named: "Scene.scnassets/CMD-1.dae") {
			if let loadedCraft = craftScene.rootNode.childNode(withName: "Craft", recursively: true) {
				scene.rootNode.addChildNode(loadedCraft)
				craft = loadedCraft
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
			sceneView.allowsCameraControl = false
			sceneView.showsStatistics = true
			sceneView.backgroundColor = UIColor.black

			// Set up camera
			if let cameraNode = scene.rootNode.childNode(withName: "Camera", recursively: true) {
				let craftCamera = CraftCamera(camera: cameraNode)
				craftCamera.camera = cameraNode
				craftCamera.vabMode = false
				craftCamera.target = SCNVector3(x:0.0, y:0.0, z:0.0)
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
		
		// Number formatter
		numberFormatter.numberStyle = .decimal
		
		// UI Update Loop
		startUserInterfaceUpdateTimer()
		missionHasStarted = true
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
		
	}
	
	// MARK: - Update UI
	
	func updateReadouts() {
		// Altitude
		let roundedAltitude = round(altitude)
		if roundedAltitude > 999999 {
			let altKm = roundedAltitude / 1000.0
			let dec = (altKm >= 10000.0) ? 0 : 1
			numberFormatter.maximumFractionDigits = dec
			numberFormatter.minimumFractionDigits = dec
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
		velocityReadout?.text = numberFormatter.string(from: velocityVectors[0] as NSNumber)
		
		// MET: Mission Elapsed Time
		let met = universalTime - missionStartTime
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
		metString = String(format:"%@ %1.0fs", metString, metS)
		if metN < 0 {
			metString = "-" + metString
		}
		METReadout?.text = metString
		
		// UT: Universal Time
		let (_, utY, utD, utH, utM, utS) = componentsFromTimeInterval(universalTime)
		UTCDayReadout?.text = String(format:"Y%d, d%d", utY+1, utD+1)
		UTCTimeReadout?.text = String(format:"%02d:%02d:%02.0f", utH, utM, utS)

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
		if enableRCS {
			RCSButton?.backgroundColor = buttonGreenlightBackgroundColor
		} else {
			RCSButton?.backgroundColor = buttonNormalBackgroundColor
		}
		
		if enableSAS {
			SASButton?.backgroundColor = buttonGreenlightBackgroundColor
		} else {
			SASButton?.backgroundColor = buttonNormalBackgroundColor
		}
	}
	
	func updateCraft(interval:TimeInterval) {
		// Update the craft position and rotation
		
		// Add angular acceleration to angular velocity
		let initialAngularVelocity = angularVelocity
		angularVelocity[0] += angularAcceleration[0] * interval
		angularVelocity[1] += angularAcceleration[1] * interval
		angularVelocity[2] += angularAcceleration[2] * interval

		// Rotation
		let x = CGFloat ( interval * (initialAngularVelocity[0] + angularVelocity[0]) * 0.5)
		let y = CGFloat ( interval * (initialAngularVelocity[1] + angularVelocity[1]) * 0.5)
		let z = CGFloat ( interval * (initialAngularVelocity[2] + angularVelocity[2]) * 0.5)

		let action = SCNAction.rotateBy(x: x, y: y, z: z, duration: interval)
		craft?.runAction(action)
	}
	
	// MARK: - UI Update Loop
	
	func startUserInterfaceUpdateTimer() {
		let interval = userInterfaceUpdateInterval
		userInterfaceUpdateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { _ in
			// Update physics and UI
			self.universalTime += interval
			self.updateCraft(interval: interval)
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
		enableRCS = !enableRCS
		updateButtonStates()
	}
	
	@IBAction func toggleSAS(_ sender: Any?) {
		enableSAS = !enableSAS
		updateButtonStates()
		
		if enableSAS {
			angularVelocity = [0.0, 0.0, 0.0]
		}
	}
	
	@IBAction func pitchUpOn(_ sender: Any?) {
		angularAcceleration[0] = Double.pi / 16.0
	}

	@IBAction func pitchUpOff(_ sender: Any?) {
		angularAcceleration[0] = 0.0
		if enableSAS {
			angularVelocity = [0.0, 0.0, 0.0]
		}
	}

	@IBAction func pitchDownOn(_ sender: Any?) {
		angularAcceleration[0] = -Double.pi / 32.0
	}
	
	@IBAction func pitchDownOff(_ sender: Any?) {
		angularAcceleration[0] = 0.0
		if enableSAS {
			angularVelocity = [0.0, 0.0, 0.0]
		}
	}
	
	@IBAction func yawLeft(_ sender: Any?) {
	}
	
	@IBAction func yawRight(_ sender: Any?) {
	}
	
	@IBAction func rollLeft(_ sender: Any?) {
	}
	
	@IBAction func rollRight(_ sender: Any?) {
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
