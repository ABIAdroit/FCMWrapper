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

        let wrapper : ApnsToFcmConverter = ApnsToFcmConverter.init(googleLegacyServerkey: "AIzaSyCOEHG-Tnsh2heA2Zs7150Bko8MD6HMpok", senderID: "614872028604")

//        wrapper.convertAPNsToFCMAndRegistered(importApnsFromFileURL: nil , isDebug: false) { (url, success ) in
//
//        }
        wrapper.convertAPNsToFCMAndRegisteredToWithTopicName(importApnsFromFileURL: nil, isDebug: true , topic: "IOS-AirFrayer") { (url , success) in
           // debugPrint("\(url), \(success)")
            let alertController = UIAlertController(title: "Message", message: "Task : \(success)", preferredStyle: .alert)
            self.present(alertController, animated: true, completion: nil)
        }
        wrapper.registerdExsistingFCMTokenToTopicName(importApnsFromFileURL: nil, isDebug: true, topic: "IOS-AirFrayer") { (_, success ) in

        }

    }


}

