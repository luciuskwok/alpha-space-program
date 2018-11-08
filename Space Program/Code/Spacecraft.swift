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
	var position = simd_double3()
	var velocity = simd_double3(x:2287.0, y:0.0, z:0.0)
	var missionStartTime:TimeInterval = 0.0
	var missionHasStarted = false
	var controlTorque = Float(1000.0) // newton-meters
	
	// Sphere of influence
	var planetRadius = Double(600000)
	var planetPosition = simd_double3()
	
	// Other state
	var enableRCS = false
	var enableSAS = true
	var throttle = Float(1.0)
	var pilotControls = float3()
	
	// Constants
	let tau = 2.0 * Float.pi
	// Vectors
	let forward = float3(x:0.0, y:1.0, z:0.0)
	let right = float3(x:1.0, y:0.0, z:0.0)
	let up = float3(x:0.0, y:0.0, z:-1.0)
	

	// MARK: -
	
	func distance(from:simd_double3, to:simd_double3) -> Double {
		let dx = to.x - from.x
		let dy = to.y - from.y
		let dz = to.z - from.z
		let a = hypot(dx, dy)
		return hypot(a, dz)
	}
	
	func altitude() -> Double {
		let d = distance(from:position, to: planetPosition)
		return d - planetRadius
	}
	
	func velocityScalar() -> Double {
		return distance(from:velocity, to: simd_double3())
	}
	
	func orientation() -> simd_quatf {
		// Use the presentation node because it is changed by the physics simulation while the sceneNode isn't.
		if let node = sceneNode?.presentation {
			return node.simdOrientation
		}
		return simd_quatf()
	}
	
	// MARK: - Physics
	// Using SceneKit physics
	
	func updatePhysicsBody() {
		let body = SCNPhysicsBody.dynamic()
		body.mass = 2500 // kg
		let cylinder = SCNCylinder(radius: 0.625, height: 3.1)
		body.physicsShape = SCNPhysicsShape(geometry: cylinder, options: [:])
		body.usesDefaultMomentOfInertia = true
		
		// There is no drag in space
		body.angularDamping = 0.0
		body.damping = 0.0
		
		sceneNode?.physicsBody = body
	}
	
	func clearAllForces() {
		sceneNode?.physicsBody?.clearAllForces()
	}
	
	func updatePhysics(interval:TimeInterval) {
		// Update applied torque on each axis separately
		
		// Pitch
		if pilotControls.x != 0.0 {
			applyTorque(axis: right, angle: pilotControls.x * controlTorque, asImpulse:false)
		}

		// Roll
		if pilotControls.y != 0.0 {
			applyTorque(axis: forward, angle: pilotControls.y * controlTorque, asImpulse:false)
		}

		// Yaw
		if pilotControls.z != 0.0 {
			applyTorque(axis: up, angle: pilotControls.z * controlTorque, asImpulse:false)
		}
	}

	func applyTorque(axis:float3, angle:Float, asImpulse:Bool) {
		// SceneKit applies torque in the world's frame of reference, so rotate the axis to match the craft's orientation.
		let localAxis = orientation().act(axis)
		let torque = SCNVector4(x:localAxis.x, y:localAxis.y, z:localAxis.z, w:angle)
		sceneNode?.physicsBody?.applyTorque(torque, asImpulse: asImpulse)
	}
	

	// MARK: - Attitude Indicators
	// The convention used here is that the craft's Y-axis represents its forward motion.
	
	func heading() -> Double {
		// Measure the heading as the angle in the x-y plane.
		let forwardOrientation = orientation().act(forward)
		return Double(atan2(forwardOrientation.x, forwardOrientation.y))
	}
	
	// MARK: -
	
	func toggleRCS() {
		enableRCS = !enableRCS
	}
	
	func toggleSAS() {
		enableSAS = !enableSAS
		if enableSAS {
			clearAllForces()
		}
	}
	
	func instantRotateDegrees(by deltaAngles:float3) {
		if let node = sceneNode {
			let fwd = float3(x:0.0, y:1.0, z:0.0)
			let up = float3(x:0.0, y:0.0, z:-1.0)
			let right = float3(x:1.0, y:0.0, z:0.0)
			
			// Pitch
			let pitchAngle = deltaAngles.x / 360.0 * tau
			node.simdLocalRotate(by: simd_quatf(angle:pitchAngle, axis:right))

			// Roll
			let rollAngle = deltaAngles.y / 360.0 * tau
			node.simdLocalRotate(by: simd_quatf(angle:rollAngle, axis:fwd))

			// Yaw
			let yawAngle = deltaAngles.z / 360.0 * tau
			node.simdLocalRotate(by: simd_quatf(angle:yawAngle, axis:up))
		}
	}

	
	// MARK: - Debug
	
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
	

}
