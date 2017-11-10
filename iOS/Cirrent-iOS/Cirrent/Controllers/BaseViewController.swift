//
//  BaseViewController.swift
//  Cirrent_New
//
//  Created by PSIHPOK on 12/19/16.
//  Copyright © 2016 PSIHPOK. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {

    let navBarTintColor:UIColor = UIColor(red: 0, green: 0.73, blue: 1, alpha: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupNavigationBar() {
        self.navigationController?.navigationBar.tintColor = navBarTintColor
        self.setNavigationBarItem()
    }
    
    func setTitle(title:String) {
        self.navigationController?.navigationBar.items?[0].title = title
    }
}
