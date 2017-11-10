//
//  MenuTableViewCell.swift
//  SamsungARTIK
//
//  Created by alimi shalini on 11/30/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit

class MenuTableViewCell: UITableViewCell {

    @IBOutlet weak var menuItemLabel: UILabel!
    @IBOutlet weak var rightArrowImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
}
