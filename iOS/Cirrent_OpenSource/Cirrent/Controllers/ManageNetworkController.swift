//
//  NetworkManageController.swift
//  Cirrent
//
//  Created by PSIHPOK on 2/28/17.
//  Copyright © 2017 Cirrent. All rights reserved.
//

import UIKit
import ActionCell

class ManageNetworkController: UIViewController, UITableViewDelegate, UITableViewDataSource, LPRTableViewDelegate {

    @IBOutlet weak var networkTableView: LPRTableView!
    var tableView: UITableView!
    let identififer = "networkManageCell"
    
    var networks:[KnownNetwork] = [KnownNetwork]()
    var deviceID:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView = networkTableView
        networkTableView.dataSource = self
        networkTableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let addItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNetwork))
        self.navigationItem.rightBarButtonItem = addItem
        self.navigationItem.title = "Manage Networks"
    }
    
    func addNetwork() {
        self.performSegue(withIdentifier: "AddNetwork", sender: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ProgressView.sharedView.showProgressView(view: self.view)
        CirrentService.sharedService.getKnownNetworks(tokenMethod: SampleCloudService.sharedService.getToken, deviceID: deviceID, completion: {
            array in
            
            DispatchQueue.main.async {
                if array != nil {
                    ProgressView.sharedView.dismissProgressView()
                    self.networks = array!
                    self.networks.sort {
                        $0.priority < $1.priority
                    }
                    self.networkTableView.reloadData()
                }
                else {
                    CirrentService.sharedService.getKnownNetworks(tokenMethod: SampleCloudService.sharedService.getToken, deviceID: self.deviceID, completion: {
                        array in
                        
                        DispatchQueue.main.async {
                            ProgressView.sharedView.dismissProgressView()
                            if array != nil {
                                self.networks = array!
                                self.networks.sort {
                                    $0.priority < $1.priority
                                }
                            }
                            else {
                                self.networks = [KnownNetwork]()
                            }
                            self.networkTableView.reloadData()
                        }
                    })
                }
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return networks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identififer, for: indexPath)
        let network = networks[indexPath.row]
        cell.textLabel?.text = network.ssid + " - " + network.getStatus()
        
        let wrapper = ActionCell()
        wrapper.delegate = self
        wrapper.animationStyle = .ladder
        wrapper.wrap(cell: cell, actionsLeft: [], actionsRight: [
            {
                let action = TextAction(action: "delete")
                action.label.text = "Delete"
                action.label.font = UIFont.systemFont(ofSize: 15)
                action.label.textColor = UIColor.white
                action.backgroundColor = UIColor(red:0.9, green:0.1, blue:0.1, alpha:1.0)
                return action
            }(),
            ])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let temp = networks[sourceIndexPath.row].priority
        networks[sourceIndexPath.row].priority = networks[destinationIndexPath.row].priority
        networks[destinationIndexPath.row].priority = temp
        networks.insert(networks.remove(at: sourceIndexPath.row), at: destinationIndexPath.row)
    }
    
    func tableView(_ tableView: UITableView, draggingCell cell: UITableViewCell, at indexPath: IndexPath) -> UITableViewCell {
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier != nil && segue.identifier! == "AddNetwork" {
            let controller = segue.destination as! AddNetworkController
            controller.deviceID = self.deviceID
        }
    }
}

extension ManageNetworkController : ActionCellDelegate {
    public func didActionTriggered(cell: UITableViewCell, action: String) {
        let indexPath = networkTableView.indexPath(for: cell)
        if indexPath == nil {
            return
        }
        
        if action == "delete" {
            ProgressView.sharedView.showProgressView(view: self.view)
            let network = networks[indexPath!.row]
            let net = Network()
            net.ssid = network.ssid
            net.roamingID = network.roamingID
            net.security = network.security
            CirrentService.sharedService.deleteNetwork(tokenMethod: SampleCloudService.sharedService.getToken, deviceID: deviceID, network: net, completion: {
                response in
                
                DispatchQueue.main.async {
                    ProgressView.sharedView.dismissProgressView()
                    if response == .SUCCESS {
                        self.networks.remove(at: indexPath!.row)
                        self.networkTableView.deleteRows(at: [indexPath!], with: .left)
                    }
                    else {
                        ProgressView.sharedView.showToast(view: self.view, message: "Failed to delete network from device.")
                    }
                }
            })
        }
    }
}

