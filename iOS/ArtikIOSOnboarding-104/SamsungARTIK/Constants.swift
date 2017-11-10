//
//  Constants.swift
//  SamsungARTIK
//
//  Created by alimi shalini on 11/30/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit
import Foundation
class Constants {
    
    // MARK: List of Constants
        
    static let ANIMATION_DURATION = 0.4
    static let grayColor : UIColor = UIColor(red: 101/255.0, green: 106/255.0, blue: 110/255.0, alpha: 1.0)
    static let textBoxColor : UIColor = UIColor(red: 224/255.0, green: 235/255.0, blue: 244/255.0, alpha: 1.0)
    //static let listColor : UIColor = UIColor(red: 50/255.0, green: 80/255.0, blue: 108/255.0, alpha: 1.0)
    static let listColor : UIColor = UIColor(red: 212/255.0, green: 93/255.0, blue: 47/255.0, alpha: 1)
    static let listTextColor : UIColor = UIColor(red: 172/255.0, green: 201/255.0, blue: 219/255.0, alpha: 1.0)
    //static let topBottomBarColor : UIColor = UIColor(red: 27/255.0, green: 49/255.0, blue: 69/255.0, alpha: 1.0)
    static let topBottomBarColor : UIColor = UIColor(colorLiteralRed: 9/255.0, green: 26/255.0, blue: 44/255.0, alpha: 1)
    static let backgroundWhiteColor : UIColor = UIColor.white
    static let NETWORK_CONNECTION_CHANGED = NSLocalizedString("NETWORK CONNECTION CHANGED", comment: "")
    
    static let RESPONSE_ACCESS_TOKEN_KEY = "access_token"
    static let CLIENT_ID = "af1f6d71b0d24374933d86f946cc0eb6"
    //static let CLIENT_ID = "466e06d3f6544bcd96174f27ce91289f"
   // static let CLIENT_ID = "89d12b4d9fd44c5498084e212a25379c"
    static let LOGIN_URL = "https://accounts.artik.cloud/authorize?client_id=%@&response_type=token&redirect_uri=artik://onboarding"
    static let SIGNIN_URL = "https://accounts.artik.cloud/signin?client_id=%@&response_type=token&redirect_uri=artik://onboarding&prompt=select_account"
    static let USER_ID = "USER_ID"
    static let ACCESS_TOKEN = "ACCESS TOKEN"
    static let REFRESH_TOKEN = "REFRESH TOKEN"
    static let USER_PROFILE_NAME = "USER NAME"
    static let USER_PROFILE_EMAIL = "USER EMAIL ID"
    static let USER_PROFILE_FULLNAME = "USER FULL NAME"
    static let USER_PROFILE_CREATED = "USER CREATED"
    static let USER_PROFILE_MODIFIED = "USER MODIFIED"

    static let LOGOUT_URL = "https://accounts.artik.cloud/signout?redirect_uri=artik://onboarding"
    
    static let REGEX_USER_NAME_LIMIT = "^.{4,31}$"
    static let REGEX_Module_LIMIT = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789,"
    static let REGEX_User_Name_Restrict = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 "

    static let OTHER_WIFI = "Other"
    
    static let SERVICE_UUID = "FFFFFFFF-C0C1-FFFF-C0C1-"
    
