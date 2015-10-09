//
//  AppDelegate.swift
//  XCTUIBridge
//
//  Created by kviksilver on 09/29/2015.
//  Copyright (c) 2015 kviksilver. All rights reserved.
//

import UIKit
import XCTUIBridge

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?



    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
     
        _ = XCTUIBridge.register("test") { () -> Void in
            print("got notification")
        }
        
        return true
    }


}

