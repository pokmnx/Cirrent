//
//  FieldsViewController.swift
//  SamsungARTIK
//
//  Created by Vaibhav Singh on 09/03/17.
//  Copyright © 2017 alimi shalini. All rights reserved.
//

import UIKit
import ArtikCloud

class FieldsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {

    @IBOutlet weak var fieldsTableView: UITableView!

    var module : Module!
    var deviceSnapshot : ACSnapshotResponse?
    var deviceManifest : ACFieldsActions?
    var manifest_field_keys = [String]()
    var manifest_fields = [String:Field]()

    override func viewDidLoad() {
        super.viewDidLoad()
        fieldsTableView.register(UINib(nibName: "FieldsTableViewCell", bundle: nil), forCellReuseIdentifier: "FieldsTableViewCell")
        fieldsTableView.tableFooterView = UIView()
        fieldsTableView.separatorColor = UIColor.gray
       // fieldsTableView.layoutMargins = UIEdgeInsets.zero
        fieldsTableView.separatorInset = UIEdgeInsets.zero
        fieldsTableView.rowHeight = UITableViewAutomaticDimension
        fieldsTableView.estimatedRowHeight = 90
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
            deviceManifest = ATDatabaseManager.getDeviceManifest(deviceTypeId: module.dtid!, version: String(describing: module.manifestVersion))
            manifest_field_keys = [String]()
            manifest_fields = [String:Field]()
            populateManifestFields(data: (deviceManifest?.fields)!, parentName: "")
            fetchSnapshot()
            self.appDelegate().getDeviceSnapshot(devices: module.id!)
        }

    }

    override func viewWillDisappear(_ animated: Bool) {
        removeObservers()
    }

    func populateManifestFields(data : [String : NSObject], parentName: String) {
        for (key, value) in data {
            let field = value as! NSDictionary
            if field.object(forKey: "type") != nil {
                var item = Field()
                item.key = parentName + key
                item.type = field.object(forKey: "type") as? String
                item.timestamp = "Not yet updated"
                item.value = "Unavailable"
                manifest_field_keys.append(parentName + key)
                manifest_fields[item.key!] = item
            } else {
                populateManifestFields(data: value as! [String : NSObject], parentName: key + ".")
            }
        }
    }

    func fetchSnapshot() {

        deviceSnapshot = ATDatabaseManager.getDeviceSnapshot(deviceId: module.id!)

        let data = deviceSnapshot?.data

        if data != nil {
            addDeviceFieldItems(data: data!, parentName: "")
        }
        self.fieldsTableView.reloadData()
    }

    func addDeviceFieldItems( data : [String : NSObject], parentName: String) {

        for (key, value) in data {
            let field = value as! NSDictionary
            if field.object(forKey: "ts") != nil {
                let keyItem = parentName + key
                var fieldItem = manifest_fields[keyItem]
                let val = field.object(forKey: "value")
                fieldItem?.value = String(describing: val!)
                fieldItem?.timestamp = ATUtilities.timeSinceFormat(timestamp: field.object(forKey: "ts") as! Int64, numericDates: false)
                manifest_fields[keyItem] = fieldItem
            } else {
                addDeviceFieldItems(data: value as! [String : NSObject], parentName: key + ".")
            }
        }
    }

    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.fetchSnapshot), name: NSNotification.Name(rawValue: "fetch_snapshot"), object: nil)
    }

    func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }


    func appDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    

    // MARK: - TableView Delegates

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        return 90 //cell height

    }

    func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        return manifest_field_keys.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // Instantiate a cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "FieldsTableViewCell", for: indexPath) as! FieldsTableViewCell

        if indexPath.row == manifest_field_keys.count {

            if indexPath.row == 0 {
                cell.name.text = "No Fields"
                cell.desc.text = "This device has no fields in it's manifest"
                cell.timesince.text = " "
            } else {
                cell.isHidden = true
            }

        } else {
            cell.name.isHidden = false
            cell.desc.isHidden = false
            cell.timesince.isHidden = false
            let keyItem = manifest_field_keys[indexPath.row]
            let fieldItem = manifest_fields[keyItem]
            cell.name.text = fieldItem?.key
            cell.desc.text = fieldItem?.value
            cell.timesince.text = fieldItem?.timestamp
        }
        return cell
    }



    struct Field {
        var key : String?
        var value : String?
        var type : String?
        var timestamp: String?
        init() {
        }
    }

}
