//
//  AddNetworkController.swift
//  Cirrent
//
//  Created by PSIHPOK on 2/28/17.
//  Copyright © 2017 Cirrent. All rights reserved.
//

import UIKit

class AddNetworkController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    var deviceID:String!
    
    @IBOutlet weak var networkName: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var security: UITextField!
    @IBOutlet weak var manualSwitch: UISwitch!
    @IBOutlet weak var showPasswordSwitch: UISwitch!
    @IBOutlet weak var showPasswordLabel: UILabel!
    
    var ssidPickerView:UIPickerView!
    var securityPickerView:UIPickerView!
    
    var candidates:[KnownNetwork] = [KnownNetwork]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        securityPickerView = UIPickerView()
        securityPickerView.dataSource = self
        securityPickerView.delegate = self
        security.inputView = securityPickerView
        security.text = securityProtocols[0]
        showPasswordSwitch.isOn = false
        self.navigationItem.title = "Add Network"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ProgressView.sharedView.showProgressView(view: self.view)
        CirrentService.sharedService.getCandidateNetworks(tokenMethod: SampleCloudService.sharedService.getToken, deviceID: deviceID, completion: {
            array in
            
            DispatchQueue.main.async {
                ProgressView.sharedView.dismissProgressView()
                if array != nil && array!.count > 0 {
                    self.ssidPickerView = UIPickerView()
                    self.ssidPickerView.delegate = self
                    self.ssidPickerView.dataSource = self
                    self.candidates = array!
                    self.ssidPickerView.reloadAllComponents()
                    self.manualSwitch.isOn = false
                    self.manualSwitch.isEnabled = true
                    self.security.isEnabled = true
                    self.networkName.inputView = self.ssidPickerView
                    self.networkName.text = array![0].ssid
                    self.security.text = self.securityProtocols[0]
                }
                else {
                    self.manualSwitch.isOn = true
                    self.manualSwitch.isEnabled = false
                }
            }
        })
    }
    
    @IBAction func onClickAdd(_ sender: Any) {
        if networkName.text == nil || networkName.text! == "" {
            ProgressView.sharedView.showToast(view: self.view, message: "Network Name should be not empty.")
            return
        }
        
        ProgressView.sharedView.showProgressView(view: self.view)
        let network = Network()
        network.ssid = networkName.text!
        network.flags = security.text!
        CirrentService.sharedService.addNetwork(tokenMethod: SampleCloudService.sharedService.getToken, deviceID: deviceID, network: network, password: password.text!, completion: {
            response in
            
            DispatchQueue.main.async {
                ProgressView.sharedView.dismissProgressView()
                if response != .SUCCESS {
                    ProgressView.sharedView.showToast(view: self.view, message: "Failed to add network to device.")
                }
                else {
                    ProgressView.sharedView.showToast(view: self.view, message: "Success - added network to device.")
                    Timer.scheduledTimer(withTimeInterval: ProgressView.DEFAULT_DELAY, repeats: false, block: {
                        timer in
                        
                        DispatchQueue.main.async {
                            if self.navigationController != nil {
                                self.navigationController!.popViewController(animated: true)
                            }
                        }
                    })
                }
            }
        })
    }
    
    @IBAction func onShowPassword(_ sender: Any) {
        if showPasswordSwitch.isOn == true {
            password.isSecureTextEntry = false
        }
        else {
            password.isSecureTextEntry = true
        }
    }
    
    @IBAction func onChangeInputType(_ sender: Any) {
        if manualSwitch.isOn == true {
            networkName.inputView = nil
            security.isEnabled = true
        }
        else {
            networkName.inputView = ssidPickerView
            security.isEnabled = false
        }
    }
    
    var securityProtocols = ["WPA2-PSK", "OPEN"]
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == securityPickerView {
            return securityProtocols.count
        }
        else {
            return candidates.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == securityPickerView {
            security.text = securityProtocols[row]
            
            if securityProtocols[row] == "OPEN" {
                password.isHidden = true
                showPasswordSwitch.isHidden = true
                showPasswordLabel.isHidden = true
            }
            else {
                password.isHidden = false
                showPasswordSwitch.isHidden = false
                showPasswordLabel.isHidden = false
            }
        }
        else {
            networkName.text = candidates[row].ssid
            //security.text = candidates[row].security
            security.text = securityProtocols[0]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == securityPickerView {
            return securityProtocols[row]
        }
        else {
            return candidates[row].ssid
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
