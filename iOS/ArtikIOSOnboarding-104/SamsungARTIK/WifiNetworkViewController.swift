//
//  WifiNetworkViewController.swift
//  SamsungARTIK
//
//  Created by alimi shalini on 12/6/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit
import CoreBluetooth
import ArtikCloud
import SwiftKeychainWrapper


class WifiNetworkViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,
    WifiPopOverDelegate, WifiOnboardingProtocol, ATAlertViewDelegate, Artik0OnboardingDelegate {
    
    static let STATE_WIFI_SETUP_INIT: Int = 0
    static let STATE_WIFI_CONNECTED: Int = 1
    static let STATE_GOT_IP_ADDRESS: Int = 2
    static let STATE_START_REGISTRATION: Int = 3
    static let STATE_REQUESTED_PIN: Int = 4
    static let STATE_RECIEVED_PIN: Int = 5
    static let STATE_COMPLETE_REGISTRATION: Int = 6
    
    @IBOutlet weak var noDataSubLabel: UILabel!
    @IBOutlet weak var NoDataMainLabel: UILabel!
    @IBOutlet weak var titleTextField: TitlesTextField!
    @IBOutlet weak var wifiNetworkTableView: UITableView!
    @IBOutlet weak var refreshButton: CustomButton!
    @IBOutlet weak var cancelButton: CustomButton!
    
    var alertView: ATAlertView!
    var wifiPopOverView: WifiPasswordPopOverView!
    var onBoardingService: WifiOnboardingService!
    var wifiSSIDDictionary = [AnyHashable: String]()
    var wifiListArray = [Any]()
    var count: Int = 0
    var dId: String!
    var deviceIp: String!
    var deviceId: String!
    var startedRegistration: Bool!
    var pinRequested: Bool!
    var detailSubscribed: Bool!
    var registrationState: Int!
    var ssid: String!
    var registrationFailureReason = ""
    var isWifiAlertPresent: Bool = false    //Internet pop-up
    var isRegistrationInProgress: Bool = false
    var isBluetoothAlertPresent: Bool = false
    var isPasswordViewPresent: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.view.backgroundColor = Constants.backgroundWhiteColor
        
        wifiNetworkTableView.register(UINib(nibName: "WifiNetworkTableViewCell", bundle: nil), forCellReuseIdentifier: "WifiNetworkTableViewCell")
        wifiNetworkTableView.tableFooterView = UIView()
        wifiNetworkTableView.separatorColor = UIColor.gray
        wifiNetworkTableView.layoutMargins = UIEdgeInsets.zero
        wifiNetworkTableView.separatorInset = UIEdgeInsets.zero
        
        registrationState = 0
        detailSubscribed = false
        
        refreshButton.setImage(#imageLiteral(resourceName: "ATRefreshHighlated"), for: .highlighted)
        cancelButton.setImage(#imageLiteral(resourceName: "ATCancelHighlated"), for: .highlighted)
        
        self.addObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        ATUtilities.showIndicator(message: NSLocalizedString("Fetching available Wi-Fi networks...", comment: ""))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300), execute: {
            self.onBoardingService = BLEManager.sharedInstance.getService()
            if self.onBoardingService != nil {
                self.count = 0
                self.onBoardingService.readCharacteristic(Constants.WIFI_DATA_CHARACTERISTIC_UUID)
            }
            else {
                print("Onboarding service is nil")
            }
            self.networkChange()
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        self.removeObservers()
        registrationFailureReason = ""
        wifiSSIDDictionary = [AnyHashable: String]()
        count = 0
        isBluetoothAlertPresent = false
    }
    
    func networkChange() {
        if isBluetoothAlertPresent == false && isRegistrationInProgress == false {
            
            if ATReachability.sharedInstance.isNetworkReachable == true {
                if isWifiAlertPresent == true {
                    if alertView != nil {
                        self.hideAlert()
                    }
                    isWifiAlertPresent = false
                }
            }
            else {
                if isPasswordViewPresent == true {
                    wifiPopOverView.removeFromSuperview()
                }
                isWifiAlertPresent = true
                self.showAlert(message: NSLocalizedString("No internet connection. Please connect to internet to register module.", comment: ""))
            }
        }
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.onWifiDataRead), name: NSNotification.Name(rawValue: "Wifi_Data_Read"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(networkChange), name: NSNotification.Name(rawValue: Constants.NETWORK_CONNECTION_CHANGED), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.moduleDisconnectedNotificationAction), name: NSNotification.Name(rawValue: "module_disconnected_or_poweredoff"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onDtidRead), name: NSNotification.Name(rawValue: Constants.NOTIF_DTID_READ), object: nil)

    }

    func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func moduleDisconnectedNotificationAction() {
        if wifiPopOverView != nil {
            wifiPopOverView.removeFromSuperview()
            isRegistrationInProgress = false
        }
        if alertView != nil {
            alertView.removeFromSuperview()
        }
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "module_disconnected_or_poweredoff"), object: nil)
        ATUtilities.hideIndicator()
        isWifiAlertPresent = false
        isBluetoothAlertPresent = true
        self.showAlert(message: NSLocalizedString("Bluetooth connection failed.", comment: ""))
    }
    
    func showTurnOnBluetoothAlert() {
        if wifiPopOverView != nil {
            wifiPopOverView.removeFromSuperview()
        }
        
        //Navigating to Plug-in(ArtikModuleIdentified) view when bluetooth is turned off
        
        BLEManager.sharedInstance.disconnectPeripheral((BLEManager.sharedInstance.discoveredPeripheral)!)
        BLEManager.sharedInstance.peripheralDelegate = nil
        BLEManager.sharedInstance.dispose()
        
        self.showAlert(message: NSLocalizedString("Bluetooth turned off.", comment: ""))
        _ = self.navigationController?.popToViewController((self.navigationController?.viewControllers[2])!, animated: true)
    }
    
    func hideBluetoothAlert() {
        self.hideAlert()
    }
    
    @IBAction func refreshAction(_ sender: Any) {
        
        if onBoardingService != nil {
            wifiListArray.removeAll()
            count = 0
            wifiSSIDDictionary = [AnyHashable: String]()
            
            if wifiListArray.count == 0 {
                NoDataMainLabel.isHidden = false
                noDataSubLabel.isHidden = false
            }
            else {
                NoDataMainLabel.isHidden = true
                noDataSubLabel.isHidden = true
            }
            
            wifiNetworkTableView.reloadData()
            ATUtilities.showIndicator(message:"Fetching available Wi-Fi networks...")
            onBoardingService.readCharacteristic(Constants.WIFI_DATA_CHARACTERISTIC_UUID)
        }
    }
    
    func appDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    // MARK: - TableView Delegates
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row % 2 == 0 {
            return 50 //cell height
        }
        else {
            return 0.5 //space heigh
        }
    }
    
    func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        return wifiListArray.count*2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Instantiate a cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "WifiNetworkTableViewCell", for: indexPath) as! WifiNetworkTableViewCell
        cell.layoutMargins = UIEdgeInsets.zero
        cell.backgroundColor = UIColor.clear
        //cell.selectionStyle = UITableViewCellSelectionStyle.none
        tableView.separatorStyle = .none
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = Constants.listColor
        cell.selectedBackgroundView = bgColorView
        
        if indexPath.row % 2 == 0 {
//            cell.backgroundColor = Constants.listColor
            cell.layer.cornerRadius = 5
            
            let wifiDict = wifiListArray[indexPath.row/2] as! [String: String]
            cell.titleLabel.text = wifiDict["ssidName"]
            
            if wifiDict["security"] == "Open" {
                cell.cellImageView.isHidden = true
            }
            else {
                cell.cellImageView.isHidden = false
            }
        }
        else {
            cell.backgroundColor = UIColor(colorLiteralRed: 151/255.0, green: 151/255.0, blue: 151/255.0, alpha: 1)
            cell.titleLabel.text = ""
            cell.cellImageView.isHidden = true
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row % 2 == 0 {
            BLEManager.sharedInstance.peripheralDelegate = self
            onBoardingService = BLEManager.sharedInstance.getService()
            onBoardingService.delegate = self
            startedRegistration = false
            pinRequested = false
            
            let wifiDict = wifiListArray[indexPath.row/2] as! [String: String]
            
            if wifiDict["security"] == "Open" {
                isPasswordViewPresent = false
            }
            else {
                isPasswordViewPresent = true
            }
            
            ssid = wifiDict["ssidName"]
            wifiPopOverView = WifiPasswordPopOverView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height), ssid: ssid, security: wifiDict["security"]!)
            wifiPopOverView.backgroundColor = UIColor.clear
            wifiPopOverView.onBoardingService = self.onBoardingService
            self.view.addSubview(wifiPopOverView)
            wifiPopOverView.delegate = self
            
            wifiPopOverView.translatesAutoresizingMaskIntoConstraints = false
            
            let subviewsDict: Dictionary = ["popOverView": wifiPopOverView];
            
            let arrXconstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[popOverView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
            self.view.addConstraints(arrXconstraints)
            
            let arrYconstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[popOverView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
            self.view.addConstraints(arrYconstraints)
        }
    }
    
    func showAlert(message: String) {
        if alertView != nil {
            alertView.removeFromSuperview()
        }
        alertView = ATAlertView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height), message: message , cancelButtonTitle: NSLocalizedString("OK", comment: ""), confirmButtonTitle: "")
        alertView.delegate = self
        alertView.tag = 454545
        alertView.backgroundColor = UIColor.clear
        
        self.view.addSubview(alertView)
        
        alertView.translatesAutoresizingMaskIntoConstraints = false
        
        let subviewsDict: Dictionary = ["alertView": alertView];
        
        let arrXconstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[alertView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.view.addConstraints(arrXconstraints)
        
        let arrYconstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[alertView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.view.addConstraints(arrYconstraints)
    }
    
    @IBAction func cancelButtonAction(_ sender: Any) {
        BLEManager.sharedInstance.disconnectPeripheral((BLEManager.sharedInstance.discoveredPeripheral)!)
        BLEManager.sharedInstance.peripheralDelegate = nil
        BLEManager.sharedInstance.dispose()
        _ = navigationController?.popToRootViewController(animated: true)
    }
    
    
    // MARK: - WifiPopOver delegates
    
    func removeWifiPopover() {
        wifiPopOverView.removeFromSuperview()
        isRegistrationInProgress = false
        isPasswordViewPresent = false
    }
    
    // MARK: - ATAlertView delegates
    func hideAlert() {
        if isWifiAlertPresent == true {
            alertView.removeFromSuperview()
            isWifiAlertPresent = false
        }
        else {
            //Navigating to dashboard if ARTIK module disconnected or bluetooth range exceeds.
            if registrationFailureReason == "" || isBluetoothAlertPresent == true {
                if BLEManager.sharedInstance.discoveredPeripheral != nil {
                    BLEManager.sharedInstance.disconnectPeripheral((BLEManager.sharedInstance.discoveredPeripheral)!)
                    BLEManager.sharedInstance.peripheralDelegate = nil
                    BLEManager.sharedInstance.dispose()
                }
                
                alertView.removeFromSuperview()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300), execute: {
                    _ = self.navigationController?.popToViewController((self.navigationController?.viewControllers[2])!, animated: true)
                })
                
            }
            else {
                onBoardingService.notifyCharacteristic(Constants.DETAILED_STATUS_CHARACTERISTIC_UUID, value: false)
                BLEManager.sharedInstance.disconnectPeripheral((BLEManager.sharedInstance.discoveredPeripheral)!)
                BLEManager.sharedInstance.peripheralDelegate = nil
                BLEManager.sharedInstance.dispose()

                _ = navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
    func showRegisteredModuleViewController(dId: String, deviceIp: String) {
        
        wifiPopOverView.removeFromSuperview()
        let registeredModuleControllerObj = self.storyboard!.instantiateViewController(withIdentifier: "RegisteredModuleViewController") as! RegisteredModuleViewController
        registeredModuleControllerObj.deviceId = dId
        registeredModuleControllerObj.ipaddress = deviceIp
        
        if self.navigationController == nil {
            let nvc = self.storyboard!.instantiateViewController(withIdentifier: "dashBoardNavigationController") as! UINavigationController
            nvc.pushViewController(registeredModuleControllerObj, animated: true)
        }
        else {
            self.navigationController!.pushViewController(registeredModuleControllerObj, animated: true)
        }
    }
    
    func joinWifiNetwork(password: String) {
        
        let authType = "SECURE"
        if ssid.characters.count == 0 {
            return
        }
        
        if onBoardingService == nil {
            print("WifiOnboardingService is nil! Sorry cannot proceed to set wifi")
            return
        }
        registrationState = WifiNetworkViewController.STATE_WIFI_SETUP_INIT
        
        isRegistrationInProgress = true
        isPasswordViewPresent = false
        
        if detailSubscribed == true {
            onBoardingService.notifyCharacteristic(Constants.DETAILED_STATUS_CHARACTERISTIC_UUID, value: false)
            detailSubscribed = false
        }
        print("Writing wifi ssid  \(ssid)")
        onBoardingService.writeCharacteristic(Constants.SSID_CHARACTERISTIC_UUID, value: ssid)
        print("Writing authmode  ")
        onBoardingService.writeCharacteristic(Constants.AUTH_CHARACTERISTIC_UUID, value: authType)
        print("Writing password  ")
        onBoardingService.writeCharacteristic(Constants.PASSPHRASE_CHARACTERISTIC_UUID, value: password)
        
        if detailSubscribed == false {
            onBoardingService.notifyCharacteristic(Constants.DETAILED_STATUS_CHARACTERISTIC_UUID, value: true)
            detailSubscribed = true
        }
    }
    
    
    //- notification selectors
    
    func onWifiDataRead(_ notification: Notification) {
        ATUtilities.hideIndicator()
        
        print("Data updated : \(String(data: onBoardingService.getWifiSSIDdata(), encoding: .utf8) )")
        
        var ssidDict: Any!
        
        do {
            ssidDict = try JSONSerialization.jsonObject(with: onBoardingService.getWifiSSIDdata(), options: [])
            
            let ssidName = (ssidDict as AnyObject).value(forKey: "ssid") as! String
            let bssidName = (ssidDict as AnyObject).value(forKey: "bssid") as! String
            let security = (ssidDict as AnyObject).value(forKey: "security") as! String
            
            if !ssidName.isEqual("end") && !bssidName.isEqual("end") && count < 100 {
                if wifiSSIDDictionary[ssidName]  == nil {
                    ATUtilities.hideIndicator()
                    var wifiDataDict = [String: String]()
                    wifiDataDict["ssidName"] = ssidName
                    wifiDataDict["security"] = security
                    
                    wifiSSIDDictionary[ssidName] = bssidName
                    wifiListArray.append(wifiDataDict)
                    print("Wifidata Recieved: \(ssidName)")
                    
                    if wifiListArray.count == 0 {
                        NoDataMainLabel.isHidden = false
                        noDataSubLabel.isHidden = false
                    }
                    else
                    {
                        NoDataMainLabel.isHidden = true
                        noDataSubLabel.isHidden = true
                    }
                    wifiNetworkTableView.reloadData()
                }
                onBoardingService.readCharacteristic(Constants.WIFI_DATA_CHARACTERISTIC_UUID)
            }
            else {
                
            }
            count += 1
            
        } catch let error as NSError {
            print("Could not parse. \(error)")
        }
        
    }

    func onDtidRead(_ notification : Notification) {

        let result = onBoardingService.deviceTypeId.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        if result == Constants.ARTIK_5_DTID || result == Constants.ARTIK_7_DTID {
            /* Secure Device Type - Proceed with SDR flow */
            print("This is a secure device type")
            startSecureDeviceRegistration()
        } else {
            /* Classic On-boarding using ENM */
            if registrationState != WifiNetworkViewController.STATE_START_REGISTRATION {
                print("Proceed with classic onboarding")
                registrationState = WifiNetworkViewController.STATE_START_REGISTRATION
                startClassicOnboarding(withIPAddress: onBoardingService.ipAddress)
            }
        }


    }

    // MARK: - WifiOnboardingProtocol
    
    func stateChanged(_ state: String) {
        print("Status changed: \(state)")
        let result = state.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if result.caseInsensitiveCompare("Invalid Token") == .orderedSame {
            self.registrationFailure(result)
        }
        else if result.caseInsensitiveCompare("Invalid SSID") == .orderedSame {
            isWifiAlertPresent = true
            if detailSubscribed == true {
                onBoardingService.notifyCharacteristic(Constants.DETAILED_STATUS_CHARACTERISTIC_UUID, value: false)
                detailSubscribed = false
            }
        }
        else if result.caseInsensitiveCompare("Invalid Password") == .orderedSame {
            if detailSubscribed == true {
                onBoardingService.notifyCharacteristic(Constants.DETAILED_STATUS_CHARACTERISTIC_UUID, value: false)
                detailSubscribed = false
            }
            
            isWifiAlertPresent = true
            //Hide wifi popover and show alert view
            self.removeWifiPopover()
            self.showAlert(message: NSLocalizedString("Wi-Fi connection failed. Invalid Password.", comment: ""))
        }
        else if result.caseInsensitiveCompare("Registeration Error") == .orderedSame {
            self.registrationFailure(result)
        }
        else if startedRegistration == false {
            self.handleEvent(state.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
        }
        else if startedRegistration == true {
            if registrationState < WifiNetworkViewController.STATE_START_REGISTRATION {
                
                let userInfo = ["response": "wifi_connected"]
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "join_wifi_network_response"), object: nil, userInfo: userInfo)
                self.getModuleInformation()
            }
            self.handleRegistrationEvents(result)
        }
    }
    
    func onBoardingService(service: WifiOnboardingService) {
        onBoardingService = service
    }
    
    // MARK: -
    
    func handleEvent(_ message: String) {
        if (message == "COMPLETED") {
        }
        else if (message == "Connection completed") {
            onBoardingService.readCharacteristic(Constants.IPADDRESS_CHARACTERISTIC_UUID)
            startedRegistration = true
        }
    }
    
    func handleRegistrationEvents(_ event: String) {
        
        if (event == "Received Token") {
            self.finalizeRegistration()
        }
        else if (event == "Registeration Error") {
            self.registrationFailure(event)
        }
        else {
            if (event == "Received Challenge") && registrationState == WifiNetworkViewController.STATE_START_REGISTRATION {
                onBoardingService.readCharacteristic(Constants.CHALLENGE_PIN_CHARACTERISTIC_UUID)
                registrationState = WifiNetworkViewController.STATE_RECIEVED_PIN
            }
            else if registrationState == WifiNetworkViewController.STATE_RECIEVED_PIN {
                self.sendPinToCloud(pin: event)
                registrationState = WifiNetworkViewController.STATE_COMPLETE_REGISTRATION
            }
            else if registrationState == WifiNetworkViewController.STATE_COMPLETE_REGISTRATION {
                print("Completed Registartion process successfully.")
            }
        }
    }
    
    /**
     Called after recieving AUTH_TOKEN from the artik device. We read the device id here
     */
    
    func finalizeRegistration() {
        onBoardingService.readCharacteristic(Constants.DID_CHARACTERISTIC_UUID)
        //device_id
    }
    
    func registrationFailure(_ reason: String) {
        print("reason = \(reason)")
        
        if wifiPopOverView != nil {
            wifiPopOverView.removeFromSuperview()
            isRegistrationInProgress = false
        }
        
        if reason == "resource unavailable" {
            registrationFailureReason = "resource unavailable"
            self.showAlert(message: NSLocalizedString("Registration Failed. No or Low connectivity", comment: ""))
        }
        else if reason == "Registeration Error" {
            registrationFailureReason = "Registeration Error"
            self.showAlert(message: NSLocalizedString("Registration Failed", comment: ""))
        }
        else {
            registrationFailureReason = "Registeration Error"
            self.showAlert(message: NSLocalizedString("Registration Failed", comment: ""))
        }
    }
    
    /*
     After wifi setup is complete and artik obtains ip address, we call this to start Registraion by setting START_REG_CHARACTERISTIC_UUID to 1
     */
    
    func startSecureDeviceRegistration() {

        onBoardingService.writeCharacteristic(Constants.START_REG_CHARACTERISTIC_UUID, value: "1") //start reg
        registrationState = WifiNetworkViewController.STATE_START_REGISTRATION

    }

    func startClassicOnboarding(withIPAddress ipa: String) {

        let onboardingService = Artik0OnboardingService()
        onboardingService.onBoardingDelegate = self
        onboardingService.ipaddress = ipa
        onboardingService.dtid = onBoardingService.deviceTypeId
        var dataDic = UserDefaults.standard.object(forKey:Constants.MODULE_AND_LOCATION_DICTIONARY)! as! [String:Any]
        let moduleName = (dataDic[Constants.MODULE_NAME] as! String)

        onboardingService.startOnboarding(ATUtilities.artikSecondaryMac, name: moduleName)

    }

    // MARK: - Artik0OnboardingDeleage

    func didOnboardArtik0() {
        self.showRegisteredModuleViewController()
    }

    func showRegisteredModuleViewController() {

        let registeredModuleControllerObj = self.storyboard!.instantiateViewController(withIdentifier: "RegisteredModuleViewController") as! RegisteredModuleViewController
        registeredModuleControllerObj.deviceType = 1
        self.navigationController!.pushViewController(registeredModuleControllerObj, animated: true)

    }


    func onboardingFailed(_ message: String) {
        self.showAlert(message: message)
    }


    func getModuleInformation() {
        onBoardingService.readCharacteristic(Constants.IPADDRESS_CHARACTERISTIC_UUID) //device_ip_address
        onBoardingService.readCharacteristic(Constants.DEVICE_TYPE_ID_CHARACTERISTIC_UUID) //device_type_id
    }
    
    /*
     After we sucessfully recieve success respone from the Artik cloud, we call this to complete registration
     */
    
    func completeRegistration() {
        onBoardingService.writeCharacteristic(Constants.COMPLETE_REG_CHARACTERISTIC_UUID, value: "1")
        //complete reg
        registrationState = WifiNetworkViewController.STATE_COMPLETE_REGISTRATION
    }
    
    /*
     When we recieve pin from Artik device, this method sends the pin to artik cloud and confirms the registration
     */
    func sendPinToCloud(pin: String) {
        let apiConfig = ACConfiguration.sharedConfig()
        let accessToken = KeychainWrapper.standard.string(forKey: Constants.ACCESS_TOKEN)!
        apiConfig?.accessToken = accessToken
        let registrationInfo = ACDeviceRegConfirmUserRequest() // Device Registration information.
        //Mandatory field
        registrationInfo.pin = pin
        
        var dataDic = UserDefaults.standard.object(forKey:Constants.MODULE_AND_LOCATION_DICTIONARY)! as! [String:Any]
        var moduleString = (dataDic[Constants.MODULE_NAME] as! String)
        var locationaString = (dataDic[Constants.LOCATION_NAME] as! String)
        
        if moduleString.characters.count <= 0 {
            moduleString = "Artik".appending(ATUtilities.getDeviceIdentifier())
            dataDic[Constants.MODULE_NAME] = moduleString
        }
        
        if locationaString.characters.count <= 0 {
            locationaString = Constants.UNSPECIFIED_LOCATION
            dataDic[Constants.LOCATION_NAME] = locationaString
        }
        
        let defaults = UserDefaults.standard
        defaults.set(dataDic, forKey:Constants.MODULE_AND_LOCATION_DICTIONARY)
        registrationInfo.deviceName = moduleString
        registrationInfo.deviceId = deviceId
        
        let apiInstance = ACRegistrationsApi()
        print("registrationInfo = \(registrationInfo)")
        
        apiInstance.confirmUser(withRegistrationInfo: registrationInfo, completionHandler: {(output: ACDeviceRegConfirmUserResponseEnvelope?, error: Error?) -> Void in
            
            if (output != nil) {
                print("Confirm user resp: \(output)")
                self.completeRegistration()
            }
            if (error != nil) {
                print("Error  \(error?.localizedDescription)")
                self.registrationFailure((error?.localizedDescription)!)
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
