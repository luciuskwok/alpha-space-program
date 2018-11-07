//
//  Spacecraft.swift
//  Space Program
//
//  Created by Lucius Kwok on 10/31/18.
//  Copyright © 2018 Felt Tip Inc. All rights reserved.
//

import Foundation
import SceneKit


class Spacecraft {
	// Parts
	var rootPart:CraftPart?
	var sceneNode:SCNNode?
	
	// Physics state
	var position = DoubleVector3()
	var velocity = DoubleVector3(x:2287.0, y:0.0, z:0.0)
	var missionStartTime:TimeInterval = 0.0
	var missionHasStarted = false
	
	// Sphere of influence
	var planetRadius = Double(600000)
	var planetPosition = DoubleVector3()
	
	// Other state
	var enableRCS = false
	var enableSAS = true
	var throttle:Double = 1.0
	
	// Constants
	let tau = 2.0 * Double.pi

	// MARK: -
	
	func altitude() -> Double {
		let distance = position.distance(to: planetPosition)
		return distance - planetRadius
	}
	
	func velocityScalar() -> Double {
		return velocity.distance(to: DoubleVector3())
	}
	
	func orientation() -> simd_quatf {
		if let node = sceneNode {
			return node.simdOrientation
		}
		return simd_quatf()
	}
	
	func rotation() -> SCNVector4 {
		// Returns axis in first 3 values, and angle of rotation in 4th value.
		if let node = sceneNode {
			return node.rotation
		}
		return SCNVector4()
	}
	
	// MARK: - Attitude Indicators
	// The convention used here is that the craft's Y-axis represents its forward motion.
	
	func pitchRollHeadingAngles() -> float3 {
		// Use the vector pointing forward from the craft to determine pitch, heading, and up/down orientation.
		let fwd = orientation().act(float3(x:0.0, y:1.0, z:0.0))
		// Use the right-wing vector to determine roll.
		let right = orientation().act(float3(x:1.0, y:0.0, z:0.0))
		// Measure the pitch as the angle between the rotated vector and the x-y (horizontal) plane.
		let pitch = 0.5 * .pi - atan2f(hypotf(fwd.x, fwd.y), fwd.z)
		// Measure the roll as the angle between the rotated vector and the x-y (horizontal) plane.
		let roll = 0.5 * .pi - atan2f(hypotf(right.x, right.y), right.z)
		// Measure the heading as the angle in the x-y plane.
		let heading = atan2f(fwd.x, fwd.y)
		return float3(x:pitch, y:roll, z:heading)
	}
	
	
	// MARK: -
	
	func updatePhysics(interval:TimeInterval) {
		// Update the craft position and rotation
	}
	
	// MARK: -
	
	func toggleRCS() {
		enableRCS = !enableRCS
	}
	
	func toggleSAS() {
		enableSAS = !enableSAS
		if enableSAS {
			killRotation()
		}
	}
	
	func killRotation() {
		// Stub.
		// Need to figure out 3-d rotation to write this code.
	}
	
	func instantRotateDegrees(by deltaAngles:DoubleVector3) {
		if let node = sceneNode {
			var angles = node.eulerAngles
			angles.x += Float(deltaAngles.x / 360.0 * tau)
			angles.y += Float(deltaAngles.y / 360.0 * tau)
			angles.z += Float(deltaAngles.z / 360.0 * tau)
			node.eulerAngles = angles
			
			//printDebugInfo()

		}
	}
	
	func printDebugInfo() {
		if let node = sceneNode {
			let t = node.transform
			var string:String
			
			print("== Transform 4x4 ==")
			string = String(format: "%1.3f %1.3f %1.3f %1.3f", t.m11, t.m12, t.m13, t.m14)
			print (string)
			string = String(format: "%1.3f %1.3f %1.3f %1.3f", t.m21, t.m22, t.m23, t.m24)
			print (string)
			string = String(format: "%1.3f %1.3f %1.3f %1.3f", t.m31, t.m32, t.m33, t.m34)
			print (string)
			string = String(format: "%1.3f %1.3f %1.3f %1.3f", t.m41, t.m42, t.m43, t.m44)
			print (string)

		}
	}
	
	func setPitchControl(_ pitch:Double) {
		// Testing: rotate by 15° increments
		if pitch > 0.0 {
			// Rotate +15° pitch
			instantRotateDegrees(by: DoubleVector3(x:15.0, y:0.0, z:0.0))
		} else if pitch < 0.0 {
			// Rotate -15° pitch
			instantRotateDegrees(by: DoubleVector3(x:-15.0, y:0.0, z:0.0))
		}
	
		if pitch == 0.0 && enableSAS {
			killRotation()
		}
	}

	func setYawControl(_ yaw:Double) {
		// Testing: yaw by 15° increments.
		if yaw > 0.0 {
			// Rotate +15° yaw
			instantRotateDegrees(by: DoubleVector3(x:0.0, y:15.0, z:0.0))
		} else if yaw < 0.0 {
			// Rotate -15° yaw
			instantRotateDegrees(by: DoubleVector3(x:0.0, y:-15.0, z:0.0))
		}

		if yaw == 0.0 && enableSAS {
			killRotation()
		}
	}

	func setRollControl(_ roll:Double) {
		// Testing: roll by 15° increments.
		if roll > 0.0 {
			// Rotate +15° roll
			instantRotateDegrees(by: DoubleVector3(x:0.0, y:0.0, z:15.0))
		} else if roll < 0.0 {
			// Rotate -15° roll
			instantRotateDegrees(by: DoubleVector3(x:0.0, y:0.0, z:-15.0))
		}

		if roll == 0.0 && enableSAS {
			killRotation()
		}
	}

	
}
