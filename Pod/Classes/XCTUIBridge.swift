//
//  XCTUIBridge.swift
//  Pods
//
//  Created by Boris Erceg on 29/09/15.
//
//

import Foundation

public typealias XCTUIBridgeRemover = () -> Void;
public typealias XCTUIBridgeCallback = () -> Void;

let XCTUIBridgeNotification = "XCTUIBridgeNotification"
let instance = XCTUIBridge()

class XCTUIBridgeCallbackContainer {
    let completion:XCTUIBridgeCallback
    init(completion: XCTUIBridgeCallback) {
        self.completion = completion
    }
}

public class XCTUIBridge {
    private var clientListeners = [String: NSMutableArray]();
    
    private init() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("notificationRecieved:"), name: XCTUIBridgeNotification, object: nil)
    }

    func notificationRecieved(notification:NSNotification) {
        if let payload = notification.userInfo,
            identifier = payload["name"] as? String,
            listeners = clientListeners[identifier] {
                for var i = 0; i < listeners.count; i++ {
                    (listeners.objectAtIndex(i) as? XCTUIBridgeCallbackContainer)?.completion()
                }
        }
    }
    
    static public func sendNotification(identifier: String) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), identifier as CFString, nil, nil, true)
    }
    
    
    static public func register(identifier: String, completion: XCTUIBridgeCallback) -> XCTUIBridgeRemover {
        if let _ = instance.clientListeners[identifier] {
            let container = XCTUIBridgeCallbackContainer(completion: completion)
            instance.clientListeners[identifier]!.addObject(container)
            let remover:XCTUIBridgeRemover = {
                instance.clientListeners[identifier]!.removeObject(container)
            }
            return remover
        } else {
            instance.clientListeners[identifier] = NSMutableArray()
            registerForDarwinNotification(identifier)
            return register(identifier, completion: completion)
        }
    }
    
    static private func registerForDarwinNotification(identifier: String) {
        let callback: @convention(block) (CFNotificationCenter!, UnsafeMutablePointer<Void>, CFString!, UnsafePointer<Void>, CFDictionary!) -> Void = { (center, observer, name, object, userInfo) in
            if let name = name {
                NSNotificationCenter.defaultCenter().postNotificationName(XCTUIBridgeNotification, object: nil, userInfo: ["name":name])
            }
        }
        
        let imp: COpaquePointer = imp_implementationWithBlock(unsafeBitCast(callback, AnyObject.self))
        let notificationCallback = unsafeBitCast(imp, CFNotificationCallback.self)
        
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), unsafeAddressOf(self), notificationCallback, identifier, nil, .DeliverImmediately)
    }

}
