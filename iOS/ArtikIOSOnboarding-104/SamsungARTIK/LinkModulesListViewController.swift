//
//  LinkModulesListViewController.swift
//  SamsungARTIK
//
//  Created by Surendra on 1/2/17.
//  Copyright © 2017 alimi shalini. All rights reserved.
//

import UIKit
import CoreData
import SwiftKeychainWrapper


class LinkModulesListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, Artik0OnboardingDelegate, ATAlertViewDelegate, ATConfirmationAlertDelegate, mDNSBrowserDelegate {
    
    @IBOutlet weak var topTextLabel: UILabel!
    @IBOutlet weak var noModulesRegisteredView: UIView!
    @IBOutlet weak var bottomView: CustomTopAndBottomBar!
    @IBOutlet weak var modulesTableView: UITableView!
    
    var confirmationAlert: ATConfirmationAlert!
    var modulesArray: [Module]!
    var bleMac: String!
    var alertView: ATAlertView!
    var selectedIndexPath : NSIndexPath!
    var deviceType: Int!
    
    var mBrowser: mDNSBrowser?
    var selectedIpAddress: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        ATUtilities.showIndicator(message:"")
        mBrowser = mDNSBrowser()
        mBrowser?.delegate = self
        self.fetchModules()
        
        modulesTableView.register(UINib(nibName: "RegisteredBoardsTableViewCell", bundle: nil), forCellReuseIdentifier: "RegisteredBoardsTableViewCell")
        modulesTableView.tableFooterView = UIView()
        modulesTableView.separatorColor = UIColor.gray
        modulesTableView.layoutMargins = UIEdgeInsets.zero
        modulesTableView.separatorInset = UIEdgeInsets.zero
        modulesTableView.isHidden = false
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.noModulesRegisteredView.isHidden = false
        topTextLabel.isHidden = false

    }

    @IBAction func okButtonAction(_ sender: Any) {
        _ = self.navigationController?.popToRootViewController(animated: true)
    }
    
    func fetchModules() {
        modulesArray = [Module]()
        mBrowser?.searchHubDevices()
        modulesTableView.reloadData()
        ATUtilities.hideIndicator()
    }
    
    func didFinish() {
        print("Finished searching hubs")
        sleep(1)

        if (mBrowser?.listHubs.count)! > 0 {
            noModulesRegisteredView.isHidden = true
            self.noModulesRegisteredView.isHidden = true
        }
        modulesTableView.reloadData()
    }
    
    // MARK: - TableView Delegates
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
         return 60 //cell height
    }
    
    func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {

        print("Total cells ", mBrowser?.listHubs.count)
        return (mBrowser?.listHubs.count)! + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Instantiate a cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "RegisteredBoardsTableViewCell", for: indexPath) as! RegisteredBoardsTableViewCell
        cell.layoutMargins = UIEdgeInsets.zero
        tableView.separatorStyle = .singleLine
        cell.backgroundColor = UIColor.clear

        let bgColorView = UIView()
        bgColorView.backgroundColor = Constants.listColor
        cell.selectedBackgroundView = bgColorView

        if indexPath.row != mBrowser?.listHubs.count {
            print("Filling cell with ", mBrowser?.listHubs[indexPath.row])
            let hubInfo = mBrowser?.listHubs[indexPath.row].components(separatedBy: ",")
            
            if hubInfo![1].contains("ARTIK5") {
                cell.artikImageView.image = #imageLiteral(resourceName: "icon_artik5")
                
            } else {
                cell.artikImageView.image = #imageLiteral(resourceName: "icon_artik7")
            }
            
            cell.moduleNameLabel.text = hubInfo![0]
            cell.deviceStatusLabel.text = hubInfo![1]
            cell.moduleLocationLabel.text = nil
            cell.artikImageView.isHidden = false
            cell.deviceStatusIcon.isHidden = true
        }
        else {
            cell.backgroundColor = UIColor(colorLiteralRed: 151/255.0, green: 151/255.0, blue: 151/255.0, alpha: 1)
            cell.moduleNameLabel.text = nil
            cell.moduleLocationLabel.text = nil
            cell.artikImageView.isHidden = true
            cell.backgroundColor = UIColor.clear
            cell.deviceStatusIcon.isHidden = true
            cell.deviceStatusLabel.text = nil
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.row == mBrowser?.listHubs.count {
            return
        }
        
        selectedIpAddress = ((mBrowser?.listHubs[indexPath.row])?.components(separatedBy: ","))![0]

        self.showConfirmationAlert(message: NSLocalizedString("Are you sure you want to continue?", comment: "") , action: "ARTIK0",title: NSLocalizedString("Confirmation", comment: ""))

        tableView.deselectRow(at: indexPath, animated: true)
        selectedIndexPath = indexPath as NSIndexPath!

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
        
        self.hideConfirmationAlert()
        self.onBoardArtikZero(withIPAddress: selectedIpAddress)
    }
    
    func onBoardArtikZero(withIPAddress ipa: String) {
        
        ATUtilities.showIndicator(message:NSLocalizedString("Registering module to ARTIK Cloud...", comment: ""))
        let onboardingService = Artik0OnboardingService()
        onboardingService.onBoardingDelegate = self
        onboardingService.ipaddress = ipa
        
        let defaults = UserDefaults.standard
        let dataDic = defaults.object(forKey:Constants.MODULE_AND_LOCATION_DICTIONARY)! as! [String:Any]
        let moduleName = (dataDic[Constants.MODULE_NAME] as! String)
        
        onboardingService.startOnboarding(bleMac, name: moduleName)
        
    }
    
    // MARK: - Artik0OnboardingDeleage
    
    func didOnboardArtik0() {
        ATUtilities.hideIndicator()
        self.showRegisteredModuleViewController()
    }
    
    func showRegisteredModuleViewController() {
        let registeredModuleControllerObj = self.storyboard!.instantiateViewController(withIdentifier: "RegisteredModuleViewController") as! RegisteredModuleViewController
        registeredModuleControllerObj.deviceType = deviceType
        
        if self.navigationController == nil {
            let nvc = self.storyboard!.instantiateViewController(withIdentifier: "dashBoardNavigationController") as! UINavigationController
            nvc.pushViewController(registeredModuleControllerObj, animated: true)
        }
        else {
            self.navigationController!.pushViewController(registeredModuleControllerObj, animated: true)
        }
        
    }
    
    func onboardingFailed(_ message: String) {
        ATUtilities.hideIndicator()
        self.showAlert(message: message)
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
    
    // MARK: - ATAlertView Delegates
    
    func hideAlert() {
        alertView.removeFromSuperview()
    }
    
    func appDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        _ = self.navigationController?.popToRootViewController(animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    
}

@IBDesignable class PaddingLabel: UILabel {
    
    @IBInspectable var topInset: CGFloat = 0.0
    @IBInspectable var bottomInset: CGFloat = 0.0
    @IBInspectable var leftInset: CGFloat = 17.0
    @IBInspectable var rightInset: CGFloat = 17.0
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
    
}
