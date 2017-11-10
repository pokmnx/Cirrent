//
//  CirrentService.swift
//
//

import Foundation
import UIKit
import Darwin
import SystemConfiguration.CaptiveNetwork
import CoreLocation


/// The CirrentService is the main entry point to the Cirrent SDK.
public class CirrentService : NSObject {
    
    open static var sharedService:CirrentService = CirrentService()
    
    public override init() {
        super.init()
        _ = APIService.sharedService
        _ = getCurrentSSID(bLog: true)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    /// The model contains the variables that are shared between the mobile app and the Cirrent SDK.
    public var model:Model? = nil
    
    private var bSupportSoftAP = true
    /// Whether softAP is supported by the device. This tells the Cirrent SDK whether it should try to 
    /// onboard the device via SoftAP if it is unable to onboard the device via the Cirrent cloud.
    ///
    /// - Parameter bSupport: if true, device supports SoftAP.  If false, device does not support SoftAP.
    public func supportSoftAP(bSupport:Bool) {
        bSupportSoftAP = bSupport
    }
    
    /// SoftAPSSID is the SSID the phone will use to associate to the device's softAP network
    public var SoftAPSSID:String {
        get {
            let ssid = UserDefaults.standard.string(forKey: Constants.SoftAP_SSID_KEY)
            if ssid == nil {
                return "wcm-softap"
            }
            return ssid!
        }
        
        set(ssid) {
            UserDefaults.standard.set(ssid, forKey: Constants.SoftAP_SSID_KEY)
        }
    }
    
    internal var ownerID:String? = nil
    
    /// Stores the OwnerID associated with this application instance. This is used by the Cirrent cloud
    /// when it is matching up the location of the mobile app to the location of the device (to find nearby devices).
    /// The sample app uses the user's login as the ownerID.
    ///
    /// - Parameter identifier: unique id for the owner of this app. If empty, the Cirrent SDK will generate a unique id.
    /// - Returns: OwnerID
    public func setOwnerIdentifier(identifier:String = "") {
        if identifier == "" {
            ownerID = UserDefaults.standard.string(forKey: Constants.OWNERID_KEY)
            if ownerID == nil || ownerID == "" {
                ownerID = UIDevice.current.identifierForVendor?.uuidString
                if ownerID == nil || ownerID == "" {
                    ownerID = generateUUID()
                }
            }
            
            if ownerID == nil || ownerID == "" {
                return
            }
            
            UserDefaults.standard.set(ownerID!, forKey: Constants.OWNERID_KEY)
        }
        else {
            ownerID = identifier
            UserDefaults.standard.set(identifier, forKey: Constants.OWNERID_KEY)
        }
        LogService.sharedService.setOwnerIdentifier(identifier: ownerID)
    }
    
    var findSoftAPStartTime:Date!
    let SOFTAP_FIND_LIMIT:TimeInterval = 45.0
    
    @objc private func appDidBecomeActive() {
        if bNeedSoftAP == false {
            return
        }
        
        let endTime = Date()
        if findSoftAPStartTime == nil {
            findSoftAPStartTime = Date()
        }
        let diff:TimeInterval = endTime.timeIntervalSince(findSoftAPStartTime)
        
        let ssid:String? = CirrentService.sharedService.getCurrentSSID()
        if diff > SOFTAP_FIND_LIMIT && (ssid == nil || ssid!.contains(SoftAPSSID) == false) {
            LogService.sharedService.log(event: .SoftAP_LONG_DURATION, data: "")
        }
        
        if ssid == nil {
            LogService.sharedService.log(event: .SoftAP_ERROR, data: "wanted-ssid=\(String(describing: SoftAPSSID));got-ssid=nil;timeout=\(diff)")
            LogService.sharedService.putLog(token: nil)
        }
        
        if ssid!.contains(SoftAPSSID) == false {
            LogService.sharedService.log(event: .SoftAP_ERROR, data: "wanted-ssid=\(String(describing: SoftAPSSID));got-ssid=\(ssid!);timeout=\(diff)")
            LogService.sharedService.putLog(token: nil)
        }
    }
    
    @objc private func appDidEnterBackground() {
        if bNeedSoftAP == false {
            return
        }
        
        findSoftAPStartTime = Date()
    }
    
    private var findDeviceTimer:Timer? = nil
    
    
    /// This function is the first method to be called during the on-boarding process. It will find nearby discoverable
    /// devices in the Cirrent cloud.  It will first upload the location of the phone, and then look for devices of the
    /// correct type, that are nearby to this mobile app (based on matching location
    /// and/or WI-FI scans), and that have not been claimed by another user.  It will return a list of nearby devices.
    ///
    /// - Parameters:
    ///   - tokenHandler: method that will generate a SEARCH token
    ///   - completion: callback (FIND_DEVICE_RESULT, [Device]?) -> Void
    
    @objc public func findDevice(tokenMethod:TokenHandler, completion: @escaping FindDeviceCompletionHandler) {
        tokenMethod(.SEARCH, nil, {
            searchToken in
            
            if searchToken == nil {
                completion(.FAILED_INVALID_TOKEN, nil)
                LogService.sharedService.debug(data: "Find Devices Failed: Error=Search Token is nil")
                return
            }
            
            self.bNeedSoftAP = false
            let logStr = "OS:\(self.getSystemVersion()), Model:\(UIDevice.current.modelName)"
            LogService.sharedService.log(event: .SEARCH_START, data: logStr)
            self.initModel()
            
            if (self.model!.ssid == nil || self.model!.bssid == nil) && self.isOnCellularNetwork() == false {
                LogService.sharedService.log(event: .LOCATION_ERROR, data: "Find Devices Failed: Error=Phone is offline")
                completion(FIND_DEVICE_RESULT.FAILED_NETWORK_OFFLINE, nil)
                return
            }
            
            if CLLocationManager.locationServicesEnabled() == false {
                LogService.sharedService.log(event: .LOCATION_ERROR, data: "Find Devices Failed: Error=LOCATION SERVICE DISABLED")
                LogService.sharedService.putLog(token: searchToken)
                completion(FIND_DEVICE_RESULT.FAILED_LOCATION_DISABLED, nil)
                return
            }
            
            self.uploadEnvironment(searchToken: searchToken!, completion: {
                resp in
                
                if resp != RESPONSE.SUCCESS {
                    LogService.sharedService.debug(data: "Find Devices Failed: Error=UPLOAD ENVIRONMENT FAILED - TRYING AGAIN")
                    LogService.sharedService.putLog(token: searchToken)
                    
                    self.uploadEnvironment(searchToken: searchToken!, completion: {
                        resp in
                        
                        if resp != RESPONSE.SUCCESS {
                            self.needSoftAP()
                            LogService.sharedService.debug(data: "Find Devices Failed: Error=UPLOAD ENVIRONMENT FAILED - TRYING AGAIN")
                            LogService.sharedService.putLog(token: searchToken)
                            completion(.FAILED_UPLOAD_ENVIRONMENT, nil)
                            return
                        }
                        
                        DispatchQueue.main.async {
                            self.findNearByDevices(searchToken:searchToken!, completion: {
                                result, devices in
                                if result != FIND_DEVICE_RESULT.SUCCESS {
                                    self.needSoftAP()
                                    LogService.sharedService.debug(data: "Find Devices Failed: Error=There are no nearby devices")
                                    LogService.sharedService.putLog(token: searchToken)
                                    completion(result, nil)
                                }
                                else {
                                    var logStr = ""
                                    for device in devices! {
                                        logStr += "id=\(device.deviceId);"
                                    }
                                    LogService.sharedService.log(event: .DEVICES_RECEIVED, data: logStr)
                                    LogService.sharedService.putLog(token: searchToken)
                                    completion(FIND_DEVICE_RESULT.SUCCESS, devices)
                                }
                            })
                        }
                    })
                    return
                }
                
                DispatchQueue.main.async {
                    self.findNearByDevices(searchToken:searchToken!, completion: {
                        result, devices in
                        if result != FIND_DEVICE_RESULT.SUCCESS {
                            self.needSoftAP()
                            LogService.sharedService.debug(data: "Find Devices Failed: Error=There are no devices")
                            LogService.sharedService.putLog(token: searchToken)
                            completion(result, nil)
                        }
                        else {
                            var logStr = ""
                            for device in devices! {
                                logStr += "id=\(device.deviceId);"
                            }
                            LogService.sharedService.log(event: .DEVICES_RECEIVED, data: logStr)
                            LogService.sharedService.putLog(token: searchToken)
                            completion(FIND_DEVICE_RESULT.SUCCESS, devices)
                        }
                    })
                }
            })
        })
    }
    
    var softAPCount:Int = 0
    var bNeedSoftAP:Bool = false
    
    private func needSoftAP() {
        bNeedSoftAP = true
        increaseSoftAPCount()
    }
    
    private func increaseSoftAPCount() {
        softAPCount += 1
        LogService.sharedService.log(event: .SoftAP_SCREEN, data: "count=\(softAPCount)")
    }
    
    private var maxRetryCount = 6
    private func findNearByDevices(searchToken:String, completion:@escaping FindDeviceCompletionHandler) {
        if findDeviceTimer != nil {
            findDeviceTimer?.invalidate()
        }
        
        self.findDeviceTimer = Timer.scheduledTimer(withTimeInterval: Constants.FIND_DEVICE_TIME_INTERVAL, repeats: true, block: {
            t in
            self.getDevicesInRange(searchToken: searchToken, completion: {
                result, devices in
                
                if result != FIND_DEVICE_RESULT.SUCCESS {
                    if self.maxRetryCount <= 0 {
                        self.maxRetryCount = 6
                        self.findDeviceTimer?.invalidate()
                        self.findDeviceTimer = nil
                        completion(result, nil)
                        return
                    }
                    else {
                        self.maxRetryCount -= 1
                        LogService.sharedService.debug(data: "Left Find Devices Retry Count - \(self.maxRetryCount)")
                        return
                    }
                }
                
                self.findDeviceTimer?.invalidate()
                self.findDeviceTimer = nil
                self.model?.setDevices(devices: devices!)
                completion(FIND_DEVICE_RESULT.SUCCESS, devices)
            })
        })
    }
    
    private func getDevicesInRange(searchToken:String, completion: @escaping FindDeviceCompletionHandler) {
        if ownerID == nil {
            LogService.sharedService.debug(data: "Get Devices In Range Failed: Error=OwnerID is missed")
            completion(FIND_DEVICE_RESULT.FAILED_NO_RESPONSE, nil)
            return
        }
        
        APIService.sharedService.getDevicesInRange(searchToken: searchToken, appID: ownerID!, completion: {
             data, response, error in
            guard let _ = data, error == nil else {
                LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Get Devices In Range Failed - no response")
                completion(FIND_DEVICE_RESULT.FAILED_NO_RESPONSE, nil)
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                if httpStatus.statusCode == 401 {
                    LogService.sharedService.log(event: .TOKEN_ERROR, data: "Get Devices In Range Failed: Error=INVALID_TOKEN")
                    completion(FIND_DEVICE_RESULT.FAILED_INVALID_TOKEN, nil)
                }
                else {
                    LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Get Devices In Range Failed: Error=INVALID_STATUS:\(httpStatus.statusCode)")
                    completion(FIND_DEVICE_RESULT.FAILED_INVALID_STATUS, nil)
                }
                return
            }
            
            let str = String(data: data!, encoding: .utf8)
            print(str!)
            
            let jsonData:JSON = JSON(data: data!)
            let jsonArray = jsonData["devices"]
            
            var deviceArray:[Device] = [Device]()
            
            for item in jsonArray {
                let device = self.getDeviceFromJson(data: item.1)
                deviceArray.append(device)
            }
            
            if deviceArray.count == 0 {
                LogService.sharedService.debug(data: "Get Devices In Range Failed: Error=There is no devices")
                completion(FIND_DEVICE_RESULT.FAILED_NO_DEVICE, nil)
            }
            else {
                LogService.sharedService.debug(data: "Get Devices In Range Success")
                completion(FIND_DEVICE_RESULT.SUCCESS, deviceArray)
            }
        })
    }
    
    /// This is an optional method that requests that the device perform some identifying action, such as flashing a light
    /// or playing a sound.  The request is sent to the Cirrent cloud, and the device will perform the action when it checks
    /// in with the cloud to see if there are any actions to be performed. This helps the user to confirm that they 
    /// onboarding the correct device.
    ///
    /// - Parameters:
    ///   - tokenMethod: method that will generate a token authorizing this function
    ///   - deviceID: Cirrent Device Identifier
    ///   - completion: callback (RESPONSE) -> Void
    
    @objc public func identifyYourself(tokenMethod:TokenHandler, deviceID:String, completion: @escaping CompletionHandler) {
        if model == nil || model?.devices.count == 0 {
            LogService.sharedService.debug(data: "Identify Yourself Failed: id=\(deviceID),Error=This is an invalid device")
            completion(.FAILED_INVALID_DEVICE_ID)
            return
        }
        
        var bExist = false
        for dev in (model?.devices)! {
            if dev.deviceId == deviceID {
                bExist = true
                break
            }
        }
        
        if bExist == false {
            LogService.sharedService.debug(data: "Identify Yourself Failed: id=\(deviceID),Error=This Device is not nearby")
            completion(.FAILED_INVALID_DEVICE_ID)
            return
        }
        
        tokenMethod(.SEARCH, deviceID, {
            searchToken in
            
            if searchToken == nil {
                LogService.sharedService.debug(data: "Identify Yourself Failed: id=\(deviceID),Error=Search Token is nil")
                completion(.FAILED_INVALID_TOKEN)
                return
            }
            else {
                APIService.sharedService.identifyYourself(searchToken: searchToken!, deviceID: deviceID, completion: {
                    data, response, error in
                    guard let _ = data, error == nil else {
                        LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Identify Yourself Failed - no response")
                        completion(.FAILED_NO_RESPONSE)
                        return
                    }
                    
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                        LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Identify Yourself Failed: id=\(deviceID),Error=\(LogService.getResponseErrorString(response: .FAILED_INVALID_STATUS))")
                        completion(.FAILED_INVALID_STATUS)
                        return
                    }
                    
                    LogService.sharedService.debug(data: "Identify Yourself Success: id=\(deviceID)")
                    completion(.SUCCESS)
                })
            }
        })
    }
    
