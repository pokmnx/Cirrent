//
//  ZipKeyFailedController.swift
//  SamsungARTIK
//
//  Created by Marco on 5/3/17.
//  Copyright © 2017 Samsung Artik. All rights reserved.
//

import UIKit

class ZipKeyFailedController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func onClickOk(_ sender: Any) {
        _ = self.navigationController?.popToRootViewController(animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
