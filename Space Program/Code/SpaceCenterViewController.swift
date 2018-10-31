//
//  SpaceCenterViewController.swift
//  Space Program
//
//  Created by Lucius Kwok on 10/30/18.
//  Copyright © 2018 Felt Tip Inc. All rights reserved.
//

import UIKit

class SpaceCenterViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
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
