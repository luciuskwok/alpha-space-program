//
//  SpaceCenterViewController.swift
//  Space Program
//
//  Created by Lucius Kwok on 10/30/18.
//  Copyright © 2018 Felt Tip Inc. All rights reserved.
//

import UIKit

class SpaceCenterViewController: UIViewController {
	
	var gameState = GameState()

	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		navigationController?.isNavigationBarHidden = false
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "ShowLaunchPad" {
			if let dest = segue.destination as? GameViewController {
				dest.gameState = self.gameState
			}
		} else if segue.identifier == "ShowTracking" {
			if let dest = segue.destination as? TrackingViewController {
				dest.gameState = self.gameState
			}
		}
	}
	
	// MARK: -
	
	@IBAction func showVAB(_ sender:Any?) {
		self.performSegue(withIdentifier: "ShowVAB", sender: nil)
	}
	
	@IBAction func showLaunchPad(_ sender:Any?) {
		self.performSegue(withIdentifier: "ShowLaunchPad", sender: nil)
	}
	
	@IBAction func showHangar(_ sender:Any?) {
		//self.performSegue(withIdentifier: "ShowHangar", sender: nil)
	}
	
	@IBAction func showTracking(_ sender:Any?) {
		self.performSegue(withIdentifier: "ShowTracking", sender: nil)
	}
	
	@IBAction func showMissionControl(_ sender:Any?) {
		self.performSegue(withIdentifier: "ShowMissionControl", sender: nil)
	}

	@IBAction func showResearch(_ sender:Any?) {
		self.performSegue(withIdentifier: "ShowResearch", sender: nil)
	}
	
}
