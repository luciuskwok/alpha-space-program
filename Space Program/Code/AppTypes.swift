//
//  AppTypes.swift
//  Space Program
//
//  Created by Lucius Kwok on 11/3/18.
//  Copyright © 2018 Felt Tip Inc. All rights reserved.
//

import Foundation

struct DoubleVector3 {
	var x: Double
	var y: Double
	var z: Double
	
	init() {
		x = 0.0; y = 0.0; z = 0.0
	}
	
	init(x: Double, y: Double, z: Double) {
		self.x = x
		self.y = y
		self.z = z
	}
	
	func distance(to: DoubleVector3) -> Double {
		let dx = to.x - self.x
		let dy = to.y - self.y
		let dz = to.z - self.z
		let a = hypot(dx, dy)
		return hypot(a, dz)
	}
	
}
