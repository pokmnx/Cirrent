//
//  DeviceManageController.swift
//  Cirrent
//
//  Created by PSIHPOK on 2/23/17.
//  Copyright © 2017 Cirrent. All rights reserved.
//

import UIKit
import ActionCell


class ManageDeviceController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var deviceTableView: UITableView!
    var tableView: UITableView!
    
    
    var deviceArray:[SampleDevice] = [SampleDevice]()
    let cellIdentifier = "deviceManageCell"
    let cellHeight:CGFloat = 100
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView = deviceTableView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setTitle(title: "Setup")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        ProgressView.sharedView.showProgressView(view: self.view)
        SampleCloudService.sharedService.getBoundDevices(completion: {
            response, devices in
            
            DispatchQueue.main.async {
                ProgressView.sharedView.dismissProgressView()
                if response != BOUND_DEVICES_RESULT.SUCCESS {
                    self.goToAddNewDevice()
                }
                else {
                    if devices != nil {
                        self.deviceArray = devices!
                        for device in self.deviceArray {
                            let key = device.deviceID + "_friendlyName"
                            let friendlyName = UserDefaults.standard.string(forKey: key)
                            if friendlyName != nil {
                                device.friendlyName = friendlyName!
                            }
                            else {
                                device.friendlyName = device.deviceID
                            }
                        }
                        
                        self.deviceTableView.reloadData()
                    }
                    else {
                        self.goToAddNewDevice()
                    }
                }
            }
        })
    }
    
    func goToAddNewDevice() {
        self.performSegue(withIdentifier: "AddNewDevice", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:DeviceManageCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! DeviceManageCell
        
        let device = deviceArray[indexPath.row]
        
        cell.deviceImageView.sd_setImage(with: URL(string: device.imageURL))
        cell.deviceFriendlyName.text = device.friendlyName
        cell.deviceCompany.text = device.name
        cell.deviceType.text = device.deviceID
        
        let wrapper = ActionCell()
        wrapper.delegate = self
        wrapper.animationStyle = .ladder
        wrapper.wrap(cell: cell, actionsLeft: [], actionsRight: [
            {
                let action = TextAction(action: "delete")
                action.label.text = "Delete"
                action.label.font = UIFont.systemFont(ofSize: 15)
                action.label.textColor = UIColor.white
                action.backgroundColor = UIColor(red:0.9, green:0.1, blue:0.1, alpha:1.0)
                return action
            }(),
            {
                let action = TextAction(action: "edit")
                action.label.text = "Edit"
                action.label.font = UIFont.systemFont(ofSize: 15)
                action.label.textColor = UIColor.white
                action.backgroundColor = UIColor(red:0.9, green:0.8, blue:0.1, alpha:0.5)
                return action
            }(),
            ])
        
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == nil {
            return
        }
        
        if segue.identifier! == "manageNetwork" {
            let cell = sender as! UITableViewCell
            let indexPath = deviceTableView.indexPath(for: cell)
            if indexPath == nil {
                return
            }
            
            let destination = segue.destination as! ManageNetworkController
            destination.deviceID = deviceArray[indexPath!.row].deviceID
        }
    }
    
}

extension ManageDeviceController : ActionCellDelegate {
    public func didActionTriggered(cell: UITableViewCell, action: String) {
        let indexPath = deviceTableView.indexPath(for: cell)
        if indexPath == nil {
            return
        }
        
        let device = deviceArray[indexPath!.row]
        
        if action == "delete" {
            ProgressView.sharedView.showProgressView(view: self.view)
            CirrentService.sharedService.resetDevice(tokenMethod: SampleCloudService.sharedService.getToken, deviceID: device.deviceID, completion: {
                response in
                
                if response != .SUCCESS {
                    DispatchQueue.main.async {
                        ProgressView.sharedView.dismissProgressView()
                        ProgressView.sharedView.showToast(view: self.view, message: "Failed to remove device from your account.")
                    }
                }
                else {
                    SampleCloudService.sharedService.resetDevice(deviceID: device.deviceID, completion: {
                        token, response in
                        
                        if response == .SUCCESS {
                            self.deviceArray.remove(at: indexPath!.row)
                            DispatchQueue.main.async {
                                self.deviceTableView.deleteRows(at: [indexPath!], with: .left)
                                ProgressView.sharedView.dismissProgressView()
                            }
                        }
                        else {
                            DispatchQueue.main.async {
                                ProgressView.sharedView.dismissProgressView()
                                ProgressView.sharedView.showToast(view: self.view, message: "Failed to remove device from your account.")
                            }
                        }
                    })
                }
            })
/*
            SampleCloudService.sharedService.resetDevice(deviceID: device.deviceID, completion: {
                token, response in
                
                if response != .SUCCESS {
                    DispatchQueue.main.async {
                        ProgressView.sharedView.dismissProgressView()
                        ProgressView.sharedView.showToast(view: self.view, message: "Failed to remove device from your account.")
                    }
                }
                else {
                    CirrentService.sharedService.resetDevice(tokenMethod: SampleCloudService.sharedService.getToken, deviceID: device.deviceID, completion: {
                        response in
                        
                        if response == .SUCCESS {
                            self.deviceArray.remove(at: indexPath!.row)
                            DispatchQueue.main.async {
                                self.deviceTableView.deleteRows(at: [indexPath!], with: .left)
                                ProgressView.sharedView.dismissProgressView()
                            }
                        }
                        else {
                            DispatchQueue.main.async {
                                ProgressView.sharedView.dismissProgressView()
                                ProgressView.sharedView.showToast(view: self.view, message: "Failed to remove device from your account.")
                            }
                        }
                    })
                }
            })
*/
        }
        else if action == "edit" {
            let alertController = UIAlertController(title: "Custom Device Name", message: "Please type new device name.", preferredStyle: .alert)
            alertController.addTextField(configurationHandler: {
                textfield in
                textfield.text = device.friendlyName
            })
            
            let saveAction = UIAlertAction(title: "Save", style: .default, handler: {
                action in
                DispatchQueue.main.async {
                    let textfield = alertController.textFields![0]
                    if textfield.text != nil && textfield.text != "" {
                        device.friendlyName = textfield.text!
                        let key = device.deviceID + "_friendlyName"
                        UserDefaults.standard.set(device.friendlyName, forKey: key)
                        self.tableView.reloadRows(at: [indexPath!], with: .none)
                    }
                }
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alertController.addAction(saveAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
