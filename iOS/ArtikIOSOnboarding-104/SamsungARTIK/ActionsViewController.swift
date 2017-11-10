//
//  ActionsViewController.swift
//  SamsungARTIK
//
//  Created by Vaibhav Singh on 09/03/17.
//  Copyright © 2017 alimi shalini. All rights reserved.
//

import UIKit
import ArtikCloud
import Toaster

class ActionsViewController: UIViewController , UITableViewDataSource, UITableViewDelegate, ATAlertViewDelegate  {

    @IBOutlet weak var actionsTableView: UITableView!

    var alertView: ATAlertView!
    var isAlertActive : Bool = false

    var deviceManifest : ACFieldsActions?
    var module : Module!
    var actions: [String : NSObject]!
    var actionNames = [String]()
    var actionObjects = [NSObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        actionsTableView.register(UINib(nibName: "ActionsTableViewCell", bundle: nil), forCellReuseIdentifier: "ActionsTableViewCell")
        actionsTableView.tableFooterView = UIView()
        actionsTableView.separatorColor = UIColor.gray
       // actionsTableView.layoutMargins = UIEdgeInsets.zero
        actionsTableView.separatorInset = UIEdgeInsets.zero

    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        actionsTableView.reloadData()

        /* Check to see if any actions need to be sent */
        if self.appDelegate().actionParams != nil {
            print("Sending action to the cloud")
            ATUtilities.showIndicator(message: "Sending action to the cloud")
            self.appDelegate().postActions(name: self.appDelegate().selectedActionName, ddid: self.module.id!, parameters: self.appDelegate().actionParams!)
            self.appDelegate().actionParams = nil

        }


    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.addObservers()

        module = self.appDelegate().selectedModule
        deviceManifest = ATDatabaseManager.getDeviceManifest(deviceTypeId: module.dtid!, version: String(describing: module.manifestVersion))

        if (deviceManifest == nil) {
            self.appDelegate().getDeviceManifest(deviceTypeId: module.dtid!, Version: String(describing: module.manifestVersion))
        } else {
            actions = deviceManifest?.actions
            for (actionName, actionObject) in actions {
                actionNames.append(actionName)
                actionObjects.append(actionObject)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }

    func fetchManifest() {

        deviceManifest = ATDatabaseManager.getDeviceManifest(deviceTypeId: module.dtid!, version: String(describing: module.manifestVersion))

        if (deviceManifest != nil) {
            actions = deviceManifest?.actions
            for (actionName, actionObject) in actions {
                actionNames.append(actionName)
                actionObjects.append(actionObject)
            }

            actionsTableView.reloadData()
        }

    }

    func showAlert(message: String) {

        if isAlertActive {
            print ("Returning as alert is already active")
            return
        }

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

    func actionSuccess() {
        print("Action Sent Success")
        ATUtilities.hideIndicator()
        ATUtilities.showToastMessage(message: "SUCCEEDED to send the action")

    }

    func actionFailed() {
        ATUtilities.hideIndicator()
        print("Action Sent FAILED")
        showAlert(message: "FAILED to send the action")
        //ATUtilities.showToast(message: "FAILED to send the action")
    }

    func hideAlert() {
        self.alertView.delegate = nil
        self.alertView.removeFromSuperview()
        self.isAlertActive = false
    }

    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.fetchManifest), name: NSNotification.Name(rawValue: "fetch_manifest_data"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.actionSuccess), name: NSNotification.Name(rawValue: "action_success"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.actionFailed), name: NSNotification.Name(rawValue: "action_failed"), object: nil)
    }

    func appDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    // MARK: - TableView Delegates
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
       
        return 90 //cell height
       
    }
    
    func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        
        if actions != nil {
            return actions.count + 1
        }
 
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Instantiate a cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActionsTableViewCell", for: indexPath) as! ActionsTableViewCell

        if indexPath.row == actions.count {
            /* We use the last cell to resolve the problem of the last cell not showing up completely */

            if indexPath.row == 0 {
                cell.name.text = "No Actions"
                cell.desc.text = "There are no actions provisioned for this device"
                cell.icon.isHidden = true
            } else {
                cell.isHidden = true
            }
        } else {

            cell.desc.isHidden = false
            cell.icon.isHidden = false
            cell.name.isHidden = false
            cell.name.text = actionNames[indexPath.row]

            let action = actionObjects[indexPath.row] as! NSDictionary
            cell.desc.text = action.object(forKey: "description") as? String

        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)

        let row = indexPath.row

        if row == actionNames.count {
            return
        }

        let action = actionObjects[indexPath.row] as! NSDictionary
        let params = action.object(forKey: "parameters") as? NSDictionary

        if params == nil || (params?.count)! > 0 {
            //showAlert(message: "Actions with parameters will soon be supported.")
            if isMultiLevelManifest(params: params!) {
                showAlert(message: "Multi Level Device Manifest is not supported")
                return
            }

            self.appDelegate().selectedActionName = actionNames[row]
            self.appDelegate().selectedActionObject = actionObjects[row]
            launchActionParamsView()
        } else {
            self.appDelegate().postActions(name: actionNames[row], ddid: module.id!, parameters: [:])
            ATUtilities.showIndicator(message: "Sending action to the cloud")
        }

    }


    func isMultiLevelManifest(params : NSDictionary) -> Bool {

        for (_, value) in params {
            let child = value as! NSDictionary
            let type = child.object(forKey: "type") as Any?
            if type == nil {
                return true
            }
        }
        return false;
    }

    func launchActionParamsView() {

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "ActionParameters")
        self.present(controller, animated: true, completion: nil)
        

    }

}
