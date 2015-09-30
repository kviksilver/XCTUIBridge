//
//  XCTUIBridge.swift
//  Pods
//
//  Created by Boris Erceg on 29/09/15.
//
//

import Foundation

public typealias XCTUIBridgePayload = [String: AnyObject]
public typealias XCTUIBridgeCompletion = (XCTUIBridgePayload?)->Void

enum XCTUIBridgeError: ErrorType {
    case MissingSelector
}

public protocol XCTUIBridgeDelegate: class {
    func bridgeReceivedMessage(message: XCTUIBridgeMessage) -> XCTUIBridgePayload?
}

public struct XCTUIBridgeMessage {
    
    let selector: Selector
    let identifier: String
    let data: XCTUIBridgePayload?
    
    public init(selector: Selector, data:XCTUIBridgePayload? = nil) {
        self.selector = selector
        self.identifier = String(arc4random())
        self.data = data
    }
    
    init(dictionary: [String:AnyObject]) throws {
        guard let selectorFromDict = dictionary["selector"] as? String,
            identifierFromDict = dictionary["id"] as? String else {
                
            throw XCTUIBridgeError.MissingSelector
        }
        
        selector = Selector(selectorFromDict)
        if let dataFromDict = dictionary["data"] as? XCTUIBridgePayload {
            data = dataFromDict
        } else {
            data = nil
        }
        identifier = identifierFromDict
        
    }
    
    func serialized() -> [String:AnyObject] {
        var dictionary = [String:AnyObject]()
        if let data = data {
            dictionary["data"] = data
        }
        dictionary["id"] = identifier
        //TODO: better way to get string selector from string?
        dictionary["selector"] = selector.description
    
        
        return dictionary
    }
}

enum XCTUIBridgeSide: String {
    case Test = "XCTUIBridgeSideTest"
    case Client = "XCTUIBridgeSideClient"
}

let XCTUIBridgeNotification = "XCTUIBridgeNotification"

public final class XCTUIBridge: NSObject {
    private weak var delegate: XCTUIBridgeDelegate?
    var callbacks = [String: XCTUIBridgeCompletion]()
    
    public init(delegate: XCTUIBridgeDelegate) {
        self.delegate = delegate
        super.init()
        registerClientSide()
    }
    
    public override init() {
        super.init()
    }
    public func sendMessage(message: XCTUIBridgeMessage, completion: XCTUIBridgeCompletion) {
        registerTestSide()
        callbacks[message.identifier] = completion
        XCTUIBridge.sendDarwinNotificationWithIdentifier(XCTUIBridgeSide.Test.rawValue, payload: message.serialized())
    }
    
    func registerClientSide() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("notificationRecieved:"), name: XCTUIBridgeNotification, object: nil)
        XCTUIBridge.registerForDarwinNotificationsWithIdentifier(XCTUIBridgeSide.Client.rawValue)
    }
    
    func registerTestSide() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("notificationRecieved:"), name: XCTUIBridgeNotification, object: nil)
        XCTUIBridge.registerForDarwinNotificationsWithIdentifier(XCTUIBridgeSide.Test.rawValue)
    }
    
    func testSideBridgeRecivedMessage(message: XCTUIBridgeMessage) {
        if let callback = callbacks[message.identifier] {
            callback(message.data)
        }
        //TODO clear callback
    }
    
    func clientSideBridgeRecivedMessage(message: XCTUIBridgeMessage) {
        
        delegate?.bridgeReceivedMessage(message)
    }
    
    func notificationRecieved(notification:NSNotification) {
        if let userInfoDictionary = notification.userInfo,
            identifier = userInfoDictionary["identifier"] as? String,
            bridgeSide = XCTUIBridgeSide(rawValue: identifier),
            payload = userInfoDictionary["payload"] {
                do {
                    let message = try XCTUIBridgeMessage(dictionary: payload as! [String:AnyObject] )
                    switch bridgeSide {
                    case .Test:
                        testSideBridgeRecivedMessage(message)
                        break
                    case .Client:
                        clientSideBridgeRecivedMessage(message)
                        break
                    }
                } catch {
                
                }
        }
    }
    
    static private func registerForDarwinNotificationsWithIdentifier(identifier: String) {
        let center = CFNotificationCenterGetLocalCenter()
        let suspensionBehavior = CFNotificationSuspensionBehavior.DeliverImmediately
        
        let callback: @convention(block) (CFNotificationCenter!, UnsafeMutablePointer<Void>, CFString!, UnsafePointer<Void>, CFDictionary!) -> Void = { (center, observer, name, object, userInfo) in
            if let name = name,
                userInfo = userInfo {
                    let userInfoDictionary = ["identifier" : name, "payload" : userInfo] as [NSObject: AnyObject]
                    NSNotificationCenter.defaultCenter().postNotificationName(XCTUIBridgeNotification, object: nil, userInfo: userInfoDictionary)
            }
        }
        
        let imp: COpaquePointer = imp_implementationWithBlock(unsafeBitCast(callback, AnyObject.self))
        let notificationCallback: CFNotificationCallback = unsafeBitCast(imp, CFNotificationCallback.self)
        CFNotificationCenterAddObserver(center, nil, notificationCallback, identifier, nil, suspensionBehavior)
    }
    
    static private func sendDarwinNotificationWithIdentifier(name: String, payload: CFDictionaryRef) {
        let center = CFNotificationCenterGetLocalCenter()
        CFNotificationCenterPostNotification(center, name as CFString, nil, payload, true)
    }
}
