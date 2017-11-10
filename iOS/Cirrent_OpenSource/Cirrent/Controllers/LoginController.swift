//
//  LoginController.swift
//  Cirrent_New
//
//  Created by PSIHPOK on 12/17/16.
//  Copyright © 2016 PSIHPOK. All rights reserved.
//

import UIKit
import JGProgressHUD

class LoginController: UIViewController {

    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.items?[0].title = "Login"
                
        if SampleCloudService.sharedService.bLogged == true {
            autoLogin()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onGoWebSite(_ sender: Any) {
        let url = URL(string: Constants.CIRRENT_WEBSITE)
        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
    }

    @IBAction func onLogin(_ sender: Any) {
        if emailField.text == nil || emailField.text?.characters.count == 0 {
            ProgressView.sharedView.showAlert(viewController: self, message: "Please Fill Email Address Field.")
            return
        }
        
        if passwordField.text == nil || passwordField.text?.characters.count == 0 {
            ProgressView.sharedView.showAlert(viewController: self, message: "Please Fill Password Field.")
            return
        }
        
        ProgressView.sharedView.showProgressView(view: self.view)
        
        SampleCloudService.sharedService.login(username: emailField.text!, password: passwordField.text!, completion: {
            response in
            DispatchQueue.main.async {
                ProgressView.sharedView.dismissProgressView()
                if response == LOGIN_RESULT.SUCCESS {
                    SampleCloudService.sharedService.bLogged = true
                    self.goConfigureView()
                }
                else {
                    ProgressView.sharedView.showAlert(viewController: self, message: "We had a problem signing you in. Please try again.")
                }
            }
        })
    }
    
    func autoLogin() {
        let username = SampleCloudService.sharedService.username
        let password = SampleCloudService.sharedService.password
        
        if username == nil || password == nil {
            return
        }
        
        ProgressView.sharedView.showProgressView(view: self.view)
        
        emailField.text = username
        passwordField.text = password
        
        SampleCloudService.sharedService.login(username: username!, password: password!, completion: {
            response in
            DispatchQueue.main.async {
                ProgressView.sharedView.dismissProgressView()
                if response == LOGIN_RESULT.SUCCESS {
                    (UIApplication.shared.delegate as! AppDelegate).moveToMainController()
                }
                else {
                    ProgressView.sharedView.showAlert(viewController: self, message: "We had a problem signing you in. Please try again.")
                }
            }
        })
    }
    
    func goConfigureView() {
        self.performSegue(withIdentifier: "Configure", sender: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        super.touchesBegan(touches, with: event)
        
        if emailField.isFirstResponder && touch!.view != emailField {
            emailField.resignFirstResponder()
        }
        
        if passwordField.isFirstResponder && touch?.view != passwordField {
            passwordField.resignFirstResponder()
        }
    }
    
    func setUpNavigationBar() {
        self.navigationController?.navigationBar.tintColor = UIColor(red: 0, green: 0.73, blue: 1, alpha: 1)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }

}
