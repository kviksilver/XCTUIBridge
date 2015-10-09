//
//  ViewController.swift
//  XCTUIBridge
//
//  Created by kviksilver on 09/29/2015.
//  Copyright (c) 2015 kviksilver. All rights reserved.
//

import UIKit
import XCTUIBridge

class ViewController: UIViewController {

    @IBOutlet weak var button: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        _ = XCTUIBridge.register("test") { [weak self] in
            if let weakSelf = self {
                weakSelf.button.setTitle("wow", forState: .Normal)
            }
        }
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

