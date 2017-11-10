//
//  Artik0OnboardingService.swift
//  SamsungARTIK
//
//  Created by Surendra on 1/2/17.
//  Copyright © 2017 alimi shalini. All rights reserved.
//

import UIKit
import AFNetworking
import SwiftKeychainWrapper


protocol Artik0OnboardingDelegate: NSObjectProtocol {
    func didOnboardArtik0()
    func onboardingFailed(_ message: String)
}

class Artik0OnboardingService: NSObject {
    
    weak var onBoardingDelegate: Artik0OnboardingDelegate?
    var ipaddress: String!
    var foundArtikZero = false
    var deviceUUID = ""
    var deviceMac = ""
    var deviceName = ""
    var dtid = ""
    
    func startOnboarding(_ deviceBLEMac: String, name: String) {
        deviceMac = deviceBLEMac
        deviceName = name
        self.checkHubDiscoveryMode()
    }
    
    /*
     PUT a http req to MODE_URL with json data as ("discoverystarted", true)
     Should recieve a success response with discoverystarted as true
     if success reponse with discoverystarted as true, then registerModuleToCloud();
     */
    
    func setHubDiscoveryMode() {
        print("setHubDiscoveryMode")
        
        let urlString = String(format: Constants.REGISTER_URL, ipaddress)
        let url = URL(string: urlString)!
        var parametersDictionary = [AnyHashable: Any]()
        parametersDictionary["discoverystarted"] = "true"
        
        let manager = AFHTTPSessionManager()
        manager.responseSerializer = AFHTTPResponseSerializer()
        
        manager.put(url.absoluteString, parameters: parametersDictionary, success: {(_ task: URLSessionDataTask, _ responseObject: Any) -> Void in
            var json = responseObject as! [AnyHashable: Any]
            if (json["discoverystarted"] as! String) != "" {
                print("setHubDiscoveryMode:: discovery started")
                self.perform(#selector(self.sendUserDetails), with: nil, afterDelay: 5)
            }
            else {
                print("Error in setting the discovery state")
                self.onBoardingDelegate?.onboardingFailed("Error in discovery")
            }
        }, failure: {(task: URLSessionDataTask?, error: Error) -> Void in
            print("Error: \(error)")
            self.onBoardingDelegate?.onboardingFailed(error.localizedDescription)
        })
    }
    
    /**
     -> GET MODE_URL
     -> Should recieve a success response with json {discoverystarted: true}
     if (jsonResponse.getBoolean("discoverystarted")) {
     registerModuleToCloud();
     } else {
     setHubDiscoveryMode();
     }
     */
    
    func checkHubDiscoveryMode() {
        print("checkHubDiscoveryMode")
        
        let urlString = String(format: Constants.MODE_URL, ipaddress)
        
        let manager = AFHTTPSessionManager()
        manager.get(urlString, parameters: nil, progress: nil, success: {(_ task: URLSessionTask, _ responseObject: Any) -> Void in
            print("JSON: \(responseObject)")
            var json = (responseObject as! [AnyHashable: Any])
            if json["discoverystarted"] != nil {
                print("checkHubDiscoveryMode:: discoveryStarted is true, should call register to cloud")
                self.sendUserDetails()
            }
            else {
                self.setHubDiscoveryMode()
            }
        }, failure: {(operation: URLSessionTask?, error: Error) -> Void in
            print("Error: \(error)")
            self.onBoardingDelegate?.onboardingFailed(error.localizedDescription)
        })
    }
    
    /**
     ("uuid", mEdgeNode.getDeviceUUID());
     ("dtid", DEVICE_TYPE);
     ("name", mEdgeNode.getName());
     
     -> POST to REGISTER_URL a json with above data
     -> you will recieve a success response with json data {success:true}
     */
    
    func registerModuleToCloud() {
        print("registerModuleToCloud")
        
        let defaults = UserDefaults.standard
        var dataDic = defaults.object(forKey:Constants.MODULE_AND_LOCATION_DICTIONARY)! as! [String:Any]
        
        var edgeNodeName = (dataDic[Constants.MODULE_NAME] as! String)
        
        if edgeNodeName.characters.count < 5 {
            edgeNodeName = "Artik-".appending(ATUtilities.getDeviceIdentifier())
        }
        
        var location = (dataDic[Constants.LOCATION_NAME] as! String)
        location = (location.characters.count > 0) ? location : Constants.UNSPECIFIED_LOCATION
        let dataDictionary = [
            Constants.MODULE_NAME : edgeNodeName,
            Constants.LOCATION_NAME : location
        ]
        
        defaults.set(dataDictionary, forKey: Constants.MODULE_AND_LOCATION_DICTIONARY)
        
        if deviceName.characters.count > 0 {
            edgeNodeName = deviceName
        }
        
        let urlString = String(format: Constants.REGISTER_URL, ipaddress)
        let url = URL(string: urlString)!
        
        var parametersDictionary = [AnyHashable: Any]()
        parametersDictionary["uuid"] = deviceUUID

        if !dtid.isEmpty {
            parametersDictionary["dtid"] = dtid
        }
        parametersDictionary["name"] = edgeNodeName
        
        let manager = AFHTTPSessionManager()
        manager.responseSerializer = AFHTTPResponseSerializer()
        manager.requestSerializer = AFJSONRequestSerializer()
        manager.post(url.absoluteString, parameters: parametersDictionary, progress: nil, success: {(_ task: URLSessionDataTask, _ responseObject: Any) -> Void in
            print("Response \(String(data: responseObject as! Data, encoding: String.Encoding.utf8))")
            var isSuccess: Bool!
            var errorValue = ""
            
            do {
                if (responseObject is Data) {
                    
                    var jsonDictionary = try JSONSerialization.jsonObject(with: responseObject as! Data, options: []) as! [String: Any]
                    
                    if let resp: Bool = jsonDictionary["success"] as! Bool? {
                        isSuccess = resp
                    }
                    if let resp: String = jsonDictionary["error"] as! String? {
                        errorValue = resp
                    }
                }
                else {
                    print("its probably a dictionary")
                    var jsonDictionary = (responseObject as! [AnyHashable: Any])
                    print("jsonDictionary - \(jsonDictionary)")
                    
                    if let resp: Bool = jsonDictionary["success"] as! Bool? {
                        isSuccess = resp
                    }
                    if let resp: String = jsonDictionary["error"] as! String? {
                        errorValue = resp
                    }
                }
            }
            catch {
                print("json error: \(error)")
            }
            
            if isSuccess == true {
                print("registerModuleToCloud:: success")
                self.onBoardingDelegate?.didOnboardArtik0()
            }
            else {
                self.onBoardingDelegate?.onboardingFailed(errorValue)
                print("failed registerModuleToCloud")
            }
        }, failure: {(_ task: URLSessionDataTask?, _ error: Error) -> Void in
            print("Error  \(error)")
            self.onBoardingDelegate?.onboardingFailed(error.localizedDescription)
        })
    }
    
    func sendUserDetails() {
        print("sendUserDetails")
        
        let urlString = String(format: Constants.USER_DETAILS_URL, ipaddress)
        let url = URL(string: urlString)!
        
        let defaults = KeychainWrapper.standard
        
        var parametersDictionary = [AnyHashable: Any]()
        parametersDictionary["user_id"] = (defaults.string(forKey: Constants.USER_ID))
        parametersDictionary["token"] = (defaults.string(forKey: Constants.ACCESS_TOKEN))
        
        let manager = AFHTTPSessionManager()
        manager.responseSerializer = AFJSONResponseSerializer()
        manager.requestSerializer = AFJSONRequestSerializer()
        manager.put(url.absoluteString, parameters: parametersDictionary, success: {(task: URLSessionDataTask, responseObject: Any) -> Void in
            
            //Onboarding done
            var responseDict = (responseObject as! [String: Any])
            
            if let resp: Bool = responseDict["success"] as! Bool? {
                if resp == true {
                    print("senduserdetails:: success")
                    self.searchDevices()
                }
                else {
                    print("failed sending user details")
                    self.onBoardingDelegate?.onboardingFailed("Failed setting user details")
                }
            }
            else {
                print("failed sending user details")
                self.onBoardingDelegate?.onboardingFailed("Failed setting user details")
            }
            
        }, failure: {(task: URLSessionDataTask?, error: Error?) -> Void in
            print("Error  \(error)")
            self.onBoardingDelegate?.onboardingFailed((error?.localizedDescription)!)
        })
    }
    
    func searchDevices() {
        print("checkHubDiscoveryMode")
        
        let urlString = String(format: Constants.DEVICES_URL, ipaddress)
        
        let manager = AFHTTPSessionManager()
        manager.get(urlString, parameters: nil, progress: nil, success: {(_ task: URLSessionTask, _ responseObject: Any) -> Void in
            print("JSON: \(responseObject)")
            
            let jsonArray = (responseObject as! [Any])
            print("jsonArray: \(jsonArray.debugDescription)")
            for object: Any in jsonArray {
                var dictItem = (object as! [AnyHashable: Any])
                let uuid = dictItem["uuid"] as! String
                print("uuidfromresp: \(uuid)")
                if uuid.localizedCaseInsensitiveContains(self.deviceMac) {
                    self.foundArtikZero = true
                    self.deviceUUID = uuid
                    self.registerModuleToCloud()
                }
            }
            
            if !self.foundArtikZero {
                print("Could not find the required artik 0")
                self.onBoardingDelegate?.onboardingFailed("Could not find the required ARTIK 0.")
            }
            
        }, failure: {(operation: URLSessionTask?, error: Error?) -> Void in
            print("Error  \(error)")
            self.onBoardingDelegate?.onboardingFailed((error?.localizedDescription)!)
        })
    }
}
