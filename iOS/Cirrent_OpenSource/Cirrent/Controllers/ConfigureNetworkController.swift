//
//  CredentialController.swift
//  Cirrent_New
//
//  Created by PSIHPOK on 12/17/16.
//  Copyright © 2016 PSIHPOK. All rights reserved.
//

import UIKit

class ConfigureNetworkController: BaseViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {

    
    @IBOutlet weak var titleLabel: UILabel!
    
    
    @IBOutlet weak var networkField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var showPasswordSwitch: UISwitch!
    @IBOutlet weak var showPasswordLabel: UILabel!
    @IBOutlet weak var hiddenNetworkSwitch: UISwitch!
    @IBOutlet weak var networkSecurityLabel: UILabel!
    @IBOutlet weak var networkSecurityField: UITextField!
    @IBOutlet weak var networkPasswordLabel: UILabel!
    @IBOutlet weak var storePasswordToVaultSwitch: UISwitch!
    @IBOutlet weak var storePasswordToVaultLabel: UILabel!
    
    var networkPicker:UIPickerView!
    var securityPicker:UIPickerView!
    
    let navBarHeight:CGFloat = 64.0
    
    var pickerViewShow:Bool = false
    var selectedNetwork:Network? = nil
    
    var selectedIndex = 0
    
    var securities = ["WPA2-PSK", "OPEN"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationItem.title = "Get Connected"
        
        titleLabel.text = "We found your device, now let's get it connected to your network"
        
        let networks = CirrentService.sharedService.model!.getNetworks()
        let ssid = CirrentService.sharedService.getCurrentSSID()
        
        if networks.count == 0 {
            hiddenNetworkSwitch.isEnabled = false
        }
        else {
            if CirrentService.sharedService.model!.isOnZipKeyNetwork() == true {
                if ssid == nil && CirrentService.sharedService.isOnCellularNetwork() == false {
                    ProgressView.sharedView.showToast(view: self.view, message: "Your phone is offline. Please check your network setting and try again.")
                    Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false, block: {_ in
                        DispatchQueue.main.async {
                            (UIApplication.shared.delegate as! AppDelegate).moveToMainController()
                        }
                    })
                    return
                }
                
                if ssid == nil {
                    if selectedNetwork == nil && networks.count > 0 {
                        selectedNetwork = networks[0]
                    }
                }
                else {
                    for net in networks {
                        if net.ssid == ssid {
                            selectedNetwork = net
                            break
                        }
                        selectedIndex += 1
                    }
                    
                    if selectedNetwork == nil && networks.count > 0 {
                        selectedNetwork = networks[0]
                        selectedIndex = 0
                    }
                }
            }
            else {
                for net in networks {
                    if AppDelegate.SoftAPBeforeSSID != nil && net.ssid == AppDelegate.SoftAPBeforeSSID! {
                        selectedNetwork = net
                        break
                    }
                    selectedIndex += 1
                }
                
                if selectedNetwork == nil && networks.count > 0 {
                    selectedNetwork = networks[0]
                    selectedIndex = 0
                }
            }
            
            networkField.text = selectedNetwork!.ssid
            networkPicker = UIPickerView()
            networkPicker.delegate = self
            networkPicker.dataSource = self
            networkField.inputView = networkPicker
            
            if selectedNetwork!.flags == "[ESS]" || selectedNetwork!.flags == "OPEN" {
                selectedNetwork!.open = true
                passwordField.text = ""
                showPasswordElements(bShow: false)
            }
            else {
                selectedNetwork!.open = false
                showPasswordElements(bShow: true)
            }
        }
        
        showPasswordSwitch.isOn = false
        
