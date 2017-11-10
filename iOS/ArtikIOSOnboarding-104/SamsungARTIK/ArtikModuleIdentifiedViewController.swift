//
//  ArtikModuleIdentifiedViewController.swift
//  SamsungARTIK
//
//  Created by Surendra on 12/1/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper


class ArtikModuleIdentifiedViewController: UIViewController,UITextFieldDelegate {
    
    @IBOutlet weak var artikTypeLabel: UILabel!
    @IBOutlet weak var artikTypeImageView: UIImageView!
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var titleTextField: TitlesTextField!
    @IBOutlet weak var entryFieldsBackgroundView: UIView!
    @IBOutlet weak var viewUUID: UIView!
    @IBOutlet weak var plugInView: UIView!
    @IBOutlet weak var enterButton: CustomButton!
    @IBOutlet weak var skipButton: CustomButton!
    @IBOutlet weak var plugInImageView: UIImageView!
    @IBOutlet weak var continueButton: CustomButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var enterModuleLocationTextField: TextFieldValidator!
    @IBOutlet weak var enterModuleNameTextfield: TextFieldValidator!
    @IBOutlet weak var manualOrQRLabel: UILabel!
    @IBOutlet weak var uuidLabel: UILabel!
    var bleMac: String!
    var isFromManual : Bool!
    var deviceType: Int!
    var uuidString: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x:0.0, y:titleView.frame.size.height - 1.0, width:titleView.frame.width+100, height:0.5)
        bottomLine.backgroundColor = UIColor.white.cgColor
        
        titleView.layer.addSublayer(bottomLine)

        enterModuleNameTextfield.presentInView=self.view;
        enterModuleLocationTextField.presentInView=self.view;
        enterModuleLocationTextField.isMandatory = false
        enterModuleNameTextfield.isMandatory = false
        
        enterButton.isUserInteractionEnabled = false
        enterButton.alpha = 0.5
        enterModuleLocationTextField.setValue(UIColor.init(colorLiteralRed: 101/255.0, green: 106/255.0, blue: 110/255.0, alpha: 1), forKeyPath: "_placeholderLabel.textColor")
        enterModuleNameTextfield.setValue(UIColor.init(colorLiteralRed: 101/255.0, green: 106/255.0, blue: 110/255.0, alpha: 1), forKeyPath: "_placeholderLabel.textColor")
        
        viewUUID.layer.borderColor = UIColor(colorLiteralRed: 247/255.0, green: 148/255.0, blue: 29/255.0, alpha: 1).cgColor
        
        if isFromManual == true{
            manualOrQRLabel.text = NSLocalizedString("Module ID", comment: "")
        }
        else{
            manualOrQRLabel.text = NSLocalizedString("QR code", comment: "")
        }
        
        uuidLabel.text = uuidString
        uuidLabel.text = uuidLabel.text?.uppercased()
        
        deviceType = Int(ATUtilities.artikDeviceId())
        titleTextField.text = String(format: "ARTIK %@ identified", ATUtilities.artikDeviceId())
        
        artikTypeLabel.text = String(format: "ARTIK %@ identified", ATUtilities.artikDeviceId())
        
        if deviceType == 0 {
            artikTypeImageView.image = #imageLiteral(resourceName: "icon_artik0")
        }
        else if deviceType == 5 {
            artikTypeImageView.image = #imageLiteral(resourceName: "icon_artik5")
        }
        else if deviceType == 7 {
            artikTypeImageView.image = #imageLiteral(resourceName: "icon_artik7")
        }
        else {
            artikTypeImageView.image = #imageLiteral(resourceName: "icon_artik10")
        }
        
        enterModuleLocationTextField.underlined(width: 0.4)
        enterModuleNameTextfield.underlined(width: 0.4)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        /********* Plug-in animation *********/
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        let hover = CABasicAnimation(keyPath: "position")
        
        hover.isAdditive = true
        hover.fromValue = NSValue(cgPoint: CGPoint.zero)
        hover.toValue = NSValue(cgPoint: CGPoint(x: 0.0, y: 22.0))
        hover.autoreverses = true
        hover.duration = 1.0
        hover.repeatCount = Float.infinity
        plugInImageView.layer.add(hover, forKey: "myHoverAnimation")
        /********* Plug-in animation *********/
    }
    
    @IBAction func enterButtonAction(_ sender: Any) {
        self.saveDetails(withModuleName: enterModuleNameTextfield.text!)
        self.removingObserver()
        self.displayPlugInViewMethod()
    }
    
    func saveDetails(withModuleName moduleName: String) {
        
        let dataDictionary = [
            Constants.MODULE_NAME : moduleName,
            Constants.LOCATION_NAME : enterModuleLocationTextField.text! as String
            ] as [String : Any]
        
        let defaults = UserDefaults.standard
        defaults.set(dataDictionary, forKey:Constants.MODULE_AND_LOCATION_DICTIONARY)
    
    }
    
    @IBAction func skipButtonAction(_ sender: Any) {
        self.saveDetails(withModuleName: enterModuleNameTextfield.text!)
        self.removingObserver()
        self.displayPlugInViewMethod()
    }
    
    func displayPlugInViewMethod() {
        titleView.isHidden = true
        titleTextField.isHidden = false
        plugInView.isHidden = false
        continueButton.isHidden = false
        skipButton.isHidden = true
        enterButton.isHidden = true
        
        titleTextField.text = NSLocalizedString("Apply power to your ARTIK module", comment: "")
    }
   
    @IBAction func continueButtonAction(_ sender: Any) {

        /* Choose the onboarding service/controller based upon the device type as deduced from QR Code Serial Number */

        if deviceType == 0 {

            if ATUtilities.getDeviceIdentifier().contains("051")  || ATUtilities.getDeviceIdentifier().contains("053") {
                // For Artik 05X
                let softAPModuleController = self.storyboard?.instantiateViewController(withIdentifier: "SoftAPViewController") as! SoftAPViewController
                softAPModuleController.mac = ATUtilities.artikPrimaryMac
                self.saveDetails(withModuleName: enterModuleNameTextfield.text!)
                self.navigationController!.pushViewController(softAPModuleController, animated: true)

            } else {
                // For Edge Nodes like Artik 020, 030
                let linkModuleController = self.storyboard?.instantiateViewController(withIdentifier: "LinkModulesListViewController") as! LinkModulesListViewController
                linkModuleController.bleMac = bleMac
                linkModuleController.deviceType = deviceType
                self.saveDetails(withModuleName: enterModuleNameTextfield.text!)
                self.navigationController!.pushViewController(linkModuleController, animated: true)

            }
        }
        else {
            // For Gateway Hubs like Artik 5,7,10
            let bluetoothPairingControllerObj = self.storyboard!.instantiateViewController(withIdentifier: "BluetoothPairingViewController") as! BluetoothPairingViewController
            bluetoothPairingControllerObj.bleMac = bleMac
            self.saveDetails(withModuleName: enterModuleNameTextfield.text!)
            self.navigationController!.pushViewController(bluetoothPairingControllerObj, animated: true)
        }
        self.removingObserver()
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        self.removingObserver()
        
        if plugInView.isHidden == false {
            _ = navigationController?.popToRootViewController(animated: true)
        }
        else {
            _ = navigationController?.popViewController(animated: true)
        }
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool{
        
        if textField == enterModuleNameTextfield {
            
            let newString = NSString(string: textField.text!).replacingCharacters(in: range, with: string)
            let set = NSCharacterSet(charactersIn: Constants.REGEX_User_Name_Restrict);
            let inverted = set.inverted;
            
            if (string as NSString).rangeOfCharacter(from: inverted).location == NSNotFound {
                
                if newString.characters.count > 0 {
                    enterModuleNameTextfield.addRegx(Constants.REGEX_USER_NAME_LIMIT, withMsg: "Name must be minimum 4 characters & maximum 32 characters")
                    
                    if (newString.characters.count) < 4 || (newString.characters.count) > 32 {
                        enterButton.alpha = 0.5
                        enterButton.isUserInteractionEnabled = false
                        
                        if (newString.characters.count) > 32 {
                            enterButton.alpha = 1
                            enterButton.isUserInteractionEnabled = true
                            return false
                        }
                    }
                    else {
                        enterButton.alpha = 1
                        enterButton.isUserInteractionEnabled = true
                    }
                }
            }
                
            else {
                return false
            }
            
            return true
        }
        return true
    }
    
    func enableEnterButton()  {
        enterButton.alpha = 1
        enterButton.isUserInteractionEnabled = true
    }
    
    func disableEnterButton()  {
        enterButton.alpha = 0.5
        enterButton.isUserInteractionEnabled = false
    }
    
    func keyboardWillShow(notification: NSNotification) {
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }
    
    func removingObserver() {
        self.view.endEditing(true)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
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

