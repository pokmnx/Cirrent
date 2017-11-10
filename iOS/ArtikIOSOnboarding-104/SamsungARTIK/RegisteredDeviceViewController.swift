//
//  RegisteredDeviceViewController.swift
//  SamsungARTIK
//
//  Created by Marco on 5/4/17.
//  Copyright © 2017 Samsung Artik. All rights reserved.
//

import UIKit
import CirrentSDK

class RegisteredDeviceViewController: UIViewController {

    @IBOutlet weak var successLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let deviceID:String = (CirrentService.sharedService.model?.selectedDevice?.getDeviceID())!
        let ssid:String = (CirrentService.sharedService.model?.selectedNetwork?.ssid)!
        if CirrentService.sharedService.model?.selectedProvider != nil {
            let providerSSID:String = (CirrentService.sharedService.model?.selectedProvider?.getProviderName())!
            successLabel.text = "Your \(deviceID) is now connected to your private, secure \(providerSSID) network: \(ssid)"
        }
        else {
            let device = CirrentService.sharedService.model?.selectedDevice
            
            if device!.getProviderAttribution() != "" {
                let providerAttribution:String = device!.getProviderAttribution()
                let connectedSSID:String = (CirrentService.sharedService.model?.selectedNetwork?.ssid)!
                successLabel.text = "An \(providerAttribution) Hotspot was used to accelerate your connection to \(connectedSSID)"
            }
            else {
                successLabel.text = "Your \(deviceID) is now connected to your private network: \(ssid)"
            }
        }
    }

    @IBAction func onClickContinue(_ sender: Any) {
        ATUtilities.showIndicator1(message: "Resetting Module Now...")
        let deviceID:String = (CirrentService.sharedService.model?.selectedDevice?.getDeviceID())!
        CirrentService.sharedService.resetDevice(tokenMethod: SampleCloudService.sharedService.getToken, deviceID: deviceID, completion: {
            response in
            
            DispatchQueue.main.async {
                ATUtilities.hideIndicator1()
                let delegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
                let initialViewController = self.storyboard?.instantiateViewController(withIdentifier: "dashBoardNavigationController")
                delegate.window?.rootViewController = initialViewController
                delegate.window?.makeKeyAndVisible()
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
