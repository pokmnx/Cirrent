//
//  RegisteredBoardsTableViewCell.swift
//  SamsungARTIK
//
//  Created by alimi shalini on 11/29/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit

class RegisteredBoardsTableViewCell: UITableViewCell {

    @IBOutlet weak var moduleNameLabel: UILabel!
    @IBOutlet weak var artikImageView: UIImageView!
    @IBOutlet weak var moduleLocationLabel: UILabel!
    @IBOutlet weak var deviceStatusLabel: UILabel!
    @IBOutlet weak var deviceStatusIcon: UIImageView!
      
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
}
