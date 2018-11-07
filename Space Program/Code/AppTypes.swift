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
	
	init(x: Float, y: Float, z: Float) {
		self.x = Double(x)
		self.y = Double(y)
		self.z = Double(z)
	}
	
	func distance(to: DoubleVector3) -> Double {
		let dx = to.x - self.x
		let dy = to.y - self.y
		let dz = to.z - self.z
		let a = hypot(dx, dy)
		return hypot(a, dz)
	}
	
}

struct DoubleVector4 {
	var x: Double
	var y: Double
	var z: Double
	var w: Double
	
	init() {
		x = 0.0; y = 1.0; z = 0.0; w = 0.0
	}
	
	init(x: Double, y: Double, z: Double, w: Double) {
		self.x = x
		self.y = y
		self.z = z
		self.w = w
	}
	
	init(x: Float, y: Float, z: Float, w: Float) {
		self.x = Double(x)
		self.y = Double(y)
		self.z = Double(z)
		self.w = Double(w)
	}
	
	init(fromEulerAngles euler: DoubleVector3) {
		let c1 = cos(euler.z * 0.5)
		let c2 = cos(euler.y * 0.5)
		let c3 = cos(euler.x * 0.5)
		let s1 = sin(euler.z * 0.5)
		let s2 = sin(euler.y * 0.5)
		let s3 = sin(euler.x * 0.5)
		
		self.w = c1 * c2 * c3 + s1 * s2 * s3
		self.x = c1 * s2 * c3 - s1 * c2 * s3
		self.y = c1 * c2 * s3 + s1 * s2 * c3
		self.z = s1 * c2 * c3 - c1 * s2 * s3
	}
}
