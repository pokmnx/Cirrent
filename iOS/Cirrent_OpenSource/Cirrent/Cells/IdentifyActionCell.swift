//
//  IdentifyActionCell.swift
//  Cirrent_New
//
//  Created by PSIHPOK on 12/17/16.
//  Copyright © 2016 PSIHPOK. All rights reserved.
//

import UIKit

class IdentifyActionCell: UITableViewCell, UITextFieldDelegate {

    var device:Device!
    var parentView:UIView!
    var indexPath:IndexPath!
    var parentController:SelectDeviceController!
    var inputField:UITextField? = nil
    
    
    @IBOutlet weak var deviceAliasField: UITextField!
    @IBOutlet weak var userActionCheckMark: UIImageView!
    @IBOutlet weak var deviceImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func onClickIdentifyYourselfAction(_ sender: Any) {
        CirrentService.sharedService.identifyYourself(tokenMethod: SampleCloudService.sharedService.getToken, deviceID: device.getDeviceID(), completion: {
            response in
            
            self.parentController.bIdentifyActionProgressViewShown = true
            if response == .SUCCESS {
                DispatchQueue.main.async {
                    ProgressView.sharedView.showToast(view: self.parentView, message: self.device.getIdentifyingActionDescription(), duration: 10)
                }
            }
            else {
                DispatchQueue.main.async {
                    ProgressView.sharedView.showToast(view: self.parentView, message: "Identify Failed", duration: 10)
                }
            }
        })
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.deviceAliasField.isEnabled = false
        let alertController = UIAlertController(title: "Custom Device Name", message: "Please type new device name.", preferredStyle: .alert)
        alertController.addTextField(configurationHandler: {
            textfield in
            textfield.text = self.device!.friendlyName
            self.inputField = textField
        })
        
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: {
            action in
            DispatchQueue.main.async {
                let textfield = alertController.textFields![0]
                self.deviceAliasField.text = textfield.text!
                if self.indexPath != nil && self.parentController != nil {
                    self.device.friendlyName = textfield.text!
                    self.parentController.deviceListView.reloadRows(at: [self.indexPath], with: .none)
                }
                self.deviceAliasField.isEnabled = true
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            action in
            DispatchQueue.main.async {
                self.deviceAliasField.isEnabled = true
            }
            
        })
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        self.parentController!.present(alertController, animated: true, completion: nil)
        
        return false
    }
    
    
}
