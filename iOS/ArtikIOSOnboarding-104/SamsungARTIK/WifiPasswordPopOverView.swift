//
//  WifiPopOverView.swift
//  SamsungARTIK
//
//  Created by alimi shalini on 12/6/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

protocol WifiPopOverDelegate {
    func removeWifiPopover()
    func showRegisteredModuleViewController(dId: String, deviceIp: String)
    func joinWifiNetwork(password: String)
}

class WifiPasswordPopOverView: UIView, UIGestureRecognizerDelegate,UITextFieldDelegate {
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    var deviceId: String!
    var ipAddress: String!
    var onBoardingService: WifiOnboardingService!
    var delegate: WifiPopOverDelegate?
    var titleLabel : UILabel!
    var transparentView : UIView!
    var passwordView : UIView!
    var showPasswordButton : UIButton!
    var showPasswordImageView : UIImageView!
    var savePasswordButton : UIButton!
    var savePasswordImageView : UIImageView!
    var passwordTextField : UITextField!
    var loaderView : UIView!
    var activityIndicator : UIActivityIndicatorView!
    var indicatorViewTopLabel : UILabel!
    var indicatorViewBottomLabel : UILabel!
    var wifiSSID: String!
    var securityString: String!
    var isToastPresent: Bool! = false
    var savePassword : Bool = true
    var savedPassword : String!
    
