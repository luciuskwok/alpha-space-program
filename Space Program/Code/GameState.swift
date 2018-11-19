//
//  GameState.swift
//  Space Program
//
//  Created by Lucius Kwok on 11/19/18.
//  Copyright © 2018 Felt Tip Inc. All rights reserved.
//

import Foundation

class GameState {
	var universalTime = Double(0.0)
	
	
	// MARK: -
	
	func universalTimeString() -> (date:String, time:String) {
		// UT: Universal Time
		let (_, utY, utD, utH, utM, utS) = componentsFromTimeInterval(universalTime)
		let date = String(format:"Y%d, d%d", utY+1, utD+1)
		let time = String(format:"%02d:%02d:%02.0f", utH, utM, floor(utS))
		return (date, time)
	}
	
	func elapsedTimeString(since:Double) -> String {
		let met = universalTime - since
		let (metN, metY, metD, metH, metM, metS) = componentsFromTimeInterval(met)
		var metString = ""
		if metY > 0 {
			metString = String(format:"%dY", metY)
		}
		if metD > 0 || metString.count > 0 {
			metString = String(format:"%@ %dd", metString, metD)
		}
		if metH > 0 || metString.count > 0 {
			metString = String(format:"%@ %dh", metString, metH)
		}
		if metM > 0 || metString.count > 0 {
			metString = String(format:"%@ %dm", metString, metM)
		}
		metString = String(format:"%@ %1.0fs", metString, floor(metS))
		if metN < 0 {
			metString = "-" + metString
		}
		return metString
	}
	
	func componentsFromTimeInterval(_ interval:Double) -> (sign: Int, year: Int, day: Int, hour: Int, minute: Int, second: Double) {
		var sec = interval
		var sign = 1
		
		if sec < 0.0 {
			sec = -sec
			sign = -1
		}
		
		let min = Int(floor(sec / 60.0))
		let hr = min / 60
		let day = hr / 6
		let year = day / 426
		let secRemainder = sec.truncatingRemainder(dividingBy:60.0)
		
		return (sign, year, day % 426, hr % 6, min % 60, secRemainder)
	}


}
