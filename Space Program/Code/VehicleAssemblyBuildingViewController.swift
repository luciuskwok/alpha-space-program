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
	@IBOutlet weak var sceneView: SCNView?
	@IBOutlet weak var partsCollectionView: UICollectionView?
	
	var parts:[[String:Any]]?
	var currentCellSize = CGSize(width: 80, height: 80)
	
	// MARK: -
	
	override func awakeFromNib() {
		parts = readJSON(file:"Parts")
	}
	
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