        securityPicker = UIPickerView()
        securityPicker.delegate = self
        securityPicker.dataSource = self
        networkSecurityField.inputView = securityPicker
        hiddenNetworkSwitch.isOn = false
        networkSecurityField.isHidden = true
        networkSecurityLabel.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let networks = CirrentService.sharedService.model!.getNetworks()
        if networks.count > 0 {
            (networkField.inputView as! UIPickerView).selectRow(selectedIndex, inComponent: 0, animated: false)
        }
    }
    
    @IBAction func onClickConnect(_ sender: Any) {
        let networks = CirrentService.sharedService.model!.getNetworks()
        if hiddenNetworkSwitch.isOn == true || networks.count == 0 {
            selectedNetwork = Network()
            
            if networkField.text != nil && networkField.text != "" {
                selectedNetwork!.ssid = networkField.text!
            }
            else {
                ProgressView.sharedView.showToast(view: self.view, message: "Please enter Network SSID.")
                return
            }
            
            if passwordField.isHidden == true {
                selectedNetwork!.flags = securities[1]
            }
            else {
                selectedNetwork!.flags = securities[0]
            }
        }
        
        if selectedNetwork != nil {
            if selectedNetwork!.flags == "[ESS]" || selectedNetwork!.flags == "OPEN" {
                selectedNetwork!.open = true
                passwordField.text = ""
            }
            else {
                selectedNetwork!.open = false
            }
            
            if selectedNetwork!.open == false && passwordField.text == "" {
                ProgressView.sharedView.showToast(view: self.view, message: "Please enter your network password.")
                return
            }
            
            CirrentService.sharedService.model?.selectedNetwork = selectedNetwork
            CirrentService.sharedService.model?.selectedNetworkPassword = passwordField.text
            
            let ssid:String = (selectedNetwork?.ssid)!
            LogService.sharedService.debug(data: "Private Network to connect to \(ssid)")
            
            if selectedNetwork!.open == false && passwordField.text!.characters.count < 8 {
                ProgressView.sharedView.showToast(view: self.view, message: "Please recheck your network password. It should be at least 8 characters.")
                return
            }
            
            sendCredential()
        }
        else {
            ProgressView.sharedView.showToast(view: self.view, message: "Please select a network and enter its password.")
        }
    }
    
    func sendCredential() {
        ProgressView.sharedView.showProgressView(view: self.view)
        var bAddToVault = false
        if storePasswordToVaultSwitch.isHidden == false && storePasswordToVaultSwitch.isOn == true {
            bAddToVault = true
        }
        
        let deviceID:String = (CirrentService.sharedService.model?.selectedDevice!.getDeviceID())!
        CirrentService.sharedService.putPrivateCredentials(tokenMethod: SampleCloudService.sharedService.getToken, deviceID: deviceID, bAddToVault: bAddToVault, completion: {
            response, creds in
            
            if response == CREDENTIAL_RESPONSE.SUCCESS {
                DispatchQueue.main.async {
                    ProgressView.sharedView.dismissProgressView()
                    self.performSegue(withIdentifier: "Connecting", sender: nil)
                }
            }
            else {
                DispatchQueue.main.async {
                    ProgressView.sharedView.showToast(view: self.view, message: "Sending Credential Failed")
                }
            }
        })
    }
    
    @IBAction func onChangeShowPassword(_ sender: Any) {
        passwordField.isSecureTextEntry = !(showPasswordSwitch.isOn)
    }
    
    @IBAction func onChangeHiddenNetwork(_ sender: Any) {
        networkSecurityLabel.isHidden = !hiddenNetworkSwitch.isOn
        networkSecurityField.isHidden = !hiddenNetworkSwitch.isOn
        if hiddenNetworkSwitch.isOn == true {
            networkField.inputView = nil
        }
        else {
            networkField.inputView = networkPicker
        }
    }
    
    func showPasswordElements(bShow:Bool) {
        networkPasswordLabel.isHidden = !bShow
        passwordField.isHidden = !bShow
        showPasswordSwitch.isHidden = !bShow
        showPasswordLabel.isHidden = !bShow
        storePasswordToVaultLabel.isHidden = !bShow
        storePasswordToVaultSwitch.isHidden = !bShow
        
        if CirrentService.sharedService.model?.isOnZipKeyNetwork() == false {
            storePasswordToVaultLabel.isHidden = true
            storePasswordToVaultSwitch.isHidden = true
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == networkPicker {
            let networks = CirrentService.sharedService.model?.getNetworks()
            return networks!.count
        }
        else {
            return securities.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == networkPicker {
            let networks = CirrentService.sharedService.model?.getNetworks()
            let network = networks?[row]
            return network?.ssid
        }
        else {
            return securities[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == networkPicker {
            let networks = CirrentService.sharedService.model?.getNetworks()
            let network = networks?[row]
            networkField.text = network?.ssid
            selectedNetwork = network
        
            if selectedNetwork!.flags == "[ESS]" || selectedNetwork!.flags == "OPEN" {
                selectedNetwork!.open = true
                passwordField.text = ""
                showPasswordElements(bShow: false)
            }
            else {
                selectedNetwork!.open = false
                showPasswordElements(bShow: true)
            }
        }
        else {
            networkSecurityField.text = securities[row]
            if row == 1 {
                passwordField.text = ""
                showPasswordElements(bShow: false)
            }
            else {
                showPasswordElements(bShow: true)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    }
}
