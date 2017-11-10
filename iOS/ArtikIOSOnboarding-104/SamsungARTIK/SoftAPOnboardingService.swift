//
//  SoftAPOnboardingService.swift
//  SamsungARTIK
//
//  Created by Vaibhav Singh on 27/03/17.
//  Copyright © 2017 alimi shalini. All rights reserved.
//

import Foundation
import AFNetworking

protocol SoftAPOnboardingDelegate: NSObjectProtocol {
    func didGetWifiList()
    func didConfigureWifi()
    func didFindModuleOnLocalWifi()
    func didReadDtid()
    func didReadPin()
    func didOnboardSuccess()
    func didOnboardFailure(error: String)
}

class SoftAPOnboardingService: NSObject, mDNSBrowserDelegate  {

    let wifiURL = "http://192.168.10.1/v1.0/wifi/accesspoints"
    let wifiConfigURL = "http://192.168.10.1/v1.0/wifi/config"
    let cloudConfigURL = "http://%@:80/v1.0/artikcloud"
    let registrationURL = "http://%@:80/v1.0/artikcloud/registration"

    weak var delegate: SoftAPOnboardingDelegate?

    var mdnsBrowser : mDNSBrowser
    var wifiList = [[AnyHashable: Any]]()
    var mac : String!
    var deviceIp : String!
    var dtid : String!
    var pin : String!


    override init() {
        mdnsBrowser = mDNSBrowser()
        super.init()
        mdnsBrowser.type = "_http._tcp."
        mdnsBrowser.searchByName = true
        mdnsBrowser.delegate = self
    }

    func setMac(macAddress: String) {
        mac = macAddress
        mdnsBrowser.searchName = "ARTIK_" + mac.lowercased()
    }

    func getWifiList() {

        let manager = AFHTTPSessionManager()
        manager.get(wifiURL, parameters: nil, progress: nil, success: {(_ task: URLSessionTask, _ responseObject: Any) -> Void in
            var json = (responseObject as! [AnyHashable: Any])
            if json["accesspoints"] != nil {
                self.wifiList = json["accesspoints"] as! [[AnyHashable: Any]]
                print("Got \(self.wifiList.count) APs")
                self.delegate?.didGetWifiList()
            }
        }, failure: {(operation: URLSessionTask?, error: Error) -> Void in
            print("Error: \(error)")
            self.delegate?.didOnboardFailure(error: error.localizedDescription)
        })

    }

    func configureWifi(ssid: String?, passphrase: String?) {

        var parametersDictionary = [AnyHashable: Any]()
        parametersDictionary["ssid"] = ssid!
        parametersDictionary["connect"] = true

        if passphrase != nil {
            parametersDictionary["passphrase"] = passphrase!
            parametersDictionary["security"] = "Secure"

        } else {
            parametersDictionary["security"] = "Open"
        }

        let manager = AFHTTPSessionManager()
        manager.responseSerializer = AFJSONResponseSerializer()
        manager.requestSerializer = AFJSONRequestSerializer()
        manager.post(wifiConfigURL, parameters: parametersDictionary, progress: nil, success: {(_ task: URLSessionDataTask, _ responseObject: Any) -> Void in

            print("JSON: \(responseObject)")
            self.delegate?.didConfigureWifi()

        }, failure: {(operation: URLSessionTask?, error: Error) -> Void in
            print("Error: \(error)")
            self.delegate?.didOnboardFailure(error: error.localizedDescription)
        })

    }

    func startDeviceDiscovery() {
        mdnsBrowser.searchHubDevices()
    }

    /* MDNS Browser Callback */
    func didFinish() {
        /* Check for your board */
        print("Search Finished")
        if mdnsBrowser.listHubs.count > 0 {
            let desc = mdnsBrowser.listHubs[0].components(separatedBy: ",")
            deviceIp = desc[0]
            print("Found device at \(deviceIp!)")
            self.delegate?.didFindModuleOnLocalWifi()
        }

    }

    func readDtid() {

        let url = String(format:cloudConfigURL , deviceIp!)
        let manager = AFHTTPSessionManager()
        manager.get(url, parameters: nil, progress: nil, success: {(_ task: URLSessionTask, _ responseObject: Any) -> Void in
            var json = (responseObject as! [AnyHashable: Any])
            if json["dtid"] != nil {
                self.dtid = json["dtid"] as! String
                print("Device DTID is \(self.dtid!)")
                self.delegate?.didReadDtid()
            }
        }, failure: {(operation: URLSessionTask?, error: Error) -> Void in
            print("Error: \(error)")
            self.delegate?.didOnboardFailure(error: error.localizedDescription)
        })
    }

    func passDeviceInfo(did: String, token: String) {


        var parametersDictionary = [AnyHashable: Any]()
        parametersDictionary["did"] = did
        parametersDictionary["token"] = token

        let url = String(format:cloudConfigURL , deviceIp!)
        let manager = AFHTTPSessionManager()
        manager.responseSerializer = AFJSONResponseSerializer()
        manager.requestSerializer = AFJSONRequestSerializer()
        manager.post(url, parameters: parametersDictionary, progress: nil, success: {(_ task: URLSessionTask, _ responseObject: Any) -> Void in
            var json = (responseObject as! [AnyHashable: Any])
            print("\(json)")
            if json["error"] != nil {
                let error = json["error"] as! Bool
                if !error {
                    self.delegate?.didOnboardSuccess()
                } else {
                    self.delegate?.didOnboardFailure(error: json["reason"] as! String)
                }
            }
        }, failure: {(operation: URLSessionTask?, error: Error) -> Void in
            print("Error: \(error)")
            self.delegate?.didOnboardFailure(error: error.localizedDescription)
        })

    }

    func startRegistration() {
        let url = String(format:registrationURL , deviceIp!)
        let manager = AFHTTPSessionManager()
        manager.get(url, parameters: nil, progress: nil, success: {(_ task: URLSessionTask, _ responseObject: Any) -> Void in
            var json = (responseObject as! [AnyHashable: Any])

            if json["error"] != nil {
                let error = json["error"] as! Bool
                if error {
                    self.delegate?.didOnboardFailure(error: json["reason"] as! String)
                    return
                }
            }

            if json["pin"] != nil {
                self.pin = json["pin"] as! String
                print("Registration Pin is \(self.pin!)")
                self.delegate?.didReadPin()
            }
        }, failure: {(operation: URLSessionTask?, error: Error) -> Void in
            print("Error: \(error)")
            self.delegate?.didOnboardFailure(error: error.localizedDescription)
        })
    }

    func completeRegistration() {
        let url = String(format:registrationURL , deviceIp!)
        let manager = AFHTTPSessionManager()
        manager.put(url, parameters: nil, success: {(_ task: URLSessionTask, _ responseObject: Any) -> Void in
            var json = (responseObject as! [AnyHashable: Any])
            if json["error"] != nil {
                let error = json["error"] as! Bool
                if !error {
                    self.delegate?.didOnboardSuccess()
                } else {
                    self.delegate?.didOnboardFailure(error: json["reason"] as! String)
                }
            }
        }, failure: {(operation: URLSessionTask?, error: Error) -> Void in
            print("Error: \(error)")
            self.delegate?.didOnboardFailure(error: error.localizedDescription)
        })
    }

}
