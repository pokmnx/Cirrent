//
//  WifiNetworkTableViewCell.swift
//  SamsungARTIK
//
//  Created by alimi shalini on 12/6/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit

class WifiNetworkTableViewCell: UITableViewCell {

    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        self.backgroundColor = Constants.listColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
}
