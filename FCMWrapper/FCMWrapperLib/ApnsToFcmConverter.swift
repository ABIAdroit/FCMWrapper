//
//  ApnsToFcmConverter.swift
//  ThumbnailMaker
//
//  Created by M Abubaker Majeed on 01/01/2019.
//  Copyright © 2019 Content Arcade. All rights reserved.
//

import Foundation
import Firebase

class ApnsToFcmConverter {

    private static let fcmErrorMessageForAlreadyCreatedGroup = "notification_key already exists"

    private let dispatchGroup = DispatchGroup()
    private let fileManager   = FileManager.default
    private let semaphore     = DispatchSemaphore(value: 0)
    private let installarQueue = DispatchQueue(label: "com.FCMInstaller.queue" , attributes: .concurrent)
    fileprivate let defaultSession = URLSession(configuration: .default)
    fileprivate let defaultFileName = "APNs"
    fileprivate let defaultFileType = "txt"
    fileprivate let registerURL     = "https://iid.googleapis.com/iid/v1:batchImport"
    fileprivate let createGroupURL  = "https://android.googleapis.com/gcm/notification"
    fileprivate let subscribeURL    = "https://iid.googleapis.com/iid/v1:batchAdd"
    fileprivate let fcmValidationTokenURL = "https://iid.googleapis.com/iid/info/"
    fileprivate let fcmRemoveTopicURL = "https://iid.googleapis.com/iid/v1:batchRemove"

    fileprivate let googleLegacyServerkey : String?
    fileprivate let senderID :  String?
    fileprivate var groupName:  String? = "General"
    fileprivate var topicName:  String? = "GeneralTopic"
    fileprivate var fcmTokens:  Array<String> = []

    init(googleLegacyServerkey : String , senderID : String) {
        self.googleLegacyServerkey = googleLegacyServerkey
        self.senderID = senderID
    }

    // MARK:- Default User : Public

