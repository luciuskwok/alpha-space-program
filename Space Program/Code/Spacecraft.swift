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
	var angularVelocity = DoubleVector3()
	var angularAcceleration = DoubleVector3()
	var missionStartTime:TimeInterval = 0.0
	var missionHasStarted = false
	
	// Sphere of influence
	var planetRadius = Double(600000)
	var planetPosition = DoubleVector3()
	
	// Other state
	var enableRCS = false
	var enableSAS = true
	var throttle:Double = 1.0

	// MARK: -
	
	func altitude() -> Double {
		let distance = position.distance(to: planetPosition)
		return distance - planetRadius
	}
	
	func velocityScalar() -> Double {
		return velocity.distance(to: DoubleVector3())
	}
	
	func orientation() -> DoubleQuaternion {
		if let a = sceneNode?.orientation {
			return DoubleQuaternion(x:a.x, y:a.y, z:a.z, w:a.w)
		}
		return DoubleQuaternion()
	}
	
	// MARK: -
	
	func updatePhysics(interval:TimeInterval) {
		// Update the craft position and rotation
		
		// Add angular acceleration to angular velocity
		let initialAngularVelocity = angularVelocity
		angularVelocity.x += angularAcceleration.x * interval
		angularVelocity.y += angularAcceleration.y * interval
		angularVelocity.z += angularAcceleration.z * interval
		
		// Rotation delta
		let dx = interval * (initialAngularVelocity.x + angularVelocity.x) * 0.5
		let dy = interval * (initialAngularVelocity.y + angularVelocity.y) * 0.5
		let dz = interval * (initialAngularVelocity.z + angularVelocity.z) * 0.5
		
		// Apply rotation
		if let node = sceneNode {
			var currentRotation = node.eulerAngles
			currentRotation.x += Float(dx)
			currentRotation.y +=  Float(dy)
			currentRotation.z += Float(dz)
			node.eulerAngles = currentRotation
		}
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
		angularVelocity = DoubleVector3()
		angularAcceleration = DoubleVector3()
	}
	
	func setPitchControl(_ x:Double) {
		angularAcceleration.x = x * Double.pi / 9.0
		
		if x == 0.0 && enableSAS {
			killRotation()
		}
	}

	func setYawControl(_ yaw:Double) {
		angularAcceleration.z = yaw * Double.pi / 9.0
		
		if yaw == 0.0 && enableSAS {
			killRotation()
		}
	}

	func setRollControl(_ roll:Double) {
		angularAcceleration.y = roll * Double.pi / 9.0
		
		if roll == 0.0 && enableSAS {
			killRotation()
		}
	}

	
}
