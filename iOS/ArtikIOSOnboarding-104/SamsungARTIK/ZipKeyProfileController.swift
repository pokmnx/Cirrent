//
//  ZipKeyProfileController.swift
//  SamsungARTIK
//
//  Created by Marco on 5/6/17.
//  Copyright © 2017 Samsung Artik. All rights reserved.
//

import UIKit
import CirrentSDK

class ZipKeyProfileController: UIViewController, ATAlertViewDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var username: CustomTextField!
    @IBOutlet weak var password: CustomTextField!
    @IBOutlet weak var profileUsername: UILabel!
    @IBOutlet weak var loginButton: CustomButton!
    
    var alert : UIAlertController!
    var alertView: ATAlertView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if SampleCloudService.sharedService.bLogged == true {
            titleLabel.text = "ZipKey Profile"
            username.isHidden = true
            password.isHidden = true
            profileUsername.isHidden = false
            profileUsername.text = SampleCloudService.sharedService.username
            loginButton.setTitle("Logout", for: .normal)
        }
        else {
            titleLabel.text = "Login to Zipkey Account"
            username.isHidden = false
            password.isHidden = false
            profileUsername.isHidden = true
            loginButton.setTitle("Login", for: .normal)
        }
    }

    @IBAction func onClickBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onClickLogin(_ sender: Any) {
        if SampleCloudService.sharedService.bLogged == true {
            SampleCloudService.sharedService.logOut()
            CirrentService.sharedService.setOwnerIdentifier(identifier: SampleCloudService.sharedService.username)
            titleLabel.text = "Login to Zipkey Account"
            username.isHidden = false
            password.isHidden = false
            profileUsername.isHidden = true
            loginButton.setTitle("Login", for: .normal)
        }
        else {
            if username.text == nil || username.text! == "" {
                showAlert(message: "Please fill Username.")
                return
            }
            
            if password.text == nil || password.text! == "" {
                showAlert(message: "Please fill Password.")
                return
            }
            
            ATUtilities.showIndicator(message: "Log in ZipKey Cloud...")
            SampleCloudService.sharedService.login(username: username.text!, password: password.text!, completion: {
                result in
                
                DispatchQueue.main.async {
                    ATUtilities.hideIndicator()
                    
                    if result == LOGIN_RESULT.SUCCESS {
                        self.titleLabel.text = "ZipKey Profile"
                        self.username.isHidden = true
                        self.password.isHidden = true
                        self.profileUsername.isHidden = false
                        self.profileUsername.text = SampleCloudService.sharedService.username
                        self.loginButton.setTitle("Logout", for: .normal)
                    }
                    else if result == LOGIN_RESULT.FAILED_INVALID_STATUS {
                        self.showAlert(message: "User Credential is not correct. Please try again")
                    }
                    else {
                        self.showAlert(message: "Unable to Login")
                    }
                }
            })
        }
    }
    
    func showAlert(message: String) {
        alertView = ATAlertView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height), message: message , cancelButtonTitle: NSLocalizedString("OK", comment: ""), confirmButtonTitle: "")
        alertView.delegate = self
        alertView.backgroundColor = UIColor.clear
        self.view.addSubview(alertView)
        
        alertView.translatesAutoresizingMaskIntoConstraints = false
        
        let subviewsDict: Dictionary = ["alertView": alertView]
        
        let arrXconstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[alertView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.view.addConstraints(arrXconstraints)
        
        let arrYconstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[alertView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.view.addConstraints(arrYconstraints)
    }
    
    func hideAlert() {
        alertView.removeFromSuperview()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
