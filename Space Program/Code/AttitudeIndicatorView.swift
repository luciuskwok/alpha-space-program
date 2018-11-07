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
	let tau = 2.0 * Float.pi
	let groundColor = UIColor(hue: 30.0/360.0, saturation: 1.0, brightness: 0.667, alpha: 1.0)
	let skyColor = UIColor(hue: 210.0/360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)

	var pitchAngle = CGFloat(0.0) {
		didSet {
			if pitchAngle != oldValue {
				setNeedsDisplay()
			}
		}
	}
	
	var rollAngle = CGFloat(0.0) {
		didSet {
			if rollAngle != oldValue {
				setNeedsDisplay()
			}
		}
	}
	
	var heading = CGFloat(0.0)  {
		didSet {
			if heading != oldValue {
				setNeedsDisplay()
			}
		}
	}

	override func draw(_ rect: CGRect) {
		let margin = CGFloat(2.0)
		let width = bounds.size.width - 2.0 * margin
		let radius = width * 0.5
		let center = CGPoint(x: radius + margin, y: radius + margin)
		let contextClipRect = CGRect(x: margin, y: margin, width: width, height: width)
		
		if let context = UIGraphicsGetCurrentContext() {
			// Use circle as clipping path and to draw border
			context.beginPath()
			context.addEllipse(in: contextClipRect)
			context.closePath()
			context.clip()

			// Use an affine transform to rotate for roll, and then translate for pitch
			context.saveGState()
			context.translateBy(x: center.x, y: center.y)
			context.rotate(by: rollAngle)
			context.translateBy(x: 0.0, y: radius * pitchAngle * 2.0 / .pi)

			// Ground fill
			let groundPath = UIBezierPath(rect: CGRect(x:-radius, y:0.0, width:width, height:width))
			groundColor.set()
			groundPath.fill()
			
			// Sky fill
			let skyPath = UIBezierPath(rect: CGRect(x:-radius, y:-width, width:width, height:width))
			skyColor.set()
			skyPath.fill()

			// Horizon path
			let horizonPath = UIBezierPath()
			horizonPath.move(to:CGPoint(x:-radius, y:0.0))
			horizonPath.addLine(to:CGPoint(x:radius, y:0.0))
			horizonPath.lineWidth = 2.5
			UIColor.white.set()
			horizonPath.stroke()
			
			// Print debug info
			print(String(format:"Pitch=%1.0f, Roll=%1.0f", pitchAngle / .pi * 180.0, rollAngle / .pi * 180.0))
			
			// Reset context to remove transform
			context.restoreGState()
			
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
