//
//  DeviceManageCell.swift
//  Cirrent
//
//  Created by PSIHPOK on 2/23/17.
//  Copyright © 2017 Cirrent. All rights reserved.
//

import UIKit

class DeviceManageCell: UITableViewCell {

    @IBOutlet weak var deviceImageView: UIImageView!
    
    @IBOutlet weak var deviceFriendlyName: UILabel!
    
    @IBOutlet weak var deviceCompany: UILabel!
    
    @IBOutlet weak var deviceType: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