    private var userActionTimer:Timer!
    
    /// Some products require that the user take some action on the device to show they have selected the correct device.
    /// If this product requires user action, this method is called to poll to see if the user has taken the action on the
    /// device.  It polls the cloud repeatedly until device reports that the user has performed some action on the device 
    /// (e.g. pressed a button on the device)
    ///
    /// - Parameters:
    ///   - tokenMethod: method that will generate a token authorizing this function
    ///   - completion: a string describing the action that was performed
    
    @objc public func pollForUserAction(tokenMethod:TokenHandler, completion:@escaping UserActionCompletionHandler) {
        if model == nil || model!.devices.count == 0 {
            return
        }
        
        tokenMethod(.SEARCH, nil, {
            searchToken in
            
            if searchToken == nil {
                return
            }
            
            self.userActionTimer = Timer.scheduledTimer(withTimeInterval: Constants.USER_ACTION_TIME_INTERVAL, repeats: true, block: {
                t in
                for dev in self.model!.devices {
                    if dev.userActionEnabled == false {
                        continue
                    }
                    
                    self.getUserActionPerformedStatus(searchToken: searchToken!, device: dev, completion: {
                        response in
                        
                        if response == .SUCCESS {
                            dev.confirmedOwnerShip = true
                            completion(dev)
                        }
                    })
                }
            })
        })
    }
    
    private func getUserActionPerformedStatus(searchToken:String, device:Device, completion:@escaping CompletionHandler) {
        APIService.sharedService.getUserActionPerformedStatus(searchToken: searchToken, deviceID: device.deviceId, completion: {
            data, response, error in
            
            guard let _ = data, error == nil else {
                LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Get UserAction Performed Status Failed - no response")
                completion(.FAILED_NO_RESPONSE)
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                if httpStatus.statusCode == 401 {
                    LogService.sharedService.log(event: .TOKEN_ERROR, data: "Get UserAction Performed Status Failed: id=\(device.deviceId),Error=INVALID_TOKEN")
                    completion(.FAILED_INVALID_TOKEN)
                }
                else {
                    LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Get UserAction Performed Status Failed: id=\(device.deviceId),Error=INVALID_STATUS(\(httpStatus.statusCode))")
                    completion(.FAILED_INVALID_STATUS)
                }
                return
            }
            
            let status:JSON = JSON(data: data!)
            let statusCode = status["code"].intValue
            let message = status["message"].stringValue
            
            if statusCode == 200 {
                LogService.sharedService.debug(data: "\(device.deviceId) - \(message)")
                completion(.SUCCESS)
            }
            else {
                LogService.sharedService.debug(data: "\(device.deviceId) - \(message)")
                completion(.FAILED_INVALID_STATUS)
            }
        })
    }
    
    /// Stop polling for user action - this is called if the app decides to wait no longer for the user to 
    /// complete the action on the device.  This tells the SDK to cancel the timer controlling how long to 
    /// poll for the user action.  This might be necessary if the user selects a different device, for example.
    @objc public func stopPollForUserAction() {
        if userActionTimer != nil {
            userActionTimer.invalidate()
        }
    }
    
    /// Delete a network that was previously provisioned for this device
    ///
    /// - Parameters:
    ///   - tokenMethod: method that will generate a token authorizing this function
    ///   - deviceID: the device from which the network should be deleted
    ///   - network: the network to be deleted
    ///   - completion: completion handler
    
