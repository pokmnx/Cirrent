//
//  DropDownViewController.swift
//  SamsungARTIK
//  Drop Down Menu on top right for Dashboard and Device Control
//
//  Created by alimi shalini on 1/19/17.
//  Copyright © 2017 alimi shalini. All rights reserved.
//

import UIKit

class DropDownViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    @IBOutlet weak var dropDownTableView: UITableView!
    let cellReuseIdentifier = "cell"

    var values = [String]()


    func updateItems(items : [String]) {
        values = items
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        dropDownTableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        dropDownTableView.tableFooterView = UIView()
        dropDownTableView.separatorColor = UIColor.gray
        dropDownTableView.layoutMargins = UIEdgeInsets.zero
        dropDownTableView.separatorInset = UIEdgeInsets.zero
        dropDownTableView.isScrollEnabled = false

        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 50 //cell height
    }
    
    func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
            return values.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as UITableViewCell!

        cell.layoutMargins = UIEdgeInsets.zero
        tableView.separatorStyle = .none
        cell.backgroundColor = UIColor.clear
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = Constants.listColor
        cell.selectedBackgroundView = bgColorView

        cell.textLabel?.text = values[indexPath.row]

        cell.textLabel?.textColor = Constants.topBottomBarColor
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15)
        cell.textLabel?.textAlignment = .left
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "DropdownSelectedIndex"), object: indexPath.row)
        self.dismiss(animated: true, completion: nil)
    }

}
