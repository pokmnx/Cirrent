//
//  BluetoothPairingViewController.swift
//  SamsungARTIK
//
//  Created by alimi shalini on 12/6/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit
import CoreBluetooth

class BluetoothPairingViewController: UIViewController, LeDiscoveryDelegate, ATAlertViewDelegate {
    
    @IBOutlet weak var phoneImageView: UIImageView!
    @IBOutlet weak var blutoothImageView: UIImageView!
    @IBOutlet weak var boardImageView: UIImageView!
    @IBOutlet weak var pairedImageView: UIImageView!
    @IBOutlet weak var pleaseWaitButton: CustomButton!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var connectToWifiButton: UIButton!
    @IBOutlet weak var titleTextField: TitlesTextField!
    @IBOutlet weak var dottedImgVw: UIImageView!
    @IBOutlet weak var dashedLineView: UIView!
    
    var bleMac: String!
    var deviceType: Int!
    var alertView: ATAlertView!
    var discoveredPeripheral: CBPeripheral!
    var bleTimer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        blutoothImageView.blink()
        
        deviceType = Int(ATUtilities.artikDeviceId())
        
        self.refreshView(false)
        self.addObservers()
        self.pleaseWaitButton.backgroundColor = UIColor.white
        self.pleaseWaitButton.setTitleColor(UIColor.black, for: .normal)
        
        bleTimer = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(self.showPairingFailedAlert), userInfo: nil, repeats: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if deviceType != 0 {
            BLEManager.sharedInstance.discoveryDelegate = self
            
            if BLEManager.sharedInstance.bluetoothState == CBManagerState.poweredOn {
                if discoveredPeripheral == nil {
                    BLEManager.sharedInstance.startScanning(forUUIDString: self.serviceUUID())
                    print("Should have started scanning for devices")
                }
            }
            else {
                print("Turn bluetooth on")
            }
        }
        else {
            self.perform(#selector(self.backgroundRefreshview), with: true, afterDelay: 0.5)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.removeObservers()
        
        if self.navigationController!.viewControllers.index(of: self) == NSNotFound {
            if discoveredPeripheral != nil {
                BLEManager.sharedInstance.disconnectPeripheral(discoveredPeripheral)
            }
        }
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.onboardingServiceFound), name: NSNotification.Name(rawValue: "serviceDicsovered"), object: nil)
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func showPairingFailedAlert() {
        self.showAlert(message: NSLocalizedString("Bluetooth connection failed.", comment: ""))
    }
    
    func showTurnOnBluetoothAlert() {
        self.connectToWifiButton.isEnabled = false
        self.showAlert(message: NSLocalizedString("Bluetooth turned off.", comment: ""))
    }
    
    func onboardingServiceFound() {
        self.connectToWifiButton.isEnabled = true
    }
    
    func backgroundRefreshview(_ value: Bool) {
        self.refreshView(value)
    }
    
    func refreshView(_ wifiConnected: Bool) {
        if wifiConnected {
            
        }
        else {
            
        }
    }
    
    func appDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    // MARK: - LeDiscoveryDelegate
    func discoveryDidRefresh() {
        self.discoveredPeripheral = BLEManager.sharedInstance.discoveredPeripheral
        self.appDelegate().discoveredPeripheral = self.discoveredPeripheral
        
        if discoveredPeripheral != nil {
            print("Found peripheral: \(discoveredPeripheral) , stopping scan")
            BLEManager.sharedInstance.connect(discoveredPeripheral)
            BLEManager.sharedInstance.stopScanning()
        }
    }
    
    func discoveryStatePoweredOff() {
        self.showAlert(message: NSLocalizedString("Bluetooth turned off.", comment: ""))
        print("Bluetooth is not on?")
    }
    
    func discoveryStatePoweredOn() {
        if alertView != nil {
            alertView.removeFromSuperview()
        }
        
        BLEManager.sharedInstance.startScanning(forUUIDString: self.serviceUUID())
    }
    
    func peripheralDidConnect(_ value: Bool) {
        if value == true {
            print("Connected to peripheral: ")
            self.discoveredPeripheral = BLEManager.sharedInstance.discoveredPeripheral
            
            self.showPairedView()
        }
        else {
            print("Disconnected from peripheral: ")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "module_disconnected_or_poweredoff"), object: nil)
        }
    }
    
    func hideAlert() {
        if alertView != nil {
            if BLEManager.sharedInstance.discoveredPeripheral != nil {
                BLEManager.sharedInstance.disconnectPeripheral((BLEManager.sharedInstance.discoveredPeripheral)!)
                BLEManager.sharedInstance.peripheralDelegate = nil
            }
            
            BLEManager.sharedInstance.dispose()
            
            alertView.removeFromSuperview()
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    func showAlert(message: String!) {
        if alertView != nil {
            alertView.removeFromSuperview()
        }
        
        alertView = ATAlertView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height), message: message, cancelButtonTitle: NSLocalizedString("OK", comment: ""), confirmButtonTitle: "")
        alertView.delegate = self
        alertView.backgroundColor = UIColor.clear
        self.view.addSubview(alertView)
        
        alertView.translatesAutoresizingMaskIntoConstraints = false
        
        let subviewsDict: Dictionary = ["alertView": alertView];
        
        let arrXconstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[alertView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.view.addConstraints(arrXconstraints)
        
        let arrYconstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[alertView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.view.addConstraints(arrYconstraints)
    }
    
    func performAnimation() {
        let hover = CABasicAnimation(keyPath: "position")
        hover.isAdditive = true
        hover.fromValue = NSValue(cgPoint: CGPoint.zero)
        hover.toValue = NSValue(cgPoint: CGPoint(x: 25.0, y: 0.0))
        hover.autoreverses = false
        hover.duration = 1.0
        hover.repeatCount = Float.infinity
        dashedLineView.layer.add(hover, forKey: "myHoverAnimation")
    }
    
    func showPairedView() {
        bleTimer.invalidate()
        dottedImgVw.isHidden = true
        phoneImageView.isHidden = true
        dashedLineView.isHidden = true
        blutoothImageView.isHidden = true
        boardImageView.isHidden = true
        pairedImageView.isHidden = false
        bottomView.isHidden = false
        
        self.pleaseWaitButton.setTitle(NSLocalizedString("Device paired", comment: ""), for: .normal)
        titleTextField.text = NSLocalizedString("Device paired", comment: "")
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.showTurnOnBluetoothAlert), name: NSNotification.Name(rawValue: "bluetooth_off_notification"), object: nil)
    }
    
    @IBAction func connectToWifiAction(_ sender: Any) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "bluetooth_off_notification"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "module_disconnected_or_poweredoff"), object: nil)
        let wifiListControllerObj = self.storyboard!.instantiateViewController(withIdentifier: "WifiNetworkViewController") as! WifiNetworkViewController
        self.navigationController!.pushViewController(wifiListControllerObj, animated: true)
    }
    
    func serviceUUID() -> String {
        return Constants.SERVICE_UUID.appending(bleMac)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
}



