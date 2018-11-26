//
//  CelestialBody.swift
//  Space Program
//
//  Created by Lucius Kwok on 11/23/18.
//  Copyright © 2018 Felt Tip Inc. All rights reserved.
//

import Foundation
import SceneKit

class CelestialBody {
	let name: String
	let orbit: OrbitalElements
	let gravitationalConstant: Double
	let bodyRadius: Double
	
	var position = simd_double3()
	var influenceRadius = Double(0.0) // to be computed from the orbit
	weak var parentBody: CelestialBody?
	var children = [CelestialBody]()

	var sphereOfInfluenceNode: SCNNode?
	var bodyNode: SCNNode?
	var orbitLineNode: SCNNode?

	
	// MARK: -
	
	init(name:String, orbit:OrbitalElements, gravitationalConstant:Double, bodyRadius:Double) {
		self.name = name
		self.orbit = orbit
		self.gravitationalConstant = gravitationalConstant
		self.bodyRadius = bodyRadius
	}
	
	init(info:[String:Any]) {
		// Read property values from the dictionary. Note that any missing or invalid values will cause a crash.
		name = info["name"] as! String
		gravitationalConstant = info["GM"] as! Double
		bodyRadius = info["radius"] as! Double
		
		orbit = OrbitalElements(info:info)

		if let sceneFile = info["sceneFile"] as? String {
			bodyNode = loadBodyNode(sceneFile: sceneFile)
		} else if let hexColor = info["color"] as? String {
			let color = AppDelegate.color(rgbHexValue: hexColor)
			bodyNode = createBodyNode(color: color)
		}
		
		let soi = createSoiNode()
		soi.addChildNode(bodyNode!)
		sphereOfInfluenceNode = soi
		
		// Add children last, since they are nested inside the SOI node
		if let childrenInfo = info["children"] as? [[String:Any]] {
			for childInfo in childrenInfo {
				let childBody = CelestialBody(info: childInfo)
				self.children.append(childBody)
				childBody.parentBody = self
				//soi.addChildNode(childBody.sphereOfInfluenceNode!)
				soi.addChildNode(childBody.createOrbitLineNode())
			}
		}
	}
	
	// MARK: -
	
	func loadBodyNode(sceneFile:String) -> SCNNode {
		// Loads a model from a file and creates a hierarchy of a SOI node and the model node inside it.
		// This assumes that the node name is the same as the self.name string.
		
		// Model in file should be a sphere with radius=1.0m, this will scale the sphere to match the radius
		let scene = SCNScene(named: "Scene.scnassets/" + sceneFile)!
		let bNode = scene.rootNode.childNode(withName: name, recursively: true)!
		let r = bodyRadius
		bNode.scale = SCNVector3(r, r, r)
		bNode.name = name + "_Body"
		// Return body node, which the caller should add to the SOI node.
		return bNode
	}
	
	func createBodyNode(color:UIColor) -> SCNNode {
		// Geometry
		let bodySphere = SCNSphere(radius: 1.0)
		
		// Material
		let bodyMaterial = bodySphere.firstMaterial!
		bodyMaterial.diffuse.contents = color
		
		let bNode = SCNNode(geometry: bodySphere)
		let r = bodyRadius
		bNode.scale = SCNVector3(r, r, r)
		bNode.name = name + "_Body"
		return bNode
	}
	
	func createSoiNode() -> SCNNode {
		// SOI node allows moons and craft to be independent from the scale and rotation settings of the bodyNode.
		let soiNode = SCNNode(geometry: nil)
		soiNode.name = name + "_SOI"
		sphereOfInfluenceNode = soiNode
		return soiNode
	}

	func createOrbitLineNode() -> SCNNode {
		let flatCoords = orbit.orbitPathCoordinates(divisions: 180)
		var geoCoords = [SCNVector3]()
		var geoElements = [SCNGeometryElement]()
		var index = Int16(0)
		for coord in flatCoords {
			geoCoords.append (SCNVector3 (x:Float(coord.x), y:0.0, z:Float(coord.y) ) )
			if index > 0 {
				geoElements.append (SCNGeometryElement(indices: [index-1, index], primitiveType: .line) )
			}
			index += 1
		}
		let vertexSource = SCNGeometrySource(vertices: geoCoords)
		let orbitGeometry = SCNGeometry(sources: [vertexSource], elements: geoElements)
		
		let orbitMaterial = orbitGeometry.firstMaterial!
		orbitMaterial.fillMode = .lines
		orbitMaterial.isDoubleSided = true
		orbitMaterial.lightingModel = .constant
		
		let sceneNode = SCNNode(geometry: orbitGeometry)
		sceneNode.name = name + "_Orbit"
		sceneNode.castsShadow = false
		self.orbitLineNode = sceneNode
		return sceneNode
	}
	
	func localCoordinates(atTime time:Double) -> simd_double3 {
		let GM = parentBody!.gravitationalConstant
		let (rp, angle) = orbit.polarCoordinates(atTime: time, GM: GM)
		
		let x = rp * cos(angle)
		let y = 0.0
		let z = -rp * sin(angle)
		
		// TODO: apply orbit rotations (inclination, etc.)

		return simd_double3(x, y, z)
	}
	
	func universeCoordinates() -> simd_double3 {
		var r = self.position
		var ancestor = self.parentBody
		while ancestor != nil {
			r += ancestor!.position
			ancestor = ancestor!.parentBody
		}
		return r
	}

	func updatePosition(atTime time:Double, recursive:Bool) {
		if orbit.semiMajorAxis > 0.0 {
			let r = localCoordinates(atTime: time)
			self.position = r
			//sphereOfInfluenceNode!.position = SCNVector3(x:Float(r.x), y:Float(r.y), z:Float(r.z))
		}
		
		if recursive {
			for child in children {
				child.updatePosition(atTime: time, recursive: true)
			}
		}
	}
	
	
}
