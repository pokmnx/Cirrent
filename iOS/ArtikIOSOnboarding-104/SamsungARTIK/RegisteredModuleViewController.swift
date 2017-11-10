//
//  registeredModuleViewController.swift
//  SamsungARTIK
//
//  Created by alimi shalini on 12/7/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit
import ArtikCloud
import SwiftKeychainWrapper


class RegisteredModuleViewController: UIViewController {
    
    @IBOutlet weak var titleTextField: TitlesTextField!
    
    var deviceId: String!
    var ipaddress: String!
    var deviceType: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        titleTextField.text = NSLocalizedString("Module Registered successfully", comment: "")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)

        self.appDelegate().getModules(isFromPullDown: true)
        
    }
    
    func appDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    @IBAction func continueButtonAction(_ sender: Any) {
        self.appDelegate().isFirstTimeLogin = true
        
        if deviceType != nil && deviceType == 0 {
            
        }
        else {
            BLEManager.sharedInstance.disconnectPeripheral((BLEManager.sharedInstance.discoveredPeripheral)!)
            BLEManager.sharedInstance.peripheralDelegate = nil
            BLEManager.sharedInstance.dispose()

        }
        
        let dashBoardViewControllerObj = self.storyboard?.instantiateViewController(withIdentifier: "DashBoardViewController")
        self.navigationController?.pushViewController(dashBoardViewControllerObj!, animated: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        let dashBoardViewControllerObj = self.storyboard?.instantiateViewController(withIdentifier: "DashBoardViewController")
        self.navigationController?.viewControllers = [dashBoardViewControllerObj!]
    }
    
    func updateUserProperties(withDeviceId deviceId: String, ipaddress: String) {
        ATUtilities.showIndicator(message: "Updating IP address")
        
        let userId = KeychainWrapper.standard.string(forKey: Constants.USER_ID)
        var propertiesArray = [[String: String]]()
        
        let myDictionary = [
            Constants.USER_PROPERTIES_IPADDRESS_KEY : ipaddress,
            Constants.USER_PROPERTIES_DEVICE_ID_KEY : deviceId
        ]
        propertiesArray.append(myDictionary)
        
        var jsonData: Data!
        do {
            jsonData = try JSONSerialization.data(withJSONObject: propertiesArray, options: [.prettyPrinted])
        } catch {
        }
        
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        let properties = ACAppProperties()
        properties.uid = userId
        properties.properties = jsonString
        properties.aid = Constants.CLIENT_ID
        
        let apiInstance = ACUsersApi()
        
        apiInstance.updateUserProperties(withUserId: userId, properties: properties, aid: Constants.CLIENT_ID, completionHandler: {(_ output: ACPropertiesEnvelope?, _ error: Error?) -> Void in
            if (output != nil) {
                print("ACUsersApi->updateUserProperties:\(output)")
            }
            if (error != nil) {
//                let errorResponse: String = String(data: ((error as! NSError).userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] as! NSData) as Data, encoding: String.Encoding.utf8)!
                
                print("Error calling ACUsersApi->updateUserProperties: \(error?.localizedDescription)")
            }
            ATUtilities.hideIndicator()
        })
    }
    
    func createUserProperties(withDeviceId deviceId: String, ipaddress: String) {
        ATUtilities.showIndicator(message: "Updating IP address")
        
        let myDictionary = [
            Constants.USER_PROPERTIES_IPADDRESS_KEY : ipaddress,
            Constants.USER_PROPERTIES_DEVICE_ID_KEY : deviceId
        ]
        
        let arr = [myDictionary]
        
        var jsonData: Data!
        do {
            jsonData = try JSONSerialization.data(withJSONObject: arr, options: [.prettyPrinted])
        } catch {
            
        }
        
        let jsonString = String(data: jsonData, encoding: .utf8)
        let properties = ACAppProperties()
        
        // Properties to be updated
        let userId = KeychainWrapper.standard.string(forKey: Constants.USER_ID)!
        properties.uid = userId
        properties.properties = jsonString
        properties.aid = Constants.CLIENT_ID
        
        let apiInstance = ACUsersApi()
        
        apiInstance.createUserProperties(withUserId: userId, properties: properties, aid: Constants.CLIENT_ID, completionHandler: {(_ output: ACPropertiesEnvelope?, _ error: Error?) -> Void in
            if (output != nil) {
                print("ACUsersApi->createUserProperties: \(output)")
                self.appDelegate().isUserPropertiesCreated = true
            }
            if (error != nil) {
//                let errorResponse: String = String(data: ((error as! NSError).userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] as! NSData) as Data, encoding: String.Encoding.utf8)!
                print("Error calling ACUsersApi->createUserProperties: \(error?.localizedDescription)")
            }
            ATUtilities.hideIndicator()
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
