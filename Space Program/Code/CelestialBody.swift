//
//  CelestialBody.swift
//  Space Program
//
//  Created by Lucius Kwok on 11/23/18.
//  Copyright © 2018 Felt Tip Inc. All rights reserved.
//

import Foundation

class CelestialBody {
	let orbit: OrbitalElements
	let gravitationalConstant: Double
	let radius: Double
	
	init(orbit o:OrbitalElements, gravitationalConstant gm:Double, radius r:Double) {
		orbit = o
		gravitationalConstant = gm
		radius = r
	}
	
	
}
