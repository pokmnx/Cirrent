//
//  AppDelegate.swift
//  Cirrent_New
//
//  Created by PSIHPOK on 12/17/16.
//  Copyright © 2016 PSIHPOK. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    
    var bShouldCheckSoftAP:Bool = false
    let SoftAP_NOTIFICATION = "SoftAPNotification"
    static var SoftAPBeforeSSID:String? = nil
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        CirrentService.sharedService.supportSoftAP(bSupport: true)
        IQKeyboardManager.sharedManager().enable = true
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: {
            granted, error in
            
            if granted {
                UNUserNotificationCenter.current().delegate = self
            }
        })
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        SampleCloudService.sharedService.getToken(tokenType: .ANY, deviceID: nil, completion: {
            token in
            
            LogService.sharedService.putLog(token: token)
        })
        
        if bShouldCheckSoftAP == true {
            CirrentService.sharedService.stopAllAction()
            checkSoftAPInBackground()
        }
    }
    
    var bgTask:UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var checkSoftAPTimer:Timer!
    
    func checkSoftAPInBackground() {
        bgTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.bgTask)
            self.bgTask = UIBackgroundTaskInvalid
        })
        
        checkSoftAPTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: {
            timer in
            
            let ssid = CirrentService.sharedService.getCurrentSSID()
            print ("checking softap ssid")
            if ssid != nil && ssid! == CirrentService.sharedService.SoftAPSSID {
                // did we get an IP address?
                
                let address : String? = NetworkTool.getWifiAddress()
                if address == nil {
                    LogService.sharedService.debug(data: "No IP address yet, so wait")
                    return;
                }
                else {
                    LogService.sharedService.debug(data: "SoftAP IP Address:" + address!)
                }

                let content = UNMutableNotificationContent()
                content.title = NSString.localizedUserNotificationString(forKey:
                    "Return To Cirrent App", arguments: nil)
                content.body = NSString.localizedUserNotificationString(forKey:
                    "Tap here to return to the Cirrent app to complete the setup for your product.", arguments: nil)
                content.sound = UNNotificationSound.default()
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1,
                                                                repeats: false)
                // Schedule the notification.
                let request = UNNotificationRequest(identifier: "SoftApLocalNotification", content: content, trigger: trigger)
                let center = UNUserNotificationCenter.current()
                center.add(request, withCompletionHandler: nil)
                timer.invalidate()
            }
        })
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

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        if bShouldCheckSoftAP == true {
            checkSoftAPAndRun()
        }
/* LEAVE OUT FOR NOW AS THE SDK WILL TAKE CARE OF THIS
        SuccessViewController.bindUnBoundDevices(completion: {
            bSuccess in
            
            if bSuccess == true {
                print ("unbound device success")
            }
            else {
                print ("unbound device failed")
            }
        })
 */
    }
    
    func checkSoftAPAndRun() {
        if checkSoftAPTimer != nil {
            checkSoftAPTimer.invalidate()
        }
        
        let ssid:String? = CirrentService.sharedService.getCurrentSSID()
        if ssid!.contains(CirrentService.sharedService.SoftAPSSID) == true {
            let SoftAPNotify = Notification.Name(SoftAP_NOTIFICATION)
            NotificationCenter.default.post(name: SoftAPNotify, object: nil)
            LogService.sharedService.putLog(token: nil)
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func getStoryboard() -> UIStoryboard {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard
    }
    
    func changeViewController(controller:UIViewController) {
        
        self.window?.rootViewController = controller
        self.window?.makeKeyAndVisible()
    }
    
    func moveToLoginController() {
        let loginNavController = getStoryboard().instantiateViewController(withIdentifier: "LoginNavController")
        changeViewController(controller: loginNavController)
    }
    
    func moveToConfigureController() {
        let configureNavController = getStoryboard().instantiateViewController(withIdentifier: "ConfigureNavController")
        changeViewController(controller: configureNavController)
    }
    
    func moveToManageNetworkController() {
        let networkController:UINavigationController = getStoryboard().instantiateViewController(withIdentifier: "manageNetworkNavController") as! UINavigationController
        let menuController:UINavigationController = getStoryboard().instantiateViewController(withIdentifier: "MenuController") as! UINavigationController
        let slideMenuController = SlideMenuController(mainViewController: networkController, rightMenuViewController: menuController)
        slideMenuController.automaticallyAdjustsScrollViewInsets = true
        changeViewController(controller: slideMenuController)
    }
    
    func moveToMainController() {
        let mainNavController:UINavigationController = getStoryboard().instantiateViewController(withIdentifier: "StartNavController") as! UINavigationController
        let menuController:UINavigationController = getStoryboard().instantiateViewController(withIdentifier: "MenuController") as! UINavigationController
        let slideMenuController = SlideMenuController(mainViewController: mainNavController, rightMenuViewController: menuController)
        slideMenuController.automaticallyAdjustsScrollViewInsets = true
        changeViewController(controller: slideMenuController)
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
}

