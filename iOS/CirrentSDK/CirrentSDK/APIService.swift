//
//  APIService.swift
//  Cirrent_New
//
//  Created by PSIHPOK on 12/17/16.
//  Copyright © 2016 PSIHPOK. All rights reserved.
//

import Foundation
import CoreLocation

class APIService : NSObject, CLLocationManagerDelegate {
//API Service Base URL
    private static let apiServer = "https://app.cirrentsystems.com"
    private static let endPoint = "https://app.cirrentsystems.com/2016-01/"
    
//API Service Main URL
    private static let ENVIRONMENT_URL = endPoint + "environment"
    private static let DEVICES_URL = endPoint + "devices"
    private static let BOUND_DEVICES_URL = endPoint + "location/bounddevices"
    private static let REGISTER_DEVICE_URL = endPoint + "app/confirmdevices"
    private static let LOG_URL = endPoint + "log/"
    
//Singleton Variable
    public static let sharedService:APIService = APIService()
    private var locationManager:CLLocationManager!
    private var currentLocation:CLLocation? = nil
    
//Initialize
    override init() {
        super.init()
        self.initLocationManager()
    }
    
    private func initLocationManager() {
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    private var locationTickCount = 0
    private let locationTickLimit = 20
    private var locationTimer:Timer!
    
    func getCurrentLocation(completion: @escaping LocationCompletionHandler) {
        
        locationManager.startUpdatingLocation()
        
        locationTickCount = 0
        DispatchQueue.main.async {
            self.locationTimer = Timer.scheduledTimer(withTimeInterval: Constants.LOCATION_TIMER_TICK_INTERVAL, repeats: true, block: {
                t in
                
                if self.locationTickCount < self.locationTickLimit {
                    self.locationTickCount += 1
                    if self.currentLocation != nil && self.currentLocation!.horizontalAccuracy < 200 {
                        LogService.sharedService.log(event: .LOCATION, data: "Lat=\(self.currentLocation!.coordinate.latitude);Long=\(self.currentLocation!.coordinate.longitude)")
                        if self.currentLocation!.horizontalAccuracy < 200 {
                            completion(true)
                            self.locationManager.stopUpdatingLocation()
                            self.locationTimer.invalidate()
                        }
                    }
                }
                else {
                    completion(false)
                    self.locationManager.stopUpdatingLocation()
                    self.locationTimer.invalidate()
                }
            })
        }
    }
    
    func uploadEnvironment(searchToken:String, appID:String, model:Model?, callback: @escaping CompletionHandler) {
        
        var reqStr:String = ""
        if currentLocation == nil {
            reqStr = "{\"appID\":\"\(appID)\""
        }
        else {
            reqStr = "{\"location\":{\"latitude\":\(currentLocation!.coordinate.latitude),\"longitude\":\(currentLocation!.coordinate.longitude),\"accuracy\":\(currentLocation!.horizontalAccuracy)},\"appID\":\"\(appID)\""
        }
        if model != nil && model!.bssid != nil && model!.bssid != "" && model!.ssid != nil && model!.ssid != "" {
            reqStr += ",\"wifi_scans\":[{\"bssid\":\"\(model!.bssid!)\",\"ssid\":\"\(model!.ssid!)\"}]"
        }

        reqStr += "}"
        
        self.sendPutRequest(token:searchToken, url: APIService.ENVIRONMENT_URL, body: reqStr, completionHandler: {
            data, response, error in
            
            guard let _ = data, error == nil else {
                callback(.FAILED_NO_RESPONSE)
                return
            }
                
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                
                if httpStatus.statusCode == 401 {
                    callback(.FAILED_INVALID_TOKEN)
                }
                else {
                    callback(.FAILED_INVALID_STATUS)
                }
            }
            
            callback(.SUCCESS)
        })
        
        LogService.sharedService.debug(data: APIService.ENVIRONMENT_URL + " Called")
    }
    
    func getDevicesInRange(searchToken:String, appID:String, completion:@escaping CallBack) {
        let url = APIService.endPoint + "devices"
        self.sendGetRequest(token:searchToken, url: url, parameters: ["ownerID" : appID as AnyObject], completionHandler: completion)
        LogService.sharedService.debug(data: url + " Called")
    }
    
    func identifyYourself(searchToken:String, deviceID:String, completion:@escaping CallBack) {
        let url = APIService.DEVICES_URL + "/" + deviceID + "/identify_yourself"
        self.sendPutRequest(token:searchToken, url: url, parameters: [:], completionHandler: completion)
        LogService.sharedService.debug(data: url + " Called")
    }
    
    func getDeviceStatus(manageToken:String, deviceID:String, uptime:Bool = false, completion:@escaping CallBack) {
        var url:String = APIService.DEVICES_URL + "/" + deviceID + "/status"
        if uptime == true {
            url = APIService.DEVICES_URL + "/" + deviceID + "/status?uptime=0"
        }
        self.sendGetRequest(token:manageToken, url: url, parameters: [:], completionHandler: completion)
        LogService.sharedService.debug(data: url + " Called")
    }
    
