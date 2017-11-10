//
//  ProviderConnectController.swift
//  SamsungARTIK
//
//  Created by Marco on 5/4/17.
//  Copyright © 2017 Samsung Artik. All rights reserved.
//

import UIKit
import SDWebImage
import CirrentSDK

class ProviderConnectController: UIViewController {

    
    @IBOutlet weak var automaticButton: UIButton!
    @IBOutlet weak var providerImageView: UIImageView!
    
    var provider:ProviderKnownNetwork? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        
        provider = CirrentService.sharedService.model?.getProviderNetwork()
        if provider == nil {
            return
        }
        
        providerImageView.sd_setImage(with: URL(string: provider!.getProviderLogo()))
        automaticButton.layer.borderWidth = 1
        automaticButton.layer.borderColor = UIColor(red: 0, green: 172 / 255.0, blue: 1, alpha: 1).cgColor
        automaticButton.layer.masksToBounds = true
        automaticButton.layer.cornerRadius = 8
    }
    
    @IBAction func onConnectWithProvider(_ sender: Any) {
        CirrentService.sharedService.model?.selectedProvider = provider
        let device = CirrentService.sharedService.model?.selectedDevice
        ATUtilities.showIndicator(message: "\(device!.getDeviceID()) is connecting to \(provider!.getSSID()) using \(provider!.getProviderName())...")
        CirrentService.sharedService.putProviderCredentials(tokenMethod: SampleCloudService.sharedService.getToken, deviceID: device!.getDeviceID(), providerUDID: provider!.getProviderUUID(), completion: {
            response, creds in
            
            DispatchQueue.main.async {
                if creds == nil {
                    ATUtilities.hideIndicator()
                    ATUtilities.showToastMessage(message: "Failed to join \(self.provider!.getProviderName())")
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: {
                        t in
                        _ = self.navigationController?.popToRootViewController(animated: true)
                    })
                }
                else {
                    CirrentService.sharedService.getDeviceJoiningStatus(tokenMethod: SampleCloudService.sharedService.getToken, deviceID: device!.getDeviceID(), handler: {
                        status in
                        
                        DispatchQueue.main.async {
                            switch (status) {
                            case .JOINED:
                                ATUtilities.hideIndicator()
                                ATUtilities.showToastMessage(message: "Module is connected")
                                
                                Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: {
                                    t in
                                    
                                    let controller:RegisteredDeviceViewController = self.storyboard!.instantiateViewController(withIdentifier: "RegisteredDeviceViewController") as! RegisteredDeviceViewController
                                    self.navigationController!.pushViewController(controller, animated: true)
                                    self.navigationController?.viewControllers = [controller]
                                })
                                
                                break
                            case .RECEIVED_CREDS:
                                ATUtilities.showIndicator(message: "Connecting module to your network")
                                break
                            case .ATTEMPTING_TO_JOIN:
                                ATUtilities.showIndicator(message: "Attempting to join")
                                break
                            case .OPTIMIZING_CONNECTION:
                                ATUtilities.showIndicator(message: "Checking connectivity...")
                                break
                            case .TIMED_OUT:
                                ATUtilities.hideIndicator()
                                ATUtilities.showToastMessage(message: "Let's try again.")
                                break
                            case .GET_DEVICE_STATUS_FAILED,
                                 .FAILED_INVALID_STATUS,
                                 .FAILED_INVALID_TOKEN,
                                 .SELECTED_DEVICE_NIL,
                                 .FAILED_NO_RESPONSE,
                                 .NOT_SoftAP_NETWORK,
                                 .FAILED:
                                ATUtilities.hideIndicator()
                                ATUtilities.showToastMessage(message: "Module failed to join. Let's try again.")
                                break
                            }
                        }
                    })
                }
            }
        })
    }
    
    @IBAction func onConnectManually(_ sender: Any) {
        let controller:PrivateNetworkConnectController = self.storyboard!.instantiateViewController(withIdentifier: "PrivateNetworkConnectController") as! PrivateNetworkConnectController
        controller.networks = (CirrentService.sharedService.model?.getNetworks())!
        self.navigationController!.pushViewController(controller, animated: true)
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
