//
//  CameraController.swift
//  Space Program
//
//  Created by Lucius Kwok on 11/3/18.
//  Copyright © 2018 Felt Tip Inc. All rights reserved.
//

import Foundation
import SceneKit


class CameraController {
	var cameraNode:SCNNode
	var vabMode = true
	var target = SCNVector3()
	var distance = Float(5.0)
	var distanceMax = Float(20.0)
	var distanceMin = Float(1.25)
	var panAngle = Float(0.0) // radians
	var tiltAngle = Float(15.0/180.0 * .pi)
	var tiltMax = Float(89.0 / 180.0 * .pi)
	var tiltMin = Float(-89.0 / 180.0 * .pi)
	var panPreviousLocation = CGPoint()
	var pinchInitialDistance:Float = 0.0

	// MARK: -
	
	init(camera:SCNNode) {
		self.cameraNode = camera
	}
	
	func addGestureRecognizers(to view:UIView) {
		// Add gesture recognizers
		let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
		view.addGestureRecognizer(pinchGesture)
		
		if vabMode {
			let twoFingerPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleTwoFingerPan(_:)))
			twoFingerPanGesture.minimumNumberOfTouches = 2
			twoFingerPanGesture.maximumNumberOfTouches = 2
			view.addGestureRecognizer(twoFingerPanGesture)
		}
		
		let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
		panGesture.minimumNumberOfTouches = 1
		panGesture.maximumNumberOfTouches = 1
		view.addGestureRecognizer(panGesture)
	}
	
	func updateCameraPosition() {
		// Point camera by moving camera to target, changing its rotation, and translating by the distance while rotated.
		cameraNode.position = target
		cameraNode.eulerAngles = SCNVector3(x: -tiltAngle, y: panAngle, z:0.0)
		cameraNode.localTranslate(by: SCNVector3(x:0, y:0, z:distance))
	}
	
	@objc func handlePan(_ sender:UIGestureRecognizer) {
		let currentLocation = sender.location(in: sender.view)
		if sender.state == .changed || sender.state == .ended {
			// Horizontal axis
			let deltaX = Float(currentLocation.x - panPreviousLocation.x)
			if deltaX != 0.0 {
				// Pan around point horizontally
				panAngle = (panAngle - deltaX * (2.0 * .pi) / 720.0 +  (2.0 * .pi)).truncatingRemainder(dividingBy:  (2.0 * .pi))
			}
			
			// Vertical axis
			let deltaY = Float(currentLocation.y - panPreviousLocation.y)
			if deltaY != 0.0 {
				if vabMode {
					// In VAB mode, vertical pan gestures move the camera target up and down.
					target.y += deltaY * distance / 320.0
					target.y = max(0.25, target.y)
					target.y = min(19.75, target.y) // replace with actual max height limit
				} else {
					// In game mode, vertical gestures adjust the tilt
					tiltAngle = min(tiltMax, max(tiltMin, tiltAngle + deltaY * (2.0 * .pi) / 720.0))
				}
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
	
	@objc func handleTwoFingerPan(_ sender:UIGestureRecognizer) {
		let currentLocation = sender.location(in: sender.view)
		if (sender.state == .changed || sender.state == .ended) && sender.numberOfTouches == 2 {
			// Tilt camera from -85° to +85°
			let deltaY = Float(currentLocation.y - panPreviousLocation.y)
			if deltaY != 0.0 {
				tiltAngle = min(tiltMax, max(tiltMin, tiltAngle + deltaY * (2.0 * .pi) / 720.0))
				updateCameraPosition()
			}
		}
		if sender.state == .cancelled {
			print("[LK] Tilt cancelled")
		}
		panPreviousLocation = currentLocation
	}
	
	@objc func handlePinch(_ sender:UIGestureRecognizer) {
		if let pinch = sender as? UIPinchGestureRecognizer {
			if pinch.state == .began {
				pinchInitialDistance = distance
			} else if pinch.state == .changed || pinch.state == .ended {
				// Change camera distance within limits
				distance = pinchInitialDistance / Float(pinch.scale)
				distance = max(distanceMin, min(distanceMax, distance))
				updateCameraPosition()
			} else if pinch.state == .cancelled {
				distance = pinchInitialDistance
			}
		}
	}
}
