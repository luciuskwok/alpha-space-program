//
//  OrbitalElements.swift
//  Space Program
//
//  Created by Lucius Kwok on 11/23/18.
//  Copyright © 2018 Felt Tip Inc. All rights reserved.
//

import Foundation
import simd

struct OrbitalElements {
	var semiMajorAxis: Double  // a, in meters
	var eccentricity: Double  // e or ε = (Ap - Pe) / (Ap + Pe)
	var inclination: Double  // i, in radians
	var longitudeOfAscendingNode: Double // Ω (capital omega), in radians
	var argumentOfPeriapsis: Double // ω (small omega), in radians
	var trueAnomalyAtEpoch: Double // θ (theta) at M₀, in radians
	
	// MARK: -

	init(semiMajorAxis sma:Double, eccentricity e:Double) {
		semiMajorAxis = sma
		eccentricity = e
		inclination = 0.0
		longitudeOfAscendingNode = 0.0
		argumentOfPeriapsis = 0.0
		trueAnomalyAtEpoch = 0.0
	}
	
	init(semiMajorAxis sma:Double, eccentricity e:Double, inclination inc:Double, longitudeOfAscendingNode an:Double, argumentOfPeriapsis pe:Double, trueAnomalyAtEpoch ta:Double) {
		semiMajorAxis = sma
		eccentricity = e
		inclination = inc
		longitudeOfAscendingNode = an
		argumentOfPeriapsis = pe
		trueAnomalyAtEpoch = ta
	}
	
	// MARK: -
	
	func orbitalPeriod(GM: Double) -> Double {
		// GM: Gravitation constant, in m²/s³
		return 2.0 * .pi * sqrt(pow(semiMajorAxis, 3) / GM)
	}
	
	func apoapsisFromCenter() -> Double {
		// Ap = SMA * (1 + e)
		return semiMajorAxis * (1 + eccentricity)
	}
	
	func periapsisFromCenter() -> Double {
		// Pe = SMA * (1 - e)
		return semiMajorAxis * (1 - eccentricity)
	}
	
	func eccentricAnomaly(fromTrueAnomaly ta:Double) -> Double {
		// E: eccentric anomaly
		// E = arctan( sqrt( (1 - ε) / (1 + ε) * tan(θ / 2)² ) ) * 2
		// E = arctan( sqrt( (1 - ε) / (1 + ε) ) * tan(θ / 2) ) * 2
		// E = arctan( sqrt(1 - ε) / sqrt(1 + ε) * tan(θ / 2) ) * 2
		// E = arctan( sqrt(1 - ε) / sqrt(1 + ε) * cos(θ / 2) / sin(θ / 2) ) * 2
		// E = arctan( sqrt(1 - ε) * cos(θ / 2) / sqrt(1+ ε) * sin(θ / 2) ) * 2
		// E = atan2( sqrt(1- ε) * cos(θ / 2), sqrt(1+ ε) * sin(θ / 2) ) * 2
		// atan2(y, x) = atan(y/x)

		let e = eccentricity
		return 2.0 * atan( sqrt((1-e) / (1+e)) * tan(ta/2) )
	}
	
	func trueAnomaly(fromEccentricAnomaly ea:Double) -> Double {
		// cos(θ) = (cos (E) - ε) / (1 - ε * cos(E))
		// if ε is not close to 1.0, use: θ = 2 * atan2( sqrt(1-ε) * cos(E/2), sqrt(1-ε) * sin(E/2) )
		//let sign = (ea < 0.0) ? -1.0 : 1.0
		let e = eccentricity
		return 2.0 * atan2( sqrt(1+e) * sin(ea/2), sqrt(1-e) * cos(ea/2) )
	}
	
	func eccentricAnomaly(fromMeanAnomaly ma:Double) -> Double {
		var ea: Double = ma
		var correction = Double(1.0)
		while fabs(correction) > 1e-6 && fabs(correction) <= 2 * .pi {
			correction = (ea - ma - eccentricity * sin (ea)) / (1 - eccentricity * cos (ea))
			// == DEBUG ==
			if fabs(correction) > .pi {
				print("correction=\(correction), ea=\(ea)")
			}
			// == END DEBUG ==
			ea = ea - correction
		}
		return ea
	}
	
