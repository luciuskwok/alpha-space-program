//
//  OrbitalElements.swift
//  Space Program
//
//  Created by Lucius Kwok on 11/23/18.
//  Copyright © 2018 Felt Tip Inc. All rights reserved.
//

import Foundation

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
		return atan (sqrt ( (1-eccentricity)/(1+eccentricity) * pow (tan (ta/2), 2) ) ) * 2.0
	}
	
	func trueAnomaly(fromEccentricAnomaly ea:Double) -> Double {
		// cos(θ) = (cos (E) - ε) / (1 - ε * cos(E))
		// if ε is not close to 1.0, use: θ = 2 * atan2( sqrt(1-ε) * cos(E/2), sqrt(1-ε) * sin(E/2) )
		let sign = (ea < 1.0) ? -1.0 : 1.0
		return sign * 2.0 * atan2( sqrt(1.0 - eccentricity) * cos(ea / 2.0), sqrt(1.0 + eccentricity) * sin(ea / 2.0) )
	}
	
	func eccentricAnomaly(fromMeanAnomaly ma:Double) -> Double {
		var ea: Double = (eccentricity > 0.5) ? .pi : ma
		var correction: Double
		
		repeat {
			correction = (ea - ma + eccentricity * sin (ea)) / (1 - eccentricity * cos (ea))
			if correction < 0.001 {
				break
			}
			ea = ea - correction
		} while true
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

}
