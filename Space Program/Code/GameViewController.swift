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

class GameViewController: UIViewController {
	
	@IBOutlet weak var sceneView: SCNView?
	
	@IBOutlet weak var escapeButton: UIButton?
	
	@IBOutlet weak var altitudeReadout: UILabel?

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
	var rotationVectors:[Double] = [0.0, 0.0, 0.0]
	var rotationDeltas:[Double] = [0.0, 0.0, 0.0]
	var universalTime = 0.0
	var missionStartTime = 0.0
	var missionHasStarted = false
	var craft:SCNNode?
	
	// Other variables
	let buttonGreenlightBackgroundColor = UIColor(hue: 135.0/360.0, saturation: 0.67, brightness: 1.0, alpha: 0.67)
	let buttonNormalBackgroundColor = UIColor(white: 1.0, alpha: 0.67)

	let numberFormatter = NumberFormatter()
	let physicsUpdateInterval = 1.0/30.0
	var physicsTimer:Timer?
	
	
	// MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = SCNScene(named: "CMD-1.scnassets/CMD-1.scn")!
        craft = scene.rootNode.childNode(withName: "Craft-1", recursively: true)
		
		// Remove floor plane
		let floor = scene.rootNode.childNode(withName: "Floor_Plane", recursively: true)
		floor?.removeFromParentNode()
		
		// Add space skybox
		scene.background.contents = [
			UIImage(named:"space_skybox_right"),
			UIImage(named:"space_skybox_left"),
			UIImage(named:"space_skybox_up"),
			UIImage(named:"space_skybox_down"),
			UIImage(named:"space_skybox_front"),
			UIImage(named:"space_skybox_back")
		]
        
        sceneView?.scene = scene
        sceneView?.allowsCameraControl = true
        sceneView?.showsStatistics = true
        sceneView?.backgroundColor = UIColor.black
        
        // Tap gesture recognizer that highlights part in red
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView?.addGestureRecognizer(tapGesture)
		
		// Number formatter
		numberFormatter.numberStyle = .decimal
		
		// Physics
		startPhysicsTimer()
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
	
	// MARK: - Update UI
	
	func updateReadouts() {
		// Craft stats
		altitudeReadout?.text = numberFormatter.string(from: altitude as NSNumber)
		velocityReadout?.text = numberFormatter.string(from: velocityVectors[0] as NSNumber)
		
		// MET: Mission Elapsed Time
		let met = universalTime * 60.0 - missionStartTime
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
		let (_, utY, utD, utH, utM, utS) = componentsFromTimeInterval(universalTime * 60.0)
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
		
		// Update rotation vectors
		rotationVectors[0] += rotationDeltas[0] * interval
		rotationVectors[1] += rotationDeltas[1] * interval
		rotationVectors[2] += rotationDeltas[2] * interval

		// Rotation
		let x = CGFloat(rotationVectors[0] * interval)
		let y = CGFloat(rotationVectors[1] * interval)
		let z = CGFloat(rotationVectors[2] * interval)

		let action = SCNAction.rotateBy(x: x, y: y, z: z, duration: interval)
		craft?.runAction(action)
	}
	
	// MARK: - Physics
	
	func startPhysicsTimer() {
		let interval = physicsUpdateInterval
		physicsTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { _ in
			// Update physics and UI
			self.universalTime += interval
			self.updateCraft(interval: interval)
			self.updateReadouts()
		})
	}
	
	func stopPhysicsTimer() {
		physicsTimer?.invalidate()
		physicsTimer = nil
	}
	
	// MARK: - Handle Buttons
	
	@IBAction func handleEscape(_ sender: Any?) {
		// Stop physics while in pause menu.
		stopPhysicsTimer()
		
		let alert = UIAlertController(title: "Paused", message: nil, preferredStyle: .actionSheet)
		
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
			// Resume physics
			self?.startPhysicsTimer()
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
			rotationVectors = [0.0, 0.0, 0.0]
		}
	}
	
	@IBAction func pitchUpOn(_ sender: Any?) {
		rotationDeltas[0] = Double.pi / 32.0
	}

	@IBAction func pitchUpOff(_ sender: Any?) {
		rotationDeltas[0] = 0.0
		if enableSAS {
			rotationVectors = [0.0, 0.0, 0.0]
		}
	}

	@IBAction func pitchDownOn(_ sender: Any?) {
		rotationDeltas[0] = -Double.pi / 32.0
	}
	
	@IBAction func pitchDownOff(_ sender: Any?) {
		rotationDeltas[0] = 0.0
		if enableSAS {
			rotationVectors = [0.0, 0.0, 0.0]
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
