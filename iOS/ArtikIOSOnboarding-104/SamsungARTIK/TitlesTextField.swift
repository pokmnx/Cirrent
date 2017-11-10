//
//  CustomTextField.swift
//  SamsungARTIK
//
//  Created by alimi shalini on 11/28/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit

class TitlesTextField: UITextField {
    
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
        self.backgroundColor = UIColor.black
        self.font = UIFont.systemFont(ofSize: 15)
        self.isUserInteractionEnabled = false
        self.textColor = UIColor.white
        
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x:0.0, y:self.frame.size.height - 1.0, width:self.frame.width+100, height:0.5)
        bottomLine.backgroundColor = UIColor.white.cgColor
        self.borderStyle = UITextBorderStyle.none
        self.layer.addSublayer(bottomLine)
        
//        let topLine = CALayer()
//        topLine.frame = CGRect(x:0.0, y:self.bounds.height-1, width:self.bounds.width+100, height:1.0)
//        topLine.backgroundColor = UIColor(colorLiteralRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.8).cgColor
//        self.borderStyle = UITextBorderStyle.none
//        self.layer.addSublayer(topLine)
        
    }
    
    let padding = UIEdgeInsets(top: 0, left: 17, bottom: 0, right: 5)
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    
    
    
}
