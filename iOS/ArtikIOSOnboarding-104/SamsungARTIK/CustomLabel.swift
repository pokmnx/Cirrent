//
//  CustomLabel.swift
//  SamsungARTIK
//
//  Created by alimi shalini on 11/28/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit

class CustomLabel: UILabel {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    let topInset = CGFloat(5.0), bottomInset = CGFloat(5.0), leftInset = CGFloat(8.0), rightInset = CGFloat(8.0)
    
    override func drawText(in rect: CGRect) {
        let insets: UIEdgeInsets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = Constants.topBottomBarColor
        self.font = UIFont.systemFont(ofSize: 15)
        self.textColor = UIColor.white
    }

}
