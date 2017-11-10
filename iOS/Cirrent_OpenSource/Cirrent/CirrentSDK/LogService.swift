
//
//  LogService.swift
//  Cirrent_New
//
//  Created by PSIHPOK on 12/19/16.
//  Copyright © 2016 PSIHPOK. All rights reserved.
//

import Foundation

class Log {
    var date:Date!
    var event:String!
    var detailStr:String!
    
    init() {
        date = Date()
    }
    
    init(event:String, data:JSON) {
        date = Date()
        self.event = event
    }
    
    func getLogString() -> String {
        var retStr = ""
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Constants.DATE_FORMAT_STR
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        retStr = dateFormatter.string(from: date)
        
        retStr += "|"
        retStr += event
        retStr += "|"
        
        retStr += detailStr
        return retStr
    }
}

public class LogService {
    private var logs:[Log]! = []
    public static let sharedService:LogService = LogService()
    private static let LOGFILE_PATH = "softap_log.txt"
    private static let LOGFILE_PATH_KEY = "SOFTAP_LOG_PATH_KEY"
    private var token:String? = nil
    private var ownerID:String? = nil
    
    public func setOwnerIdentifier(identifier:String?) {
        ownerID = identifier
    }
    
    public func putLog(token:String?) {
        print("PUT LOG CALLED")
        
        if token != nil {
            self.token = token
        }
        
        loadAndUploadLogs(completion: {
            () -> Void in
            
            print("LOAD AND UPLOAD LOGS")
            var fileStr = ""
            for log in self.logs {
                let logStr = log.getLogString()
                fileStr += logStr + "\\n"
            }
            
            self.uploadLog(fileStr: fileStr)
        })
    }
    
