//
//  CelestialBody.swift
//  Space Program
//
//  Created by Lucius Kwok on 11/23/18.
//  Copyright © 2018 Felt Tip Inc. All rights reserved.
//

import Foundation
import SceneKit

class CelestialBody {
	let orbit: OrbitalElements
	let gravitationalConstant: Double
	let radius: Double
	let sceneNode: SCNNode
	
	init(orbit o:OrbitalElements, gravitationalConstant gm:Double, radius r:Double, sceneNode n:SCNNode) {
		orbit = o
		gravitationalConstant = gm
		radius = r
		sceneNode = n
		// sceneNode should be a sphere with radius=1.0m, this will scale the sphere to match the radius
		n.scale = SCNVector3(r, r, r)
	}
	
	
}
