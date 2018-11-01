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
	var altitude = 0.0
	var velocityVectors:[Double] = [0.0, 0.0, 0.0]
	var rotationVectors:[Double] = [0.0, 0.0, 0.0]
	var universalTime = 0.0
	var missionStartTime = 0.0
	var craft:SCNNode?
	
	// Other variables
	let buttonGreenlightBackgroundColor = UIColor(hue: 135.0/360.0, saturation: 0.67, brightness: 1.0, alpha: 0.67)
	let buttonNormalBackgroundColor = UIColor(white: 1.0, alpha: 0.67)

	let numberFormatter = NumberFormatter()
	
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
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView?.addGestureRecognizer(tapGesture)
		
		// Number formatter
		numberFormatter.numberStyle = .decimal
		
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
		altitudeReadout?.text = numberFormatter.string(from: altitude as NSNumber)
		velocityReadout?.text = numberFormatter.string(from: velocityVectors[0] as NSNumber)
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
	
	// MARK: - Handle Buttons
	
	@IBAction func handleEscape(_ sender: Any?) {
		let alert = UIAlertController(title: "Paused", message: nil, preferredStyle: .actionSheet)
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		
		// Go back to Space Center
		alert.addAction(UIAlertAction(title: "Space Center", style: .default, handler: { [weak self] _ in
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
	}

	@IBAction func pitchUpOff(_ sender: Any?) {
	}

	@IBAction func pitchDownOn(_ sender: Any?) {
	}
	
	@IBAction func pitchDownOff(_ sender: Any?) {
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
