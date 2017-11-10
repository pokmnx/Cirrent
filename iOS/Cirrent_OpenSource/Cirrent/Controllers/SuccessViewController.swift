//
//  SuccessViewController.swift
//  Cirrent_New
//
//  Created by PSIHPOK on 12/17/16.
//  Copyright © 2016 PSIHPOK. All rights reserved.
//

import UIKit

class SuccessViewController: BaseViewController {

    @IBOutlet weak var providerImageView: UIImageView!
    @IBOutlet weak var learnMoreButton: UIButton!
    @IBOutlet weak var connectedLabel: UILabel!
    
    var learnMoreURL:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationItem.title = "Success"
        
        let deviceID:String = (CirrentService.sharedService.model?.selectedDevice?.getDeviceID())!
        let ssid:String = (CirrentService.sharedService.model?.selectedNetwork?.ssid)!
        learnMoreButton.isHidden = true
        if CirrentService.sharedService.model?.selectedProvider != nil {
            providerImageView.isHidden = false
            
            let providerSSID:String = (CirrentService.sharedService.model?.selectedProvider?.getProviderName())!
            
            providerImageView.sd_setImage(with: URL(string: (CirrentService.sharedService.model?.selectedProvider?.getProviderLogo())!))
            connectedLabel.text = "Your \(deviceID) is now connected to your private, secure \(providerSSID) network: \(ssid)"
        }
        else {
            providerImageView.isHidden = true
            let device = CirrentService.sharedService.model?.selectedDevice
            
            if device!.getProviderAttribution() != "" {
                let providerAttribution:String = device!.getProviderAttribution()
                let connectedSSID:String = (CirrentService.sharedService.model?.selectedNetwork?.ssid)!
                connectedLabel.text = "An \(providerAttribution) Hotspot was used to accelerate your connection to \(connectedSSID)"    
                
                if device!.getProviderAttributionLogo() != "" {
                    providerImageView.isHidden = false
                    providerImageView.sd_setImage(with: URL(string: device!.getProviderAttributionLogo()))
                }
                
                if device!.getProviderAttributionLearnMoreURL() != "" {
                    learnMoreButton.isHidden = false
                    learnMoreURL = device!.getProviderAttributionLearnMoreURL()
                    learnMoreButton.setTitle(learnMoreURL, for: .normal)
                }
            }
            else {
                connectedLabel.text = "Your \(deviceID) is now connected to your private network: \(ssid)"
            }
            
            if CirrentService.sharedService.model?.isOnZipKeyNetwork() != true {
                SuccessViewController.registerUnboundDevice(deviceID: deviceID)
            }
        }
    }
    
    public static let unboundDeviceInfoKey = "unbound_device_info"
    static func registerUnboundDevice(deviceID:String) {
        let accountID:String = SampleCloudService.sharedService.accountID!
        var realID:String = deviceID.replacingOccurrences(of: accountID, with: "")
        realID.remove(at: realID.startIndex)
        let info = UserDefaults.standard.string(forKey: SuccessViewController.unboundDeviceInfoKey)
        if info == nil {
            UserDefaults.standard.set(realID, forKey: SuccessViewController.unboundDeviceInfoKey)
        }
        else {
            var devicesInfo:String = info!
            devicesInfo += "|\(realID)"
            UserDefaults.standard.set(devicesInfo, forKey: SuccessViewController.unboundDeviceInfoKey)
        }
    }
    
    public static func bindUnBoundDevices(completion:@escaping (Bool) -> Void) {
        let info = UserDefaults.standard.string(forKey: SuccessViewController.unboundDeviceInfoKey)
        if info == nil {
            print ("There is no device which need to be bound.")
            completion(true)
            return
        }
        
        var deviceIDs:[String] = info!.components(separatedBy: "|")
        SampleCloudService.sharedService.bindDevice(deviceID: deviceIDs[0], friendlyName: nil, completion: {
            token, response in
            
            if response != .SUCCESS {
                print("Failed to bind device to sample cloud - \(deviceIDs[0])")
                completion(false)
            }
            else {
                CirrentService.sharedService.bindDevice(tokenMethod: SampleCloudService.sharedService.getToken, deviceID: deviceIDs[0], friendlyName: nil, completion: {
                    response in
                    
                    if response != .SUCCESS {
                        print("Failed to bind device to sample cloud - \(deviceIDs[0])")
                        completion(false)
                    }
                    else {
                        deviceIDs.remove(at: 0)
                        if deviceIDs.count == 0 {
                            UserDefaults.standard.set(nil, forKey: SuccessViewController.unboundDeviceInfoKey)
                            completion(true)
                        }
                        else {
                            var info:String = ""
                            for deviceID in deviceIDs {
                                info += deviceID + "|"
                            }
                            info.remove(at: info.index(before: info.endIndex))
                            UserDefaults.standard.set(info, forKey: SuccessViewController.unboundDeviceInfoKey)
                            bindUnBoundDevices(completion: completion)
                        }
                    }
                })
            }
        })
    }
    
    @IBAction func onClickLearnMore(_ sender: Any) {
        
        if learnMoreURL.contains("https://") == false {
            let url = "https://\(learnMoreURL)"
            UIApplication.shared.open(URL(string: url)!, options: [:], completionHandler: nil)
        }
        else {
            UIApplication.shared.open(URL(string: learnMoreURL)!, options: [:], completionHandler: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
}
