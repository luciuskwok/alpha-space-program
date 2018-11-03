//
//  CraftCamera.swift
//  Space Program
//
//  Created by Lucius Kwok on 11/3/18.
//  Copyright © 2018 Felt Tip Inc. All rights reserved.
//

import Foundation
import SceneKit


class CraftCamera {
	let tau = 2.0 * Float.pi

	var camera:SCNNode?
	var cameraTarget = SCNVector3(x:0.0, y:5.0, z:0.0)
	var cameraDistance:Float = 5.0
	var cameraPanAngle:Float = 0.0 // radians
	var cameraTiltAngle:Float = (15.0/180.0) * .pi // radians
	var panPreviousLocation = CGPoint()
	var tiltPreviousLocation = CGPoint()
	var pinchInitialCameraDistance:Float = 0.0

	// MARK: -
	
	func addGestureRecognizers(to view:UIView) {
		// Add gesture recognizers
		let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
		view.addGestureRecognizer(pinchGesture)
		
		let tiltGesture = UIPanGestureRecognizer(target: self, action: #selector(handleTilt(_:)))
		tiltGesture.minimumNumberOfTouches = 2
		tiltGesture.maximumNumberOfTouches = 2
		view.addGestureRecognizer(tiltGesture)
		
		let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
		panGesture.minimumNumberOfTouches = 1
		panGesture.maximumNumberOfTouches = 1
		view.addGestureRecognizer(panGesture)
	}
	
	func updateCameraPosition() {
		if let camera = camera {
			// Point camera by moving camera to target, changing its rotation, and translating by the distance while rotated.
			camera.position = cameraTarget
			camera.eulerAngles = SCNVector3(x: -cameraTiltAngle, y: cameraPanAngle, z:0.0)
			camera.localTranslate(by: SCNVector3(x:0, y:0, z:cameraDistance))
		}
	}
	
	@objc func handlePan(_ sender:UIGestureRecognizer) {
		let currentLocation = sender.location(in: sender.view)
		if sender.state == .changed || sender.state == .ended {
			// Orbit angle around point
			let deltaX = Float(currentLocation.x - panPreviousLocation.x)
			if deltaX != 0.0 {
				cameraPanAngle = (cameraPanAngle - deltaX * tau / 360.0 + tau).truncatingRemainder(dividingBy: tau)
			}
			
			// Height of target
			let deltaY = Float(currentLocation.y - panPreviousLocation.y)
			if deltaY != 0.0 {
				cameraTarget.y += deltaY * cameraDistance / 320.0
				cameraTarget.y = max(0.25, cameraTarget.y)
				cameraTarget.y = min(19.75, cameraTarget.y) // replace with actual max height limit
			}
			
			if deltaX != 0.0 || deltaY != 0.0 {
				updateCameraPosition()
			}
		}
		if sender.state == .cancelled {
			print("[LK] Pan cancelled")
		}
		panPreviousLocation = currentLocation
	}
	
	@objc func handleTilt(_ sender:UIGestureRecognizer) {
		let currentLocation = sender.location(in: sender.view)
		if (sender.state == .changed || sender.state == .ended) && sender.numberOfTouches == 2 {
			// Tilt camera from -85° to +85°
			let deltaY = Float(currentLocation.y - tiltPreviousLocation.y)
			if deltaY != 0.0 {
				let tiltLimitMax = 85.0/180.0 * Float.pi
				let tiltLimitMin = -85.0/180.0 * Float.pi
				cameraTiltAngle = min(tiltLimitMax, max(tiltLimitMin, cameraTiltAngle - deltaY * tau / 720.0))
				updateCameraPosition()
			}
		}
		if sender.state == .cancelled {
			print("[LK] Tilt cancelled")
		}
		tiltPreviousLocation = currentLocation
	}
	
	@objc func handlePinch(_ sender:UIGestureRecognizer) {
		if let pinch = sender as? UIPinchGestureRecognizer {
			if pinch.state == .began {
				pinchInitialCameraDistance = cameraDistance
			} else if pinch.state == .changed || pinch.state == .ended {
				// Change camera distance within limits
				cameraDistance = pinchInitialCameraDistance / Float(pinch.scale)
				cameraDistance = max(1.25, min(20.0, cameraDistance))
				updateCameraPosition()
			} else if pinch.state == .cancelled {
				cameraDistance = pinchInitialCameraDistance
			}
		}
	}
}
