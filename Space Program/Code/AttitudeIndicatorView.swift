//
//  AttitudeIndicatorView.swift
//  Space Program
//
//  Created by Lucius Kwok on 11/4/18.
//  Copyright © 2018 Felt Tip Inc. All rights reserved.
//

import UIKit

class AttitudeIndicatorView: UIView {
	let tau = 2.0 * Double.pi
	
	var orientation = DoubleQuaternion() {
		didSet {
			setNeedsDisplay()
		}
	}

	override func draw(_ rect: CGRect) {
		
		let margin = CGFloat(2.0)
		let width = bounds.size.width - 2.0 * margin
		let radius = bounds.size.width * 0.5 - margin
		let center = CGPoint(x: radius + margin, y: radius + margin)
		let contextClipRect = CGRect(x: margin, y: margin, width: width, height: width)
		
		if let context = UIGraphicsGetCurrentContext() {
			// Use circle as clipping path and to draw border
			context.beginPath()
			context.addEllipse(in: contextClipRect)
			context.closePath()
			context.clip()
			
			// Pitch
			let pitch = CGFloat(orientation.x/tau + 1.25).truncatingRemainder(dividingBy: 1.0) // range of 0.0 to 1.0
			let pitchY = radius * ((2.0 - pitch * 2.0).truncatingRemainder(dividingBy: 1.0) - 0.5)
			let upsideDown = (pitch > 0.5)
			
			// Roll
			let roll = CGFloat(orientation.z)
			
			// Horizon line
			let pt1 = CGPoint(x: center.x + cos(roll) * radius * 2, y: center.y + sin(roll) * radius * 2 + pitchY)
			let pt2 = CGPoint(x: center.x - cos(roll) * radius * 2, y: center.y - sin(roll) * radius * 2 + pitchY)
			let horizonLine = UIBezierPath()
			horizonLine.move(to:pt1)
			horizonLine.addLine(to: pt2)
			horizonLine.lineWidth = 0.75
			UIColor.white.set()
			horizonLine.stroke()
			
			if pitch <= 0.5 {
				// Right-side up
			}
			
			
			// Draw the center markings
			let markPath = UIBezierPath()
			markPath.move(to: CGPoint(x: center.x - 25, y: center.y))
			markPath.addLine(to: CGPoint(x: center.x - 10, y: center.y))
			markPath.addLine(to: CGPoint(x: center.x, y: center.y + 10))
			markPath.addLine(to: CGPoint(x: center.x + 10, y: center.y))
			markPath.addLine(to: CGPoint(x: center.x + 25, y: center.y))
			markPath.lineWidth = 1.5
			markPath.lineCapStyle = .round
			markPath.lineJoinStyle = .round
			UIColor.yellow.set()
			markPath.stroke()
			
			let centerPoint = UIBezierPath(ovalIn: CGRect(x: center.x - 1.0, y: center.y - 1.0, width: 2.0, height: 2.0))
			centerPoint.fill()

			// Draw the border
			context.resetClip()
			let borderPath = UIBezierPath(ovalIn: contextClipRect)
			borderPath.lineWidth = 2.0
			UIColor.black.set()
			borderPath.stroke()
		}
	}
	
	
}
