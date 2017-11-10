//
//  MenuController.swift
//  Cirrent_New
//
//  Created by PSIHPOK on 12/19/16.
//  Copyright © 2016 PSIHPOK. All rights reserved.
//

import UIKit

class MenuController: UITableViewController {

    var menus = ["Home", "Configuration"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.isScrollEnabled = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menus.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath)
        let row = indexPath.row
        cell.textLabel?.text = menus[row]
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        changeViewController(indexPath: indexPath)
    }
    
    func changeViewController(indexPath : IndexPath) {
        let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
        switch indexPath.row {
        case 0:// Start Over
            appDelegate.moveToMainController()
            break
        case 1:// Configuration
            appDelegate.moveToConfigureController()
            break
        default:
            return
        }
    }
}