    init (frame : CGRect, ssid: String, security: String) {
        wifiSSID = ssid
        securityString = security
        super.init(frame : frame)
        savedPassword = KeychainWrapper.standard.string(forKey: ssid)
        addBehavior()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addBehavior (){
        print("Add all the behavior here")
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onPeripheralDisconnected), name: NSNotification.Name(rawValue: Constants.NOTIF_PERIPHERAL_DISCONNECTED), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onDeviceIdRead), name: NSNotification.Name(rawValue: Constants.NOTIF_DEVICE_ID_READ), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onArtikIPRead), name: NSNotification.Name(rawValue: Constants.NOTIF_IP_ADDRESS_READ), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.joinWifiNetworkResponse), name: NSNotification.Name(rawValue: "join_wifi_network_response"), object: nil)
        
        transparentView = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        transparentView.backgroundColor = UIColor.black
        transparentView.alpha = 0.8
        self.addSubview(transparentView)
        
        let subviewsDict: Dictionary = ["transparentView": transparentView];
        
        transparentView.translatesAutoresizingMaskIntoConstraints = false
        
        let arrXconstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[transparentView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.addConstraints(arrXconstraints)
        
        let arrYconstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[transparentView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.addConstraints(arrYconstraints)
        
        passwordView = UIView(frame: CGRect(x: self.bounds.size.width/2-140, y: self.bounds.size.height/2-100, width: 280, height: 240))
        passwordView.layer.cornerRadius=5
        passwordView.backgroundColor = Constants.backgroundWhiteColor
        self.addSubview(passwordView)
        
        titleLabel = UILabel(frame:CGRect(x: 0, y: 5, width: passwordView.bounds.size.width, height: 35))
        titleLabel.text = wifiSSID
        titleLabel.textAlignment = NSTextAlignment.center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = Constants.topBottomBarColor
        passwordView.addSubview(titleLabel)
        
        // Bottom line for title label
        let border = CALayer()
        let width = CGFloat(1.0)
        border.borderColor = Constants.topBottomBarColor.cgColor
        border.frame = CGRect(x: 0, y: titleLabel.frame.size.height - width, width:  titleLabel.frame.size.width, height: 1)
        border.borderWidth = width
        titleLabel.layer.addSublayer(border)
        titleLabel.layer.masksToBounds = true
        
        let psswordLabel = UILabel(frame:CGRect(x: 15, y: 40, width: passwordView.bounds.size.width-20, height: 30))
        psswordLabel.text = NSLocalizedString("Password", comment: "")
        psswordLabel.textAlignment = NSTextAlignment.left
        psswordLabel.font = UIFont.systemFont(ofSize: 15)
        psswordLabel.backgroundColor = UIColor.clear
        psswordLabel.textColor = Constants.topBottomBarColor
        passwordView.addSubview(psswordLabel)
        
        passwordTextField = CustomTextField(frame:CGRect(x: 10, y: 70, width: passwordView.bounds.size.width-20, height: 40))
        passwordTextField.placeholder = NSLocalizedString("Enter Wi-Fi Password", comment: "")
        passwordTextField.setValue(UIColor(red: 118/255.0, green: 127/255.0, blue: 135/255.0, alpha: 1.0), forKeyPath: "_placeholderLabel.textColor")

        if savedPassword != nil {
            passwordTextField.text = savedPassword
        }

        passwordTextField.textColor = Constants.backgroundWhiteColor
        passwordTextField.backgroundColor = Constants.topBottomBarColor
        passwordTextField.layer.cornerRadius = 5
        passwordTextField.isSecureTextEntry = true
        passwordTextField.delegate = self
        passwordView.addSubview(passwordTextField)
        
        if UIScreen.main.bounds.size.height <= 568 {
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        }
        
        
        
        showPasswordButton = UIButton(frame:CGRect(x: 15, y: 115, width: passwordView.bounds.size.width-20, height: 40))
        showPasswordButton.tag = 1
        showPasswordButton.addTarget(self, action: #selector(showPasswordButtonAction), for: UIControlEvents.touchUpInside)
        showPasswordButton.setTitle(NSLocalizedString("Show Password", comment: ""), for: .normal)
        showPasswordButton.backgroundColor = UIColor.clear
        passwordView.addSubview(showPasswordButton)
        showPasswordButton.contentHorizontalAlignment = .left
        showPasswordButton.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: 20.0, bottom: 0.0, right: 0.0)
        showPasswordButton.setTitleColor(Constants.topBottomBarColor, for: .normal)
        showPasswordButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        
        showPasswordImageView = UIImageView(frame:CGRect(x: 0, y: 12, width: 16, height: 16))
        showPasswordImageView.image = UIImage(named: "ATShowPassword.png")
        showPasswordButton.addSubview(showPasswordImageView)


        savePasswordButton = UIButton(frame:CGRect(x: 15, y: 160, width: passwordView.bounds.size.width-20, height: 40))
        savePasswordButton.tag = 4
        savePasswordButton.addTarget(self, action: #selector(savePasswordButtonAction), for: UIControlEvents.touchUpInside)
        savePasswordButton.setTitle(NSLocalizedString("Do not save password", comment: ""), for: .normal)
        savePasswordButton.backgroundColor = UIColor.clear
        passwordView.addSubview(savePasswordButton)
        savePasswordButton.contentHorizontalAlignment = .left
        savePasswordButton.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: 20.0, bottom: 0.0, right: 0.0)
        savePasswordButton.setTitleColor(Constants.topBottomBarColor, for: .normal)
        savePasswordButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)

        savePasswordImageView = UIImageView(frame:CGRect(x: 0, y: 12, width: 16, height: 16))
        savePasswordImageView.image = UIImage(named: "ATHidePassword.png")
        savePasswordButton.addSubview(savePasswordImageView)

        
        let lineView = UIView(frame: CGRect(x: 0, y: passwordView.bounds.size.height-41 , width: passwordView.bounds.size.width, height: 1))
        lineView.backgroundColor = Constants.topBottomBarColor
        passwordView.addSubview(lineView)
        
        let confirmButton = CustomButton(frame:CGRect(x: passwordView.bounds.size.width/2, y: passwordView.bounds.size.height-40, width: passwordView.bounds.size.width/2, height: 40))
        confirmButton.addTarget(self, action: #selector(enterButtonAction), for: UIControlEvents.touchUpInside)
        confirmButton.setTitle(NSLocalizedString("CONFIRM", comment: ""), for: .normal)
        confirmButton.backgroundColor = UIColor.clear
        confirmButton.setTitleColor(UIColor.black, for: .normal)
        passwordView.addSubview(confirmButton)
        confirmButton.setTitleColor(Constants.topBottomBarColor, for: .normal)
        confirmButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        confirmButton.setBackgroundColor(color: Constants.listColor, forState: .highlighted)
        confirmButton.setTitleColor(Constants.backgroundWhiteColor, for: .highlighted)
        
        let cancelButton = CustomButton(frame:CGRect(x: 0, y: passwordView.bounds.size.height-40, width: passwordView.bounds.size.width/2, height: 40))
        cancelButton.addTarget(self, action: #selector(cancelButtonAction), for: UIControlEvents.touchUpInside)
        cancelButton.setTitle(NSLocalizedString("CANCEL", comment: ""), for: .normal)
        cancelButton.backgroundColor = UIColor.clear
        cancelButton.setTitleColor(UIColor.black, for: .normal)
        passwordView.addSubview(cancelButton)
        cancelButton.setTitleColor(Constants.topBottomBarColor, for: .normal)
        cancelButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        cancelButton.setBackgroundColor(color: Constants.listColor, forState: .highlighted)
        cancelButton.setTitleColor(Constants.backgroundWhiteColor, for: .highlighted)
        
        // Bottom line for title label
        let sideborder = CALayer()
        sideborder.borderColor = Constants.topBottomBarColor.cgColor
        sideborder.frame = CGRect(x: cancelButton.bounds.size.width-width, y: 0, width:  width, height: cancelButton.bounds.size.height)
        
        sideborder.borderWidth = width
        cancelButton.layer.addSublayer(sideborder)
        cancelButton.layer.masksToBounds = true
        
        loaderView = UIView(frame: CGRect(x: self.bounds.size.width/2-140, y: self.bounds.size.height/2-100, width: 280, height: 200))
        loaderView.layer.cornerRadius=5
        loaderView.backgroundColor = Constants.backgroundWhiteColor
        self.addSubview(loaderView)
        loaderView.isHidden = true
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        activityIndicator.frame = CGRect(x: loaderView.bounds.size.width/2-120/2, y: loaderView.bounds.size.height/2-120/2, width: 120, height: 120)
        loaderView.addSubview(activityIndicator)
        let transform : CGAffineTransform! = CGAffineTransform(scaleX: 2.5, y: 2.5)
        activityIndicator.transform = transform
        
        indicatorViewTopLabel = UILabel(frame:CGRect(x: 5, y: 5, width: passwordView.bounds.size.width-10, height: 30))
        indicatorViewTopLabel.text = ""
        indicatorViewTopLabel.textAlignment = NSTextAlignment.center
        indicatorViewTopLabel.font = UIFont.boldSystemFont(ofSize: 15)
        indicatorViewTopLabel.backgroundColor = UIColor.clear
        loaderView.addSubview(indicatorViewTopLabel)
        indicatorViewTopLabel.textColor = Constants.topBottomBarColor
        
        indicatorViewBottomLabel = UILabel(frame:CGRect(x: 5, y: loaderView.bounds.size.height - 35, width: passwordView.bounds.size.width-10, height: 30))
        indicatorViewBottomLabel.text = NSLocalizedString("Connecting . . . . .", comment: "")
        indicatorViewBottomLabel.textAlignment = NSTextAlignment.center
        indicatorViewBottomLabel.font = UIFont.boldSystemFont(ofSize: 15)
        indicatorViewBottomLabel.backgroundColor = UIColor.clear
        loaderView.addSubview(indicatorViewBottomLabel)
        indicatorViewBottomLabel.textColor = Constants.topBottomBarColor
        
        if securityString == "Open" {
            self.enterButtonAction()
        }
    }
    
    func cancelButtonAction() {
        self.removingObserver()
        self.delegate?.removeWifiPopover()
    }
    
    func enterButtonAction() {
        // handling code
        self.removingObserver()
        
        activityIndicator.startAnimating()
        passwordView.isHidden = true
        loaderView.isHidden = false
        
        if securityString == "Open" {
            Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(self.joinWifiForOpenNetwork), userInfo: nil, repeats: false)
        }
        else {
            if passwordTextField.text == "" {
                self.hideToastActivity()
                
                if isToastPresent == false {
                    self.makeToast(NSLocalizedString("Please enter password", comment: ""))
                    isToastPresent = true
                    Timer.scheduledTimer(timeInterval: ToastManager.shared.duration, target: self, selector: #selector(self.changeToastPresentStatus), userInfo: nil, repeats: false)
                }
                
                activityIndicator.stopAnimating()
                passwordView.isHidden = false
                loaderView.isHidden = true
                return
            }
            let password = passwordTextField.text!

            if savePassword {
                KeychainWrapper.standard.set(password,  forKey: wifiSSID)
            } else {
                KeychainWrapper.standard.removeObject(forKey: wifiSSID)
            }
            delegate?.joinWifiNetwork(password: password)
        }
    }
    
    func joinWifiForOpenNetwork() {
        delegate?.joinWifiNetwork(password: "")
    }
    
    func changeToastPresentStatus() {
        isToastPresent = false
    }
    
    //- notification selectors
    
    func onDeviceIdRead(_ notification: Notification) {
        deviceId = onBoardingService.onboardingDeviceId
        print("device id read: \(deviceId)")
        self.callRegisteredModuleViewController(dId: deviceId, deviceIp: ipAddress)
    }
    
    func onArtikIPRead(_ notification: Notification) {
        ipAddress = onBoardingService.ipAddress
        print("IP address read: \(ipAddress)")
    }
    
    func onPeripheralDisconnected(_ notification: Notification) {
        print("Device Disconnected")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "module_disconnected_or_poweredoff"), object: nil)
    }
    
    func joinWifiNetworkResponse(note: Notification) {
        //Handle Views
        if note.userInfo?["response"] as! String == "wifi_connected" {
            self.showSuccesfulMessage()
        }
        else if note.userInfo?["response"] as! String == "wrong_password" {
            loaderView.isHidden = true
            passwordView.isHidden = false
        }
        else if note.userInfo?["response"] as! String == "no_internet" {
            loaderView.isHidden = true
            passwordView.isHidden = false
        }
    }
    
    func showSuccesfulMessage() {
        activityIndicator.isHidden = false
        indicatorViewTopLabel.text = NSLocalizedString("Successfully Connected To Wi-Fi", comment: "")
        indicatorViewBottomLabel.text = NSLocalizedString("Registering module to ARTIK Cloud...", comment: "")
    }
    
    func callRegisteredModuleViewController(dId: String, deviceIp: String) {
        self.delegate?.showRegisteredModuleViewController(dId: dId, deviceIp: deviceIp)
    }
    
    func showPasswordButtonAction(sender:UIButton!) {
        if sender.tag == 1 {
            showPasswordImageView.image = UIImage(named: "ATHidePassword.png")
            sender.tag = 2
            passwordTextField.isSecureTextEntry = false
            showPasswordButton.setTitle(NSLocalizedString("Hide Password", comment: ""), for: .normal)
        }
        else{
            showPasswordImageView.image = UIImage(named: "ATShowPassword.png")
            sender.tag = 1
            passwordTextField.isSecureTextEntry = true
            showPasswordButton.setTitle(NSLocalizedString("Show Password", comment: ""), for: .normal)
        }
    }

    func savePasswordButtonAction(sender:UIButton!) {
        if sender.tag == 3 {
            savePasswordImageView.image = UIImage(named: "ATHidePassword.png")
            sender.tag = 4
            savePassword = true
            savePasswordButton.setTitle(NSLocalizedString("Do not save password", comment: ""), for: .normal)
        }
        else{
            savePasswordImageView.image = UIImage(named: "ATShowPassword.png")
            sender.tag = 3
            savePassword = false
            savePasswordButton.setTitle(NSLocalizedString("Save Password", comment: ""), for: .normal)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        return true
    }
    
    func keyboardWillShow(notification: NSNotification) {
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.frame.origin.y == 0{
                self.frame.origin.y -= keyboardSize.height
            }
        }
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.frame.origin.y != 0{
                self.frame.origin.y += keyboardSize.height
            }
        }
    }
    
    func removingObserver() {
        self.endEditing(true)
        //NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)

    }
    
}
