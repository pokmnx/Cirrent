//
//  AppDelegate.swift
//  SamsungARTIK
//
//  Created by alimi shalini on 11/28/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit
import ArtikCloud
import CoreBluetooth
import CoreData
import Fabric
import Crashlytics
import SwiftKeychainWrapper
import CirrentSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var serverReachable: ATReachability!
    var isFirstTimeLogin: Bool!
    var discoveredPeripheral: CBPeripheral!
    var userProperties = [[String: String]]()
    var selectedMenuItemInd : Int = 0
    var isUserPropertiesCreated: Bool!
    var userTotalDevices : Int!
    var deviceTypeIdSet = Set<String>()
    var deviceManifestIdSet = Set<String>()
    var selectedModule : Module!
    var deviceDeleted : Bool = false
    var selectedActionName : String!
    var selectedActionObject : NSObject!
    var actionParams : [String:NSObject]?
    var isRefreshing : Bool = false
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Fabric.with([Crashlytics.self])
        self.setStatusBarBackgroundColor(color: Constants.topBottomBarColor)
        isFirstTimeLogin = false
        isUserPropertiesCreated = false
        
        CirrentService.sharedService.setOwnerIdentifier(identifier: SampleCloudService.sharedService.username)
        self.setRootViewController(isFromLogin: false)
        return true
    }
    
    func setStatusBarBackgroundColor(color: UIColor) {
        guard let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else { return }
        statusBar.backgroundColor = color
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        serverReachable = ATReachability.sharedInstance
        serverReachable.configureReachability()
        return true
    }

    /** 
     This function catches the OAuth redirect-url from the browser
     */

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        if url.absoluteString.contains(Constants.RESPONSE_ACCESS_TOKEN_KEY) {
            let string = url.absoluteString.replacingOccurrences(of: "#", with: "&")
            let components = string.components(separatedBy: "&")
            let accessTokenArray = (components[1] as String).components(separatedBy: "=")
            let refreshTokenArray = (components[1] as String).components(separatedBy: "=")
            
            let defaults = KeychainWrapper.standard
            defaults.set(accessTokenArray[1], forKey: Constants.ACCESS_TOKEN)
            defaults.set(refreshTokenArray[1], forKey: Constants.REFRESH_TOKEN)
        }
        // Check if the token has expired or not
        self.getUserName()

        return true
    }


    /**
     Get User Profile
     [See also](https://developer.artik.cloud/documentation/api-reference/rest-api.html#get-the-current-users-profile)
     */
    func getUserName() {
        ATUtilities.showIndicator(message:"Loading")
        
        let defaults = KeychainWrapper.standard

        let apiConfig = ACConfiguration.sharedConfig()
        apiConfig?.accessToken = KeychainWrapper.standard.string(forKey: Constants.ACCESS_TOKEN)
        
        let apiInstance = ACUsersApi()
        apiInstance.getSelfWithCompletionHandler { (output: ACUserEnvelope?, error: Error?) in
            if output != nil {
                
                defaults.set((output?.data.fullName)!, forKey: Constants.USER_PROFILE_FULLNAME)
                defaults.set((output?.data.name)!, forKey: Constants.USER_PROFILE_NAME)
                defaults.set((output?.data.email)!, forKey: Constants.USER_PROFILE_EMAIL)                
                defaults.set((output?.data.createdOn)! as Int, forKey: Constants.USER_PROFILE_CREATED)
                defaults.set((output?.data.modifiedOn)!, forKey: Constants.USER_PROFILE_MODIFIED)
                /* Update Crashlytics profiling */
                Crashlytics.sharedInstance().setUserName(output?.data.name!)
                Crashlytics.sharedInstance().setUserEmail((output?.data.email)!)

                self.setRootViewController(isFromLogin: true)
            }
            if error != nil {
                print("Error in getUsername \(error?.localizedDescription)")
                self.setRootViewController(isFromLogin: false)
            }
        }
    }

    /**
     Choose Device Dashbord Page or Login Page depending upon the availability of Access Token
     */

    func setRootViewController(isFromLogin: Bool) {

        ATUtilities.hideIndicator()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let defaults = KeychainWrapper.standard
        
        if defaults.string(forKey: Constants.ACCESS_TOKEN) != nil {
            let initialViewController = storyboard.instantiateViewController(withIdentifier: "dashBoardNavigationController")
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
            if ATReachability.sharedInstance.isNetworkReachable == true {
                getModules(isFromPullDown:false)
            }
        } else {
            let initialViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
        }
        
    }

    /**
     Delete a device 
     https://developer.artik.cloud/documentation/api-reference/rest-api.html#delete-a-device
     */
    func deleteModule(deviceId: String) -> Void {
        if ATReachability.sharedInstance.isNetworkReachable == true {
            ATUtilities.showIndicator(message:"Deletion In Progress")
            
            let apiConfig: ACConfiguration = ACConfiguration.sharedConfig()
            apiConfig.accessToken = KeychainWrapper.standard.string(forKey: Constants.ACCESS_TOKEN)
            let apiInstance = ACDevicesApi()
            apiInstance.deleteDevice(withDeviceId: deviceId, completionHandler: { (output: ACDeviceEnvelope?, error: Error?) in
                if output?.data != nil {
                    ATDatabaseManager.deleteModulewith(id: deviceId as String)
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.MODULE_DELETED_NOTIF), object: nil)
                }
                if error != nil {
                    print("Delete module failed. Error = \(error)")
                    let code = String((error as! NSError).code)
                    if code == "-1011" {
                        ATDatabaseManager.deleteModulewith(id: deviceId as String)
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.MODULE_DELETED_NOTIF), object: nil)
                    }
                    else {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.MODULE_DELETE_FAILED), object: nil, userInfo: ["errorDesc": (error?.localizedDescription)! as String])
                    }
                }
            })
        }
    }

    /**
     Get Modules - This function will fetch the list of devices either if isFromPullDown is true or there are no deivces in the local database
     */
    func getModules( isFromPullDown: Bool) {
        if ATReachability.sharedInstance.isNetworkReachable == true {
            

            let apiConfig: ACConfiguration = ACConfiguration.sharedConfig()
            apiConfig.accessToken = KeychainWrapper.standard.string(forKey: Constants.ACCESS_TOKEN)
            
            print("Acces Token \(apiConfig.accessToken)")
            /* Check if access token is still valid */
            let apiInstance = ACTokensApi()
            apiInstance.tokenInfo(completionHandler: { (output: ACTokenInfoSuccessResponse?, error:Error?) in
                if output != nil {
                    let userId = output?.data.userId // User ID
                    
                    KeychainWrapper.standard.set(userId!, forKey: Constants.USER_ID)
                    
                    let searchResults = ATDatabaseManager.getAllModules()
                    
                    let dtidSearchResults = ATDatabaseManager.getAllDeviceType()
                    
                    for dtid in dtidSearchResults {
                        self.deviceTypeIdSet.insert(dtid.dtid!)
                    }
                    
                    let manifestSearchResults = ATDatabaseManager.getAllDeviceManifest()
                    
                    for manifest in manifestSearchResults {
                        self.deviceManifestIdSet.insert(manifest.dtid!)
                    }
                    
                    if searchResults.count == 0  || isFromPullDown {

                        if !self.isRefreshing {
                            ATDatabaseManager.truncateEntity()
                            self.deviceTypeIdSet.removeAll()
                            self.isRefreshing = true
                            self.getUserDevices(offset: 0, count: 100, includedProperties: false)
                        }
                    } else {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "fetch_dashboard_data"), object: nil)
                    }
                }
                if error != nil {
                    /* Access token expired */
                    print("Error calling ACTokensApi->tokenInfo: \(error)")
                    ATUtilities.hideIndicator()
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let initialViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
                    self.window?.rootViewController = initialViewController
                    self.window?.makeKeyAndVisible()
                }
            })
        }
    }
    
    /**
     Get User Devices from Artik Cloud 
     https://developer.artik.cloud/documentation/api-reference/rest-api.html#get-a-users-devices
     */
    func getUserDevices(offset: Int, count: Int, includedProperties : Bool) {
        
        let apiInstance = ACUsersApi()
        
        let userId = KeychainWrapper.standard.string(forKey: Constants.USER_ID)
        
        apiInstance.getUserDevices(withUserId: userId, offset: offset as NSNumber!, count: count as NSNumber!, includeProperties: includedProperties as NSNumber!, completionHandler: { (output: ACDevicesEnvelope?, error: Error?) in
            if output != nil {
               // print("Modules : \(output)")
                
                var sdids = ""
                let count = Int((output?.data.devices.count)!)
                for i in 0..<count {
                    let module = output?.data.devices[i] as! ACDevice
                    ATDatabaseManager.insertDevice(moduleDict: module)
                    sdids += module._id + ","
                }

                /* Update Device Snapshot */
                if count > 0 {
                    sdids = sdids.substring(to: sdids.index(before: sdids.endIndex))
                    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .milliseconds(100) , execute: {
                        self.getDeviceSnapshot(devices: sdids)
                    })
                }
                
                self.userTotalDevices = output?.total as Int!
                
                
                if (offset == 0) {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "fetch_dashboard_data"), object: nil)
                }


                /* Check if there are more devices to fetch */
                if self.userTotalDevices > offset + count {
                    self.getUserDevices(offset: offset + count, count: 100, includedProperties: includedProperties)
                } else {

                    /* No more devices to fetch */
                    if (offset != 0) {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "fetch_dashboard_data"), object: nil)
                    }

                    self.isRefreshing = false
                    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .milliseconds(100) , execute: {

                        let modules = ATDatabaseManager.getAllModules()

                        for module in modules {

                            /* Get Device Type Information */

                            if (!self.deviceTypeIdSet.contains(module.dtid!)) {
                                self.deviceTypeIdSet.insert(module.dtid!)
                                self.getDeviceTypeInformation(deviceTypeId: module.dtid!)
                            }

                            /* Get Device Manfiest  */

                            let manifestId = module.dtid! + "-" + String(describing : module.manifestVersion)
                            if (!self.deviceManifestIdSet.contains(manifestId)) {
                                self.deviceManifestIdSet.insert(manifestId)
                                self.getDeviceManifest(deviceTypeId: module.dtid!, Version: String(describing : module.manifestVersion))
                            }
                            
                        }
                    })
                }
            }
            if error != nil {
                print("Error calling getUserdDevices: \(error)")
                ATUtilities.hideIndicator()
            }
            
        })
        
    }

    /**
     Get a Device Type
     https://developer.artik.cloud/documentation/api-reference/rest-api.html#get-a-device-type
     */
    func getDeviceTypeInformation(deviceTypeId: String) {
        
        
        if (ATDatabaseManager.doesExistDeviceTypeInfo(deviceTypeId: deviceTypeId)) {
            return
        }
        
        let apiInstance = ACDeviceTypesApi()
        
        apiInstance.getDeviceType(withDeviceTypeId: deviceTypeId, completionHandler:  { (output : ACDeviceTypeEnvelope?, error:Error?) in
            
            if output != nil {
                //print ("Device Type \(output)")
                ATDatabaseManager.insertDeviceType(deviceType: (output?.data)! as ACDeviceType)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "fetch_devicetypes"), object: nil)
            }

            if error != nil {
                print("Error calling getUserDeviceTypes: \(error)")
            }
        })
        
    }

    /**
     Get Device Manifest
     https://developer.artik.cloud/documentation/api-reference/rest-api.html#get-manifest-properties
     */
    
    func getDeviceManifest(deviceTypeId: String, Version: String) {
        
        if (ATDatabaseManager.doesExistDeviceManifestInfo(deviceTypeId: deviceTypeId, version: Version)) {
            return
        }
        
        let apiInstance = ACDeviceTypesApi()
       // print("Getting device manifest for \(deviceTypeId) and \(Version)")
        
        apiInstance.getManifestProperties(withDeviceTypeId: deviceTypeId, version: Version, completionHandler:  { (output : ACManifestPropertiesEnvelope?, error: Error?) in
            
            if error != nil {
                print("Error calling getDeviceManifest: \(error)")
                return
            }
            
            if output != nil {
                ATDatabaseManager.insertDeviceManifest(deviceTypeId: deviceTypeId, version: Version, deviceManifest: (output?.data)! as ACManifestProperties)

                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "fetch_manifest_data"), object: nil)
            }
            
        })
        
    }

    /**
     Get Device Message Snapshot
     https://developer.artik.cloud/documentation/api-reference/rest-api.html#get-message-snapshots
     */
    
    func getDeviceSnapshot(devices : String) {
    
        let apiInstance = ACMessagesApi()
        
        apiInstance.getMessageSnapshots(withSdids: devices, includeTimestamp: true, completionHandler :  { ( output: ACSnapshotResponses?, error : Error?) in
            
            if error != nil {
                print("Error calling getDeviceSnapshot: \(error)")
                return
            }
            
            if output != nil {
                
                let responses = (output?.data)! as! [ACSnapshotResponse]
                for snapshot in responses {
                    ATDatabaseManager.insertDeviceSnapshot(snapshotResponse: snapshot)

                    /* Update lastSeen on Device Table */
                    ATDatabaseManager.updateDevicePresence(deviceId: snapshot.sdid!, lastSeen: self.findLatestTimeStamp(data: snapshot.data))
                }

                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "fetch_snapshot"), object: nil)
            }
            
        })
        
    }

    func findLatestTimeStamp(data : [String : NSObject]) -> Int64 {

        var maxTimeStamp =  Int64(-1);

        for (_, value) in data {
            let field = value as! NSDictionary
            var ts = Int64(-1)
            if field.object(forKey: "ts") != nil {
                ts = field.object(forKey: "ts") as! Int64
            } else {
             ts = findLatestTimeStamp(data: value as! [String : NSObject])
            }
            if ts > maxTimeStamp {
                maxTimeStamp = ts
            }
        }

        return maxTimeStamp
    }

    /**
     Get Last Messages 
     https://developer.artik.cloud/documentation/api-reference/rest-api.html#get-last-normalized-messages
     */
    func getLastMessages(deviceId: String, count: Int) {

        let apiInstance = ACMessagesApi()

        apiInstance.getLastNormalizedMessages(withCount: count as NSNumber!, sdids: deviceId, fieldPresence: nil, completionHandler:  { (output : ACNormalizedMessagesEnvelope?, error :Error?) in
            if error != nil {
                print("Error calling getLastMessages: \(error)")
                return
            }

            if output != nil {
                let messages = (output?.data)! as! [ACNormalizedMessage]
                for message in messages {
                    ATDatabaseManager.insertLastNormalizedMessage(response: message)
                    ATDatabaseManager.updateDevicePresence(deviceId: message.sdid!, lastSeen: Int64(message.ts!))
                }
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refresh"), object: nil)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refresh_presence"), object: nil)
            }
        })

    }

    /**
     Post an action
     https://developer.artik.cloud/documentation/api-reference/rest-api.html#post-a-message-or-action
     */

    func postActions (name: String, ddid: String, parameters: [String : NSObject]) {

        let apiInstance = ACMessagesApi()

        let actions = ACActions()

        actions.ddid = ddid
        actions.type = "action"
        let data = ACActionArray()
        var actionList = [ACAction]()
        let action = ACAction()
        action.name = name
        action.parameters = parameters
        actionList.append(action)
        data.actions = actionList as [Any]
        actions.data = data

        apiInstance.sendActions(withData: actions, completionHandler:  { (output : ACMessageIDEnvelope?, error : Error?) in

            if error != nil {

                print("Failed to post the action. \(error)")
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "action_failed"), object: nil)

                return
            }
            print("Sending Action Success")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "action_success"), object: nil)
        })

    }

    /**
     Get Last Action 
     https://developer.artik.cloud/documentation/api-reference/rest-api.html#get-normalized-actions
     */

    func getLastActions(deviceId: String) {

        let apiInstance = ACMessagesApi()
        let start : Int64 = 1483264528016 // 1 year ago
        let startDate = NSNumber(value: start)
        let endDate = Int64(Date().timeIntervalSince1970 * 1000) as NSNumber
        apiInstance.getNormalizedActions(withUid: nil, ddid: deviceId, mid: nil, offset: nil, count: 1, startDate: startDate, endDate: endDate, order: "desc", completionHandler:  { (output: ACNormalizedActionsEnvelope?, error:Error?) in
            if error != nil {
                print("Error calling getLastActions: \(error)")
                return
            }

            if output != nil {
                let actions = (output?.data)! as! [ACNormalizedAction]
                for action in actions {
                    ATDatabaseManager.updateDevicePresence(deviceId: deviceId, lastSeen: Int64(action.ts!))
                }
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refresh_presence"), object: nil)
            }
        })

    }

    /**
     This API is not used currently
     */

    func getDeviceProperties(deviceId : String) {

        let apiInstance = ACDevicesManagementApi()

        apiInstance.getPropertiesWithDid(deviceId, includeTimestamp: true, completionHandler:  { (output : ACMetadataEnvelope?, error:Error?) in

            if error != nil {
                print("Error calling deviceProperties: \(error)")
                return
            }

            if output != nil {
                print("Device Properties \(output?.data)")
            }

        })

    }

    /**
     Get User Properties
     https://developer.artik.cloud/documentation/api-reference/rest-api.html#get-a-users-application-properties
     */
    func getUserProperties(forUserId userId: String) {
        let apiInstance = ACUsersApi()
        apiInstance.getUserProperties(withUserId: userId, aid: Constants.CLIENT_ID, completionHandler: {(_ output: ACPropertiesEnvelope?, _ error: Error?) -> Void in
            
            if output != nil {
                print("ACUsersApi->getUserProperties: \(output)")
                
                do {
                    let propertiesJsonArray = try JSONSerialization.jsonObject(with: (output?.data.properties.data(using: .utf8))!, options: []) as! [[String: String]]
                    
                    for propertyDic in propertiesJsonArray {
                        self.userProperties.append(propertyDic)
                    }
                    
                    self.isUserPropertiesCreated = true
                    print("userProperties = \(self.userProperties)")
                    ATUtilities.hideIndicator()
                }
                catch {
                }
            }
            
            if (error != nil) {
                print("Error calling ACUsersApi->getUserProperties: \(error?.localizedDescription)")
            }
        })
    }

    /**
     Get Device Presence
     https://developer.artik.cloud/documentation/api-reference/rest-api.html#get-device-presence
     */
    func getDevicePresence (deviceId : String) {

        let apiInstance = ACDevicesApi()
        apiInstance.getDevicePresence(withDeviceId: deviceId, completionHandler:  { ( output: ACPresenceEnvelope?, error : Error?) in

            if error != nil {
                print("Error in Device Presence API \(error)")
                return
            }

            if output != nil {

                let lastSeenOn = output?.data?.lastSeenOn as! Int64
                ATDatabaseManager.updateDevicePresence(deviceId: (output?.sdid!)!, lastSeen: lastSeenOn)
                print("Updating Device presence with \(lastSeenOn)")

                if (lastSeenOn != -1) {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refresh_presence"), object: nil)
                } else {
                    /* This device does not have presence field. So, try to get last message and last action */
                    self.getDeviceSnapshot(devices: deviceId)
                    self.getLastActions(deviceId: deviceId)
                }
            }

        })

    }

    /**
     This function does not work due to library issues. Use addDeviceToArtikCloud() instead
     */
    func addDeviceToCloud( name: String, dtid: String) {

        let apiInstance = ACDevicesApi()
        let device = ACDevice()

        device.dtid = dtid
        device.name = name
        device.uid = KeychainWrapper.standard.string(forKey: Constants.USER_ID)!
        device.manifestVersionPolicy = "LATEST"

        print("Device to be created \(device)")
        apiInstance.apiClient.setHeaderValue("application/json", forKey: "Content-Type")
        apiInstance.addDevice(with: device, completionHandler:  { (output: ACDeviceEnvelope?, error : Error?) in

            if error != nil {
                print("Error in Device Create API \(error)")
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "device_creation_failed"), object: nil)
                return
            }

            if output?.data != nil {
                let module = (output?.data)! as ACDevice
                self.generateDeviceToken(did: module._id)
            }

        })

    }

    /**
     Add Device to Artik Cloud
     https://developer.artik.cloud/documentation/api-reference/rest-api.html#create-a-device
     */
    func addDeviceToArtikCloud(name: String, dtid: String) {

        let url = "https://api.artik.cloud/v1.1/devices"

        var parametersDictionary = [AnyHashable: Any]()
        parametersDictionary["uid"] = KeychainWrapper.standard.string(forKey: Constants.USER_ID)!
        parametersDictionary["name"] = name
        parametersDictionary["dtid"] = dtid
        parametersDictionary["manifestVersionPolicy"] = "LATEST"

        let manager = AFHTTPSessionManager()
        manager.responseSerializer = AFJSONResponseSerializer()
        manager.requestSerializer = AFJSONRequestSerializer()
        manager.requestSerializer.setValue("Bearer " + KeychainWrapper.standard.string(forKey: Constants.ACCESS_TOKEN)!, forHTTPHeaderField: "Authorization")

        manager.post(url, parameters: parametersDictionary, progress: nil, success: {(_ task: URLSessionDataTask, _ responseObject: Any) -> Void in

            print("JSON: \(responseObject)")

            let json = responseObject as! [AnyHashable: Any]
            let data = json["data"] as! [AnyHashable: Any]
            self.generateDeviceToken(did: data["id"] as! String)

        }, failure: {(operation: URLSessionTask?, error: Error) -> Void in
            print("Error: \(error)")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "device_creation_failed"), object: nil)
        })

    }

    /**
     Generate Device Token 
     https://developer.artik.cloud/documentation/api-reference/rest-api.html#create-device-token
     */

    func generateDeviceToken( did : String ) {

        let apiInstance = ACDevicesApi()
        apiInstance.updateDeviceToken(withDeviceId: did, completionHandler:  { (output: ACDeviceTokenEnvelope?, error: Error?) in

            if error != nil {
                print("Error in Device Token API \(error)")
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "device_creation_failed"), object: nil)
                return
            }

            if output?.data != nil {
                let device = (output?.data)! as ACDeviceToken
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "device_creation_success"), object: device)
            }

        })

    }


    /**
     Delete User Application Properties
     https://developer.artik.cloud/documentation/api-reference/rest-api.html#delete-a-users-application-properties
     */

    func deleteUserProperties() {
        let apiInstance = ACUsersApi()
        apiInstance.deleteUserProperties(withUserId: KeychainWrapper.standard.string(forKey: Constants.USER_ID), aid: nil, completionHandler: {(_ output: ACPropertiesEnvelope?, _ error: Error?) -> Void in
            if output != nil {
                print("Deleted user properties")
            }
            if (error != nil) {
                print("Couldn't delete user properties")
            }
            
        })
    }



    /// This function confirms the Pin obtained through secure device registration
    ///
    /// - Parameters:
    ///   - deviceName:
    ///   - pin: 
    func confirmUser(deviceName: String, pin: String) {
        let apiInstance = ACRegistrationsApi()
        let registrationInfo = ACDeviceRegConfirmUserRequest() // Device Registration information.
        //Mandatory field
        registrationInfo.pin = pin
        registrationInfo.deviceName = deviceName

        print("registrationInfo = \(registrationInfo)")
        apiInstance.confirmUser(withRegistrationInfo: registrationInfo, completionHandler: {(output: ACDeviceRegConfirmUserResponseEnvelope?, error: Error?) -> Void in

            if (output != nil) {
                print("Confirm user resp: \(output)")
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "confirm_user_success"), object: nil)
            }
            if (error != nil) {
                print("Error  \(error?.localizedDescription)")
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "device_creation_failed"), object: nil)
            }
        })

    }

    /**
     This function stores the module used in the Device Control Panel
     */
    func selectedDevice( module : Module) {
        selectedModule = module;
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
}

