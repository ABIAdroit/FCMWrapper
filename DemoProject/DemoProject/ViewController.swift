//
//  ViewController.swift
//  DemoProject
//
//  Created by M Abubaker Majeed on 04/01/2019.
//  Copyright © 2019 M Abubaker Majeed. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.


        
    }

    override func viewDidAppear(_ animated: Bool) {

        let wrapper : ApnsToFcmConverter = ApnsToFcmConverter.init(googleLegacyServerkey: "googleLegacyServerkey", senderID: "SenderID")
//        wrapper.convertAPNsToFCMAndRegistered(importApnsFromFileURL: nil , isDebug: false) { (url, success ) in
//
//        }
        wrapper.convertAPNsToFCMAndRegisteredToWithTopicName(importApnsFromFileURL: nil, isDebug: false , topic: "IOS-App") { (url , success) in
            debugPrint("\(url), \(success)")
            let alertController = UIAlertController(title: "Message", message: "Task : \(success)", preferredStyle: .alert)
            self.present(alertController, animated: true, completion: nil)
        }
//        wrapper.registerdExsistingFCMTokenToTopicName(importApnsFromFileURL: nil, isDebug: true, topic: "IOS-AirFrayer") { (_, success ) in
//
//        }

    }


}

