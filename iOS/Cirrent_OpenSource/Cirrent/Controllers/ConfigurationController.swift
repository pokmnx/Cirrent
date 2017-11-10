//
//  ConfigureController.swift
//  Cirrent_New
//
//  Created by PSIHPOK on 12/17/16.
//  Copyright © 2016 PSIHPOK. All rights reserved.
//

import UIKit

class ConfigurationController: UIViewController {

    @IBOutlet weak var appIDLabel: UILabel!
    @IBOutlet weak var SoftAPSSIDField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationBar()
        showAppInfo()
        let delegate = (UIApplication.shared.delegate) as! AppDelegate
        delegate.bShouldCheckSoftAP = false
    }
    
    func showAppInfo() {
        appIDLabel.text = SampleCloudService.sharedService.ownerID!
        SoftAPSSIDField.text = CirrentService.sharedService.SoftAPSSID
    }
    
    @IBAction func onClickDone(_ sender: Any) {
        if SoftAPSSIDField.text?.characters.count == 0 {
            ProgressView.sharedView.showAlert(viewController: self, message: "SoftAP SSID should be filled.")
            return
        }
        
        CirrentService.sharedService.SoftAPSSID = SoftAPSSIDField.text!
        (UIApplication.shared.delegate as! AppDelegate).moveToMainController()
    }
    
    @IBAction func onClickSignOut(_ sender: Any) {
        SampleCloudService.sharedService.logOut()
        (UIApplication.shared.delegate as! AppDelegate).moveToLoginController()
    }
    
    func setUpNavigationBar() {
        self.navigationController?.navigationBar.items?[0].title = "Settings"
        self.navigationController?.navigationBar.tintColor = UIColor(red: 0, green: 0.73, blue: 1, alpha: 1)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        super.touchesBegan(touches, with: event)
        
        if SoftAPSSIDField.isFirstResponder && touch!.view != SoftAPSSIDField {
            SoftAPSSIDField.resignFirstResponder()
        }
    }
}
