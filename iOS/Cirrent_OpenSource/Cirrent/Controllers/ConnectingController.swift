//
//  ConnectingController.swift
//  Cirrent_New
//
//  Created by PSIHPOK on 12/17/16.
//  Copyright © 2016 PSIHPOK. All rights reserved.
//

import UIKit

class ConnectingController: BaseViewController {

    @IBOutlet weak var deviceImageView: UIImageView!
    @IBOutlet weak var providerImageView: UIImageView!
    @IBOutlet weak var networkName: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationItem.title = "Get Connected"

        setDeviceAndProviderImage()
        getDeviceJoiningStatus()
    }

    func setDeviceAndProviderImage() {
        if CirrentService.sharedService.model?.providerName != nil {
            LogService.sharedService.debug(data: "Connecting Screen: provider name: \(String(describing: CirrentService.sharedService.model?.providerName))")
        }

        if CirrentService.sharedService.model?.getZipKeyHotSpot() != nil {
            LogService.sharedService.debug(data: "Connecting Screen: device zipkey hotspot?: \(String(describing: CirrentService.sharedService.model?.getZipKeyHotSpot()))")
        }

        if CirrentService.sharedService.model?.selectedNetwork != nil {
            networkName.text = CirrentService.sharedService.model?.selectedNetwork?.ssid
        }

        providerImageView.isHidden = true

        let url = CirrentService.sharedService.model?.selectedDevice?.getImageURL()
        if url != nil {
            deviceImageView.sd_setImage(with: URL(string: url!))
        }

        if CirrentService.sharedService.model?.selectedProvider != nil {
            providerImageView.isHidden = false
            if CirrentService.sharedService.model?.selectedProvider!.getProviderLogo() != nil {
                providerImageView.sd_setImage(with: URL(string: (CirrentService.sharedService.model?.selectedProvider!.getProviderLogo())!))
            }
        }
        else {
            let device = CirrentService.sharedService.model?.selectedDevice
            if device!.getProviderAttribution() != "" && device!.getProviderAttributionLogo() != "" {
                providerImageView.isHidden = false
                providerImageView.sd_setImage(with: URL(string: device!.getProviderAttributionLogo()))
            }
        }       
    }

    func getDeviceJoiningStatus() {
        
        var message = "Contacting your device... \nConnecting to " + (CirrentService.sharedService.model?.selectedNetwork?.ssid)!
        
        let device = CirrentService.sharedService.model?.selectedDevice
        
        if CirrentService.sharedService.model?.selectedProvider != nil {
            message = "Connecting to " + (CirrentService.sharedService.model?.selectedNetwork?.ssid)! + " using"
        }
        else {
            if device!.getProviderAttribution() != "" && device!.getProviderAttributionLogo() != "" {
                let deviceID:String = device!.getDeviceID()
                let providerAttribution:String = device!.getProviderAttribution()
                message = "Connecting \(deviceID) to your network via an \(providerAttribution) Hotspot"
            }
        }
        
        ProgressView.sharedView.showProgressView(view: self.view, message: message)
        CirrentService.sharedService.getDeviceJoiningStatus(tokenMethod: SampleCloudService.sharedService.getToken, deviceID: device!.getDeviceID(), handler: {
            status in
            
            DispatchQueue.main.async {
                switch (status) {
                case .JOINED:
                    ProgressView.sharedView.showToast(view: self.view, message: "Device is connected")
                    self.moveToProperController(segueIdentifier: "Success")
                    break
                case .RECEIVED_CREDS:
                    ProgressView.sharedView.changeMessage(message: "Connecting device to your network")
                    break
                case .ATTEMPTING_TO_JOIN:
                    ProgressView.sharedView.changeMessage(message: "Attempting to join")
                    break
                case .OPTIMIZING_CONNECTION:
                    ProgressView.sharedView.changeMessage(message: "Checking connectivity...")
                    break
                case .TIMED_OUT:
                    ProgressView.sharedView.showToast(view: self.view, message: "Let's try again.")
                    self.moveToProperController(segueIdentifier: "Failed")
                    break
                case .GET_DEVICE_STATUS_FAILED,
                     .FAILED_INVALID_STATUS,
                     .FAILED_INVALID_TOKEN,
                     .SELECTED_DEVICE_NIL,
                     .FAILED_NO_RESPONSE,
                     .NOT_SoftAP_NETWORK,
                     .FAILED:
                    ProgressView.sharedView.showToast(view: self.view, message: "Device failed to join. Let's try again.")
                    self.moveToProperController(segueIdentifier: "Back")
                    break
                }
            }
        })
    }

    func moveToProperController(segueIdentifier:String) {
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: ProgressView.DEFAULT_DELAY, repeats: false, block: {
                t in
                if segueIdentifier == "Back" {
                    _ = self.navigationController?.popViewController(animated: true)
                    let controllerArray = self.navigationController?.viewControllers
                    if controllerArray != nil && controllerArray!.count > 2 {
                        let viewController:ConfigureNetworkController? = controllerArray?[controllerArray!.count - 1] as? ConfigureNetworkController
                        if viewController != nil {
                            viewController?.titleLabel.text = "We weren't able to connect the device. Please re-enter the network password."
                        }
                    }
                }
                else if segueIdentifier == "StartOver" {
                    let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.moveToMainController()
                }
                else {
                    self.performSegue(withIdentifier: segueIdentifier, sender: nil)
                }
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    }

}
