//
//  ATReachability.swift
//  SamsungARTIK
//
//  Created by Surendra on 12/13/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import Foundation
import ReachabilitySwift

class ATReachability {
    var serverReachable: Reachability!
    
    let reachability = Reachability()!
    var isNetworkReachable: Bool!
    
    static let sharedInstance : ATReachability = {
        let instance = ATReachability()
        //        instance.checkAndUpdateReachabilityStatus()
        return instance
    }()
    
    func configureReachability() {
        self.isNetworkReachable = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reachabilityChanged),name: ReachabilityChangedNotification,object: nil)
        do{
            try reachability.startNotifier()
        }catch{
            print("could not start reachability notifier")
        }
        
        self.checkAndUpdateReachabilityStatus()
    }
    
    @objc func reachabilityChanged(note: NSNotification) {
        self.checkAndUpdateReachabilityStatus()
    }
    
    func checkAndUpdateReachabilityStatus() {
        if reachability.isReachable {
            if reachability.isReachableViaWiFi {
                self.isNetworkReachable = true
                //                print("Reachable via WiFi")
            } else if reachability.isReachableViaWWAN {
                self.isNetworkReachable = true
                //                print("Reachable via Cellular")
            } else {
                self.isNetworkReachable = true
                //                print("Reachable via Cellular")
            }
        } else {
            self.isNetworkReachable = false
            print("Network not reachable")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NETWORK_CONNECTION_CHANGED), object: nil, userInfo: nil)
    }
}
