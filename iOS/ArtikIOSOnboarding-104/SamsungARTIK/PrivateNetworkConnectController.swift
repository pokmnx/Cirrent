//
//  PrivateNetworkConnectController.swift
//  SamsungARTIK
//
//  Created by Marco on 5/4/17.
//  Copyright © 2017 Samsung Artik. All rights reserved.
//

import UIKit
import CirrentSDK

class PrivateNetworkConnectController: UIViewController, UITableViewDataSource, UITableViewDelegate, PrivateNetworkPopOverDelegate {

    @IBOutlet weak var networkListView: UITableView!
    @IBOutlet weak var password: CustomTextField!
    var networks:[Network] = [Network]()
    var popOverView:PrivateNetworkPopOverView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        networkListView.register(UINib(nibName: "WifiNetworkTableViewCell", bundle: nil), forCellReuseIdentifier: "WifiNetworkTableViewCell")
        networkListView.tableFooterView = UIView()
        networkListView.separatorColor = UIColor.gray
        networkListView.layoutMargins = UIEdgeInsets.zero
        networkListView.separatorInset = UIEdgeInsets.zero
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let network = networks[indexPath.row]
        CirrentService.sharedService.model?.selectedNetwork = network
        popOverView = PrivateNetworkPopOverView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height), ssid: network.ssid)
        popOverView.backgroundColor = UIColor.clear
        popOverView.translatesAutoresizingMaskIntoConstraints = false
        popOverView.delegate = self
        self.view.addSubview(popOverView)
        
        let subviewsDict: Dictionary = ["popOverView": popOverView];
        
        let arrXconstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[popOverView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.view.addConstraints(arrXconstraints)
        
        let arrYconstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[popOverView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.view.addConstraints(arrYconstraints)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return networks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WifiNetworkTableViewCell", for: indexPath) as! WifiNetworkTableViewCell
        cell.layoutMargins = UIEdgeInsets.zero
        cell.backgroundColor = UIColor.clear
        //cell.selectionStyle = UITableViewCellSelectionStyle.none
        tableView.separatorStyle = .none
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = Constants.listColor
        cell.selectedBackgroundView = bgColorView
        cell.layer.cornerRadius = 5
        
        let network = networks[indexPath.row]
        cell.titleLabel.text = network.ssid
        
        return cell
    }
    
    func joinWifiNetwork(password: String) {
        CirrentService.sharedService.model?.selectedNetworkPassword = password
        let device = CirrentService.sharedService.model?.selectedDevice
        DispatchQueue.main.async {
            CirrentService.sharedService.putPrivateCredentials(tokenMethod: SampleCloudService.sharedService.getToken, deviceID: device!.getDeviceID(), completion: {
                response, creds in
                
                if response == CREDENTIAL_RESPONSE.SUCCESS {
                    CirrentService.sharedService.getDeviceJoiningStatus(tokenMethod: SampleCloudService.sharedService.getToken, deviceID: device!.getDeviceID(), handler: {
                        status in
                        
                        DispatchQueue.main.async {
                            switch (status) {
                            case .JOINED:
                                self.popOverView.showSuccesfulMessage()
                                Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: {
                                    t in
                                    
                                    let controller:RegisteredDeviceViewController = self.storyboard!.instantiateViewController(withIdentifier: "RegisteredDeviceViewController") as! RegisteredDeviceViewController
                                    self.navigationController!.pushViewController(controller, animated: true)
                                    self.navigationController?.viewControllers = [controller]
                                })
                                break
                            case .RECEIVED_CREDS:
                                self.popOverView.indicatorViewBottomLabel.text = "Connecting module to your network"
                                break
                            case .ATTEMPTING_TO_JOIN:
                                self.popOverView.indicatorViewBottomLabel.text = "Attempting to join"
                                break
                            case .OPTIMIZING_CONNECTION:
                                self.popOverView.indicatorViewBottomLabel.text = "Checking connectivity..."
                                break
                            case .TIMED_OUT:
                                self.popOverView.activityIndicator.isHidden = true
                                self.popOverView.indicatorViewTopLabel.text = "Connecting Failed"
                                self.popOverView.indicatorViewBottomLabel.text = "Let's try again."
                                Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: {
                                    t in
                                    
                                    self.removeWifiPopover()
                                })
                                break
                            case .GET_DEVICE_STATUS_FAILED,
                                 .FAILED_INVALID_STATUS,
                                 .FAILED_INVALID_TOKEN,
                                 .SELECTED_DEVICE_NIL,
                                 .FAILED_NO_RESPONSE,
                                 .NOT_SoftAP_NETWORK,
                                 .FAILED:
                                self.popOverView.activityIndicator.isHidden = true
                                self.popOverView.indicatorViewTopLabel.text = "Connecting Failed"
                                self.popOverView.indicatorViewBottomLabel.text = "Module failed to join. Let's try again."
                                Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: {
                                    t in
                                    
                                    self.removeWifiPopover()
                                    self.navigationController!.popToRootViewController(animated: true)
                                })
                                break
                            }
                        }
                    })
                }
                else {
                    self.popOverView.activityIndicator.isHidden = true
                    self.popOverView.indicatorViewTopLabel.text = "Connecting Failed"
                    self.popOverView.indicatorViewBottomLabel.text = "Sending Credential Failed"
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: {
                        t in
                        
                        self.removeWifiPopover()
                    })
                }
            })
        }
    }
    
    func removeWifiPopover() {
        popOverView.removeFromSuperview()
    }
    
    func showRegisteredModuleViewController(dId: String, deviceIp: String) {
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    @IBAction func onClickConnect(_ sender: Any) {
        
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
