//
//  SelectDeviceController.swift
//  Cirrent_New
//
//  Created by PSIHPOK on 12/17/16.
//  Copyright © 2016 PSIHPOK. All rights reserved.
//

import UIKit
import SDWebImage

class SelectDeviceController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var deviceListView: UITableView!
    
    let identifyActionCellID = "IdentifyActionCell"
    let normalActionCellID = "NormalActionCell"
    let identifyActionCell_NibName = "IdentifyActionCell"
    let normalActionCell_NibName = "NormalActionCell"
    
    let identifyActionCellHeight:CGFloat = 200
    let normalActionCellHeight:CGFloat = 170
    
    var bIdentifyActionProgressViewShown:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Select Device"
        
        registerCell()
        CirrentService.sharedService.pollForUserAction(tokenMethod: SampleCloudService.sharedService.getToken, completion: {
            device in
            var index = 0
            let model = CirrentService.sharedService.model
            
            var bFind:Bool = false
            if model != nil && model!.getDevices() != nil && model!.getDevices()?.count != 0 {
                for dev in model!.getDevices()! {
                    if dev.getDeviceID() == device.getDeviceID() {
                        bFind = true
                        break
                    }
                    index += 1
                }
            }
            
            if bFind == true {
                let indexPath:IndexPath = IndexPath(row: index, section: 0)
                DispatchQueue.main.async {
                    self.deviceListView.beginUpdates()
                    self.deviceListView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.none)
                    self.deviceListView.endUpdates()
                }
            }
        })
    }
    
    func registerCell() {
        deviceListView.register(UINib(nibName: identifyActionCell_NibName, bundle: nil), forCellReuseIdentifier: identifyActionCellID)
        deviceListView.register(UINib(nibName: normalActionCell_NibName, bundle: nil), forCellReuseIdentifier: normalActionCellID)
        deviceListView.delaysContentTouches = false
        
        for subview in deviceListView.subviews {
            if subview is UIScrollView {
                (subview as! UIScrollView).delaysContentTouches = false
                break
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let devices = CirrentService.sharedService.model?.getDevices()
        let count = devices?.count
        return count!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell? = nil
        let devices = CirrentService.sharedService.model?.getDevices()
        let device = devices![indexPath.row]
        if device.getIdentifyingActionEnabled() == true {
            cell = tableView.dequeueReusableCell(withIdentifier: identifyActionCellID)
            (cell as! IdentifyActionCell).parentView = self.view
            (cell as! IdentifyActionCell).device = device
            (cell as! IdentifyActionCell).parentController = self
            (cell as! IdentifyActionCell).indexPath = indexPath
            (cell as! IdentifyActionCell).deviceAliasField.text = device.friendlyName
            (cell as! IdentifyActionCell).deviceImageView.sd_setImage(with: URL(string: device.getImageURL()))
            
            if device.getUserActionEnabled() == false {
                (cell as! IdentifyActionCell).userActionCheckMark.isHidden = true
            }
            else {
                (cell as! IdentifyActionCell).userActionCheckMark.isHidden = false
            }
            
            if device.getConfirmedOwnerShip() == true {
                (cell as! IdentifyActionCell).userActionCheckMark.image = #imageLiteral(resourceName: "check-mark")
            }
            else {
                (cell as! IdentifyActionCell).userActionCheckMark.image = #imageLiteral(resourceName: "unchecked")
            }
        }
        else {
            cell = tableView.dequeueReusableCell(withIdentifier: normalActionCellID)
            (cell as! NormalActionCell).device = device
            (cell as! NormalActionCell).parentView = self.view
            (cell as! NormalActionCell).parentController = self
            (cell as! NormalActionCell).indexPath = indexPath
            (cell as! NormalActionCell).deviceAliasField.text = device.friendlyName
            (cell as! NormalActionCell).deviceImageView.sd_setImage(with: URL(string: device.getImageURL()))
            
            if device.getUserActionEnabled() == false {
                (cell as! NormalActionCell).userActionCheckMark.isHidden = true
            }
            else {
                (cell as! NormalActionCell).userActionCheckMark.isHidden = false
            }
            
            if device.getConfirmedOwnerShip() == true {
                (cell as! NormalActionCell).userActionCheckMark.image = #imageLiteral(resourceName: "check-mark")
            }
            else {
                (cell as! NormalActionCell).userActionCheckMark.image = #imageLiteral(resourceName: "unchecked")
            }
        }
        
        cell?.accessoryType = .disclosureIndicator
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let devices = CirrentService.sharedService.model!.getDevices()
        let device = devices![indexPath.row]
        
        if device.getUserActionEnabled() == false {
            ProgressView.sharedView.showProgressView(view: self.view)
            selectDeviceAndAskStatus(device: device)
        }
        else {
            if device.getConfirmedOwnerShip() == true {
                CirrentService.sharedService.stopPollForUserAction()
                ProgressView.sharedView.showProgressView(view: self.view)
                selectDeviceAndAskStatus(device: device)
            }
            else {
                ProgressView.sharedView.showToast(view: self.view, message: device.getUserActionDescription())
            }
        }
    }
    
    func selectDeviceAndAskStatus(device:Device) {
        _ = CirrentService.sharedService.selectDevice(deviceID: device.deviceId)
        SampleCloudService.sharedService.bindDevice(deviceID: device.getDeviceID(), friendlyName: device.friendlyName, completion: {
            token, response in
            
            if response != .SUCCESS {
                DispatchQueue.main.async {
                    ProgressView.sharedView.showToast(view: self.view, message: "There is a problem binding the device. Try again.")
                }
            }
            else {
                CirrentService.sharedService.bindDevice(tokenMethod: SampleCloudService.sharedService.getToken, deviceID: device.getDeviceID(), friendlyName: nil, completion: {
                    response in
                    
                    if response != .SUCCESS {
                        DispatchQueue.main.async {
                            ProgressView.sharedView.showToast(view: self.view, message: "There is some problem binding the device. Try again.")
                        }
                    }
                    else {
                        SampleCloudService.sharedService.bindedDevice = true
                        SampleCloudService.sharedService.getBoundDevices(completion: {
                            result, devices in
                            
                            if result != .SUCCESS {
                                DispatchQueue.main.async {
                                    ProgressView.sharedView.showToast(view: self.view, message: "There is some problem on the device. Try again.")
                                }
                            }
                            else {
                                CirrentService.sharedService.getDeviceStatus(tokenMethod: SampleCloudService.sharedService.getToken, deviceID: device.getDeviceID(), uptime: false, completion: {
                                    response, status in
                                    
                                    if response != .SUCCESS {
                                        DispatchQueue.main.async {
                                            ProgressView.sharedView.showToast(view: self.view, message: "There is some problem on the device. Try again.")
                                        }
                                    }
                                    else {
                                        DispatchQueue.main.async {
                                            ProgressView.sharedView.dismissProgressView()
                                            self.performSegue(withIdentifier: "DeviceDetail", sender: nil)
                                        }
                                    }
                                })
                            }
                        })
                    }
                })
            }
        })
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let devices = CirrentService.sharedService.model!.getDevices()
        let device = devices![indexPath.row]
        if device.getIdentifyingActionEnabled() != false {
            return self.identifyActionCellHeight
        }
        else {
            return self.normalActionCellHeight
        }
    }

    @IBAction func onGoSoftAP(_ sender: Any) {
        self.performSegue(withIdentifier: "SoftAP", sender: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.navigationController!.viewControllers.index(of: self) == nil {
            CirrentService.sharedService.stopPollForUserAction()
        }
        CirrentService.sharedService.stopPollForUserAction()
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SoftAP" {
            let SoftAPController:GoToSoftAPController = segue.destination as! GoToSoftAPController
            SoftAPController.bShouldFindDevice = false
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if bIdentifyActionProgressViewShown == true {
            bIdentifyActionProgressViewShown = false
            ProgressView.sharedView.dismissProgressView()
        }
    }
}
