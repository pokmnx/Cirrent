//
//  ManualInputViewController.swift
//  SamsungARTIK
//
//  Created by alimi shalini on 12/2/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit

class ManualInputViewController: UIViewController,UITextFieldDelegate, ATAlertViewDelegate {
    
    @IBOutlet weak var submitButton: CustomButton!
    @IBOutlet weak var titleTextField: TitlesTextField!
    @IBOutlet weak var moduleIdTextField: UITextField!
    var alertView: ATAlertView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        submitButton.alpha = 0.5
        submitButton.isUserInteractionEnabled = false
        submitButton.setTitleColor(UIColor.white, for: .highlighted)
        
        moduleIdTextField.setValue(UIColor.init(colorLiteralRed: 101/255.0, green: 106/255.0, blue: 110/255.0, alpha: 1), forKeyPath: "_placeholderLabel.textColor")
        moduleIdTextField.autocorrectionType = UITextAutocorrectionType.no
        moduleIdTextField.underlined(width: 0.5)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        moduleIdTextField.text = ""
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        self.removingObserver()
        let _ = navigationController?.popViewController(animated: true)
    }
    
    @IBAction func submitButtonAction(_ sender: Any) {
        
        let manualEntryString = moduleIdTextField.text!.replacingOccurrences(of: " ", with: "")
        
        if ATUtilities.validateQR(qrString: manualEntryString) == true {
            let valArray = manualEntryString.components(separatedBy: ",")
            
            self.removingObserver()
            
            let artikIdentifiedControllerObj = self.storyboard!.instantiateViewController(withIdentifier: "ArtikModuleIdentifiedViewController") as! ArtikModuleIdentifiedViewController
            artikIdentifiedControllerObj.isFromManual = true
            artikIdentifiedControllerObj.uuidString = manualEntryString
            artikIdentifiedControllerObj.bleMac = valArray.last
            self.navigationController!.pushViewController(artikIdentifiedControllerObj, animated: true)
        }
        else {
            self.view.endEditing(true)
            self.showAlert()
        }
    }
    
    //MARK: - ATAlertView Delegates
    
    func hideAlert() {
        alertView.removeFromSuperview()
    }
    
    func showAlert() {
        
        alertView = ATAlertView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height), message: NSLocalizedString("Module Id is invalid !\nPlease enter valid module id.", comment: "") , cancelButtonTitle: NSLocalizedString("OK", comment: ""), confirmButtonTitle: "")
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
    
    //MARK: - UITextField Delegates
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool{
        let set = NSCharacterSet(charactersIn: Constants.REGEX_Module_LIMIT);
        let inverted = set.inverted;
        
        if (string as NSString).rangeOfCharacter(from: inverted).location == NSNotFound {
            let newString = NSString(string: textField.text!).replacingCharacters(in: range, with: string)
            
            if textField == moduleIdTextField {
                
                if newString.characters.count > 3  {
                    submitButton.alpha = 1
                    submitButton.isUserInteractionEnabled = true
                }
                else {
                    submitButton.alpha = 0.5
                    submitButton.isUserInteractionEnabled = false
                }
            }
            return true
        }
        else
        {
            return false
        }
        
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