	func meanAnomaly(fromEccentricAnomaly ea:Double) -> Double {
		// M: mean anomaly
		// M = E - ε * sin(E)
		return ea - eccentricity * sin(ea)
	}
	
	func radius(atEccentricAnomaly ea:Double) -> Double {
		// r = a * (1 - ε cos(E))
		return semiMajorAxis * (1.0 - eccentricity * cos(ea))
	}
	
	func radius(atTrueAnomaly ta:Double) -> Double {
		// r = a * (1 - ε²) / 1 + ε * cos(θ)
		return semiMajorAxis * (1 - pow(eccentricity, 2)) / (1 + eccentricity * cos(ta))
	}
	
	func polarCoordinates(atTime t:Double, GM:Double) -> (r:Double, angle:Double) {
		let p = orbitalPeriod(GM:GM)
		let ma = (t / p).truncatingRemainder(dividingBy: p) * 2 * .pi
		let ea = eccentricAnomaly(fromMeanAnomaly: ma)
		let ta = trueAnomaly(fromEccentricAnomaly: ea)
		let r = radius(atEccentricAnomaly: ea)
		return (r:r, angle:ta)
	}
	
	func velocity(distance r:Double, GM:Double) -> Double {
		return sqrt (GM * (2 / r - 1 / semiMajorAxis) )
	}
	
	func orbitPathCoordinates(divisions:Int) -> [simd_double2] {
		var coords:[simd_double2] = []
		for index in 0...divisions {
			let ea = (Double(index) / Double(divisions)) * 2 * .pi
			let r = radius(atEccentricAnomaly: ea)
			let ta = trueAnomaly(fromEccentricAnomaly: ea)
			let x = r * cos(ta)
			let y = r * sin(ta)
			coords.append(simd_double2(x:x, y:y))
		}
		return coords
	}

	// MARK: - Testing
	static func runTest() {
		testOneOrbit(GM: 3.5316e12, sma: 9110920, ecc: 0.746733)
		//testOneOrbit(GM: 3.5316e12, sma: 9110920, ecc: 0.0)
		
	}
	
	static func printRemainders() {
		for index in -10...10 {
			let x = Double(index)
			print(String(format:"x=%3.0f, remainder=%2.0f, truncatingRemainder=%2.0f", x, x.remainder(dividingBy: 5.0), x.truncatingRemainder(dividingBy: 5.0)))
		}
	}
	
	static func testOneOrbit(GM:Double, sma:Double, ecc:Double) {
		let testOrbit = OrbitalElements(semiMajorAxis: sma, eccentricity: ecc)
		let apoapsis = testOrbit.apoapsisFromCenter()
		let periapsis = testOrbit.periapsisFromCenter()
		let period = testOrbit.orbitalPeriod(GM: GM)
		
		print("== Orbit Calculation Test ==")
		print("Semi-major axis:", testOrbit.semiMajorAxis, "Eccentricity:", testOrbit.eccentricity)
		print("Ap:", apoapsis, "Pe:", periapsis)
		print("Period:", period)
		
		// Test anomaly calcuations in 2 full circles
		for deg in stride(from: -360, through: 360, by: 15) {
			let ta = Double(deg) / 180.0 * .pi
			let ea1 = testOrbit.eccentricAnomaly(fromTrueAnomaly: ta)
			let ta1 = testOrbit.trueAnomaly(fromEccentricAnomaly: ea1)
			let ma2 = testOrbit.meanAnomaly(fromEccentricAnomaly: ea1)
			let ea2 = testOrbit.eccentricAnomaly(fromMeanAnomaly: ma2)
			let ta2 = testOrbit.trueAnomaly(fromEccentricAnomaly: ea2)
			
			print(String(format:"θ=%6.3f, ea1=%6.3f, ta1=%6.3f, ma2=%6.3f, ea2=%6.3f, ta2=%6.3f", ta, ea1, ta1, ma2, ea2, ta2))
		}
		
		// Test position calculations
		let timeSincePe = 21039.5
		let (rp, angle) = testOrbit.polarCoordinates(atTime: timeSincePe, GM: GM)
		print("t:", timeSincePe, "distance:", rp, "θ:", angle)
		
		let velocity = testOrbit.velocity(distance: rp, GM: GM)
		print("velocity:", velocity)
	}

}