    static let STATUS_CHARACTERISTIC_UUID = "FFFFFFFF-C0C1-FFFF-C0C1-201401000001"
    static let DETAILED_STATUS_CHARACTERISTIC_UUID = "FFFFFFFF-C0C1-FFFF-C0C1-201401000002"
    static let SSID_CHARACTERISTIC_UUID = "FFFFFFFF-C0C1-FFFF-C0C1-201401000003" // For setting wifi SSID
    static let AUTH_CHARACTERISTIC_UUID = "FFFFFFFF-C0C1-FFFF-C0C1-201401000004" // For setting auth type
    static let PASSPHRASE_CHARACTERISTIC_UUID = "FFFFFFFF-C0C1-FFFF-C0C1-201401000005" // For setting wifi password
    static let CHANNEL_CHARACTERISTIC_UUID = "FFFFFFFF-C0C1-FFFF-C0C1-201401000006"
    static let COMMAND_CHARACTERISTIC_UUID = "FFFFFFFF-C0C1-FFFF-C0C1-201401000007"
    static let VENDORID_CHARACTERISTIC_UUID = "FFFFFFFF-C0C1-FFFF-C0C1-201401000008"
    static let DEVICEID_CHARACTERISTIC_UUID = "FFFFFFFF-C0C1-FFFF-C0C1-201401000009"
    static let WIFI_STATE_CHARACTERISTIC_UUID = "FFFFFFFF-C0C1-FFFF-C0C1-201401000010" //Subscribe for WIFI state notification
    static let IPADDRESS_CHARACTERISTIC_UUID = "FFFFFFFF-C0C1-FFFF-C0C1-201401000011" //Read for IPAddress
    static let WIFI_DATA_CHARACTERISTIC_UUID = "FFFFFFFF-C0C1-FFFF-C0C1-201401000012"//Read SSID
    
    static let ARTIK_0_DEVICE_TYPE = "dtffe018d82ab24f2981dea0307a630f71"
    static let ARTIK_0_DTID = "dtffe018d82ab24f2981dea0307a630f71"
    static let ARTIK_5_DTID = "dt6594d3d6959446f292ab19b26609251b"
    static let ARTIK_7_DTID = "dtc5ecf0abccaa428c853e144c964ad727"
    static let ARTIK_053_SDR_DTID = "dt2d93bdb9c8fa446eb4a35544e66150f7"

    static let CHALLENGE_PIN_CHARACTERISTIC_UUID = "0000FFF1-0000-1000-8000-00805F9B34FB"
    static let ACCESS_TOKEN_CHARACTERISTIC_UUID = "0000FFF2-0000-1000-8000-00805F9B34FB"
    static let DEVICE_TYPE_ID_CHARACTERISTIC_UUID = "0000FFF3-0000-1000-8000-00805F9B34FB"
    static let SDR_VENDOR_ID_CHARACTERISTIC_UUID = "0000FFF4-0000-1000-8000-00805F9B34FB"
    static let START_REG_CHARACTERISTIC_UUID = "0000FFF5-0000-1000-8000-00805F9B34FB"
    static let COMPLETE_REG_CHARACTERISTIC_UUID = "0000FFF6-0000-1000-8000-00805F9B34FB"
    static let DID_CHARACTERISTIC_UUID = "0000FFF7-0000-1000-8000-00805F9B34FB"
    static let UID_CHARACTERISTIC_UUID = "0000FFF8-0000-1000-8000-00805F9B34FB"
    
    //Notifications
    static let NOTIF_DEVICE_ID_READ = "device_id_read"
    static let NOTIF_IP_ADDRESS_READ = "ip_address_read"
    static let NOTIF_WIFI_DATA_READ = "Wifi_Data_Read"
    static let NOTIF_DTID_READ = "Dtid_Read"
    static let NOTIF_PERIPHERAL_DISCONNECTED = "peripheral_dsconnected"
    
    static let MODULE_DELETED_NOTIF = "module_deleted_notification"
    static let MODULE_DELETE_FAILED = "module_delete_failed"
    
    static let MODULE_AND_LOCATION_DICTIONARY = "MODULE AND LOCATION DICTIONARY"
    static let MODULE_NAME = "MODULE NAME"
    static let LOCATION_NAME = "LOCATION NAME"
    static let UNSPECIFIED_LOCATION = "Unspecified location"
    
    static let USER_PROPERTIES_IPADDRESS_KEY = "ipaddress"
    static let USER_PROPERTIES_DEVICE_ID_KEY = "deviceid"
    
    static let REGISTER_MODULE = "Register Modules"
    static let REGISTER_EDGE_NODE = "Register Edge Node"

    static let DEVICES_URL = "http://%@:80/v1.0/devices"
    static let USER_DETAILS_URL = "http://%@:80/v1.0/service/conf"
    static let REGISTER_URL = "http://%@:80/v1.0/service/AKCProvision"
    static let MODE_URL = "http://%@:80/v1.0/service"
    
    static let ARTIK_DEVICE_TYPE = 11079
}
