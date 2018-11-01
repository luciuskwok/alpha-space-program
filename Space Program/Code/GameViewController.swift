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

	// MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = SCNScene(named: "CMD-1.scnassets/CMD-1.scn")!
        let craft = scene.rootNode.childNode(withName: "Craft-1", recursively: true)!
        
        // animate the craft
        craft.runAction (SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))
        
        sceneView?.scene = scene
        sceneView?.allowsCameraControl = true
        sceneView?.showsStatistics = true
        sceneView?.backgroundColor = UIColor.black
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView?.addGestureRecognizer(tapGesture)
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		navigationController?.isNavigationBarHidden = true
	}
	
	@IBAction func handleEscape(_ sender: Any?) {
		let alert = UIAlertController(title: "Paused", message: nil, preferredStyle: .actionSheet)
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		
		// Go back to Space Center
		alert.addAction(UIAlertAction(title: "Space Center", style: .default, handler: { [weak self] _ in
			self?.navigationController?.popViewController(animated: true)
		}))
		
		present(alert, animated: true, completion: nil)
	}
    
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

}
