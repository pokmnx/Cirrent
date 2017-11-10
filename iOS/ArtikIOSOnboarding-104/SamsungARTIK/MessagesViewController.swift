//
//  MessagesViewController.swift
//  SamsungARTIK
//
//  Created by Vaibhav Singh on 09/03/17.
//  Copyright © 2017 alimi shalini. All rights reserved.
//

import UIKit
import ArtikCloud


class MessagesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {

    @IBOutlet weak var fieldsTableView: UITableView!
    

    var fields: [String : NSObject]!
    var module : Module!
    var deviceMessages : [ACNormalizedMessage]?
    var keys = [String]()
    var values = [NSObject]()
    var descriptions = [String]()
    var timestamps = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        fieldsTableView.register(UINib(nibName: "FieldsTableViewCell", bundle: nil), forCellReuseIdentifier: "FieldsTableViewCell")
        fieldsTableView.tableFooterView = UIView()
        fieldsTableView.separatorColor = UIColor.gray
  //      fieldsTableView.layoutMargins = UIEdgeInsets.zero
        fieldsTableView.separatorInset = UIEdgeInsets.zero
        fieldsTableView.reloadData()

    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.addObservers()

        module = self.appDelegate().selectedModule

        if module != nil {
            refresh()
            self.appDelegate().getLastMessages(deviceId: module.id!, count: 100)
        }

    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }

    func refresh() {

        deviceMessages = ATDatabaseManager.getLastNormalizedMessages(deviceId: module.id!)
        keys = [String]()
        descriptions = [String]()
        timestamps = [String]()
        values = [NSObject]()
        for data in deviceMessages! {

            for (key, value) in data.data {
                keys.append(key)
                descriptions.append(String(describing: value))
                timestamps.append(ATUtilities.timeSinceFormat(timestamp: data.ts as Int64, numericDates: true))
            }

        }

        self.fieldsTableView.reloadData()

    }

    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.refresh), name: NSNotification.Name(rawValue: "refresh"), object: nil)
    }


    func appDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }


    // MARK: - TableView Delegates

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        return 90 //cell height

    }

    func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        return keys.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // Instantiate a cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "FieldsTableViewCell", for: indexPath) as! FieldsTableViewCell

        if (indexPath.row == keys.count) {

            if indexPath.row == 0 {
                cell.name.text = "No History"
                cell.desc.text = "No messages sent in the last 3 months"
                cell.timesince.text = " "
            } else {
                cell.isHidden = true
            }

        } else {
            cell.name.isHidden = false
            cell.desc.isHidden = false
            cell.timesince.isHidden = false
            cell.name.text = keys[indexPath.row]
            cell.desc.text = descriptions[indexPath.row]
            cell.timesince.text = timestamps[indexPath.row]
        }
        return cell
    }
    
    


}