    public func convertAPNsToFCMAndRegistered(importApnsFromFileURL : URL? , isDebug : Bool ,completionHandler : @escaping (_ registreFcmTokens : [String] , _ isSuccessfulyCompleted : Bool ) -> Void) {
        guard (self.googleLegacyServerkey?.count)! > 0, (self.senderID?.count)!>0 else {
            fatalError("Its important that you initilzed object with google legacy server key and senderID, Please goto console.firebase.google.com for further help")
        }
        let startDate = Date()
        let apnsA = getAPNsTokenArrayFromURL(fileURL: importApnsFromFileURL)
        guard apnsA.count > 0 else {
            completionHandler ( [] , false)
            return
        }
        installarQueue.async {
            self.startRegistrationProcess(arrayOfToken: apnsA , isDebug: isDebug)
            self.dispatchGroup.notify(queue: self.installarQueue ) {
                debugPrint("\(self.fcmTokens.count)")
                debugPrint("Total Time for token : \(Date().timeIntervalSince(startDate))s")
                DispatchQueue.main.async {
                    completionHandler ( self.fcmTokens , true)
                }
            }
        }
    }
    public func convertAPNsToFCMAndRegisteredTo(importApnsFromFileURL : URL? , isDebug : Bool , groupToSubscribe : String  ,completionHandler : @escaping (_ registreFileURL : URL? , _ isSuccessfulyCompleted : Bool ) -> Void) {
        guard (self.googleLegacyServerkey?.count)! > 0, (self.senderID?.count)!>0 else {
            fatalError("Its important that you initilzed object with google legacy server key and senderID, Please goto console.firebase.google.com for further help")
        }
        let startDate = Date()
        let apnsA = getAPNsTokenArrayFromURL(fileURL: importApnsFromFileURL)
        guard apnsA.count > 0 else {
            completionHandler ( nil , false)
            return
        }
        self.groupName = groupToSubscribe
        installarQueue.async {
            self.startRegistrationProcess(arrayOfToken: apnsA , isDebug: isDebug)
            self.validateFCMTokens(arrayOfToken: self.fcmTokens)
           // self.createGroup(groupName: self.groupName!, isDebug: isDebug)
            self.dispatchGroup.notify(queue: self.installarQueue ) {
                debugPrint("\(self.fcmTokens.count)")
                debugPrint("Total Time for token : \(Date().timeIntervalSince(startDate))s")
                DispatchQueue.main.async {
                    completionHandler ( nil , true)
                }
            }
        }
    }
    public func convertAPNsToFCMAndRegisteredToWithTopicName(importApnsFromFileURL : URL? , isDebug : Bool , topic : String  ,completionHandler : @escaping (_ registreFileURL : URL? , _ isSuccessfulyCompleted : Bool ) -> Void) {
        guard (self.googleLegacyServerkey?.count)! > 0, (self.senderID?.count)!>0 else {
            fatalError("Its important that you initilzed object with google legacy server key and senderID, Please goto console.firebase.google.com for further help")
        }
        let startDate = Date()
        let apnsA = getAPNsTokenArrayFromURL(fileURL: importApnsFromFileURL)
        guard apnsA.count > 0 else {
            completionHandler ( nil , false)
            return
        }
        self.topicName = topic
        installarQueue.async {
            self.startRegistrationProcess(arrayOfToken: apnsA , isDebug: isDebug)
            //self.validateFCMTokens(arrayOfToken: self.fcmTokens)
            self.createAndAddToTopic(topicName: self.topicName!, fcmTokenA: self.fcmTokens)
            self.dispatchGroup.notify(queue: self.installarQueue ) {
                debugPrint("\(self.fcmTokens.count)")
                debugPrint("Total Time for token : \(Date().timeIntervalSince(startDate)/60) Min")
                DispatchQueue.main.async {
                    completionHandler ( nil , true)
                }
            }
        }
    }
    public func convertAPNsToFCMAndRemovedFromTopic (importApnsFromFileURL : URL? , isDebug : Bool , topic : String  ,completionHandler : @escaping (_ registreFileURL : URL? , _ isSuccessfulyCompleted : Bool ) -> Void) {
        guard (self.googleLegacyServerkey?.count)! > 0, (self.senderID?.count)!>0 else {
            fatalError("Its important that you initilzed object with google legacy server key and senderID, Please goto console.firebase.google.com for further help")
        }
        let startDate = Date()
        let apnsA = getAPNsTokenArrayFromURL(fileURL: importApnsFromFileURL)
        guard apnsA.count > 0 else {
            completionHandler ( nil , false)
            return
        }
        self.topicName = topic
        installarQueue.async {
            self.startRegistrationProcess(arrayOfToken: apnsA , isDebug: isDebug)
            //self.validateFCMTokens(arrayOfToken: self.fcmTokens)
            //self.createAndAddToTopic(topicName: self.topicName!, fcmTokenA: self.fcmTokens)
            self.removeTopic(topicName: self.topicName!, fcmTokenA: self.fcmTokens)
            self.dispatchGroup.notify(queue: self.installarQueue ) {
                debugPrint("\(self.fcmTokens.count)")
                debugPrint("Total Time for token : \(Date().timeIntervalSince(startDate)/60) Min")
                DispatchQueue.main.async {
                    completionHandler ( nil , true)
                }
            }
        }
    }
    // MARK:- Private
    fileprivate func startRegistrationProcess(arrayOfToken : Array<String> , isDebug : Bool ) -> Void {
        var currentIndex  = 0
        let chunks = arrayOfToken.chunked(into: 100)
        for chunkForAPI in chunks {
            self.dispatchGroup.enter()
            self.registerToken(arrayOfToken: Array(chunkForAPI) , isDebug: isDebug) { [weak self]
                (isRegistered)  in
                if let self = self {
                    if currentIndex == chunks.count - 1 {
                        self.semaphore.signal()
                    }else{
                        currentIndex += 1
                    }
                    self.dispatchGroup.leave()
                }
            }
        }
        self.semaphore.wait()
    }
    fileprivate func validateFCMTokens(arrayOfToken : Array<String> ) -> Void {
        var currentIndex  = 0
        let chunks = arrayOfToken.chunked(into: 1)
        for chunkForAPI in chunks {
            self.dispatchGroup.enter()
            sleep(1);
            self.valiDateToken(fcmToken: chunkForAPI[0]) { [weak self] (isValidated) in
                if let self = self {
                    if currentIndex == chunks.count - 1 {
                        self.semaphore.signal()
                    }else{
                        currentIndex += 1
                    }
                    self.dispatchGroup.leave()
                }
            }
        }
        self.semaphore.wait()
    }
    fileprivate func createGroup (groupName: String , isDebug : Bool) -> Void {
        let chunks = self.fcmTokens.chunked(into: 20)
        for chunkForAPI in chunks {
            self.dispatchGroup.enter()
            self.createGroup(groupName: groupName , registrationIds: chunkForAPI , isDebug: isDebug) { [weak self] (isCreated , groupAlreadyCreated) in
                if let self = self {
                    debugPrint("isCreated : \(isCreated)")
                    if groupAlreadyCreated {
                        self.semaphore.signal()
                        self.dispatchGroup.leave()
                        self.addToGroup(groupName: groupName, isDebug: isDebug)
                    }else{
                        self.semaphore.signal()
                        self.dispatchGroup.leave()
                    }
                }
            }
            self.semaphore.wait()
        }
    }
    fileprivate func addToGroup (groupName: String , isDebug : Bool) -> Void {
        let chunks = self.fcmTokens.chunked(into: 20)
        for chunkForAPI in chunks {
            self.dispatchGroup.enter()
            self.addToGroup(groupName: groupName, registrationIds: chunkForAPI , isDebug: isDebug) {  [weak self] ( isCreated , groupAlreadyCreated) in
                if let self = self {
                    debugPrint("isCreated : \(isCreated)")
                    if groupAlreadyCreated {
                        self.semaphore.signal()
                        self.dispatchGroup.leave()
                    }else{
                        self.semaphore.signal()
                        self.dispatchGroup.leave()
                    }
                }
            }
            self.semaphore.wait()
        }
    }
    fileprivate func createAndAddToTopic (topicName: String , fcmTokenA : Array<String> ) -> Void {
         var currentIndex  = 0
        let chunks = fcmTokenA.chunked(into: 100)
        for chunkForAPI in chunks {
            self.dispatchGroup.enter()
            sleep(1)
            self.createTopic(topic: topicName, registrationIds: chunkForAPI) {  [weak self] (created, isTopicAlreadyCreated ) in
                if let self = self {
                    debugPrint("isCreated : \(isTopicAlreadyCreated)")
                    if currentIndex == chunks.count - 1 {
                        self.semaphore.signal()
                    }else{
                        currentIndex += 1
                    }
                     self.dispatchGroup.leave()
                }else{
                    debugPrint("No Self")
                }

            }
        }
         self.semaphore.wait()
    }
    fileprivate func removeTopic (topicName: String , fcmTokenA : Array<String> ) -> Void {
        var currentIndex  = 0
        let chunks = fcmTokenA.chunked(into: 100)
        for chunkForAPI in chunks {
            self.dispatchGroup.enter()
            self.removeTopic(topic: topicName, registrationIds: chunkForAPI) {  [weak self] (ActionRemoved, isRemoved ) in
                if let self = self {
                    debugPrint("isRemoved : \(isRemoved)")
                    if currentIndex == chunks.count - 1 {
                        self.semaphore.signal()
                    }else{
                        currentIndex += 1
                    }
                    self.dispatchGroup.leave()
                }else{
                    debugPrint("No Self")
                }
            }
        }
        self.semaphore.wait()
    }

