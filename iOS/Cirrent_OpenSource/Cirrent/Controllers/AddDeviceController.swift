//
//  AddDeviceController.swift
//  Cirrent_New
//
//  Created by PSIHPOK on 12/17/16.
//  Copyright © 2016 PSIHPOK. All rights reserved.
//

import UIKit

class AddDeviceController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationItem.title = "Setup"
        
        let delegate = (UIApplication.shared.delegate) as! AppDelegate
        delegate.bShouldCheckSoftAP = false
    }
    
    @IBAction func onAddDevice(_ sender: Any) {
        ProgressView.sharedView.showProgressView(view: self.view, message: "Finding nearby devices...")
        
        CirrentService.sharedService.setOwnerIdentifier(identifier: SampleCloudService.sharedService.ownerID!)
        CirrentService.sharedService.findDevice(tokenMethod: SampleCloudService.sharedService.getToken, completion: {
            result, devices in
            
            if result == FIND_DEVICE_RESULT.FAILED_NETWORK_OFFLINE {
                DispatchQueue.main.async {
                    ProgressView.sharedView.showToast(view: self.view, message: "You need to be online to set up your device. Please connect your phone.")
                }
            }
            else if result == FIND_DEVICE_RESULT.FAILED_LOCATION_DISABLED {
                DispatchQueue.main.async {
                    ProgressView.sharedView.showToast(view: self.view, message: "Location Service should be enabled. Please enable location services under Settings/Privacy.")
                }
            }
            else if result == FIND_DEVICE_RESULT.SUCCESS {
                var devIDArray:[String] = []
                for dev in devices! {
                    devIDArray.append(dev.getDeviceID())
                }
                
                DispatchQueue.main.async {
                    ProgressView.sharedView.dismissProgressView()
                    self.performSegue(withIdentifier: "SelectDevice", sender: nil)
                }
            }
            else {
                DispatchQueue.main.async {
                    ProgressView.sharedView.showToast(view: self.view, message: "Sorry. We couldn't find your device yet, Let's try another approach.")
                    Timer.scheduledTimer(withTimeInterval: ProgressView.DEFAULT_DELAY, repeats: false, block: {
                        t in
                        self.performSegue(withIdentifier: "Failed", sender: nil)
                    })
                }
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
}
