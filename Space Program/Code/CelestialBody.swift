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
	let mass: Double
	
	var position = simd_double3()
	weak var parentBody: CelestialBody?
	var children = [CelestialBody]()

	var orbitLineNode: SCNNode
	var sphereOfInfluenceNode: SCNNode
	var bodyNode: SCNNode

	
	// MARK: -
	
	init(info:[String:Any]) {
		// Read property values from the dictionary. Note that any missing or invalid values will cause a crash.
		name = info["name"] as! String
		gravitationalConstant = info["GM"] as! Double
		bodyRadius = info["radius"] as! Double
		mass = info["mass"] as! Double

		orbit = OrbitalElements(info:info)

		orbitLineNode = CelestialBody.createOrbitLineNode(orbit:orbit)
		orbitLineNode.name = name + "_Orbit"

		sphereOfInfluenceNode = SCNNode(geometry: nil)
		sphereOfInfluenceNode.name = name + "_SOI"

		if let sceneFile = info["sceneFile"] as? String {
			bodyNode = CelestialBody.loadBodyNode(sceneFile: sceneFile, nodeName:name)
		} else {
			let hexColor = info["color"] as! String
			let color = AppDelegate.color(rgbHexValue: hexColor)
			bodyNode = CelestialBody.createBodyNode(color: color)
		}
		bodyNode.scale = SCNVector3(bodyRadius, bodyRadius, bodyRadius)
		bodyNode.name = name + "_Body"
		sphereOfInfluenceNode.addChildNode(bodyNode)
		
		// Add children last, since they are nested inside the SOI node
		if let childrenInfo = info["children"] as? [[String:Any]] {
			for childInfo in childrenInfo {
				let childBody = CelestialBody(info: childInfo)
				self.children.append(childBody)
				childBody.parentBody = self
			}
		}
	}
	
	// MARK: -
	
	static func loadBodyNode(sceneFile:String, nodeName:String) -> SCNNode {
		// Loads a model from a file and creates a hierarchy of a SOI node and the model node inside it.
		// This assumes that the node name is the same as the self.name string.
		
		// Model in file should be a sphere with radius=1.0m, this will scale the sphere to match the radius
		let scene = SCNScene(named: "Scene.scnassets/" + sceneFile)!
		let bNode = scene.rootNode.childNode(withName: nodeName, recursively: true)!
		return bNode
	}
	
	static func createBodyNode(color:UIColor) -> SCNNode {
		// Geometry
		let bodySphere = SCNSphere(radius: 1.0)
		
		// Material
		let bodyMaterial = bodySphere.firstMaterial!
		bodyMaterial.diffuse.contents = color
		
		return SCNNode(geometry: bodySphere)
	}

	static func createOrbitLineNode(orbit:OrbitalElements) -> SCNNode {
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
		sceneNode.castsShadow = false
		return sceneNode
	}
	
	// MARK: -
	
	var influenceRadius: Double {
		if let parent = parentBody {
			return orbit.semiMajorAxis * pow(mass / parent.mass, 0.4)
		} else {
			return 0.0
		}
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

	func updatePositionRecursively(atTime time:Double, universeOffset:simd_double3) {
		if orbit.semiMajorAxis > 0.0 {
			position = localCoordinates(atTime: time)
		}
			
		let r = universeCoordinates() + universeOffset
		sphereOfInfluenceNode.position = SCNVector3(x:Float(r.x), y:Float(r.y), z:Float(r.z))
		
		for child in children {
			child.updatePositionRecursively(atTime: time, universeOffset: universeOffset)
		}
	}
	
	func addSceneNodesRecursively(rootNode:SCNNode, parentNode:SCNNode) {
		/* The hierarchy of nodes is:
			+rootNode
				+parentNode — sun SOI for planets, and planet SOI being orbited for moons
					-orbitLineNode — this allows orbit line to move with the parentNode
				+soiNode — this allows each SOI to be independently positioned in the universe
					-bodyNode
		*/
		
		rootNode.addChildNode(sphereOfInfluenceNode)
		parentNode.addChildNode(orbitLineNode)
		for child in children {
			child.addSceneNodesRecursively(rootNode: rootNode, parentNode: sphereOfInfluenceNode)
		}
		// bodyNode should have already been added as chidl of sphereOfInfluenceNode.
		// The end result should be that all planets have both their soiNode and orbitLineNode as children of the rootNode,
		// While the moons have their soiNode as children of rootNode while orbitLineNode is a child of the parent soiNode.
	}
	
	func child(withBodyNode node:SCNNode, recursive:Bool) -> CelestialBody? {
		for child in children {
			if child.bodyNode == node {
				return child
			} else if recursive {
				let result = child.child(withBodyNode: node, recursive: recursive)
				if result != nil {
					return result
				}
			}
		}
		return nil
	}
	
}
