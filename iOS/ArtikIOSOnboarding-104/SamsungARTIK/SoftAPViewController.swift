//
//  SoftAPViewController.swift
//  SamsungARTIK
//
//  Created by Vaibhav Singh on 27/03/17.
//  Copyright © 2017 alimi shalini. All rights reserved.
//

import UIKit
import ArtikCloud

class SoftAPViewController: UIViewController, UITableViewDataSource,UITableViewDelegate, SoftAPOnboardingDelegate, ATAlertViewDelegate, WifiPopOverDelegate {

    enum OnboardingState {
        case connect_module
        case fetch_wifi_list
        case wifi_configured
        case find_module_local_wifi
        case register_cloud
    }


    var alertView: ATAlertView!
    var wifiPopOverView: WifiPasswordPopOverView!
    var state = OnboardingState.connect_module

    @IBOutlet weak var wifiListTableView: UITableView!

    var onboardingService : SoftAPOnboardingService!
    var mac : String!
    var isPasswordViewPresent: Bool = false
    var isWifiAlertPresent: Bool = false
    var ssid: String!


    override func viewDidLoad() {
        super.viewDidLoad()
        onboardingService = SoftAPOnboardingService()
        onboardingService.setMac(macAddress: mac)
        onboardingService.delegate = self

        self.view.backgroundColor = Constants.backgroundWhiteColor

        wifiListTableView.register(UINib(nibName: "WifiNetworkTableViewCell", bundle: nil), forCellReuseIdentifier: "WifiNetworkTableViewCell")
        wifiListTableView.tableFooterView = UIView()
        wifiListTableView.separatorColor = UIColor.gray
        wifiListTableView.layoutMargins = UIEdgeInsets.zero
        wifiListTableView.separatorInset = UIEdgeInsets.zero

        showAlert(message: "Please connect your WiFi to the Access Point ARTIK_\(mac.lowercased())")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.addObservers()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        NotificationCenter.default.removeObserver(self)
    }
    

    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(deviceCreationSuccess(note:)), name: NSNotification.Name(rawValue: "device_creation_success"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceCreationFailed), name: NSNotification.Name(rawValue: "device_creation_failed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(confirmUserSuccess), name: NSNotification.Name(rawValue: "confirm_user_success"), object: nil)
    }

    func confirmUserSuccess() {
        print("User Pin confirmed.")
        onboardingService.completeRegistration()
    }

    func deviceCreationSuccess(note: Notification) {
        let device = note.object as! ACDeviceToken
        print("Device created with \(device.did!) and \(device.accessToken!)")
        onboardingService.passDeviceInfo(did:device.did! , token: device.accessToken!)

    }

    func deviceCreationFailed() {
        print("Device Creation in cloud failed")
        ATUtilities.hideIndicator()
        showAlert(message: "Unable to register device with Artik Cloud")
    }


    @IBAction func retryButton(_ sender: Any) {
        hideAlert()
    }

