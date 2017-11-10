//
//  popOverTableViewCell.swift
//  SamsungARTIK
//
//  Created by alimi shalini on 12/1/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit

class popOverTableViewCell: UITableViewCell {

    @IBOutlet weak var cellTitle: UILabel!
    @IBOutlet weak var cellImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        self.backgroundColor = Constants.backgroundWhiteColor
        cellTitle.textColor = Constants.topBottomBarColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        // Configure the view for the selected state

        super.setSelected(selected, animated: animated)
    }
}
