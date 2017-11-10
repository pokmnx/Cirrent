//
//  CustomTopAndBottomBar.swift
//  SamsungARTIK
//
//  Created by alimi shalini on 12/15/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit

class CustomTopAndBottomBar: UIView {

    
    /*
     Only override draw() if you perform custom drawing.
     An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
         Drawing code
    }
    */
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = Constants.topBottomBarColor
    }
}
