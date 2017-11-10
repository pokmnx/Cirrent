//
//  ActionsTableViewCell.swift
//  SamsungARTIK
//
//  Created by Vaibhav Singh on 13/03/17.
//  Copyright © 2017 alimi shalini. All rights reserved.
//

import UIKit

class ActionsTableViewCell: UITableViewCell {

    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var desc: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