    public func deleteNetwork(tokenMethod:TokenHandler, deviceID:String, network:Network, completion: @escaping CompletionHandler) {
        tokenMethod(.MANAGE, deviceID, {
            manageToken in
            
            if manageToken == nil {
                LogService.sharedService.log(event: .TOKEN_ERROR, data: "Delete Network Failed: ssid=\(network.ssid),Error=ManageToken is nil")
                completion(.FAILED_INVALID_TOKEN)
                return
            }
            
            APIService.sharedService.deletePrivateNetwork(manageToken: manageToken!, deviceID: deviceID, network: network, completion: {
                data, response, error in
                
                guard let _ = data, error == nil else {
                    LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Delete Network Failed - no response")
                    completion(.FAILED_NO_RESPONSE)
                    return
                }
                
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                    if httpStatus.statusCode == 401 {
                        LogService.sharedService.log(event: .TOKEN_ERROR, data: "Delete Network Failed: ssid=\(network.ssid),Error=INVALID_TOKEN")
                        completion(.FAILED_INVALID_TOKEN)
                    }
                    else {
                        LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Delete Network Failed: ssid=\(network.ssid),Error=INVALID_STATUS")
                        completion(.FAILED_INVALID_STATUS)
                    }
                    return
                }
                
                LogService.sharedService.debug(data: "Delete Network Success")
                completion(.SUCCESS)
            })
        })
    }
    
    /// Add a new network to an already-claimed device
    ///
    /// - Parameters:
    ///   - tokenMethod: method that will generate a token authorizing this function
    ///   - deviceID: the device to which the network should be added
    ///   - network: the network to be deleted
    ///   - password: the pre-shared key for the network being added
    ///   - completion: completion handler
    
    public func addNetwork(tokenMethod:TokenHandler, deviceID:String, network:Network, password:String, completion: @escaping CompletionHandler) {
        tokenMethod(.MANAGE, deviceID, {
            manageToken in
            
            if manageToken == nil {
                LogService.sharedService.debug(data: "Add Network Failed: ssid=\(network.ssid),Error=ManageToken is nil")
                completion(.FAILED_INVALID_TOKEN)
                return
            }
            
            APIService.sharedService.deviceJoinNetwork(manageToken: manageToken!, deviceID: deviceID, network: network, password: password, completion: {
                data, response, error in
                
                guard let _ = data, error == nil else {
                    LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Add Network Failed - no response")
                    completion(.FAILED_NO_RESPONSE)
                    return
                }
                
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                    if httpStatus.statusCode == 401 {
                        LogService.sharedService.log(event: .TOKEN_ERROR, data: "Add Network Failed: ssid=\(network.ssid),Error=INVALID_TOKEN")
                        completion(.FAILED_INVALID_TOKEN)
                    }
                    else {
                        LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Add Network Failed: ssid=\(network.ssid),Error=INVALID_STATUS")
                        completion(.FAILED_INVALID_STATUS)
                    }
                    return
                }
                
                LogService.sharedService.debug(data: "Add Network Success")
                completion(.SUCCESS)
            })
        })
    }
    
    /// This method is called after the user has selected the device.  It takes as input the device id for the selected 
    /// device, and queries the Cirrent cloud for the most recent device status. The device status will include the Wi-Fi
    /// scan list from the device, which can be used to show the user a drop-down list of the networks the device can see.
    ///
    /// - Parameters:
    ///   - tokenMethod: method that will generate a token authorizing this function
    ///   - deviceID: the device whose network scan list we need
    ///   - completion: completion handler
    
    @objc public func getCandidateNetworks(tokenMethod:(_ tokenType:TOKEN_TYPE, _ deviceID:String?, _ completion: @escaping (_ token:String?) -> Void) -> Void, deviceID:String, completion: @escaping GetNetworksCompletionHandler) {
        tokenMethod(.MANAGE, deviceID, {
            manageToken in
            
            if manageToken == nil {
                LogService.sharedService.log(event: .TOKEN_ERROR, data: "Get Candidate Networks Failed: id=\(deviceID),Error=ManageToken is nil")
                completion(nil)
                return
            }
            
            APIService.sharedService.getDeviceStatus(manageToken: manageToken!, deviceID: deviceID, uptime: true, completion: {
                data, response, error in
                guard let _ = data, error == nil else {
                    LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Get Candidate Networks Failed - no response")
                    completion(nil)
                    return
                }
                
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                    if httpStatus.statusCode == 401 {
                        LogService.sharedService.log(event: .TOKEN_ERROR, data: "Get Candidate Networks Failed: id=\(deviceID),Error=INVALID_TOKEN")
                    }
                    else {
                        LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Get Candidate Networks Failed: id=\(deviceID),Error=INVALID_STATUS")
                    }
                    completion(nil)
                    return
                }
                
                let status:JSON = JSON(data: data!)
                if status["wifi_scans"] != nil && status["wifi_scans"].count > 0 {
                    var networks = [KnownNetwork]()
                    let dataArray:[AnyObject]? = status["wifi_scans"].arrayObject as [AnyObject]?
                    
                    if dataArray == nil {
                        completion(nil)
                        return
                    }
                    
                    for net in dataArray! {
                        let netData:JSON = JSON(net)
                        let network:KnownNetwork = KnownNetwork()
                        network.bssid = netData["bssid"] != nil ? String(describing: netData["bssid"]) : ""
                        network.ssid = netData["ssid"] != nil ? String(describing: netData["ssid"]) : ""
                        network.security = netData["flags"] != nil ? String(describing: netData["flags"]) : ""
                        networks.append(network)
                    }
                    completion(networks)
                }
                else {
                    completion(nil)
                }
            })
        })
    }
    
    /// Get the list of networks already provisioned in this device
    ///
    /// - Parameters:
    ///   - tokenMethod: method that will generate a token authorizing this function
    ///   - deviceID: the device identifier
    ///   - completion: completion handler
    
    @objc public func getKnownNetworks(tokenMethod:TokenHandler, deviceID:String, completion:@escaping GetNetworksCompletionHandler) {
        tokenMethod(.MANAGE, deviceID, {
            manageToken in
            
            if manageToken == nil {
                LogService.sharedService.log(event: .TOKEN_ERROR, data: "Get Known Networks Failed: id=\(deviceID),Error=INVALID_TOKEN")
                completion(nil)
            }
            else {
                APIService.sharedService.getDeviceStatus(manageToken: manageToken!, deviceID: deviceID, completion: {
                    data, response, error in
                    guard let _ = data, error == nil else {
                        LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Get Known Networks Failed - no response")
                        completion(nil)
                        return
                    }
                    
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                        if httpStatus.statusCode == 401 {
                            LogService.sharedService.log(event: .TOKEN_ERROR, data: "Get Known Networks Failed: id=\(deviceID),Error=INVALID_TOKEN")
                        }
                        else {
                            LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Get Known Networks Failed: id=\(deviceID),Error=INVALID_STATUS")
                        }
                        completion(nil)
                        return
                    }
                    
                    let status:JSON = JSON(data: data!)
                    if status["known_networks"] != nil && status["known_networks"].count > 0 {
                        var networks = [KnownNetwork]()
                        let dataArray:[AnyObject]? = status["known_networks"].arrayObject as [AnyObject]?
                        
                        if dataArray == nil {
                            completion(nil)
                            return
                        }
                        
                        for net in dataArray! {
                            let netData:JSON = JSON(net)
                            let network:KnownNetwork = KnownNetwork()
                            network.bssid = netData["bssid"] != nil ? String(describing: netData["bssid"]) : ""
                            network.ssid = netData["ssid"] != nil ? String(describing: netData["ssid"]) : ""
                            network.priority = netData["priority"] != nil ? Int(netData["priority"].intValue) : 0
                            network.credentialID = netData["credential_id"] != nil ? String(describing: netData["credential_id"]) : ""
                            network.security = netData["security"] != nil ? String(describing: netData["security"]) : ""
                            network.source = netData["source"] != nil ? String(describing: netData["source"]) : ""
                            network.roamingID = netData["roaming_id"] != nil ? String(describing: netData["roaming_id"]) : ""
                            network.status = netData["status"] != nil ? String(describing: netData["status"]) : ""
                            
                            if network.source != "NetworkConfig" {
                                networks.append(network)
                            }
                        }
                        completion(networks)
                    }
                    else {
                        completion(nil)
                    }
                })
            }
        })
    }
    
    /// Get Device Status from Cirrent Cloud
    ///
    /// - Parameters:
    ///   - tokenMethod: method that will generate a token authorizing this function
    ///   - device: the device object which user should know the status
    ///   - completion: completion handler
    
    @objc public func getDeviceStatus(tokenMethod:@escaping TokenHandler, deviceID:String, uptime:Bool, completion:@escaping DeviceStatusCompletionHandler) {
        tokenMethod(.MANAGE, deviceID, {
            manageToken in
            
            if manageToken == nil {
                tokenMethod(.ANY, nil, {
                    token in
                    LogService.sharedService.log(event: .TOKEN_ERROR, data: "Error=INVALID_TOKEN")
                    LogService.sharedService.putLog(token: token)
                    completion(.FAILED_INVALID_TOKEN, nil)
                })
                return
            }

            APIService.sharedService.getDeviceStatus(manageToken:manageToken!, deviceID: deviceID, uptime: uptime, completion: {
                data, response, error in
                guard let _ = data, error == nil else {
                    LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Get Device Status Failed - no response")
                    LogService.sharedService.putLog(token: manageToken)
                    completion(.FAILED_NO_RESPONSE, nil)
                    return
                }
                
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                    if httpStatus.statusCode == 401 {
                        LogService.sharedService.log(event: .TOKEN_ERROR, data: "Error=INVALID_TOKEN")
                        LogService.sharedService.putLog(token: manageToken)
                        completion(.FAILED_INVALID_TOKEN, nil)
                    }
                    else {
                        LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Error=" + LogService.getResponseErrorString(response: .FAILED_INVALID_STATUS))
                        LogService.sharedService.putLog(token: manageToken)
                        completion(.FAILED_INVALID_STATUS, nil)
                    }
                    
                    return
                }
                
                let status:JSON = JSON(data: data!)
                self.model?.GCN = true
                let device = self.model?.getDevice(deviceID: deviceID)
                
                if (device != nil && device!.provider_known_network != nil) {
                    self.model?.providerNetwork = ProviderKnownNetwork()
                    self.model?.providerNetwork?.ssid = device!.provider_known_network!.ssid
                    self.model?.providerNetwork?.providerLogo = device!.provider_known_network!.providerLogo
                    self.model?.providerNetwork?.providerName = device!.provider_known_network!.providerName
                    self.model?.providerNetwork?.providerUUID = device!.provider_known_network!.providerUUID
                }
                
                let jsonStr = LogService.jsonStringfy(json: status)
                if jsonStr != nil {
                    LogService.sharedService.log(event: .STATUS, data: "json=" + jsonStr!)
                    LogService.sharedService.putLog(token: manageToken)
                }
                
                let deviceStatus = DeviceStatus()
                deviceStatus.wifiScans = self.getNetworksFromJson(data: status["wifi_scans"])
                self.model?.networks = deviceStatus.wifiScans
                deviceStatus.knownNetworks = self.getKnownNetworksFromJson(data: status["known_networks"])
                if status["bound"].stringValue == "BOUND" {
                    deviceStatus.bound = true
                }
                else {
                    deviceStatus.bound = false
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                deviceStatus.timeStamp = dateFormatter.date(from: status["timestamp"].stringValue)
                
                completion(.SUCCESS, deviceStatus)
            })
        })
    }

    private func getKnownNetworksFromJson(data:JSON) -> [KnownNetwork] {
        let dataArray:[AnyObject] = data.arrayObject! as [AnyObject]
        var networks = [KnownNetwork]()
        
        for net in dataArray {
            let netData:JSON = JSON(net)
            let network:KnownNetwork = KnownNetwork()
            
            network.ssid = netData["ssid"].stringValue
            network.priority = netData["priority"].intValue
            network.credentialID = netData["credential_id"].stringValue
            network.roamingID = netData["roaming_id"].stringValue
            network.bssid = netData["bssid"].stringValue
            network.status = netData["status"].stringValue
            network.security = netData["security"].stringValue
            network.source = netData["source"].stringValue
            
            networks.append(network)
        }
        
        return networks
    }
    
    private func getNetworksFromJson(data:JSON) -> [Network] {
        let dataArray:[AnyObject] = data.arrayObject! as [AnyObject]
        var networks = [Network]()
        
        for net in dataArray {
            let netData:JSON = JSON(net)
            
            let network:Network = Network()
            network.bssid = netData["bssid"] != nil ? String(describing: netData["bssid"]) : ""
            network.ssid = netData["ssid"] != nil ? String(describing: netData["ssid"]) : ""
            network.frequency = netData["frequency"] != nil ? UInt(netData["frequency"].intValue) : 0
            network.flags = netData["flags"] != nil ? String(describing: netData["flags"]) : ""
            network.signalLevel = netData["signal_level"] != nil ? netData["signal_level"].intValue : 0
            network.anqp_roaming_consortium = netData["anqp_roaming_consortium"] != nil ? String(describing: netData["anqp_roaming_consortium"]) : ""
            network.capabilities = netData["capabilities"] != nil ? UInt(netData["capabilities"].intValue) : 0
            network.quality = netData["quality"] != nil ? UInt(netData["quality"].intValue) : 0
            network.noise_level = netData["noise_level"] != nil ? netData["noise_level"].intValue : 0
            network.information_element = netData["information_element"] != nil ? String(describing: netData["information_element"]) : ""
            
            networks.append(network)
        }
        
        return networks
    }
    
    /// If the app is on a private network for which the broadband provider has credentials, you can let the user choose to
    /// have the provider deliver the credentials to the Cirrent cloud, instead of having the user enter the private network
    /// credentials manually. The putProviderCredentials method instructs Cirrent to get the private network credentials
    /// from the broadband provider, so that they can be retrieved by the device.
    ///
    /// - Parameters:
    ///   - tokenMethod: method that will generate a token authorizing this function
    ///   - deviceID: id of device that the credentials are for
    ///   - providerUDID: UDID of a provider who has the credentials
    ///   - completion: completion handler
    
    @objc public func putProviderCredentials(tokenMethod:TokenHandler, deviceID:String, providerUDID: String, completion:@escaping CredentialCompletionHadler) {
        
        if ownerID == nil {
            LogService.sharedService.debug(data: "Put Provider Network Failed: providerUDID=\(providerUDID),Error=OwnerID is missed")
            completion(CREDENTIAL_RESPONSE.FAILED_NO_RESPONSE, nil)
            return
        }
        
        tokenMethod(.MANAGE, deviceID, {
            manageToken in
            
            if manageToken == nil {
                LogService.sharedService.log(event: .TOKEN_ERROR, data: "Error=INVALID_TOKEN")
                completion(CREDENTIAL_RESPONSE.FAILED_INVALID_TOKEN, nil)
                return
            }
            
            APIService.sharedService.putProviderCredentials(manageToken: manageToken!, appID: self.ownerID!, deviceID: deviceID, providerID: providerUDID, completion: {
                data, response, error in
                guard let _ = data, error == nil else {
                    LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Put Provider Network Failed")
                    completion(CREDENTIAL_RESPONSE.FAILED_NO_RESPONSE, nil)
                    return
                }
                
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                    if httpStatus.statusCode == 401 {
                        LogService.sharedService.log(event: .TOKEN_ERROR, data: "Put Provider Network Failed: providerUDID=\(providerUDID),Error=ManageToken is nil")
                        completion(CREDENTIAL_RESPONSE.FAILED_INVALID_TOKEN, nil)
                        return
                    }
                    else {
                        LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Put Provider Network Failed: providerUDID=\(providerUDID),Error=INVALID_STATUS:\(httpStatus.statusCode)")
                        completion(CREDENTIAL_RESPONSE.FAILED_INVALID_STATUS, nil)
                        return
                    }
                }
                
                let responseString = String(data: data!, encoding: .utf8)!
                let credentials:[String] = self.getCredentialsFromString(str: responseString)
                let providerSSID:String = (self.model?.selectedProvider?.getSSID())!
                let providerName:String = (self.model?.selectedProvider?.getProviderName())!
                self.model?.credentialId = credentials[0]
                self.model?.selectedNetwork = Network()
                self.model?.selectedNetwork?.ssid = providerSSID
                self.model?.providerName = providerName
                let logString = "ssid=\(providerSSID);provider=\(providerName);"
                LogService.sharedService.log(event: .PROVIDER_CREDS, data: logString)
                LogService.sharedService.putLog(token: manageToken)
                
                completion(CREDENTIAL_RESPONSE.SUCCESS, credentials)
            })
        })
    }
    
    @objc public func selectDevice(deviceID:String) -> Bool {
        if model == nil {
            LogService.sharedService.debug(data: "Select Device Failed: id=\(deviceID),Error=Model has not been initialized yet.")
            return false
        }
        
        if model!.devices.count == 0 {
            LogService.sharedService.debug(data: "Select Device Failed: id=\(deviceID),Error=There isn't any found devices.")
            return false
        }
        
        for device in model!.devices {
            if device.deviceId == deviceID {
                model!.selectedDevice = device
                LogService.sharedService.log(event: .DEVICE_SELECTED, data: "id=\(deviceID)")
                return true
            }
        }
        
        return true
    }
    
    /// This method binds the device, so it is considered 'claimed' by this user, and will no longer be discoverable by
    /// other users looking for nearby devices.  Cirrent keeps track of whether a device is discoverable or not, but does 
    /// not keep track of which user has bound the device. That is managed in the product cloud.
    ///
    /// - Parameters:
    ///   - tokenMethod: method that will generate a token authorizing this function
    ///   - deviceID: ID of the device that will be bound (no longer discoverable)
    ///   - completion: completion handler
    
    @objc public func bindDevice(tokenMethod:TokenHandler, deviceID:String, friendlyName:String?, completion: @escaping CompletionHandler) {
        if model == nil {
            LogService.sharedService.debug(data: "Bind Device Failed: Error=Model is nil")
            completion(.FAILED_NO_RESPONSE)
            return
        }
        
        tokenMethod(.BIND, deviceID, {
            bindToken in
            
            if bindToken == nil {
                LogService.sharedService.log(event: .TOKEN_ERROR, data: "Bind Device Failed: Error=BindToken is nil")
                completion(.FAILED_INVALID_TOKEN)
                return
            }
            
            APIService.sharedService.bindDevice(bindToken: bindToken!, completion: {
                data, response, error in
                
                guard let _ = data, error == nil else {
                    self.model?.selectedDevice = nil
                    LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Bind Device Failed - no response")
                    completion(.FAILED_NO_RESPONSE)
                    return
                }
                
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                    self.model?.selectedDevice = nil
                    if httpStatus.statusCode == 401 {
                        LogService.sharedService.log(event: .TOKEN_ERROR, data: "Bind Device Failed: Error=INVALID_TOKEN")
                        completion(.FAILED_INVALID_TOKEN)
                    }
                    else {
                        LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Bind Device Failed: Error=INVALID_STATUS:\(httpStatus.statusCode)")
                        completion(.FAILED_INVALID_STATUS)
                    }
                    return
                }
                
                LogService.sharedService.log(event: .DEVICE_BOUND, data: "id=" + self.model!.selectedDevice!.deviceId)
                completion(.SUCCESS)
            })
        })
    }
    
    /// This method resets the device state in the Cirrent cloud, so it is no longer considered 'claimed' by this user, and
    /// will be discoverable by other users looking for nearby devices.  The Cirrent cloud will also discard any status it
    /// has for this device (known networks, wi-fi scans etc.).
    ///
    /// - Parameters:
    ///   - tokenMethod: method that will generate a token authorizing this function
    ///   - deviceID: id of the device being unbound
    ///   - completion: completion handler
    
    @objc public func resetDevice(tokenMethod:(_ tokenType:TOKEN_TYPE, _ deviceID:String?, _ completion: @escaping (_ token:String?) -> Void) -> Void, deviceID:String, completion: @escaping CompletionHandler) {
        tokenMethod(.MANAGE, deviceID, {
            manageToken in
            
            if manageToken == nil {
                LogService.sharedService.log(event: .TOKEN_ERROR, data: "Reset Device Failed: id=\(deviceID),Error=ManageToken is nil")
                completion(.FAILED_INVALID_TOKEN)
            }
            
            APIService.sharedService.resetDevice(manageToken: manageToken!, deviceID: deviceID, completion: {
                data, response, error in
                guard let _ = data, error == nil else {
                    LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Reset Device Failed - no response")
                    completion(.FAILED_NO_RESPONSE)
                    return
                }
                
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                    if httpStatus.statusCode == 401 {
                        LogService.sharedService.log(event: .TOKEN_ERROR, data: "Reset Device Failed: id=\(deviceID),Error=INVALID_TOKEN")
                        completion(.FAILED_INVALID_TOKEN)
                    }
                    else {
                        LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Reset Device Failed: id=\(deviceID),Error=INVALID_STATUS:\(httpStatus.statusCode)")
                        completion(.FAILED_INVALID_STATUS)
                    }
                    return
                }
                
                LogService.sharedService.debug(data: "Reset Device Success: id=\(deviceID)")
                completion(.SUCCESS)
            })
        })
    }
    
    private func getCredentialsFromString(str: String) -> [String] {
        var credString:String = str
        credString.remove(at: credString.startIndex)
        credString.remove(at: credString.index(before: credString.endIndex))
        
        credString = credString.trimmingCharacters(in: .whitespaces)
        
        let creds = credString.characters.split{
            $0 == ","
            }.map(String.init)
        
        var credentials:[String] = [String]()
        for cred in creds {
            var newCred:String = String(cred)
            newCred.remove(at: newCred.startIndex)
            newCred.remove(at: newCred.index(before: newCred.endIndex))
            credentials.append(newCred)
        }
        
        return credentials
    }
    
    /// Send private network credentials to the device (via the Cirrent cloud or over SoftAP). The network credentials
    /// are retrieved from the selectedNetwork in the model.
    ///
    /// - Parameters:
    ///   - tokenMethod: method that will generate a token authorizing this function
    ///   - deviceID: id of device to receive the credentials
    ///   - addToVault: whether the credential should be stored in the credential vault to be used by future devices of the same type
    ///   - completion: completion handler
    
    @objc public func putPrivateCredentials(tokenMethod:@escaping TokenHandler, deviceID:String, bAddToVault:Bool = true, completion: @escaping CredentialCompletionHadler) {
        tokenMethod(.MANAGE, deviceID, {
            manageToken in
            
            if (self.model?.GCN)! {
                self.model?.credentialId = nil
                if manageToken == nil {
                    LogService.sharedService.debug(data: "Device Join Network Failed - INVALID_TOKEN")
                    completion(.FAILED_INVALID_TOKEN, nil)
                    return
                }
                
                APIService.sharedService.deviceJoinNetwork(manageToken:manageToken!, deviceID: deviceID, network: (self.model?.selectedNetwork!)!, password: (self.model?.selectedNetworkPassword)!, completion: {
                    data, response, error in
                    guard let _ = data, error == nil else {
                        LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Put private credentials Failed")
                        completion(.FAILED_NO_RESPONSE, nil)
                        return
                    }
                    
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                        if httpStatus.statusCode == 401 {
                            LogService.sharedService.log(event: .TOKEN_ERROR, data: "Put private credentials failed, Error=INVALID_TOKEN")
                            completion(.FAILED_INVALID_TOKEN, nil)
                        } else {
                            LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Device Join Network Failed - INVALID_STATUS")
                            completion(.FAILED_INVALID_STATUS, nil)
                            return
                        }
                    }
                    
                    let responseString = String(data: data!, encoding: .utf8)!
                    var credentials:[String] = self.getCredentialsFromString(str: responseString)
                    self.model?.credentialId = credentials[0]
                    let ssid:String = (self.model?.selectedNetwork?.ssid)!
                    let passLen:Int = (self.model?.selectedNetworkPassword!.characters.count)!
                    let logStr = "ssid=\(ssid);psk_len=\(passLen);source=\(ssid)"
                    LogService.sharedService.log(event: .USER_CREDS, data: logStr)
                    LogService.sharedService.putLog(token: manageToken)
                    
                    completion(.SUCCESS, credentials)
                })
            }
            else {
                if self.bSupportSoftAP == false {
                    LogService.sharedService.debug(data: "Send Credential Failed on SoftAP - This device does not support SoftAP")
                    completion(.FAILED_NO_RESPONSE, nil)
                    return
                }
                
                guard let ssid = self.getCurrentSSID() else {
                    LogService.sharedService.debug(data: "Send Credential Failed on SoftAP - SSID = Nil")
                    completion(CREDENTIAL_RESPONSE.FAILED_NO_RESPONSE, nil)
                    return
                }
                
                if ssid.contains(self.SoftAPSSID) != true {
                    LogService.sharedService.debug(data: "Send Credential Failed on SoftAP - NOT_SoftAP_NETWORK")
                    self.model?.GCN = true
                    //self.putPrivateCredentials(tokenMethod: tokenMethod, deviceID: deviceID, completion: completion)
                    completion(CREDENTIAL_RESPONSE.NOT_SoftAP, nil)
                    return
                }
                
                let enteredPassword = self.model?.selectedNetworkPassword
                var password = self.model?.selectedNetworkPassword
                
                if self.model?.selectedNetwork?.flags != "OPEN" && self.model?.selectedNetwork?.flags != "[ESS]" {
                    if self.model?.scdKey != nil {
                        let encryptedData = RSAUtil.encryptString(enteredPassword!, withKey: self.model?.scdKey!)
                        if encryptedData != nil {
                            password = encryptedData!.base64EncodedString()
                        }
                    }
                }
                
                APIService.sharedService.putSoftAPJoinNetwork(SoftAPIp: (self.model?.SoftAPIp!)!, network: (self.model?.selectedNetwork!)!, password: (self.model?.selectedNetworkPassword!)!, encryptedPassword: password!, completion: {
                    data, response, error in
                    guard let _ = data, error == nil else {
                        LogService.sharedService.log(event: .SoftAP_DROP, data: "No response from device over SoftAP")
                        self.model?.GCN = true
                        //self.putPrivateCredentials(tokenMethod: tokenMethod, deviceID: deviceID, completion: completion)
                        completion(.FAILED_NO_RESPONSE, nil)
                        return
                    }
                    
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                        LogService.sharedService.log(event: .SoftAP_ERROR, data: "Put SoftAP Join Network Failed - INVALID_STATUS:\(httpStatus.statusCode)")
                        completion(.FAILED_INVALID_STATUS, nil)
                        return
                    }
                    
                    let credential = String(data: data!, encoding: .utf8)!
                    
                    self.model?.credentialId = credential
                    let ssid:String = (self.model?.selectedNetwork?.ssid)!
                    let passLen:Int = (self.model?.selectedNetworkPassword!.characters.count)!
                    let logStr = "ssid=\(ssid);psk_len=\(passLen);source=\(ssid)"
                    LogService.sharedService.log(event: .USER_CREDS, data: logStr)
                    LogService.sharedService.putLog(token: manageToken)
                    
                    // Put the credential in an array for consistency with credentials id from the cloud (which are an array)
                    var credentials:[String] = [String]()
                    let newCred:String = String(credential)
                    credentials.append(newCred)

                    completion(.SUCCESS, credentials)
                })
            }
        })
    }
    
    private var joiningTimer:Timer!
    
    private func stopGetDeviceJoiningStatus() {
        if joiningTimer != nil {
            joiningTimer.invalidate()
        }
        if checkTimer != nil {
            checkTimer.invalidate()
        }
    }
    
    /// The getDeviceJoiningStatus method is used to get status updates from the device, via the Cirrent cloud, or 
    /// over SoftAP, while the device is moving from the ZipKey network to the private network.  
    /// The getDeviceJoiningStatus method may call the
    /// callback handler more than once, to give updated statuses as the device goes through the onboarding process.
    ///
    /// - Parameters:
    ///   - tokenMethod: method that will generate a token authorizing this function
    ///   - deviceID: id of device whose status we are checking
    ///   - handler: joining handler
    
    @objc public func getDeviceJoiningStatus(tokenMethod:@escaping TokenHandler, deviceID:String, handler: @escaping JoiningHandler) {
        if self.model?.GCN == true {
            tokenMethod(.MANAGE, deviceID, {
                manageToken in
                var index = 1
                let waitTime = 12
                self.joiningTimer = Timer.scheduledTimer(withTimeInterval: Constants.JOINING_TIME_INTERVAL, repeats: true, block: {
                    t in
                    if self.model?.GCN == true {    // checking status in the cloud
                        
                        if self.model?.selectedDevice == nil {
                            LogService.sharedService.debug(data: "JOINING - Selected Device is Nil")
                            handler(JOINING_STATUS.SELECTED_DEVICE_NIL)
                            self.joiningTimer.invalidate()
                            return
                        }
                        
                        if manageToken == nil {
                            LogService.sharedService.debug(data: "JOINING - Get Device Status Failed - INVALID_TOKEN")
                            handler(JOINING_STATUS.FAILED_INVALID_TOKEN)
                            self.joiningTimer.invalidate()
                            return
                        }
                        
                        self.getDeviceJoiningStatusfromCloud(manageToken:manageToken!, handler: {
                            response in
                            
                            index += 1
                            if index > waitTime {
                                self.joiningTimer.invalidate()
                                LogService.sharedService.debug(data: "JOINING - Failed - TIMED_OUT")
                                handler(JOINING_STATUS.TIMED_OUT)
                                return
                            }
                            
                            handler(response)
                            if (response != JOINING_STATUS.RECEIVED_CREDS && response != JOINING_STATUS.ATTEMPTING_TO_JOIN) {
                                self.joiningTimer.invalidate()
                            }
                            
                            return
                        })
                    }
                })
            })
        }
        else {
            var index = 1
            let waitTime = 12
            self.joiningTimer = Timer.scheduledTimer(withTimeInterval: Constants.JOINING_TIME_INTERVAL, repeats: true, block: {
                t in
                // checking status over SoftAP
                
                if self.bSupportSoftAP == false {
                    let logStr = "ssid=\(self.getCurrentSSID()!),credentialId=\(String(describing: self.model?.credentialId!)),provider_network=false,reason=This device does not support SoftAP"
                    LogService.sharedService.log(event: .JOINED_FAILED, data: logStr)
                    handler(JOINING_STATUS.FAILED_NO_RESPONSE)
                    self.joiningTimer.invalidate()
                    return
                }
                
                let ssid:String? = self.getCurrentSSID()
                if ssid != nil && ssid!.contains(self.SoftAPSSID) != true {
                    // May have fallen off SoftAP network - check in with cloud
                    LogService.sharedService.debug(data: "JOINING SoftAP - no longer on the SoftAP network")
                    
                    // Check in with the cloud
                    self.model?.GCN=true
                    self.bindDevice(tokenMethod: tokenMethod, deviceID: deviceID, friendlyName:"", completion:  {_ in
                        print("BOUND DEVICE ", deviceID)
                    })
                    self.checkStatusWithCloud(tokenMethod: tokenMethod, deviceID: deviceID, handler: handler)
                    self.joiningTimer.invalidate()
                    return
                }
                
                self.getDeviceJoiningStatusfromSoftAP( handler: {
                    response in
                    
                    index += 1
                    
                    if (response == JOINING_STATUS.FAILED_NO_RESPONSE) {
                        self.joiningTimer.invalidate()
                        LogService.sharedService.debug(data: "No response from SoftAP, try the cloud")
                        self.model?.GCN=true
                        self.bindDevice(tokenMethod: tokenMethod, deviceID: deviceID, friendlyName:"", completion:  {_ in
                            print("BOUND DEVICE ", deviceID)
                        })
                        self.checkStatusWithCloud(tokenMethod: tokenMethod, deviceID: deviceID, handler: handler)
                        return
                    }
                    
                    if response == JOINING_STATUS.FAILED || response == JOINING_STATUS.FAILED_INVALID_STATUS || response == JOINING_STATUS.GET_DEVICE_STATUS_FAILED {
                        self.joiningTimer.invalidate()
                        LogService.sharedService.debug(data: "SoftAP Joining Failed")
                        self.model?.GCN = true
                        self.checkStatusWithCloud(tokenMethod: tokenMethod, deviceID: deviceID, handler: handler)
                        return
                    }
                    
                    if index > waitTime {
                        self.joiningTimer.invalidate()
                        LogService.sharedService.debug(data: "outer - JOINING SoftAP - Failed - TIMED_OUT")
                        self.model?.GCN=true
                        self.checkStatusWithCloud(tokenMethod: tokenMethod, deviceID: deviceID, handler: handler)
                        return
                    }
                    
                    handler(response)
                    if (response != JOINING_STATUS.RECEIVED_CREDS && response != JOINING_STATUS.ATTEMPTING_TO_JOIN) {
                        self.joiningTimer.invalidate()
                        return
                    }
                })
            })
        }
    }
    
    var checkTimer:Timer!
    private func checkStatusWithCloud(tokenMethod:TokenHandler, deviceID:String, handler: @escaping JoiningHandler) {
        self.model?.GCN = true
        tokenMethod(.MANAGE, deviceID, {
            manageToken in
            
            print("into another token callback")
            var index = 1
            let waitTime = 12
            DispatchQueue.main.async {
                self.checkTimer = Timer.scheduledTimer(withTimeInterval: Constants.JOINING_TIME_INTERVAL, repeats: true, block: {
                    t in
                    
                    print("Here is another timer for checking status with cloud.")
                    if self.model?.selectedDevice == nil {
                        LogService.sharedService.debug(data: "JOINING - Selected Device is Nil")
                        handler(JOINING_STATUS.SELECTED_DEVICE_NIL)
                        self.checkTimer.invalidate()
                        return
                    }
                    
                    if manageToken == nil {
                        LogService.sharedService.debug(data: "JOINING - Get Device Status Failed - INVALID_TOKEN")
                        handler(JOINING_STATUS.FAILED_INVALID_TOKEN)
                        self.checkTimer.invalidate()
                        return
                    }
                    
                    self.getDeviceJoiningStatusfromCloud(manageToken:manageToken!, handler: {
                        response in
                        
                        index += 1
                        if index > waitTime {
                            self.checkTimer.invalidate()
                            LogService.sharedService.debug(data: "JOINING - Failed - TIMED_OUT")
                            handler(JOINING_STATUS.TIMED_OUT)
                            return
                        }
                        
                        handler(response)
                        if (response != JOINING_STATUS.RECEIVED_CREDS && response != JOINING_STATUS.ATTEMPTING_TO_JOIN) {
                            self.checkTimer.invalidate()
                        }
                        
                        return
                    })
                })
            }
        })
    }
    
    private func getDeviceJoiningStatusfromSoftAP(handler:@escaping JoiningHandler) {
        
        APIService.sharedService.getSoftAPDeviceStatus(SoftAPIp: (self.model?.SoftAPIp!)!, completion: {
            data, response, error in
            guard let _ = data, error == nil else {
                LogService.sharedService.debug(data: "JOINING SoftAP - Failed - NO_RESPONSE")
                handler(JOINING_STATUS.FAILED_NO_RESPONSE)
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                LogService.sharedService.debug(data: "JOINING SoftAP - Failed - INVALID_STATUS")
                handler(JOINING_STATUS.FAILED_INVALID_STATUS)
                return
            }
                    
            let status:JSON = JSON(data: data!)
            if status == nil {
                LogService.sharedService.debug(data: "JOINING SoftAP - Failed - GET_DEVICE_STATUS_FAILED")
                handler(JOINING_STATUS.GET_DEVICE_STATUS_FAILED)
            }
                    
            if status["known_networks"] != nil && status["known_networks"].count > 0 {
                let dataArray:[AnyObject] = status["known_networks"].arrayObject! as [AnyObject]
                        
                for net in dataArray {
                    let network:JSON = JSON(net)
                    if String(describing: network["ssid"]) == (self.model?.selectedNetwork?.ssid)! && String(describing: network["status"]) == "JOINED" {
                        LogService.sharedService.log(event: .SoftAP_JOINED, data: "")
                        handler(JOINING_STATUS.JOINED)
                        return
                    }
                    else if String(describing: network["ssid"]) == (self.model?.selectedNetwork?.ssid)! && String(describing: network["status"]) == "FAILED" {
                        LogService.sharedService.log(event: .SoftAP_ERROR, data: "JOINING SoftAP - Failed")
                        handler(JOINING_STATUS.FAILED)
                        return
                    }
                    else if String(describing: network["ssid"]) == (self.model?.selectedNetwork?.ssid)! && String(describing: network["status"]) == "RECEIVED" {
                        LogService.sharedService.debug(data: "JOINING SoftAP - RECEIVED_CREDS")
                        handler(JOINING_STATUS.RECEIVED_CREDS)
                    }
                    else if String(describing: network["ssid"]) == (self.model?.selectedNetwork?.ssid)! && String(describing: network["status"]) == "JOINING" {
                        LogService.sharedService.debug(data: "JOINING SoftAP - Attempting To Join")
                        handler(JOINING_STATUS.ATTEMPTING_TO_JOIN)
                    }
                    else if String(describing: network["ssid"]) == (self.model?.selectedNetwork?.ssid)! && String(describing: network["status"]) == "DISCONNECTED" {
                        LogService.sharedService.debug(data: "JOINING SoftAP - Disconnected")
                        handler(JOINING_STATUS.FAILED)
                    }
                }
            }
        })
    }

    private func getDeviceJoiningStatusfromCloud(manageToken:String!, handler:@escaping JoiningHandler) {
        
        APIService.sharedService.getDeviceStatus(manageToken:manageToken, deviceID: (self.model?.selectedDevice!.deviceId)!, completion: {
            data, response, error in
            guard let _ = data, error == nil else {
                LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Status - no response")
                LogService.sharedService.putLog(token: manageToken)
                handler(JOINING_STATUS.FAILED_NO_RESPONSE)
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                if httpStatus.statusCode == 401 {
                    LogService.sharedService.log(event: .TOKEN_ERROR, data: "Error=INVALID_TOKEN")
                    LogService.sharedService.putLog(token: manageToken)
                    handler(JOINING_STATUS.FAILED_INVALID_TOKEN)
                }
                else {
                    LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Error=" + LogService.getResponseErrorString(response: .FAILED_INVALID_STATUS))
                    LogService.sharedService.putLog(token: manageToken)
                    handler(JOINING_STATUS.FAILED_INVALID_STATUS)
                }
                
                return
            }
            
            let respStr = String(data: data!, encoding: .utf8)
            print("Status Response String - \(respStr!)")
            
            let statusJSON:JSON = JSON(data: data!)
            if statusJSON == nil {
                LogService.sharedService.log(event: .STATUS_ERROR, data: "JOINING - Failed - GET DEVICE STATUS FAILED")
                handler(JOINING_STATUS.GET_DEVICE_STATUS_FAILED)
                return
            }
            
            let status = DeviceStatus()
            status.knownNetworks = self.getKnownNetworksFromJson(data: statusJSON["known_networks"])
            
            if status.knownNetworks.count > 0 {
                for network in status.knownNetworks {
                    print("Network SSID - \(network.ssid)")
                    print("Checking Credential - \(network.credentialID)")
                    if network.ssid == (self.model?.selectedNetwork!.ssid)! && network.status == "JOINED" && network.credentialID == (self.model?.credentialId!)! {
                        var logStr = "Type="
                        if self.model?.selectedProvider != nil {
                            logStr += "PROVIDER"
                        }
                        else {
                            logStr += "USER-CREDS"
                        }
                        LogService.sharedService.log(event: .SUCCESS, data: logStr)
                        LogService.sharedService.putLog(token: manageToken)
                        
                        handler(JOINING_STATUS.JOINED)
                        return
                    }
                    else if network.ssid == (self.model?.selectedNetwork!.ssid)! && network.status == "RECEIVED" && network.credentialID == (self.model?.credentialId!)! {
                        LogService.sharedService.debug(data: "RECEIVED_CREDS")
                        handler( JOINING_STATUS.RECEIVED_CREDS)
                        return
                    }
                    else if network.ssid == (self.model?.selectedNetwork!.ssid)! && network.status == "JOINING" && network.credentialID == (self.model?.credentialId!)! {
                        LogService.sharedService.debug(data: "JOINING - Attempting To Join")
                        handler(JOINING_STATUS.ATTEMPTING_TO_JOIN)
                        return
                    }
                    else if network.ssid == (self.model?.selectedNetwork!.ssid)! && network.status == "DISCONNECTED" && network.credentialID == (self.model?.credentialId!)! {
                        var logStr:String = "ssid=\((self.model?.selectedNetwork!.ssid)!);credentialID=\((self.model?.credentialId!)!);"
                        if self.model?.selectedProvider == nil {
                            logStr += "provider_network=false"
                        }
                        else {
                            logStr += "provider_network=true"
                        }
                                    
                        LogService.sharedService.log(event: .JOINED_FAILED, data: logStr)
                        handler( JOINING_STATUS.FAILED)
                        return
                    }
                    else if network.ssid == (self.model?.selectedNetwork!.ssid)! && network.status == "FAILED" && network.credentialID == (self.model?.credentialId!)! {
                        var logStr:String = "ssid=\((self.model?.selectedNetwork!.ssid)!);credentialID=\((self.model?.credentialId!)!);"
                        if self.model?.selectedProvider == nil {
                            logStr += "provider_network=false"
                        }
                        else {
                            logStr += "provider_network=true"
                        }
                        
                        LogService.sharedService.log(event: .JOINED_FAILED, data: logStr)
                        handler( JOINING_STATUS.FAILED)
                        return
                    }

                }
            }
            
            LogService.sharedService.debug(data: "There are no networks")
            handler(JOINING_STATUS.FAILED)
            return
        })
    }

    /// Cancel any timers that are currently running in the Cirrent SDK
    @objc public func stopAllAction() {
        if findDeviceTimer != nil {
            findDeviceTimer?.invalidate()
        }
        if joiningTimer != nil {
            joiningTimer.invalidate()
        }
        if userActionTimer != nil {
            userActionTimer.invalidate()
        }
        if checkTimer != nil {
            checkTimer.invalidate()
        }
        
        findDeviceTimer = nil
        joiningTimer = nil
        userActionTimer = nil
        checkTimer = nil
    }
    
    private var SoftAPTimer:Timer!
    private var maxSoftAPRetryCount = 3
    
    /// Wait to confirm that the app has joined the SoftAP network so that onboarding can now proceed over 
    /// the SoftAP network.This method waits for the phone to join the softAP network. It then queries the device 
    /// over the SoftAP network for its status.  Once the status has been received, the mobile app can call
    /// putPrivateCredentials, and then getDeviceJoiningStatus, just as if it were communicating via the Cirrent cloud.
    /// - Parameter handler: completion handler
    @objc public func processSoftAP(handler: @escaping SoftAPHandler) {
        
        if bSupportSoftAP == false {
            LogService.sharedService.debug(data: "SoftAP Process Failed: Error=This device not support SoftAP")
            handler(.FAILED_SoftAP_NOT_SUPPORTED)
            return
        }
        
        initModel()
        if model != nil && model?.ssid != nil && model?.ssid!.contains(SoftAPSSID) == true {
            
            LogService.sharedService.log(event: .SoftAP, data: "Scan=" + (model?.ssid!)!)
            
            let ipAddress = getWiFiAddress()
            if ipAddress == nil {
                LogService.sharedService.debug(data: "SoftAP Process Failed: Error=SoftAP IP address is Nil")
                handler(.FAILED_NOT_GET_SoftAP_IP)
                return
            }
            
            model?.setSoftAPIp(ip: ipAddress!)
            LogService.sharedService.debug(data: "SoftAP Ip address - \((model?.SoftAPIp!)!)")
            SoftAPTimer = Timer.scheduledTimer(withTimeInterval: Constants.SoftAP_TIME_INTERVAL, repeats: true, block: {
                
                t in
                
                let ssid = self.getCurrentSSID()
                if ssid == nil || ssid!.contains(self.SoftAPSSID) == false {
                    LogService.sharedService.log(event: .SoftAP_DROP, data: "")
                    handler(.FAILED_NOT_SoftAP_SSID)
                    return
                }
                
                APIService.sharedService.getSoftAPDeviceInfo(SoftAPIp: (self.model?.SoftAPIp!)!, completion: {
                    data, response, error in
                    guard let _ = data, error == nil else {
                        self.maxSoftAPRetryCount -= 1
                        if self.maxSoftAPRetryCount <= 0 {
                            self.SoftAPTimer.invalidate()
                            self.maxSoftAPRetryCount = 3
                            LogService.sharedService.debug(data: "SoftAP Process Failed: Error=GET_SoftAP_DEVICE_INFO_NO_RESPONSE")
                            handler(.FAILED_SoftAP_NO_RESPONSE)
                        }
                        return
                    }
                    
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                        self.maxSoftAPRetryCount -= 1
                        if self.maxSoftAPRetryCount <= 0 {
                            self.SoftAPTimer.invalidate()
                            self.maxSoftAPRetryCount = 3
                            LogService.sharedService.debug(data: "SoftAP Process Failed: Error=GET_SoftAP_DEVICE_INFO_INVALID_STATUS")
                            handler(.FAILED_SoftAP_INVALID_STATUS)
                        }
                        return
                    }
                    
                    let deviceInfo = JSON(data: data!)
                    if deviceInfo != nil && deviceInfo["scd_public_key"] != nil {
                        self.model?.scdKey = deviceInfo["scd_public_key"].stringValue
                    }
                    
                    let device = Device()
                    device.macAddress = deviceInfo["device_id"].stringValue
                    device.deviceId = deviceInfo["device_id"].stringValue
                    
                    self.model?.devices = []
                    self.model?.devices.append(device)
                    
                    let selectedDevice = self.model?.getFirstDevice()
                    if selectedDevice != nil {
                        self.model?.selectedDevice = selectedDevice!
                    }
                    
                    APIService.sharedService.getSoftAPDeviceStatus(SoftAPIp: (self.model?.SoftAPIp!)!, completion: {
                        data, response, error in
                        guard let _ = data, error == nil else {
                            self.maxSoftAPRetryCount -= 1
                            if self.maxSoftAPRetryCount <= 0 {
                                self.SoftAPTimer.invalidate()
                                self.maxSoftAPRetryCount = 3
                                LogService.sharedService.debug(data: "SoftAP Process Failed: Error=GET_SoftAP_DEVICE_STATUS_NO_RESPONSE")
                                handler(.FAILED_SoftAP_NO_RESPONSE)
                            }
                            return
                        }
                        
                        if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                            self.maxSoftAPRetryCount -= 1
                            if self.maxSoftAPRetryCount <= 0 {
                                self.SoftAPTimer.invalidate()
                                self.maxSoftAPRetryCount = 3
                                LogService.sharedService.debug(data: "SoftAP Process Failed: Error=GET_SoftAP_DEVICE_STATUS_INVALID_STATUS")
                                handler(.FAILED_SoftAP_INVALID_STATUS)
                            }
                            return
                        }
                        
                        let status = JSON(data: data!)
                        self.successSoftAP(deviceInfo: deviceInfo, wifiScans: status["wifi_scans"], handler: handler)
                        return
                    })
                })
            })
        }
        else {
            LogService.sharedService.log(event: .SoftAP_DROP, data: "")
            handler(.FAILED_NOT_SoftAP_SSID)
            return
        }
    }
    
    
    private func successSoftAP(deviceInfo:JSON, wifiScans:JSON, handler: @escaping SoftAPHandler) {
        self.model?.GCN = false
        self.model?.setSoftAPNetworks(data: wifiScans)
        
        let device = Device()
        device.macAddress = deviceInfo["device_id"].stringValue
        device.deviceId = deviceInfo["device_id"].stringValue
        
        self.model?.devices = []
        self.model?.devices.append(device)
        
        let selectedDevice = self.model?.getFirstDevice()
        self.model?.selectedDevice = selectedDevice
        
        self.SoftAPTimer.invalidate()
        self.maxSoftAPRetryCount = 3
        handler(.SUCCESS_WITH_SoftAP)
    }
    
