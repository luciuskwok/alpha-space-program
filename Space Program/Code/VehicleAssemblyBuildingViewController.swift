//
//  VehicleAssemblyBuildingViewController.swift
//  Space Program
//
//  Created by Lucius Kwok on 10/30/18.
//  Copyright © 2018 Felt Tip Inc. All rights reserved.
//

import UIKit
import SceneKit


class VehicleAssemblyBuildingViewController:
	UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
	let tau = 2.0 * Float.pi
	
	@IBOutlet weak var sceneView: SCNView?
	@IBOutlet weak var partsCollectionView: UICollectionView?
	
	var parts:[[String:Any]]?
	var currentCellSize = CGSize(width: 80, height: 80)
	
	var camera:SCNNode?
	var cameraTarget = SCNVector3(x:0.0, y:5.0, z:0.0)
	var cameraDistance:Float = 5.0
	var cameraPanAngle:Float = 0.0 // radians
	var cameraTiltAngle:Float = (15.0/180.0) * .pi // radians
	var panPreviousLocation = CGPoint()
	var tiltPreviousLocation = CGPoint()
	var pinchInitialCameraDistance:Float = 0.0

	// MARK: -

	override func viewDidLoad() {
		super.viewDidLoad()
		
		// == Parts ==
		parts = readJSON(file:"Parts")
		
		// == 3-D Scene ==
		
		// Load the VAB scene
		let vabScene = SCNScene(named: "Scene.scnassets/VAB.scn")!
		
		// Add the CMD-1 craft and position it
		let craftScene = SCNScene(named: "Scene.scnassets/CMD-1.dae")!
		if let craft = craftScene.rootNode.childNode(withName: "Craft", recursively: true) {
			vabScene.rootNode.addChildNode(craft)
			craft.localTranslate(by: SCNVector3(x:0.0, y:5.0, z:0.0))
		} else {
			print("[LK] Craft not found in scene CMD-1.dae")
		}
		
		// Get camera
		camera = vabScene.rootNode.childNode(withName: "Camera", recursively: true)
		if camera == nil {
			print("[LK] Camera not found.")
		}
		updateCameraPosition()
	
		// Configure scene view
		sceneView?.scene = vabScene
		sceneView?.backgroundColor = UIColor.black
		sceneView?.showsStatistics = true
		sceneView?.allowsCameraControl = false
		
		// Add gesture recognizers
		let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
		sceneView?.addGestureRecognizer(pinchGesture)
		
		let tiltGesture = UIPanGestureRecognizer(target: self, action: #selector(handleTilt(_:)))
		tiltGesture.minimumNumberOfTouches = 2
		tiltGesture.maximumNumberOfTouches = 2
		sceneView?.addGestureRecognizer(tiltGesture)
		
		let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
		panGesture.minimumNumberOfTouches = 1
		panGesture.maximumNumberOfTouches = 1
		sceneView?.addGestureRecognizer(panGesture)
		
		
	}
	
	// MARK: - Camera
	
	func updateCameraPosition() {
		if let camera = camera {
			// Point camera by moving camera to target, changing its rotation, and translating by the distance while rotated.
			camera.position = cameraTarget
			camera.eulerAngles = SCNVector3(x: -cameraTiltAngle, y: cameraPanAngle, z:0.0)
			camera.localTranslate(by: SCNVector3(x:0, y:0, z:cameraDistance))
			
 		}
	}
	
	@objc func handlePan(_ sender:UIGestureRecognizer) {
		if let sceneView = sceneView {
			let currentLocation = sender.location(in: sceneView)
			if sender.state == .changed || sender.state == .ended {
				// Orbit angle around point
				let deltaX = Float(currentLocation.x - panPreviousLocation.x)
				if deltaX != 0.0 {
					cameraPanAngle = (cameraPanAngle - deltaX * tau / 360.0 + tau).truncatingRemainder(dividingBy: tau)
				}

				// Height of target
				let deltaY = Float(currentLocation.y - panPreviousLocation.y)
				if deltaY != 0.0 {
					cameraTarget.y += deltaY * cameraDistance / 320.0
					cameraTarget.y = max(0.25, cameraTarget.y)
					cameraTarget.y = min(19.75, cameraTarget.y) // replace with actual max height limit
				}
				
				if deltaX != 0.0 || deltaY != 0.0 {
					updateCameraPosition()
				}
			}
			if sender.state == .cancelled {
				print("[LK] Pan cancelled")
			}
			panPreviousLocation = currentLocation
		}
	}

	@objc func handleTilt(_ sender:UIGestureRecognizer) {
		if let sceneView = sceneView {
			let currentLocation = sender.location(in: sceneView)
			if (sender.state == .changed || sender.state == .ended) && sender.numberOfTouches == 2 {
				// Tilt camera from -85° to +85°
				let deltaY = Float(currentLocation.y - tiltPreviousLocation.y)
				if deltaY != 0.0 {
					let tiltLimitMax = 85.0/180.0 * Float.pi
					let tiltLimitMin = -85.0/180.0 * Float.pi
					cameraTiltAngle = min(tiltLimitMax, max(tiltLimitMin, cameraTiltAngle - deltaY * tau / 720.0))
					updateCameraPosition()
				}
			}
			if sender.state == .cancelled {
				print("[LK] Tilt cancelled")
			}
			tiltPreviousLocation = currentLocation
		}
	}

	@objc func handlePinch(_ sender:UIGestureRecognizer) {
		if let pinch = sender as? UIPinchGestureRecognizer {
			if pinch.state == .began {
				pinchInitialCameraDistance = cameraDistance
			} else if pinch.state == .changed || pinch.state == .ended {
				// Change camera distance within limits
				cameraDistance = pinchInitialCameraDistance / Float(pinch.scale)
				cameraDistance = max(1.25, min(20.0, cameraDistance))
				updateCameraPosition()
			} else if pinch.state == .cancelled {
				cameraDistance = pinchInitialCameraDistance
			}
		}
	}
	
	// MARK: - Parts
	
	func readJSON(file:String) -> [[String:Any]]? {
		guard let url = Bundle.main.url(forResource: file, withExtension:"json") else {
			print("[LK] File not found."); return nil
		}
		
		do {
			let data = try Data(contentsOf: url)
			if let loadedParts = try JSONSerialization.jsonObject(with: data, options: []) as? [[String:Any]] {
				return loadedParts
			}
		} catch {
			print("[LK] Error reading JSON.")
		}
		return nil
	}
	
	// MARK: - Collection View
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		if let parts = parts {
			return parts.count
		}
		return 0
	}

	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Part", for: indexPath);
		let row = indexPath.row
		
		// Background: rounded corners
		if let backgroundView = cell.viewWithTag(1) {
			backgroundView.layer.cornerRadius = 16.0
		}
		
		// Icon image
		if let imageView = cell.viewWithTag(2) as? UIImageView {
			if let imageName = parts?[row]["icon"] as? String {
				imageView.image = UIImage(named: imageName)
			} else {
				imageView.image = nil
			}
		}
		
		// Title text
		if let titleLabel = cell.viewWithTag(3) as? UILabel {
			if let titleText = parts?[row]["title"] as? String {
				titleLabel.text = titleText
			} else {
				titleLabel.text = nil
			}
		}
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		
		// Calculate safe area
		let safeAreaWidth = collectionView.frame.size.width - (collectionView.safeAreaInsets.left + collectionView.safeAreaInsets.right)
		
		if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
			var sectionInset = layout.sectionInset
			let itemWidth = currentCellSize.width
			let cellSpacing = layout.minimumInteritemSpacing
			let columns = floor((safeAreaWidth + cellSpacing) / (itemWidth + cellSpacing))
			let margin = floor((safeAreaWidth - (itemWidth + cellSpacing) * columns + cellSpacing) / (columns + 1) - 0.5)
			sectionInset.left = margin + collectionView.safeAreaInsets.left
			sectionInset.right = margin + collectionView.safeAreaInsets.right
			return sectionInset
		} else {
			return UIEdgeInsets.zero
		}
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return currentCellSize
	}

}
