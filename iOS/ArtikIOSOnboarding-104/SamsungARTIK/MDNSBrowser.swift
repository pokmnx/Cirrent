//
//  MDNSBrowser.swift
//  SamsungARTIK
//
//  Created by Vaibhav Singh on 27/01/17.
//  Copyright © 2017 alimi shalini. All rights reserved.
//

import Foundation

protocol mDNSBrowserDelegate {
    func didFinish()
}

class mDNSBrowser : NSObject, NetServiceBrowserDelegate, NetServiceDelegate {

    var mBrowser:NetServiceBrowser
    var listHubs : [String]
    var services = [NetService]()
    var delegate: mDNSBrowserDelegate?
    let watchdogTime	= DispatchTime.now() + DispatchTimeInterval.seconds(1)
    var moreComing:Bool = true

    var type = "_enm._tcp."
    var searchByName : Bool = false
    var searchName = ""
    
    override init() {
        self.listHubs = []
        self.mBrowser = NetServiceBrowser()
        super.init()
        self.mBrowser.delegate = self
    }
    
    func searchHubDevices() {
        self.listHubs = []
        mBrowser.searchForServices(ofType: type ,inDomain: "local.")
    }
    
    func start(){
        RunLoop.current.run()
    }
    
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        print("Start Hub Discover")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        
        print("Found a service ", service.name, " and moreComming ", moreComing)

        if searchByName && service.name != searchName {
            print("This service is not as \(searchName)")
            return
        }

        service.delegate = self
        service.resolve(withTimeout:0)
        self.services.append(service)
        self.moreComing = moreComing
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("Error in browsing ", errorDict)
    }
    

    
    func netServiceDidResolveAddress(_ sender: NetService) {
        print("Did Resolve service ", sender.port)
        let txt = NSString(data: sender.txtRecordData()!, encoding: String.Encoding.utf8.rawValue)
        print("Properties ", txt!)
        var numAddress = "0.0.0.0"
        
        for address in sender.addresses! {
            let theAddress = address as NSData
            var hostname = [CChar](repeating: 0,count: Int(NI_MAXHOST))
            if getnameinfo(theAddress.bytes.assumingMemoryBound(to: sockaddr.self), socklen_t(theAddress.length), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                let ip = String(cString: hostname)
                if (isValidIPV4Address(ipToValidate: ip)) {
                    numAddress = ip
                }
                print("IP: \(ip)")
            }
        }
        /* For some reason, mDNS gives carriage return byte at the start. Trimming it */
        var trimmed_props = (txt as! String).replacingOccurrences(of: "\r", with: "", options: .regularExpression)
        trimmed_props = trimmed_props.replacingOccurrences(of: "data=", with: "", options: .regularExpression)
        self.listHubs.append(numAddress + "," + trimmed_props)
        if (self.moreComing == false) {
            print("Finishing service with ", self.listHubs.count)
            delegate?.didFinish()
        }
    }
    
    func isValidIPV4Address(ipToValidate: String) -> Bool {
        
        var sin = sockaddr_in()
        if ipToValidate.withCString({ cstring in inet_pton(AF_INET, cstring, &sin.sin_addr) }) == 1 {
            // IPv4 peer.
            return true
        }
        
        return false;
    }
    
    func netServiceDidStop(_ sender: NetService) {
        print("Stopped Resolved service ", sender.txtRecordData()!)
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("UnResolved service ", sender.txtRecordData()!)
    }
}