// Private Methods
    private func initModel() {
        model = Model()
        model?.ssid = getCurrentSSID()
        model?.bssid = getCurrentBSSID()
    }

    private var environmentTimer:Timer!
    private var uploadingEnvironmentNow:Bool = false
    private func uploadEnvironment(searchToken:String, completion: @escaping CompletionHandler) {
        if ownerID == nil {
            LogService.sharedService.debug(data: "Upload Enviroment Failed: Error=OwnerID is missed")
            completion(.FAILED_NO_RESPONSE)
            return
        }
        
        initModel()
        APIService.sharedService.getCurrentLocation(completion: {
            bSuccess in
            
            if bSuccess != true {
                LogService.sharedService.log(event: .LOCATION_ERROR, data: "INACCURATE LOCATION")
                completion(.FAILED_NO_RESPONSE)
            }
            else {
                APIService.sharedService.uploadEnvironment(searchToken: searchToken, appID: self.ownerID!, model: self.model!, callback: {
                    response in
                    
                    if response == .FAILED_NO_RESPONSE {
                        LogService.sharedService.log(event: .CLOUD_CONNECTION_ERROR, data: "Upload Environment Failed")
                        completion(.FAILED_NO_RESPONSE)
                    }
                    else if response == .FAILED_INVALID_STATUS {
                        LogService.sharedService.debug(data: "Upload Environment Failed: Error=INVALID_STATUS")
                        completion(.FAILED_INVALID_STATUS)
                    }
                    else if response == .FAILED_INVALID_TOKEN {
                        LogService.sharedService.debug(data: "Upload Environment Failed: Error=INVALID_TOKEN")
                        completion(.FAILED_INVALID_TOKEN)
                    }
                    else {
                        LogService.sharedService.debug(data: "Upload Environment Success")
                        completion(.SUCCESS)
                    }
                })
            }
        })
    }
    
    private func getDeviceFromJson(data:JSON) -> Device {
        let device:Device = Device()
        device.idDeviceId = data["idDeviceId"] != nil ? data["idDeviceId"].intValue : -1
        device.idDeviceType = data["idDeviceType"] != nil ? data["idDeviceType"].intValue : -1
        device.deviceId = data["deviceId"] != nil ? data["deviceId"].stringValue : ""
        device.macAddress = data["MACAddr"] != nil ? data["MACAddr"].stringValue : ""
        device.imageURL = data["imageURL"] != nil ? data["imageURL"].stringValue : ""
        device.uptime = data["uptime"] != nil ? data["uptime"].doubleValue : -1
        device.identifyingActionEnabled = data["identifying_action_enabled"] != nil ? data["identifying_action_enabled"].boolValue : false
        device.identifyingActionDescription = data["identifying_action_description"] != nil ? data["identifying_action_description"].stringValue : ""
        device.userActionEnabled = data["user_action_enabled"] != nil ? data["user_action_enabled"].boolValue : false
        device.userActionDescription = data["user_action_description"] != nil ? data["user_action_description"].stringValue : ""
        device.providerAttribution = data["provider_attibution"] != nil ? data["provider_attibution"].stringValue : ""
        device.providerAttributionLogo = data["provider_attribution_logo"] != nil ? data["provider_attribution_logo"].stringValue : ""
        device.providerAttributionLearnMoreURL = data["provider_attribution_learn_mode"] != nil ? data["provider_attribution_learn_mode"].stringValue : ""
        
        let key = device.deviceId + "_friendlyName"
        let friendlyName = UserDefaults.standard.string(forKey: key)
        if friendlyName != nil {
            device.friendlyName = friendlyName!
        }
        else {
            device.friendlyName = device.deviceId
        }
        
        if data["provider_known_network"] == nil {
            return device
        }
        
        device.provider_known_network = ProviderKnownNetwork()
        let dataArray:[AnyObject] = data["provider_known_network"].arrayObject! as [AnyObject]
        
        for netData in dataArray {
            let net:JSON = JSON(netData)
            device.provider_known_network!.ssid = net["ssid"].stringValue
            device.provider_known_network!.providerName = net["provider_name"].stringValue
            device.provider_known_network!.providerUUID = net["provider_uuid"].stringValue
            device.provider_known_network!.providerLogo = net["provider_logo"].stringValue
            break
        }
        
        return device
    }
    
    private func generateUUID() -> String {
        let pattern = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
        var secs = UInt32(Date().timeIntervalSince1970)
        
        var uuid:String = String()
        
        for char in pattern.characters {
            let r = ((secs + arc4random() * 16) % 16) | 0
            secs = UInt32(floor(Double(secs) / 16))
            if char == "x" {
                uuid += String(format: "%X", r)
            }
            else if char == "y" {
                let val = r & 0x3 | 0x8
                uuid += String(format: "%X", val)
            }
            else {
                uuid += String(char)
            }
        }
        
        return uuid
    }
    
    private var reachability:Reachability? = nil
    private var networkStatus:Int = 0
    
    //0 : Not Reachable
    //1 : Reachable via Wifi
    //2 : Reachable via Cellular
    
    private func initReachability() {
        if reachability == nil {
            reachability = Reachability()!
        }
        else {
            return
        }
        
        reachability!.whenReachable = { reachability in
            DispatchQueue.main.async {
                if self.reachability!.isReachableViaWiFi {
                    LogService.sharedService.debug(data: "Reachable via Wifi.")
                    self.networkStatus = 1
                } else {
                    LogService.sharedService.debug(data: "Reachable via Cellular.")
                    self.networkStatus = 2
                }
                LogService.sharedService.putLog(token: nil)
            }
        }
        
        reachability!.whenUnreachable = { reachability in
            DispatchQueue.main.async {
                LogService.sharedService.debug(data: "Not Reachable")
                self.networkStatus = 0
            }
        }
        
        do {
            try reachability!.startNotifier()
        } catch {
            reachability = nil
        }
    }
    
    /// check if the phone is on cellular network or not
    ///
    /// - Returns: return true if on cellular network, false otherwise
    public func isOnCellularNetwork() -> Bool {
        if networkStatus == 2 {
            LogService.sharedService.debug(data: "Phone is on Cellular Network.")
            return true
        }
        else {
            LogService.sharedService.debug(data: "Phone is not on Cellular Network.")
            return false
        }
    }
    
    /// return SSID of the network the phone is currently on
    ///
    /// - Returns: return SSID of current network
    public func getCurrentSSID(bLog:Bool = false) -> String? {
        
        initReachability()
        guard let unwrappedCFArrayInterfaces = CNCopySupportedInterfaces() else {
            LogService.sharedService.log(event: .WIFI_SCAN_ERROR, data: "Error=this must be a simulator, no interfaces found")
            return nil
        }
        guard let swiftInterfaces = (unwrappedCFArrayInterfaces as NSArray) as? [String] else {
            LogService.sharedService.log(event: .WIFI_SCAN_ERROR, data: "Error=System error: did not come back as array of Strings")
            return nil
        }
        
        for interface in swiftInterfaces {
            LogService.sharedService.debug(data: "Looking up SSID info for \(interface)") // en0
            guard let unwrappedCFDictionaryForInterface = CNCopyCurrentNetworkInfo(interface as CFString) else {
                LogService.sharedService.log(event: .WIFI_SCAN_ERROR, data: "Error=System error: \(interface) has no information")
                return nil
            }
            guard let SSIDDict = (unwrappedCFDictionaryForInterface as NSDictionary) as? [String: AnyObject] else {
                LogService.sharedService.log(event: .WIFI_SCAN_ERROR, data: "Error=System error: interface information is not a string-keyed dictionary")
                return nil
            }
            for d in SSIDDict.keys {
                LogService.sharedService.debug(data: "\(d)=\(SSIDDict[d]!)")
            }
            
            if bLog == true {
                let logStr:String = "Scan=" + (SSIDDict["SSID"] as! String)
                LogService.sharedService.log(event: .WIFI_SCAN, data: logStr)
            }
            
            return SSIDDict["SSID"] as! String?
        }
        
        return nil
    }
    
    private func getCurrentBSSID() -> String? {
        
        guard let unwrappedCFArrayInterfaces = CNCopySupportedInterfaces() else {
            LogService.sharedService.debug(data: "this must be a simulator, no interfaces found")
            return nil
        }
        guard let swiftInterfaces = (unwrappedCFArrayInterfaces as NSArray) as? [String] else {
            LogService.sharedService.debug(data: "System error: did not come back as array of Strings")
            return nil
        }
        for interface in swiftInterfaces {
            LogService.sharedService.debug(data: "Looking up BSSID info for \(interface)") // en0
            guard let unwrappedCFDictionaryForInterface = CNCopyCurrentNetworkInfo(interface as CFString) else {
                LogService.sharedService.debug(data: "System error: \(interface) has no information")
                return nil
            }
            guard let SSIDDict = (unwrappedCFDictionaryForInterface as NSDictionary) as? [String: AnyObject] else {
                LogService.sharedService.debug(data: "System error: interface information is not a string-keyed dictionary")
                return nil
            }
            for d in SSIDDict.keys {
                LogService.sharedService.debug(data: "\(d)=\(SSIDDict[d]!)")
            }
            
            return SSIDDict["BSSID"] as! String?
        }
        
        return nil
    }
    
    private func getWiFiAddress() -> String? {
        let address : String? = NetworkTool.getWifiAddress()
        if address == nil {
            LogService.sharedService.debug(data: "Get IP Address Failed")
        }
        else {
            LogService.sharedService.debug(data: "IP Address:" + address!)
        }
        
        return address
    }
    
    private func getSystemVersion() -> String {
        let systemVersion = UIDevice.current.systemVersion
        return "iOS \(systemVersion)"
    }
}

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
        case "iPhone8,4":                               return "iPhone SE"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,3", "iPad6,4", "iPad6,7", "iPad6,8":return "iPad Pro"
        case "AppleTV5,3":                              return "Apple TV"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
}