    func appDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    // MARK: - TableView Delegates

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
       return 50 //cell height
    }

    func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {

        if onboardingService != nil {
            return onboardingService.wifiList.count + 1
        } else {
            return 1
        }
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

        if indexPath.row  != onboardingService.wifiList.count {
            cell.layer.cornerRadius = 5

            let wifiDict = onboardingService.wifiList[indexPath.row] as [AnyHashable: Any]
            cell.titleLabel.text = wifiDict["ssid"] as! String?

            if wifiDict["security"] as! String? == "Open" {
                cell.cellImageView.isHidden = true
            }
            else {
                cell.cellImageView.isHidden = false
            }
        }
        else {
            cell.titleLabel.text = ""
            cell.cellImageView.isHidden = true
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row != onboardingService.wifiList.count {

            let wifiDict = onboardingService.wifiList[indexPath.row] as [AnyHashable: Any]

            if wifiDict["security"] as! String? == "Open" {
                isPasswordViewPresent = false
            }
            else {
                isPasswordViewPresent = true
            }

            ssid = wifiDict["ssid"] as! String!
            wifiPopOverView = WifiPasswordPopOverView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height), ssid: ssid! , security: wifiDict["security"]! as! String)
            wifiPopOverView.backgroundColor = UIColor.clear
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


    /* Soft AP Delegates */
    func didGetWifiList() {
        print("Got Wifi List from the Module")
        ATUtilities.hideIndicator()
        wifiListTableView.reloadData()
    }

    func didReadDtid() {
        print("Read dtid from the module")
        ATUtilities.showIndicator(message: "Registering module to Cloud")
        ATUtilities.hideIndicator()
        // Check if it SDR flow or not
        if onboardingService.dtid == Constants.ARTIK_053_SDR_DTID {
            onboardingService.startRegistration()
        } else {
            let defaults = UserDefaults.standard
            var dataDic = defaults.object(forKey:Constants.MODULE_AND_LOCATION_DICTIONARY)! as! [String:Any]

            var name = (dataDic[Constants.MODULE_NAME] as! String)

            if name.characters.count < 5 {
                name = "Artik-".appending(ATUtilities.getDeviceIdentifier())
            }

            self.appDelegate().addDeviceToArtikCloud(name: name, dtid: onboardingService.dtid)
        }
        
    }

    func didConfigureWifi() {

        wifiPopOverView.removeFromSuperview()
        state = OnboardingState.wifi_configured
        onboardingService.wifiList.removeAll()
        wifiListTableView.reloadData()
        showAlert(message: "Wifi Configured. Please switch your phone wifi network to \(ssid!)")

    }

    func didFindModuleOnLocalWifi() {
        print("Found Device and hence reading dtid")
        ATUtilities.showIndicator(message: "Found Device. Reading Device Type Id")
        state = OnboardingState.register_cloud
        onboardingService.readDtid()
    }

    func didOnboardSuccess() {
        print("Successfull onboarding of the module")
        showRegisteredModuleViewController()
    }

    func showRegisteredModuleViewController() {

        let registeredModuleControllerObj = self.storyboard!.instantiateViewController(withIdentifier: "RegisteredModuleViewController") as! RegisteredModuleViewController
        registeredModuleControllerObj.deviceType = 0
        self.navigationController!.pushViewController(registeredModuleControllerObj, animated: true)
        
    }

    func didReadPin() {
        print("Read Pin from the module")
        let defaults = UserDefaults.standard
        var dataDic = defaults.object(forKey:Constants.MODULE_AND_LOCATION_DICTIONARY)! as! [String:Any]

        var name = (dataDic[Constants.MODULE_NAME] as! String)

        if name.characters.count < 5 {
            name = "Artik-".appending(ATUtilities.getDeviceIdentifier())
        }

        self.appDelegate().confirmUser(deviceName: name, pin: onboardingService.pin)
    }


    func didOnboardFailure(error: String) {
        ATUtilities.hideIndicator()
        showAlert(message: error)
    }

    // MARK: - WifiPopOver delegates

    func removeWifiPopover() {
        wifiPopOverView.removeFromSuperview()
        isPasswordViewPresent = false
    }

    // MARK: - ATAlertView delegates
    func hideAlert() {
        alertView.removeFromSuperview()

        switch state {
        case OnboardingState.connect_module:
            state = OnboardingState.fetch_wifi_list
            showSettings()
            break
        case OnboardingState.fetch_wifi_list:
            ATUtilities.showIndicator(message: "Fetching list of Access Points")
            onboardingService.getWifiList()
            break
        case OnboardingState.wifi_configured:
            state = OnboardingState.find_module_local_wifi
            showSettings()
            break
        case OnboardingState.find_module_local_wifi:
            ATUtilities.showIndicator(message: "Trying to discover the device on local WiFi network")
            onboardingService.startDeviceDiscovery()
            let delay = DispatchTime.now() + .seconds(30)
            DispatchQueue.main.asyncAfter(deadline: delay, execute: {
                if self.state != OnboardingState.register_cloud {
                    self.state = OnboardingState.connect_module
                    ATUtilities.hideIndicator()
                    self.showAlert(message: "Unable to find module on local WiFi network.Please re-connect your WiFi to the Access Point ARTIK_\(self.mac!)")
                }
            })
            break
        default: break
            
        }

    }

    func showRegisteredModuleViewController(dId: String, deviceIp: String) {
        wifiPopOverView.removeFromSuperview()
    }

    func joinWifiNetwork(password: String) {

        if isPasswordViewPresent == true {
            onboardingService.configureWifi(ssid: ssid, passphrase: password)
        } else {
            onboardingService.configureWifi(ssid: ssid, passphrase: nil)
        }

    }

    func showSettings() {
        let settingsUrl = URL(string: "App-Prefs:root=WIFI")
        if UIApplication.shared.canOpenURL(settingsUrl!) {
            UIApplication.shared.open(settingsUrl!, completionHandler: { (success) in
                print("Settings opened: \(success)")
            })
        }
    }

}