    // MARK:- Public URL Caller -
    // Please dont not call these methodfrom outher side if you are not sure about input data, else result in error always
    public func registerToken (arrayOfToken : [String] , isDebug : Bool , registeredHandler : @escaping (_ registerd : Bool) -> Void) {
        let parameters = ["application": Bundle.main.bundleIdentifier! , "sandbox": isDebug , "apns_tokens" : arrayOfToken ] as [String : Any]
        let url = URL(string: registerURL)! //change the url
        var request = URLRequest(url: url)
        request.httpMethod = "POST" //set http method as POST
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
        } catch let error {
            print(error.localizedDescription)
             registeredHandler(false)
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("key=\(self.googleLegacyServerkey!)", forHTTPHeaderField: "Authorization")
        //create dataTask using the session object to send data to the server
        let task = defaultSession.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil,let data = data else {
                registeredHandler(false)
                return
            }
            //create json object from data
            if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                print(json as Any)
                let jsonA = json!["results"]
                registeredHandler(self.addToFcmA(jsonA as! Array<Dictionary<String, String>>))
            }
        })
        task.resume()
    }
    public func valiDateToken (fcmToken : String , registeredHandler : @escaping (_ isValidated : Bool) -> Void) {

        let finalURLString = fcmValidationTokenURL+fcmToken
        let url = URL(string: finalURLString)! //change the url
        var request = URLRequest(url: url)
        request.httpMethod = "GET" //set http method as POST
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("key=\(self.googleLegacyServerkey!)", forHTTPHeaderField: "Authorization")
        let task = defaultSession.dataTask(with: request as URLRequest, completionHandler: { data, response, error in

            guard error == nil,let data = data else {
                registeredHandler(false)
                return
            }
            do {
                //create json object from data
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    print(json)
                    guard let applicationName : String = json["application"] as? String else {
                        debugPrint("Failure : \(fcmToken) : Response : \(json)")
                        registeredHandler(false)
                        return;
                    }
                    debugPrint("\(fcmToken) : \(applicationName) : Response : \(json)")
                    registeredHandler(true)
                }
            } catch let error {
                print(error.localizedDescription)
                registeredHandler(false)
            }
        })
        task.resume()
    }
    public func createGroup (groupName : String , registrationIds : [String] , isDebug : Bool , registeredHandler : @escaping (_ registerd : Bool ,_ isGroupAlreadyCreated : Bool) -> Void) {

        let parameters = ["operation": "create" , "notification_key_name": groupName , "registration_ids" :  registrationIds ] as [String : Any]
        let url = URL(string: createGroupURL)! //change the url
        var request = URLRequest(url: url)
        request.httpMethod = "POST" //set http method as POST
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
        } catch let error {
            print(error.localizedDescription)
            registeredHandler(false, false)
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("key=\(self.googleLegacyServerkey!)", forHTTPHeaderField: "Authorization")
        request.addValue(self.senderID! , forHTTPHeaderField: "project_id")
        //create dataTask using the session object to send data to the server



        let task = defaultSession.dataTask(with: request as URLRequest, completionHandler: { data, response, error in

            guard error == nil,let data = data else {
                registeredHandler(false , false)
                return
            }

            do {
                //create json object from data
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    print(json)
                    guard let error : String  = json["error"] as? String else {
                        let notification_key : String = json["notification_key"] as! String
                        registeredHandler(notification_key.count > 0 ?  true : false , false )
                        return;
                    }
                    print(error)
                    if error == ApnsToFcmConverter.fcmErrorMessageForAlreadyCreatedGroup {
                        registeredHandler(false , true)
                    }
                    registeredHandler(false , false)
                }
            } catch let error {
                print(error.localizedDescription)
                registeredHandler(false,false)
            }
        })
        task.resume()
    }
    public func addToGroup (groupName : String , registrationIds : [String] , isDebug : Bool , registeredHandler : @escaping (_ registerd : Bool ,_ isGroupAlreadyCreated : Bool) -> Void) {
        let parameters = ["operation": "add" , "notification_key_name": groupName , "registration_ids" :  registrationIds , "notification_key" : groupName ] as [String : Any]
        let url = URL(string: createGroupURL)! //change the url
        var request = URLRequest(url: url)
        request.httpMethod = "POST" //set http method as POST
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
        } catch let error {
            print(error.localizedDescription)
            registeredHandler(false, false)
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("key=\(self.googleLegacyServerkey!)", forHTTPHeaderField: "Authorization")
        request.addValue(self.senderID! , forHTTPHeaderField: "project_id")
        //create dataTask using the session object to send data to the server
        let task = defaultSession.dataTask(with: request as URLRequest, completionHandler: { data, response, error in

            guard error == nil,let data = data else {
                registeredHandler(false , false)
                return
            }

            do {
                //create json object from data
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    print(json)
                    guard let error : String  = json["error"] as? String else {
                        let notification_key : String = json["notification_key"] as! String
                        registeredHandler(notification_key.count > 0 ?  true : false , false )
                        return;
                    }
                    print(error)
                    if error == ApnsToFcmConverter.fcmErrorMessageForAlreadyCreatedGroup {
                        registeredHandler(false , true)
                    }
                    registeredHandler(false , false)
                }
            } catch let error {
                print(error.localizedDescription)
                registeredHandler(false,false)
            }
        })
        task.resume()
    }
    public func createTopic (topic : String , registrationIds : [String] , registeredHandler : @escaping (_ registerd : Bool ,_ isTopicAlreadyCreated : Bool) -> Void) {

        let parameters = ["to": "/topics/\(topic)" , "registration_tokens" :  registrationIds ] as [String : Any]
        let url = URL(string: subscribeURL)! //change the url
        var request = URLRequest(url: url)
        request.httpMethod = "POST" //set http method as POST
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
        } catch let error {
            print(error.localizedDescription)
            registeredHandler(false, false)
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("key=\(self.googleLegacyServerkey!)", forHTTPHeaderField: "Authorization")
        request.addValue(self.senderID! , forHTTPHeaderField: "project_id")

        let task = defaultSession.dataTask(with: request as URLRequest, completionHandler: { data, response, error in

            guard error == nil,let data = data else {
                registeredHandler(false , false)
                return
            }

            do {
                //create json object from data
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                 //   print(json)
                    guard let _ = json["results"] as? Array<Any> else {
                        registeredHandler( false , false )
                        return;
                    }
                  //  print(results)
                    registeredHandler(true , true)
                }
            } catch let error {
                print(error.localizedDescription)
                registeredHandler(false,false)
            }
        })
        task.resume()
    }
    public func removeTopic (topic : String , registrationIds : [String] , registeredHandler : @escaping (_ registerd : Bool ,_ isTopicAlreadyCreated : Bool) -> Void) {

        let parameters = ["to": "/topics/\(topic)" , "registration_tokens" :  registrationIds ] as [String : Any]
        let url = URL(string: fcmRemoveTopicURL)! //change the url
        var request = URLRequest(url: url)
        request.httpMethod = "POST" //set http method as POST
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
        } catch let error {
            print(error.localizedDescription)
            registeredHandler(false, false)
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("key=\(self.googleLegacyServerkey!)", forHTTPHeaderField: "Authorization")
        request.addValue(self.senderID! , forHTTPHeaderField: "project_id")

        let task = defaultSession.dataTask(with: request as URLRequest, completionHandler: { data, response, error in

            guard error == nil,let data = data else {
                registeredHandler(false , false)
                return
            }

            do {
                //create json object from data
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    //   print(json)
                    guard let _ = json["results"] as? Array<Any> else {
                        registeredHandler( false , false )
                        return;
                    }
                    //  print(results)
                    registeredHandler(true , true)
                }
            } catch let error {
                print(error.localizedDescription)
                registeredHandler(false,false)
            }
        })
        task.resume()
    }

    //MARK:- CustomMethods
    fileprivate func getAPNsTokenArrayFromURL(fileURL : URL?) -> Array<String> {
        var finalPath = ""
        if fileURL != nil {
            finalPath = (fileURL?.absoluteString)!
        }else{
            finalPath =  getDefaultFileUrl()
        }
        let fileData = try? String(contentsOfFile: finalPath , encoding: String.Encoding.utf8)
        //fileData = fileData!.trimmingCharacters(in: CharacterSet.newlines)
        //let wordA : [String] = (fileData?.components(separatedBy: ","))!
        let wordA : [String] = fileData!.components(separatedBy: CharacterSet.newlines)
        return wordA
    }
    fileprivate func getDefaultFileUrl() -> String {
        let path = Bundle.main.path(forResource: defaultFileName , ofType: defaultFileType)
        guard let _ = NSData(contentsOfFile: path!) else {  return " " }
        return path!
    }
    fileprivate func addToFcmA(_ fcmA : Array<Dictionary<String, String>>) -> Bool {
        for data in fcmA {
            if let fcmToken = data["registration_token"] {
                fcmTokens.append(fcmToken)
            }else{
                debugPrint("Failure")
            }
        }
        return true
    }

}
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
