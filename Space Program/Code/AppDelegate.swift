//
//  AppDelegate.swift
//  Space Program
//
//  Created by Lucius Kwok on 10/30/18.
//  Copyright © 2018 Felt Tip Inc. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		
		// Switch to Tracking automatically on launch
		if let nc = application.windows.first?.rootViewController as? UINavigationController {
			if let vc = nc.viewControllers.first as? SpaceCenterViewController {
				vc.showTracking(nil)
			}
		}
		
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}

	// MARK: - Utility
	
	static func readJSON(file:String) -> [[String:Any]]? {
		guard let url = Bundle.main.url(forResource: file, withExtension:"json") else {
			print("[LK] File not found."); return nil
		}
		
		do {
			let data = try Data(contentsOf: url)
			if let rootObject = try JSONSerialization.jsonObject(with: data, options: []) as? [[String:Any]] {
				return rootObject
			}
		} catch {
			print("[LK] Error reading JSON.")
		}
		return nil
	}

	static func color(rgbHexValue hex:String) -> UIColor {
		var rgbInt:UInt32 = 0
		Scanner(string: hex).scanHexInt32(&rgbInt)
		let maxValue = CGFloat(255.0)
		let r = CGFloat((rgbInt >> 16) & 0xFF) / maxValue;
		let g = CGFloat((rgbInt >> 8) & 0xFF) / maxValue;
		let b = CGFloat((rgbInt >> 0) & 0xFF) / maxValue;
		return UIColor(red: r, green: g, blue: b, alpha: 1.0)
	}


}

