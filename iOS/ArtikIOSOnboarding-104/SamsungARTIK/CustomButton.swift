//
//  CustomButton.swift
//  SamsungARTIK
//
//  Created by alimi shalini on 11/28/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit

class CustomButton: UIButton {
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.cornerRadius = 5
        self.layer.masksToBounds = true
        self.contentVerticalAlignment=UIControlContentVerticalAlignment.center
        self.titleLabel?.textColor = Constants.topBottomBarColor
        self.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        self.setBackgroundColor(color:Constants.listColor, forState: .highlighted)
        self.setTitleColor(UIColor.white, for: .highlighted)
        self.setTitleColor(Constants.backgroundWhiteColor, for: UIControlState.normal)
        self.backgroundColor = UIColor(colorLiteralRed: 247/255.0, green: 148/255.0, blue: 29/255.0, alpha: 1)
    }
    
}