    func bindDevice(bindToken:String, completion:@escaping CallBack) {
        let url:String = APIService.DEVICES_URL + "/bind"
        self.sendPutRequest(token: bindToken, url: url, parameters: [:], completionHandler: completion)
        LogService.sharedService.debug(data: url + " Called")
    }
    
    func resetDevice(manageToken:String, deviceID:String, completion:@escaping CallBack) {
        let url:String = APIService.DEVICES_URL + "/" + deviceID + "/reset"
        self.sendPutRequest(token: manageToken, url: url, parameters: [:], completionHandler: completion)
        LogService.sharedService.debug(data: url + " Called")
    }
    
    func getUserActionPerformedStatus(searchToken:String, deviceID:String, completion:@escaping CallBack) {
        let url:String = APIService.DEVICES_URL + "/" + deviceID + "/user_action_performed"
        self.sendGetRequest(token: searchToken, url: url, parameters: [:], completionHandler: completion)
        LogService.sharedService.debug(data: url + " Called")
    }
    
    func deletePrivateNetwork(manageToken:String, deviceID:String, network:Network, completion:@escaping CallBack) {
        let url:String = APIService.DEVICES_URL + "/" + deviceID + "/private_network"
        let dataStr = "{\"ssid\":\"\(network.ssid)\",\"roaming_id\":\"\(network.roamingID)\",\"security\":\"\(network.security)\"}"
        self.sendDeleteRequest(token: manageToken, url: url, body: dataStr, completionHandler: completion)
        LogService.sharedService.debug(data: url + " Called")
    }
    
    func putProviderCredentials(manageToken:String, appID:String, deviceID:String, providerID:String, completion: @escaping CallBack) {
        var url = APIService.DEVICES_URL + "/" + deviceID
        url = url + "/owner/" + appID + "/provider_private_network/" + providerID
        self.sendPutRequest(token:manageToken, url: url, parameters: [:], completionHandler: completion)
        LogService.sharedService.debug(data: url + " Called")
    }
    
    func deviceJoinNetwork(manageToken:String, deviceID:String, network:Network, password:String, bAddToVault:Bool = true, completion:@escaping CallBack) {
        let security = getSecurityProtocol(wifi: network)
        
        var dataStr:String = "[{\"ssid\":\"\(network.ssid)\",\"security\":\"\(security)\",\"priority\":\(network.priority)"
        
        if password != "" {
            dataStr = "[{\"ssid\":\"\(network.ssid)\",\"security\":\"\(security)\",\"priority\":\(network.priority),\"pre_shared_key\":\"\(password)\""
        }
        
        dataStr += "}]"
        
        let url:String = APIService.DEVICES_URL + "/" + deviceID + "/private_network?add_to_vault=\(bAddToVault)"
        self.sendPutRequest(token:manageToken, url: url, body: dataStr, completionHandler: completion)
        LogService.sharedService.debug(data: url + " Called")
    }
    
    func getSoftAPDeviceStatus(SoftAPIp:String, completion: @escaping CallBack) {
        let url = "http://" + SoftAPIp + "/status"
        let requestURL = URL(string:url)!
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: completion)
        task.resume()
        LogService.sharedService.debug(data: url + " Called")
    }
    
    func getSoftAPDeviceInfo(SoftAPIp:String, completion: @escaping CallBack) {
        let url = "http://" + SoftAPIp + "/device_info"
        let requestURL = URL(string:url)!
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: completion)
        task.resume()
        LogService.sharedService.debug(data: url + " Called")
    }
    
    func putSoftAPJoinNetwork(SoftAPIp:String, network:Network, password:String, encryptedPassword:String, completion: @escaping CallBack) {
        let security = getSecurityProtocol(wifi: network)
        var dataStr:String = "[{\"ssid\":\"\(network.ssid)\",\"security\":\"\(security)\",\"priority\":200,\"pre_shared_key\":\"\(password)\"}]"
        
        if encryptedPassword != "" {
            dataStr = "[{\"ssid\":\"\(network.ssid)\",\"security\":\"\(security)\",\"priority\":200,\"encrypted_pre_shared_key\":\"\(encryptedPassword)\"}]"
        }
        
        let url = "http://" + SoftAPIp + "/private_network"
        self.sendPostRequest(url: url, body: dataStr, completionHandler: completion)
        LogService.sharedService.debug(data: url + " Called")
    }
    
    func dropSoftAP(SoftAPIp:String, completion: @escaping CallBack) {
        let url = "http://" + SoftAPIp + "/drop_softap"
        self.sendPostRequest(url: url, body:"no body", completionHandler: completion)
        LogService.sharedService.debug(data: url + " Called")
    }
    
    func uploadLog(token:String, appID:String, logStr:String, completion:@escaping CallBack) {
        let url = APIService.LOG_URL + appID
        let data:String = "{\"file\":\"\(logStr)\",\"filename\":\"app\"}"
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpBody = data.data(using: .utf8)
        request.httpMethod = "PUT"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        var authStr = "Bearer "
        
        authStr += token
        request.setValue(authStr, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: completion)
        task.resume()
    }
    
