//
//  PartNode.swift
//  Space Program
//
//  Created by Lucius Kwok on 10/31/18.
//  Copyright © 2018 Felt Tip Inc. All rights reserved.
//

import Foundation

class PartNode {
	var childNodes:[PartNode] = []
	var topNode:PartNode?
	var bottomNode:PartNode?
	
	var craftPart:CraftPart
	
	init(part:CraftPart) {
		craftPart = part
	}
	
}

