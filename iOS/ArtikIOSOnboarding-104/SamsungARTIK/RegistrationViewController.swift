//
//  RegistrationViewController.swift
//  SamsungARTIK - This file is unused
//
//  Created by alimi shalini on 11/29/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import Foundation
import UIKit
import CirrentSDK

class RegistrationViewController: UIViewController {
    
    @IBOutlet weak var emailldTextField: CustomTextField!
    @IBOutlet weak var nameTextField: CustomTextField!
    @IBOutlet weak var confirmPasswordTextField: CustomTextField!
    @IBOutlet weak var passwordTextField: CustomTextField!
    @IBOutlet weak var errorMessageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func cancelButtonAction(_ sender: Any) {
        self.navigationController!.popViewController(animated: true)
    }
    
    @IBAction func registerButtonAction(_ sender: Any) {
        if (nameTextField.text?.characters.count)! >= 5 {
            if isValidEmail(testStr: emailldTextField.text!){
                if checkTextSufficientComplexity(text: passwordTextField.text!){
                    if passwordTextField.text == confirmPasswordTextField.text{
                        errorMessageLabel.text = ""
                    }
                    else{
                        errorMessageLabel.text = NSLocalizedString("Password Confirmation", comment: "")
                    }
                }
                else{
                    errorMessageLabel.text = NSLocalizedString("Invalid Password", comment: "")
                }
            }
            else{
                errorMessageLabel.text = NSLocalizedString("Invalid Email ID", comment: "")
            }
        }
        else{
            errorMessageLabel.text = NSLocalizedString("Invalid Name", comment: "")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    func checkTextSufficientComplexity( text : String) -> Bool{
        let text = text
        let capitalLetterRegEx  = "^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,}$"
        let texttest = NSPredicate(format:"SELF MATCHES %@", capitalLetterRegEx)
        let capitalresult = texttest.evaluate(with: text)
        return capitalresult
    }
    
}