// New HTTP Methods with token
    
    func sendPostRequest(token:String? = nil, url: String, body: String, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        var request = URLRequest(url: URL(string: url)!)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let authStr = getAuthoriztion(token: token)
        if authStr != nil {
            request.setValue(authStr!, forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = body.data(using: .utf8)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
    }
    
    func sendGetRequest(token:String? = nil, url: String, parameters: [String: AnyObject], completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let parameterString = parameters.stringFromHttpParameters()
        var requestURL = URL(string:"\(url)?\(parameterString)")!
        
        if parameterString == "" {
            requestURL = URL(string:url)!
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        
        let authStr = getAuthoriztion(token: token)
        if authStr != nil {
            request.setValue(authStr!, forHTTPHeaderField: "Authorization")
        }
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
    }
    
    func sendPutRequest(token:String? = nil, url: String, parameters: [String: AnyObject], completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let parameterString = parameters.stringFromHttpParameters()
        var request = URLRequest(url: URL(string: url)!)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameterString.data(using: .utf8)
        request.httpMethod = "PUT"
        
        let authStr = getAuthoriztion(token: token)
        if authStr != nil {
            request.setValue(authStr!, forHTTPHeaderField: "Authorization")
        }
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
    }
    
    func sendPutRequest(token:String? = nil, url: String, body: String, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        var request = URLRequest(url: URL(string: url)!)
        request.httpBody = body.data(using: .utf8)
        request.httpMethod = "PUT"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let authStr = getAuthoriztion(token: token)
        if authStr != nil {
            request.setValue(authStr!, forHTTPHeaderField: "Authorization")
        }
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
    }
    
    func sendDeleteRequest(token:String? = nil, url:String, body:String, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        var request = URLRequest(url: URL(string: url)!)
        request.httpBody = body.data(using: .utf8)
        request.httpMethod = "DELETE"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let authStr = getAuthoriztion(token: token)
        if authStr != nil {
            request.setValue(authStr!, forHTTPHeaderField: "Authorization")
        }
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
    }
    
    func getAuthoriztion(token:String?) -> String? {
        if token == nil || token! == "" {
            return nil
        }
        
        var authStr = "Bearer "
        authStr += token!
        
        return authStr
    }
    
    func getSecurityProtocol(wifi:Network) -> String {
        
        LogService.sharedService.debug(data: "getSecurityProtocol \(wifi.ssid)")
        
        let flags:String = wifi.flags
        if flags.range(of: "WPA/WPA2-PSK") != nil {
            return "WPA/WPA2-PSK"
        }
        else if flags.range(of: "WPA2-PSK") != nil {
            return "WPA2-PSK"
        }
        else if flags.range(of: "WPA-PSK") != nil {
            return "WPA-PSK"
        }
        else if flags.range(of: "WPA2-EAP") != nil {
            return "WPA2-EAP"
        }
        else if flags.range(of: "WPA2-ENTERPRISE") != nil {
            return "WPA2-ENTERPRISE"
        }
        else if flags.range(of: "WISPR") != nil {
            return "WISPR"
        }
        else if flags.range(of: "OPEN") != nil {
            return "OPEN"
        }
        else if flags.range(of: "Hs2.0") != nil {
            return "Hs2.0"
        }
        else if flags == "[ESS]" {
            return "OPEN"
        }
        
        return "OPEN"
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    // do stuff
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.first
        // print ("didUpdateLocations: - \(currentLocation!.coordinate.latitude), \(currentLocation!.coordinate.longitude), \(currentLocation!.horizontalAccuracy)")
    }
}

public extension String {
    
    /// Percent escapes values to be added to a URL query as specified in RFC 3986
    ///
    /// This percent-escapes all characters besides the alphanumeric character set and "-", ".", "_", and "~".
    ///
    /// http://www.ietf.org/rfc/rfc3986.txt
    ///
    /// :returns: Returns percent-escaped string.
    
    func addingPercentEncodingForURLQueryValue() -> String? {
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return self.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    }
    
}

public extension Dictionary {
    
    /// Build string representation of HTTP parameter dictionary of keys and objects
    ///
    /// This percent escapes in compliance with RFC 3986
    ///
    /// http://www.ietf.org/rfc/rfc3986.txt
    ///
    /// :returns: String representation in the form of key1=value1&key2=value2 where the keys and values are percent escaped
    
    func stringFromHttpParameters() -> String {
        let parameterArray = self.map { (key, value) -> String in
            let percentEscapedKey = (key as! String).addingPercentEncodingForURLQueryValue()!
            let percentEscapedValue = (value as! String).addingPercentEncodingForURLQueryValue()!
            return "\(percentEscapedKey)=\(percentEscapedValue)"
        }
        
        return parameterArray.joined(separator: "&")
    }
    
}
