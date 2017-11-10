//
//  SetupDeviceController.swift
//  Cirrent_New
//
//  Created by PSIHPOK on 12/17/16.
//  Copyright © 2016 PSIHPOK. All rights reserved.
//

import UIKit

class SetupDeviceController: BaseViewController {

    var device:Device!
    
    @IBOutlet weak var deviceImageView: UIImageView!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var manualConnectButton: UIButton!
    @IBOutlet weak var orLabel: UILabel!
    @IBOutlet weak var providerNetworkLogo: UIImageView!
    @IBOutlet weak var automaticConnectLabel: UILabel!
    @IBOutlet weak var automaticConnectButton: UIButton!
    
    let segueIdentifier = "ConfigureNetwork"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        device = CirrentService.sharedService.model!.selectedDevice!
        
        deviceImageView.sd_setImage(with: URL(string: device.getImageURL()))
        deviceNameLabel.text = device.getDeviceID()
        
        hideProviderViews(bHidden: true)
        self.navigationItem.title = "Get Connected"
        
        let provider = CirrentService.sharedService.model?.getProviderNetwork()
        var bAutoGo = true
        
        if provider != nil {
            var bFind = false
            if CirrentService.sharedService.model?.getSSID() != nil {
                let providerSSID:String = (provider?.getSSID())!
                let ssid:String = (CirrentService.sharedService.model?.getSSID())!
                LogService.sharedService.debug(data: "Trying to match. \(providerSSID), \(ssid)")
            }
                
            if CirrentService.sharedService.model?.getSSID() != nil && provider?.getSSID() == CirrentService.sharedService.model?.getSSID()! {
                LogService.sharedService.debug(data:"Yay!! We have a match. \(String(describing: provider?.getSSID()))")
                LogService.sharedService.debug(data: "setting the provider in found device \(String(describing: provider?.getProviderName()))")
                    
                if provider?.getProviderLogo() != "" {
                    providerNetworkLogo.sd_setImage(with: URL(string: (provider?.getProviderLogo())!))
                }
                    
                let ssid:String = (CirrentService.sharedService.model?.getSSID())!
                automaticConnectLabel.text = "Connect Automatically to \(ssid) with"
                    
                hideProviderViews(bHidden: false)
                CirrentService.sharedService.model!.selectedProvider = provider
                    
                bFind = true
                bAutoGo = false
            }
            
            if bFind == false {
                LogService.sharedService.debug(data: "No provider network. Showing the user we found their device!")
                bAutoGo = true
            }
        }
        else {
            LogService.sharedService.debug(data: "No provider network. Showing the user we found their device!")
            bAutoGo = true
        }
        
        if bAutoGo == true {
            let delay:TimeInterval = 3
            if device.getProviderAttribution() != "" && device.getProviderAttributionLogo() != "" {
                self.performSegue(withIdentifier: segueIdentifier, sender: nil)
                return
            }
            
            ProgressView.sharedView.showProgressView(view: self.view, message: "Setting Up Your Device...")
            Timer.scheduledTimer(withTimeInterval: delay, repeats: false, block: {
                t in
                DispatchQueue.main.async {
                    ProgressView.sharedView.dismissProgressView()
                    self.performSegue(withIdentifier: self.segueIdentifier, sender: nil)
                }
                t.invalidate()
            })
        }
    }
    
    func hideProviderViews(bHidden:Bool) {
        manualConnectButton.isHidden = bHidden
        orLabel.isHidden = bHidden
        providerNetworkLogo.isHidden = bHidden
        automaticConnectLabel.isHidden = bHidden
        automaticConnectButton.isHidden = bHidden
        self.navigationItem.setHidesBackButton(bHidden, animated: false)
    }
    
    @IBAction func onClickConnectManual(_ sender: Any) {
        self.performSegue(withIdentifier: "ConfigureNetwork", sender: nil)
    }
    
    @IBAction func onClickConnectAutomatic(_ sender: Any) {
        if CirrentService.sharedService.model!.selectedProvider != nil {
            ProgressView.sharedView.showProgressView(view: self.view)
            let deviceID:String = (CirrentService.sharedService.model?.selectedDevice?.getDeviceID())!
            let providerUDID:String = (CirrentService.sharedService.model?.selectedProvider?.getProviderUUID())!
            CirrentService.sharedService.putProviderCredentials(tokenMethod: SampleCloudService.sharedService.getToken, deviceID: deviceID, providerUDID: providerUDID, completion: {
                response, creds in
                
                if creds == nil {
                    LogService.sharedService.debug(data: "Unable to put provider network, sending to local wifi.")
                    DispatchQueue.main.async {
                        ProgressView.sharedView.showToast(view: self.view, message: "Unable to put provider network, sending to local wifi")
                        Timer.scheduledTimer(withTimeInterval: ProgressView.DEFAULT_DELAY, repeats: false, block: {
                            t in
                            self.performSegue(withIdentifier: self.segueIdentifier, sender: nil)
                        })
                    }
                }
                else {
                    LogService.sharedService.debug(data: "Successfully put provider network")
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "Connecting", sender: nil)
                    }
                }
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }

}
