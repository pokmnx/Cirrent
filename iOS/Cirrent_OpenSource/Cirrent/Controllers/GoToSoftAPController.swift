//
//  FailedViewController.swift
//  Cirrent_New
//
//  Created by PSIHPOK on 12/17/16.
//  Copyright © 2016 PSIHPOK. All rights reserved.
//

import UIKit

class GoToSoftAPController: BaseViewController {

    @IBOutlet weak var currentSSIDLabel: UILabel!
    @IBOutlet weak var shouldSelectSoftAPComment: UILabel!
    @IBOutlet weak var SoftAPSSIDLabel: UILabel!
    @IBOutlet weak var SoftAPSSIDLabelConstraint: NSLayoutConstraint!
    @IBOutlet weak var SoftAPImageContainer: UIImageView!
    
    static var SoftAPScreenCount = 0
    
    var bShouldFindDevice:Bool = false
    var currentSSID:String? = nil
    
    var bOnSoftAP:Bool = false
    
    let leadingConstantRatio:CGFloat = 0.13
    let wifiSettingURL = "App-Prefs:root=WIFI"
    
    @IBAction func onClickGoToSetting(_ sender: Any) {
        UIApplication.shared.open(URL(string: self.wifiSettingURL)!, options: [:], completionHandler: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = true
        self.navigationItem.title = "Setup"
        
        (UIApplication.shared.delegate as! AppDelegate).bShouldCheckSoftAP = true
        registerSoftAPNotification()
        
        bOnSoftAP = checkSoftAPAndGoDirectly()
        AppDelegate.SoftAPBeforeSSID = CirrentService.sharedService.getCurrentSSID()
        
        if bOnSoftAP == true {
            processSoftAP()
            return
        }
        
        if bShouldFindDevice == false {
            return
        }
        
        if SampleCloudService.sharedService.search_token != nil {
            CirrentService.sharedService.findDevice(tokenMethod: SampleCloudService.sharedService.getToken, completion: {
                result, devices in
                if result == FIND_DEVICE_RESULT.SUCCESS {
                    self.performSegue(withIdentifier: "SelectDevice", sender: nil)
                }
            })
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeSoftAPNotification()
    }
    
    func registerSoftAPNotification() {
        let notifyStr = (UIApplication.shared.delegate as! AppDelegate).SoftAP_NOTIFICATION
        let SoftAPNotify = Notification.Name(notifyStr)
        NotificationCenter.default.addObserver(self, selector: #selector(GoToSoftAPController.processSoftAP), name: SoftAPNotify, object: nil)
    }
    
    func removeSoftAPNotification() {
        let notifyStr = (UIApplication.shared.delegate as! AppDelegate).SoftAP_NOTIFICATION
        let SoftAPNotify = Notification.Name(notifyStr)
        NotificationCenter.default.removeObserver(self, name: SoftAPNotify, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let softAPSSID:String = CirrentService.sharedService.SoftAPSSID
        shouldSelectSoftAPComment.text = "Select \(softAPSSID)"
        SoftAPSSIDLabel.text = softAPSSID
        let imageWidth = SoftAPImageContainer.frame.size.width
        SoftAPSSIDLabelConstraint.constant = imageWidth * leadingConstantRatio
    }
    
    func checkSoftAPAndGoDirectly() -> Bool {
        currentSSID = CirrentService.sharedService.getCurrentSSID()
        if currentSSID == nil || currentSSID == "" {
            currentSSIDLabel.text = "Offline"
            return false
        }
        
        currentSSIDLabel.text = currentSSID!
        if currentSSID!.contains(CirrentService.sharedService.SoftAPSSID) == true {
            return true
        }
        
        return false
    }
    
    func processSoftAP() {
        let bCanGoSoftAP = checkSoftAPAndGoDirectly()
        if bCanGoSoftAP == false {
            ProgressView.sharedView.showToast(view: self.view, message: "Your Phone is not connected with SoftAP network or offline now.")
            return
        }
        
        removeSoftAPNotification()

        ProgressView.sharedView.showProgressView(view: self.view, message: "Contacting your device over SoftAP network...")
        CirrentService.sharedService.processSoftAP(handler: {
            response in
            DispatchQueue.main.async {
                switch (response) {
                case .SUCCESS_WITH_SoftAP:
                    self.performSegue(withIdentifier: "SoftAPConnect", sender: nil)
/*
                    let verified = CirrentService.sharedService.model?.selectedDevice?.verifyWith(accountID: SampleCloudService.sharedService.accountID)
                    if verified == false {
                        ProgressView.sharedView.showToast(view: self.view, message: "I'm sorry. This product is not valid for this account.")
                    }
                    else {
                        self.performSegue(withIdentifier: "SoftAPConnect", sender: nil)
                    }
*/
                    break
                case .FAILED_NOT_GET_SoftAP_IP,
                     .FAILED_NOT_SoftAP_SSID,
                     .FAILED_SoftAP_NO_RESPONSE,
                     .FAILED_SoftAP_INVALID_STATUS:
                    ProgressView.sharedView.showToast(view: self.view, message: "Failed to connect to your device's SoftAP network")
                    break
                case .FAILED_SoftAP_NOT_SUPPORTED:
                    ProgressView.sharedView.showToast(view: self.view, message: "This device does not support SoftAP")
                    break
                }
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
}
