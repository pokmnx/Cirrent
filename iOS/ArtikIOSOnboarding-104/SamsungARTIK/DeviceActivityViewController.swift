//
//  DeviceActivityViewController.swift
//  SamsungARTIK
//
//  Created by Vaibhav Singh on 09/03/17.
//  Copyright © 2017 alimi shalini. All rights reserved.
//

import UIKit

class DeviceActivityViewController: UIViewController, UIPopoverPresentationControllerDelegate, ATInformationAlertDelegate, ATConfirmationAlertDelegate, ATAlertViewDelegate {
    
    let dropDownMenu : [String] = ["Information", "Delete"]
    
    @IBOutlet weak var deviceName: UITextView!
    var module : Module!
    var informationAlert: ATInformationAlert!
    var confirmationAlert: ATConfirmationAlert!
    var alertView: ATAlertView!
    var deviceDeleted : Bool =  false


    @IBAction func onMenuItemSelected(_ sender: UIButton) {

        let popController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DropDownViewController")
        let viewController = popController as? DropDownViewController
        viewController?.updateItems(items: dropDownMenu)
        // set the presentation style
        popController.modalPresentationStyle = UIModalPresentationStyle.popover
        // set up the popover presentation controller
        popController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.up
        popController.popoverPresentationController?.delegate = self
        popController.popoverPresentationController?.sourceView = sender
        popController.preferredContentSize = CGSize(width: 150, height: 100)
        popController.popoverPresentationController?.sourceRect = sender.bounds
        // present the popover
        self.present(popController, animated: true, completion: nil)

    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }


    public func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        module = self.appDelegate().selectedModule
        deviceName.text = module.name
        addObservers()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        deviceDeleted = false
    }
    
    
    @IBAction func back(_ sender: UIButton) {
        _ = navigationController?.popViewController(animated: true)
    }
    

    func appDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(DropdownSelectedAction(note:)), name: NSNotification.Name(rawValue: "DropdownSelectedIndex"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deleteSuccess), name: NSNotification.Name(rawValue: Constants.MODULE_DELETED_NOTIF), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deleteFailed), name: NSNotification.Name(rawValue: Constants.MODULE_DELETE_FAILED), object: nil)
    }

    func DropdownSelectedAction(note:Notification) {
        let index = note.object as! Int
        print("Received index \(index)")

        if index == 0 {
            showInformationAlert(module: module)
        } else  if index == 1 {
            self.showConfirmationAlert(message: NSLocalizedString("Are you sure to delete?", comment: "") , action: "delete",title: NSLocalizedString("Delete", comment: ""))
        } else {
            print("Not reachabled code")
        }
    }

    func deleteSuccess() {
        ATUtilities.hideIndicator()
        self.appDelegate().deviceDeleted = true
        showAlert(message: "Successfully deleted the device from the cloud")
        
    }


    func deleteFailed(notification: Notification) {
        ATUtilities.hideIndicator()
        guard let userInfo = notification.userInfo else { return }
        if let errorMsg = userInfo["errorDesc"] as? String {
            self.showAlert(message: errorMsg)
        }
    }


    func showInformationAlert(module:Module) {
        let strModuleName: String? = module.name
        let strModuleDate =  module.createdOn!

        //Getting unix string (First 10 characters)
        let start = strModuleDate.index(strModuleDate.startIndex, offsetBy: 9)
        let end = strModuleDate.index(strModuleDate.startIndex, offsetBy: 18)

        let range = start...end
        let substring = strModuleDate[range]

        var strModuleLocation: String? = module.moduleLocation

        if let strLocation = module.moduleLocation {
            if strLocation == "" {
                strModuleLocation = NSLocalizedString("Unspecified Location", comment: "")
            }
        }
        else {
            strModuleLocation = NSLocalizedString("Unspecified Location", comment: "")
        }

        informationAlert = ATInformationAlert(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height), moduleDate: substring, moduleName: strModuleName!, moduleLocation: strModuleLocation!)
        informationAlert.delegate = self
        informationAlert.backgroundColor = UIColor.clear
        self.view.addSubview(informationAlert)

        informationAlert.translatesAutoresizingMaskIntoConstraints = false

        let subviewsDict: Dictionary = ["informationAlert": informationAlert];

        let arrXconstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[informationAlert]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.view.addConstraints(arrXconstraints)

        let arrYconstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[informationAlert]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.view.addConstraints(arrYconstraints)
    }

    func okButtonAction() {
        informationAlert.removeFromSuperview()
    }

    func showConfirmationAlert(message: String, action: String,title:String) {

        confirmationAlert = ATConfirmationAlert(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height), message: message, action: action, title:title )
        confirmationAlert.delegate = self
        confirmationAlert.backgroundColor = UIColor.clear
        self.view.addSubview(confirmationAlert)

        confirmationAlert.translatesAutoresizingMaskIntoConstraints = false

        let subviewsDict: Dictionary = ["confirmationAlert": confirmationAlert];

        let arrXconstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[confirmationAlert]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.view.addConstraints(arrXconstraints)

        let arrYconstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[confirmationAlert]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.view.addConstraints(arrYconstraints)
    }

    func hideConfirmationAlert() {
        confirmationAlert.removeFromSuperview()
    }

    func confirmButtonAction(action: String) {
        if ATReachability.sharedInstance.isNetworkReachable == true {
            if action == "delete" {
                self.appDelegate().deleteModule(deviceId: module.id! as String)
            }
        }
        else {
            if action == "delete" {
                self.showAlert(message: NSLocalizedString("Delete Failed. No internet connection.", comment: ""))
            }
        }

        confirmationAlert.removeFromSuperview()
    }

    func showAlert(message: String) {
        alertView = ATAlertView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height), message: message , cancelButtonTitle: NSLocalizedString("OK", comment: ""), confirmButtonTitle: "")
        alertView.delegate = self
        alertView.backgroundColor = UIColor.clear
        self.view.addSubview(alertView)

        alertView.translatesAutoresizingMaskIntoConstraints = false

        let subviewsDict: Dictionary = ["alertView": alertView];

        let arrXconstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[alertView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.view.addConstraints(arrXconstraints)

        let arrYconstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[alertView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.view.addConstraints(arrYconstraints)
    }

    func hideAlert() {
        alertView.removeFromSuperview()
        if self.appDelegate().deviceDeleted {
             _ = navigationController?.popViewController(animated: true)
        }
    }

}
