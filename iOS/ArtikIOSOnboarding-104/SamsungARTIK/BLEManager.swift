//
//  BLEManager.swift
//  SamsungARTIK
//
//  Created by Surendra on 12/20/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol LeDiscoveryDelegate: NSObjectProtocol {
    func discoveryDidRefresh()
    func discoveryStatePoweredOff()
    func discoveryStatePoweredOn()
    func peripheralDidConnect(_ value: Bool)
}

class BLEManager: NSObject, CBCentralManagerDelegate {
    
    var discoveryDelegate: LeDiscoveryDelegate?
    weak var peripheralDelegate: WifiOnboardingProtocol?
    var bluetoothState = CBManagerState(rawValue: 0)
    var discoveredPeripheral: CBPeripheral!
    var connectedServices = [WifiOnboardingService]()
    var serviceUUID = ""
    static var disposed: Bool = false
    var centralManager: CBCentralManager!
    var pendingInit: Bool!
    var service: WifiOnboardingService?
    
    struct Static {
        static var instance: BLEManager? = BLEManager()
    }
    
    class var sharedInstance: BLEManager {
        if disposed == true {
            disposed = false
            Static.instance = BLEManager()
        }
        return Static.instance!
    }
    
    // MARK: -
    // MARK: Init
    
    override init() {
        super.init()
        pendingInit = true
        centralManager = CBCentralManager(delegate: self, queue: nil)
        connectedServices = [WifiOnboardingService]()
    }
    
    func dispose() {
        BLEManager.disposed = true
        BLEManager.Static.instance = nil
    }
    
    /**
     Starts scanning for a bluetooth device that has a service sepcified by
     @param uuidString
     */
    
    func startScanning(forUUIDString uuidString: String) {
        if pendingInit == true {
            print("cannoot scan bluetooth is off")
            return
        }
        
        print("Scanning for a peripheral with given service: \(uuidString)")
        serviceUUID = uuidString
        
        let uuidArray = [CBUUID(string: uuidString)]
        let options = [ CBCentralManagerScanOptionAllowDuplicatesKey : Int(false),CBCentralManagerOptionShowPowerAlertKey : false ] as [String : Any]
        print("uuidArray = \(uuidArray)")
        centralManager.scanForPeripherals(withServices: uuidArray, options: options)
    }
    
    /**
     Stops scanning. This should be called once the required peripheral is found
     */
    
    func stopScanning() {
        centralManager.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("advertisementData = \(advertisementData) & RSSI = \(RSSI) & peripheral = \(peripheral)")
        
        discoveredPeripheral = peripheral
        if discoveryDelegate != nil {
            discoveryDelegate!.discoveryDidRefresh()
        }
    }
    
    // MARK: -
    // MARK: Connection/Disconnection
    /*
     Connect to required peripheral. This can be called typically from ViewController once the required peripheral is found
     */
    
    func connect(_ peripheral: CBPeripheral) {
        if peripheral.state != .connected {
            centralManager.connect(peripheral, options: [
                CBCentralManagerOptionShowPowerAlertKey : false])
        }
    }
    
    func disconnectPeripheral(_ peripheral: CBPeripheral) {
        if peripheral != nil {
            print("Cancelling peripheral connection")
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    /*
     Peripheral connection callback
     */
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        service = nil
        
        /* Create a service instance. */
        print("peripheral = \(peripheral)")
        
        service = WifiOnboardingService(peripheral: peripheral)
        service?.start(serviceUUID)
        
        if !connectedServices.contains(service!) {
            connectedServices.append(service!)
        }
        if discoveryDelegate != nil {
            discoveryDelegate?.peripheralDidConnect(true)
        }
        if peripheralDelegate != nil {
            peripheralDelegate?.onBoardingService(service: service!)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Attempted connection to peripheral \(peripheral.name) failed: \(error!.localizedDescription)")
        if discoveryDelegate != nil {
            discoveryDelegate?.peripheralDidConnect(false)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected!")
        
        if discoveryDelegate != nil {
            discoveryDelegate?.peripheralDidConnect(false)
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIF_PERIPHERAL_DISCONNECTED), object: nil)
    }
    
    func getService() -> WifiOnboardingService {
        return service!
    }
    
    func clearDevices() {
        connectedServices.removeAll()
    }
    
    /*
     Callback for bluetooth status.
     */
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var previousState = CBManagerState.unknown
        bluetoothState = centralManager.state
        
        switch centralManager.state {
        case .unsupported:
            print("The platform/hardware doesn't support Bluetooth Low Energy.")
            
        case .poweredOff:
            self.clearDevices()
            print("bluetooth is off")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "bluetooth_off_notification"), object: nil)
            /* Tell user to power ON BT for functionality, but not on first run - the Framework will alert in that instance. */
            if previousState != .unknown {
                discoveryDelegate?.discoveryStatePoweredOff()
            }
            
        case .unauthorized:
            /* Tell user the app is not allowed. */
            print("bluetooth is unauthorised")
            
        case .unknown:
            /* Bad news, let's wait for another event. */
            print("bluetooth is unknown")
            
        case .poweredOn:
            self.clearDevices()
            pendingInit = false
            print("bluetooth is on")
            discoveryDelegate!.discoveryStatePoweredOn()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "bluetooth_on_notification"), object: nil)
            
        case .resetting:
            self.clearDevices()
            print("bluetooth is resetting")
            pendingInit = true
        }
        previousState = centralManager.state
    }
}
