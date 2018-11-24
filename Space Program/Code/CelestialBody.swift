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
	let orbit: OrbitalElements
	let gravitationalConstant: Double
	let radius: Double
	var name: String?
	var sphereOfInfluenceNode: SCNNode?
	var bodyNode: SCNNode?
	var parentBody: CelestialBody?
	
	init(orbit o:OrbitalElements, gravitationalConstant gm:Double, radius r:Double, parent:CelestialBody?) {
		orbit = o
		gravitationalConstant = gm
		radius = r
		parentBody = parent
	}
	
	func loadSceneNode(fileName:String, nodeName:String) -> SCNNode {
		// Loads a model from a file and creates a hierarchy of a SOI node and the model node inside it.
		name = nodeName
		
		// Model in file should be a sphere with radius=1.0m, this will scale the sphere to match the radius
		let scene = SCNScene(named: "Scene.scnassets/" + fileName)!
		let bNode = scene.rootNode.childNode(withName: nodeName, recursively: true)!
		bNode.scale = SCNVector3(radius, radius, radius)
		bNode.name = nodeName + "_Body"
		bodyNode = bNode
		
		// Create a SOI node with no geometry so that objects within the SOI move with it.
		let soiNode = createSOINode()
		// Return SOI node, which the caller should add to the universe scene.
		return soiNode
	}
	
	func createSceneNodeSphere(named:String, color:UIColor) -> SCNNode {
		name = named
		
		// Geometry
		let bodySphere = SCNSphere(radius: 1.0)
		
		// Material
		let bodyMaterial = bodySphere.firstMaterial!
		bodyMaterial.diffuse.contents = color

		
		let bNode = SCNNode(geometry: bodySphere)
		bNode.scale = SCNVector3(radius, radius, radius)
		bNode.name = named + "_Body"
		bodyNode = bNode

		return createSOINode()
	}
	
	func createSOINode() -> SCNNode {
		// Create a SOI node with no geometry so that objects within the SOI move with it.
		let soiNode = SCNNode(geometry: nil)
		if let name = name {
			soiNode.name = name + "_SOI"
		} else {
			soiNode.name = "Unnamed_SOI"
		}
		if let bNode = bodyNode {
			soiNode.addChildNode(bNode)
		}
		sphereOfInfluenceNode = soiNode
		return soiNode
	}

	func orbitLineNode() -> SCNNode {
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
		if let name = name {
			sceneNode.name = name + "_Orbit"
		} else {
			sceneNode.name = "Unnamed_Orbit"
		}
		sceneNode.castsShadow = false
		return sceneNode
	}
	
	func coordinates(atTime time:Double) -> simd_double3 {
		let GM = parentBody!.gravitationalConstant
		let (rp, angle) = orbit.polarCoordinates(atTime: time, GM: GM)
		// TODO: apply rotation to orbit
		
		let x = rp * cos(angle)
		let y = 0.0
		let z = -rp * sin(angle)
		return simd_double3(x, y, z)
	}

	func updatePosition(atTime time:Double) {
		let r = coordinates(atTime: time)
		sphereOfInfluenceNode!.position = SCNVector3(x:Float(r.x), y:Float(r.y), z:Float(r.z))
	}
	
	
}
