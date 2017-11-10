//
//  ViewController.swift
//  SamsungARTIK
//
//  Created by alimi shalini on 11/28/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit
import AFNetworking
import ReachabilitySwift
import SafariServices


class LoginViewController: UIViewController, SFSafariViewControllerDelegate, ATAlertViewDelegate, UIGestureRecognizerDelegate {
    
    
    @IBOutlet weak var userNameTF: CustomTextField!
    @IBOutlet weak var passwordTF: CustomTextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var noInternetView: UIView!
    let reachability = Reachability()!
    var confirmationAlert: ATConfirmationAlert!

    // Using SFSafariViewController ensure Single Sign On
    var loginWebView: SFSafariViewController!

    var alert : UIAlertController!
    var alertView: ATAlertView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Could not start reachability notifier")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        NotificationCenter.default.addObserver(self, selector: #selector(networkChange), name: NSNotification.Name(rawValue: Constants.NETWORK_CONNECTION_CHANGED), object: nil)
        self.networkChange()
    }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController)
    {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func networkChange() {
        if alertView != nil {
            alertView.removeFromSuperview()
        }
        
        noInternetView.isHidden = true
        if ATReachability.sharedInstance.isNetworkReachable == true {
            self.showLoginPage()
        }
        else {
            noInternetView.isHidden = false
            self.view.endEditing(true)
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
    
    // MARK: - ATAlertView Delegates
    
    func hideAlert() {
        networkChange()
    }
    
    func showLoginPage() {
        let url = URL(string: String(format: Constants.LOGIN_URL, Constants.CLIENT_ID))
        loginWebView = SFSafariViewController(url: url!)
        loginWebView!.delegate = self
        self.present(loginWebView!, animated: true, completion: nil)
    }
    
    func logoutUser() {
        let url = URL(string: Constants.LOGOUT_URL)
        loginWebView = SFSafariViewController(url: url!)
        loginWebView!.delegate = self
        self.present(loginWebView!, animated: true, completion: nil)
        self.dismiss(animated: false) {
            print("View dismissed")
        }

    }
       
    @IBAction func loginButtonAction(_ sender: Any) {
        let dashBoardControllerObj = self.storyboard!.instantiateViewController(withIdentifier: "DashBoardViewController") as! DashBoardViewController
        self.navigationController!.pushViewController(dashBoardControllerObj, animated: true)
        self.navigationController?.viewControllers = [dashBoardControllerObj]
    }
    
    @IBAction func newUserButtonAction(_ sender: Any) {
    }
    
    @IBAction func forgotPasswordButtonAction(_ sender: Any) {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

