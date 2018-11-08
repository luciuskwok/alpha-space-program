//
//  AttitudeIndicatorView.swift
//  Space Program
//
//  Created by Lucius Kwok on 11/4/18.
//  Copyright © 2018 Felt Tip Inc. All rights reserved.
//

import UIKit
import SceneKit

class AttitudeIndicatorView: UIView {
	let groundColor = UIColor(hue: 30.0/360.0, saturation: 1.0, brightness: 0.667, alpha: 1.0)
	let skyColor = UIColor(hue: 210.0/360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)

	var orientation = simd_quatf() {
		didSet {
			if orientation != oldValue {
				setNeedsDisplay()
			}
		}
	}
	
	override func draw(_ rect: CGRect) {
		let margin = CGFloat(2.0)
		let width = bounds.size.width - 2.0 * margin
		let ballRadius = Float(width * 0.525)
		let center = CGPoint(x: bounds.size.width * 0.5, y: bounds.size.height * 0.5)
		
		if let context = UIGraphicsGetCurrentContext() {
			// Use an affine transform to move center
			context.saveGState()
			context.translateBy(x: center.x, y: center.y)

			// Set clipping
			let contextClipRect = CGRect(x: -width * 0.5, y: -width * 0.5, width: width, height: width)
			context.beginPath()
			context.addEllipse(in: contextClipRect)
			context.closePath()
			context.clip()

			// Line color
			UIColor.white.set()

			// Lines of latitude
			for latitude in stride(from:-60, through:60, by:30) {
				var points3d:[float3] = []
				let latRad = radians(degrees:Float(latitude))
				for longitude in stride(from:0, through:360, by:10) {
					let longRad = radians(degrees:Float(longitude))
					let pt = point(latitude: latRad, longitude: longRad, radius: ballRadius)
					points3d.append(pt)
				}
				let path = projectedPath(points: points3d)
				if latitude == 0 {
					path.lineWidth = 2.0
				} else {
					path.lineWidth = 1.0
				}
				path.stroke()
			}
			
			// Heading lines
			for longitude in stride(from:0, through:360, by:30) {
				var points3d:[float3] = []
				let longRad = radians(degrees:Float(longitude))
				for latitude in stride(from:-60, through:60, by:10) {
					let latRad = radians(degrees:Float(latitude))
					let pt = point(latitude: latRad, longitude: longRad, radius: ballRadius)
					points3d.append(pt)
				}
				let path = projectedPath(points: points3d)
				path.lineWidth = 0.5
				path.stroke()
		}

//
//			// Ground fill
//			let groundPath = UIBezierPath(rect: CGRect(x:-radius, y:0.0, width:width, height:width))
//			groundColor.set()
//			groundPath.fill()
//
//			// Sky fill
//			let skyPath = UIBezierPath(rect: CGRect(x:-radius, y:-width, width:width, height:width))
//			skyColor.set()
//			skyPath.fill()

			// Print debug info
			//print(String(format:"Pitch=%1.0f, Roll=%1.0f", pitchAngle / .pi * 180.0, rollAngle / .pi * 180.0))
			
			// Draw the center markings
			let markLineWidth = CGFloat(2.0)
			let markPath = UIBezierPath()
			markPath.move(to: CGPoint(x: -25, y: 0.0))
			markPath.addLine(to: CGPoint(x: -10, y: 0.0))
			markPath.addLine(to: CGPoint(x: 0.0, y: 10))
			markPath.addLine(to: CGPoint(x: 10, y: 0.0))
			markPath.addLine(to: CGPoint(x: 25, y: 0.0))
			markPath.lineWidth = markLineWidth
			markPath.lineCapStyle = .round
			markPath.lineJoinStyle = .round
			UIColor.yellow.set()
			markPath.stroke()
			
			let centerPoint = UIBezierPath(ovalIn: CGRect(x: -markLineWidth * 0.5, y: -markLineWidth * 0.5, width: markLineWidth, height: markLineWidth))
			centerPoint.fill()

			// Draw the border
			context.resetClip()
			let borderPath = UIBezierPath(ovalIn: contextClipRect)
			borderPath.lineWidth = 2.0
			UIColor.black.set()
			borderPath.stroke()
			
			// Restore G State
			context.restoreGState()
		}
	}
	
	func projectedPath(points:[float3]) -> UIBezierPath {
		// Use the inverse matrix of the orientation
		let inverted = orientation.inverse
		
		// Create a UIBezierPath given a set of 3D points.
		let path = UIBezierPath()
		var lineContinued = false
		for point in points {
			let rotatedPoint = inverted.act(point)
			
			if rotatedPoint.y <= 0.0 {
				let flatPoint = CGPoint(x: -CGFloat(rotatedPoint.x), y: CGFloat(rotatedPoint.z))
				if lineContinued {
					path.addLine(to:flatPoint)
				} else {
					path.move(to:flatPoint)
					lineContinued = true
				}
			} else {
				lineContinued = false
			}
		}
		return path
	}
	
	func point(latitude:Float, longitude:Float, radius:Float) -> float3 {
		let x = cos(latitude) * cos(longitude) * radius
		let y = cos(latitude) * sin(longitude) * radius
		let z = sin(latitude) * radius
		return float3(x:x, y:y, z:z)
	}
	
	func radians(degrees:Float) -> Float {
		return degrees / 180.0 * .pi
	}
	
	
}
