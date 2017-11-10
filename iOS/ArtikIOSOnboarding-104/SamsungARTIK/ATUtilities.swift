//
//  ATUtilities.swift
//  SamsungARTIK
//
//  Created by Surendra on 12/1/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import Foundation
import UIKit
import Toaster

class ATUtilities {
    
    func appDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    class func showIndicator(message: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        hideIndicator()
        
        if ((appDelegate.window?.viewWithTag(1111)) == nil) {
            
            let sampleView = UIView(frame: (appDelegate.window?.frame)!)
            sampleView.tag = 1111
            sampleView.backgroundColor = UIColor.clear
            sampleView.makeToastActivity(CGPoint(x: sampleView.frame.size.width/2, y: sampleView.frame.size.height/2),message: message)
            appDelegate.window?.addSubview(sampleView)
        }
    }
    
    class func hideIndicator() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if ((appDelegate.window?.viewWithTag(1111)) != nil) {
            appDelegate.window?.viewWithTag(1111)?.removeFromSuperview()
        }
    }
    
    class func showIndicator1(message: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        hideIndicator()
        
        if ((appDelegate.window?.viewWithTag(1112)) == nil) {
            
            let sampleView = UIView(frame: (appDelegate.window?.frame)!)
            sampleView.tag = 1112
            sampleView.backgroundColor = UIColor.clear
            sampleView.makeToastActivity(CGPoint(x: sampleView.frame.size.width/2, y: sampleView.frame.size.height/2),message: message)
            appDelegate.window?.addSubview(sampleView)
        }
    }
    
    class func hideIndicator1() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if ((appDelegate.window?.viewWithTag(1112)) != nil) {
            appDelegate.window?.viewWithTag(1112)?.removeFromSuperview()
        }
    }

    class func showToast(message : String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        let sampleView = UIView(frame: (appDelegate.window?.frame)!)
        sampleView.tag = 1011
        sampleView.backgroundColor = UIColor.clear
        sampleView.makeToast(message, duration: 1.0,
                             position: CGPoint(x: sampleView.frame.size.width/2, y: sampleView.frame.size.height/2))
        appDelegate.window?.addSubview(sampleView)

    }

    class func showToastMessage(message : String) {
        Toast(text: message, duration: 1.0).show()
    }

    class func validateMacAddress(macString:String) -> Bool {
        //00000000-0000-0000-0000-000000000000
        var isValid: Bool = false
        let valArray = macString.components(separatedBy: "-")
        if valArray.count != 5 {
            print("Not a valid mac address")
            return false
        }
        else if valArray[0].characters.count != 8 || valArray[1].characters.count != 4 || valArray[2].characters.count != 4 || valArray[3].characters.count != 4 || valArray[4].characters.count != 12 {
            return false
        }
            
        else if((valArray[0] + "-" + valArray[1] + "-" + valArray[2] + "-" + valArray[3] + "-").caseInsensitiveCompare(Constants.SERVICE_UUID) != ComparisonResult.orderedSame){
            return false
        }
            
        let identifierStr: String = (valArray[4] as NSString).substring(to: 1)
        
        if identifierStr == "0" || identifierStr == "5" ||  identifierStr == "7" {
            isValid = true
        }
        else {
            return false
        }
        
        if isValid == true {
            ATUtilities.setValueForArtikDeviceIdentifier(value: identifierStr)
        }
        
        return isValid
    }
    
    class func validateQR(qrString: String) -> Bool {
        var isValid: Bool = false
        let valArray = qrString.components(separatedBy: ",")
        
        //Chacking whether UUID string is valid or not.
        let uuidString = Constants.SERVICE_UUID.appending(valArray.last!)
        if UUID(uuidString: uuidString) == nil {
            return false
        }
        
        var deviceIdentifier: String!
        
        if valArray.count == 2 {
            deviceIdentifier = valArray.first
            artikPrimaryMac = valArray.last!
        }
        else if valArray.count == 3 {
            deviceIdentifier = valArray.first
            artikPrimaryMac = valArray[2] // BLE Mac
            artikSecondaryMac = valArray[1] // Wifi Mac
        }
        else {
            return false
        }
        
        if deviceIdentifier == "" {
            return false
        }
        
        self.setDeviceIdentifier(value: deviceIdentifier)
        
        let identifierStr: String = (deviceIdentifier as NSString).substring(to: 1)
        
        if identifierStr == "0" || identifierStr == "5" ||  identifierStr == "7" {
            isValid = true
        }
        else {
            isValid = false
        }
        
        if identifierStr == "0" {
            if valArray.count != 2 {
                return false
            }
            else if valArray.count == 3 {
                isValid = true
            }
        }
        
        let bleMAC: String = valArray.last!
        if bleMAC.characters.count == 12 {
            
            if identifierStr == "0" || identifierStr == "5" ||  identifierStr == "7" {
                isValid = true
            }
            else {
                isValid = false
            }
        }
        else {
            return false
        }
        
        if isValid == true {
            ATUtilities.setValueForArtikDeviceIdentifier(value: identifierStr)
        }
        return isValid
    }
    
    
    static var registrationForModules: Bool = false
    
    class func registrationForModule() -> Bool {
        return registrationForModules
    }
    
    class func setValueForRegistrationForModules(value: Bool) {
        registrationForModules = value
    }
    
    class func getRegisterTitle() -> String {
        if self.registrationForModule() == true {
            return Constants.REGISTER_MODULE
        }
        else {
            return Constants.REGISTER_EDGE_NODE
        }
    }
   
    
    
    class func getIPAddress(forDeviceId deviceId: String, fromArray array: [[String: String]]) -> String {
        for properties: [String: String] in array {
            if (properties["deviceid"] == deviceId) {
                return properties["ipaddress"]!
            }
        }
        return ""
    }
    
    
    
    static var artikDeviceIdentifier: String = ""
    static var artikPrimaryMac : String = ""
    static var artikSecondaryMac: String = ""


    class func artikDeviceId() -> String {
        return artikDeviceIdentifier
    }
    
    class func setValueForArtikDeviceIdentifier(value: String) {
        artikDeviceIdentifier = value
    }
    
    
    static var deviceIdentifier = ""
    
    class func getDeviceIdentifier() -> String
    {
        return deviceIdentifier;
    }
    
    class func setDeviceIdentifier(value: String)
    {
        deviceIdentifier = value;
    }

    /**
     Formats a date as the time since that date (e.g., “Last week, yesterday, etc.”).

     - Parameter from: The date to process.
     - Parameter numericDates: Determines if we should return a numeric variant, e.g. "1 month ago" vs. "Last month".

     - Returns: A string with formatted `date`.
     */
    class func timeSinceFormat (timestamp: Int64, numericDates: Bool = false) -> String {

        let from = NSDate(timeIntervalSince1970: TimeInterval(timestamp)/1000)

        let calendar = Calendar.current
        let now = NSDate()
        let earliest = now.earlierDate(from as Date)
        let latest = earliest == now as Date ? from : now
        let components = calendar.dateComponents([.year, .weekOfYear, .month, .day, .hour, .minute, .second], from: earliest, to: latest as Date)

        var result = ""

        if components.year! >= 2 {
            result = "\(components.year!) years ago"
        } else if components.year! >= 1 {
            if numericDates {
                result = "1 year ago"
            } else {
                result = "Last year"
            }
        } else if components.month! >= 2 {
            result = "\(components.month!) months ago"
        } else if components.month! >= 1 {
            if numericDates {
                result = "1 month ago"
            } else {
                result = "Last month"
            }
        } else if components.weekOfYear! >= 2 {
            result = "\(components.weekOfYear!) weeks ago"
        } else if components.weekOfYear! >= 1 {
            if numericDates {
                result = "1 week ago"
            } else {
                result = "Last week"
            }
        } else if components.day! >= 2 {
            result = "\(components.day!) days ago"
        } else if components.day! >= 1 {
            if numericDates {
                result = "1 day ago"
            } else {
                result = "Yesterday"
            }
        } else if components.hour! >= 2 {
            result = "\(components.hour!) hours ago"
        } else if components.hour! >= 1 {
            if numericDates {
                result = "1 hour ago"
            } else {
                result = "An hour ago"
            }
        } else if components.minute! >= 2 {
            result = "\(components.minute!) minutes ago"
        } else if components.minute! >= 1 {
            if numericDates {
                result = "1 minute ago"
            } else {
                result = "A minute ago"
            }
        } else if components.second! >= 3 {
            result = "\(components.second!) seconds ago"
        } else {
            result = "Just now"
        }

        return result
    }
    
}