    public func uploadLog(fileStr:String) {
        let appID:String? = self.ownerID
        if appID == nil || appID == "" {
            print ("Uploading Log Failed - AppID is nil")
            self.saveLogs()
        }
        else if self.token == nil || self.token! == "" {
            print ("Uploading Log Failed - INVALID_TOKEN")
            self.saveLogs()
        }
        else {
            APIService.sharedService.uploadLog(token: self.token!, appID: appID!, logStr: fileStr, completion: {
                data, response, error in
                guard let _ = data, error == nil else {
                    print("Uploading Log Failed - Cloud Connection Error (NO_RESPONSE), Logs Will be Saved in local Storage.")
                    self.saveLogs()
                    return
                }
                
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                    print("Uploading Log Failed - Cloud Connection Error (INVALID_STATUS - \(httpStatus.statusCode)), Logs Will be Saved in local Storage.")
                    print("\(httpStatus.statusCode)")
                    self.saveLogs()
                    return
                }
                
                let responseString = String(data: data!, encoding: .utf8)!
                let json:JSON = JSON(data: data!)
                let statusCode = json["statusCode"].intValue
                let message = json["message"].stringValue
                //let body = json["body"].stringValue
                
                if responseString.characters.count == 0 {
                    self.purge()
                    print ("Uploading Log Succeeded")
                }
                else {
                    self.saveLogs()
                    print (fileStr)
                    print ("Uploading Log Failed - \(statusCode), \(message)")
                }
            })
        }
    }
    
    public func debug(data:String) {
        var str = data.replacingOccurrences(of: "\\", with: "\\\\")
        str = str.replacingOccurrences(of: "\"", with: "\\\"")
        str = str.replacingOccurrences(of: "{", with: "\\\\{")
        str = str.replacingOccurrences(of: "}", with: "\\\\}")
        str = str.replacingOccurrences(of: "\n", with: "")
        
        log(event: "DEBUG", data: str)
    }
    
    private func log(event:String, data:String) {
        let lg = Log()
        lg.event = event
        lg.detailStr = data
        logs.append(lg)
        print(lg.event + "|" + lg.detailStr)
    }
    
    public func log(event:LOG_EVENT, data:String) {
        let lg = Log()
        
        switch event {
        case .SEARCH_START:
            lg.event = "SEARCH-START"
            break
        case .TOKEN_RECEIVED:
            lg.event = "TOKEN-RECEIVED"
            break
        case .TOKEN_ERROR:
            lg.event = "TOKEN-ERROR"
            break
        case .LOCATION:
            lg.event = "LOCATION"
            break
        case .LOCATION_ERROR:
            lg.event = "LOCATION-ERROR"
            break
        case .WIFI_SCAN:
            lg.event = "WIFI-SCAN"
            break
        case .WIFI_SCAN_ERROR:
            lg.event = "WIFI-SCAN-ERROR"
            break
        case .DEVICES_RECEIVED:
            lg.event = "DEVICES-RECEIVED"
            break
        case .DEVICE_SELECTED:
            lg.event = "DEVICE-SELECTED"
            break
        case .DEVICE_BOUND:
            lg.event = "DEVICE-BOUND"
            break
        case .PROVIDER_CREDS:
            lg.event = "PROVIDER-CREDS"
            break
        case .USER_CREDS:
            lg.event = "USER-CREDS"
            break
        case .STATUS:
            lg.event = "STATUS"
            break
        case .STATUS_ERROR:
            lg.event = "STATUS-ERROR"
            break
        case .SoftAP:
            lg.event = "SoftAP"
            break
        case .SoftAP_ERROR:
            lg.event = "SoftAP-ERROR"
            break
        case .SoftAP_SCREEN:
            lg.event = "SoftAP-SCREEN"
            break
        case .SoftAP_JOINED:
            lg.event = "SoftAP-JOINED"
            break
        case .SoftAP_DROP:
            lg.event = "SoftAP-DROP"
            break
        case .SoftAP_LONG_DURATION:
            lg.event = "SoftAP-LONG-DURATION"
            break
        case .CREDS_TIMEOUT:
            lg.event = "CREDS-TIMEOUT"
            break
        case .CLOUD_CONNECTION_ERROR:
            lg.event = "CLOUD-CONNECTION-ERROR"
            break
        case .JOINED_FAILED:
            lg.event = "JOINED-FAILED"
            break
        case .SUCCESS:
            lg.event = "SUCCESS"
            break
        case .EXIT:
            lg.event = "EXIT"
            break
        case .DEBUG:
            lg.event = "DEBUG"
            break
        }
        
        lg.detailStr = data
        logs.append(lg)
        
        if event == .WIFI_SCAN_ERROR {
            putLog(token: nil)
        }
        
        print("LOG - " + lg.event + "|" + lg.detailStr)
    }
    
    private func purge() {
        logs.removeAll()
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let pathURL = dir.appendingPathComponent(LogService.LOGFILE_PATH)
            do {
                let empty = ""
                try empty.write(to: pathURL, atomically: false, encoding: .utf8)
            }
            catch let error as NSError {
                print ("Failed to remove all logs from local storage \(error)")
            }
        }
    }
    
    public static func getResponseErrorString(response:RESPONSE) -> String {
        if response == RESPONSE.FAILED_NO_RESPONSE {
            return "NO_RESPONSE"
        }
        else {
            return "INVALID_STATUS"
        }
    }
    
    public static func jsonStringfy(json:JSON) -> String? {
        var jsonStr = json.rawString()
        
        if jsonStr == nil {
            return nil
        }
        else {
            jsonStr = jsonStr!.replacingOccurrences(of: "\\", with: "\\\\")
            jsonStr = jsonStr!.replacingOccurrences(of: "\"", with: "\\\"")
            jsonStr = jsonStr!.replacingOccurrences(of: "{", with: "\\\\{")
            jsonStr = jsonStr!.replacingOccurrences(of: "}", with: "\\\\}")
            jsonStr = jsonStr!.replacingOccurrences(of: "\n", with: "")
            return jsonStr!
        }
    }
    
    private func loadAndUploadLogs(completion: @escaping () -> Void) {
        if self.token == nil {
            print ("Failed Uploading Local Storage Logs - Invalid Token")
            completion()
            return
        }
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let pathURL = dir.appendingPathComponent(LogService.LOGFILE_PATH)

            do {
                let fileStr = try String(contentsOf: pathURL, encoding: .utf8)
                if fileStr != "" {
                    let appID = self.ownerID
                    if appID == nil {
                        print ("Failed Uploading Local Storage Logs - Owner ID is missed.")
                        completion()
                        return
                    }
                    APIService.sharedService.uploadLog(token: self.token!, appID: appID!, logStr: fileStr, completion: {
                        data, response, error in
                        guard let _ = data, error == nil else {
                            completion()
                            return
                        }
                        
                        if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                            completion()
                            return
                        }
                        
                        let responseString = String(data: data!, encoding: .utf8)!
                        let json:JSON = JSON(data: data!)
                        let statusCode = json["statusCode"].intValue
                        let message = json["message"].stringValue
                        
                        if responseString.characters.count == 0 {
                            self.purge()
                            print ("Success Uploading Logs on Local Storage")
                        }
                        else {
                            print ("Failed Uploading Logs on Local Storage - \(statusCode), \(message)")
                        }
                        completion()
                    })
                }
                else {
                    completion()
                }
            }
            catch let error as NSError {
                print ("Failed to load and upload logs. \(error)")
                completion()
            }
        }
        else {
            print("File System Error")
            completion()
        }
    }
    
    public func saveLogs() {
        if logs.count == 0 {
            return
        }
        
        var entireStr = ""
        var fileStr = ""
        for log in logs {
            let logStr = log.getLogString()
            fileStr += logStr + "\\n"
        }
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let pathURL = dir.appendingPathComponent(LogService.LOGFILE_PATH)
            do {
                do{
                    entireStr = try String(contentsOf: pathURL, encoding: .utf8)
                }
                catch let error as NSError {
                    print ("Failed to read logs from Local Storage. \(error)")
                }

                entireStr += fileStr
                
                try entireStr.write(to: pathURL, atomically: false, encoding: .utf8)
                logs.removeAll()
                print ("Saved logs to Local Storage.")
            }
            catch let error as NSError {
                print ("Failed to save logs to Local Storage. \(error)")
            }
        }
    }
}

