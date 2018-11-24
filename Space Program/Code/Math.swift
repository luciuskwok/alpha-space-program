//
//  Math.swift
//  Space Program
//
//  Created by Lucius Kwok on 11/24/18.
//  Copyright © 2018 Felt Tip Inc. All rights reserved.
//

import Foundation

class Math {
	
	static func rad(deg:Double) -> Double {
		return deg / 180.0 * .pi
	}
	
	static func deg(rad:Double) -> Double {
		return rad * 180.0 / .pi
	}
	
}
