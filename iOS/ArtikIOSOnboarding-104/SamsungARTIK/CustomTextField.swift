//
//  CustomTextField.swift
//  SamsungARTIK
//
//  Created by alimi shalini on 11/28/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit

class CustomTextField: UITextField,UITextFieldDelegate {

    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     
     // self.view.addSubview(txtEmailfield)
     // Drawing code
     }
     */
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = Constants.textBoxColor
        self.borderStyle = UITextBorderStyle.roundedRect
        self.layer.borderColor = UIColor.init(colorLiteralRed: 19/255.0, green: 35/255.0, blue: 49/255.0, alpha: 1).cgColor
        self.layer.borderWidth = 1
        self.layer.cornerRadius = 5
        self.font = UIFont.systemFont(ofSize: 15)
        self.autocorrectionType = UITextAutocorrectionType.no
        self.keyboardType = UIKeyboardType.default
        self.returnKeyType = UIReturnKeyType.done
        self.delegate = self
        self.contentVerticalAlignment = UIControlContentVerticalAlignment.center
        self.setValue(UIColor.init(colorLiteralRed: 101/255.0, green: 106/255.0, blue: 110/255.0, alpha: 1), forKeyPath: "_placeholderLabel.textColor")
        self.textColor = UIColor.darkGray
    }
    
    let padding = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        return true
    }
   
}
