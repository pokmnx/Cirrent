//
//  WifiOnboardingService.swift
//  SamsungARTIK
//
//  Created by Surendra on 12/21/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit
import Foundation
import CoreBluetooth

protocol WifiOnboardingProtocol: NSObjectProtocol {
    func stateChanged(_ state: String)
    func onBoardingService(service: WifiOnboardingService)
}

class WifiOnboardingService: NSObject, CBPeripheralDelegate {

    var wifiSSIDData: Data!
    var onboardingServiceUUID = ""
    var onboardingDeviceId = ""
    var ipAddress = ""
    var deviceTypeId = ""
    var servicePeripheral: CBPeripheral!
    var onboardingService: CBService!
    var detailedstatusCharacterstic: CBCharacteristic!
    var wifiStatusNotificationCharacterstic: CBCharacteristic!
    var statusNotificationCharacterstic: CBCharacteristic!
    weak var delegate: WifiOnboardingProtocol?
    
    // MARK: -
    // MARK: Init
    
    init(peripheral: CBPeripheral) {
        servicePeripheral = peripheral
        
        super.init()
        servicePeripheral.delegate = self
    }
    
    func reset() {
        if servicePeripheral != nil {
            servicePeripheral = nil
        }
    }
    
    // MARK: -
    // MARK: Service interaction
    
    func start(_ serviceUUID: String) {
        onboardingServiceUUID = serviceUUID
        servicePeripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Did discover services for peripheral: \(peripheral.description)")
        var services: [CBService]? = nil
        let charactersticUUIDs = [CBUUID(string: Constants.STATUS_CHARACTERISTIC_UUID), CBUUID(string: Constants.DETAILED_STATUS_CHARACTERISTIC_UUID), CBUUID(string: Constants.SSID_CHARACTERISTIC_UUID), CBUUID(string: Constants.AUTH_CHARACTERISTIC_UUID), CBUUID(string: Constants.PASSPHRASE_CHARACTERISTIC_UUID), CBUUID(string: Constants.CHANNEL_CHARACTERISTIC_UUID), CBUUID(string: Constants.COMMAND_CHARACTERISTIC_UUID), CBUUID(string: Constants.VENDORID_CHARACTERISTIC_UUID), CBUUID(string: Constants.DEVICEID_CHARACTERISTIC_UUID), CBUUID(string: Constants.WIFI_STATE_CHARACTERISTIC_UUID), CBUUID(string: Constants.IPADDRESS_CHARACTERISTIC_UUID), CBUUID(string: Constants.CHALLENGE_PIN_CHARACTERISTIC_UUID), CBUUID(string: Constants.ACCESS_TOKEN_CHARACTERISTIC_UUID), CBUUID(string: Constants.DEVICE_TYPE_ID_CHARACTERISTIC_UUID), CBUUID(string: Constants.SDR_VENDOR_ID_CHARACTERISTIC_UUID), CBUUID(string: Constants.START_REG_CHARACTERISTIC_UUID), CBUUID(string: Constants.COMPLETE_REG_CHARACTERISTIC_UUID), CBUUID(string: Constants.DID_CHARACTERISTIC_UUID), CBUUID(string: Constants.UID_CHARACTERISTIC_UUID), CBUUID(string: Constants.WIFI_DATA_CHARACTERISTIC_UUID)]
        
        if peripheral != servicePeripheral {
            print("Wrong Peripheral.\n")
            return
        }
        if error != nil {
            print("Error \(error)\n")
            return
        }
        
        services = peripheral.services
        if services == nil || services?.count == nil {
            return
        }
        
        onboardingService = nil
        for service: CBService in services! {
            if service.uuid.isEqual(CBUUID(string: onboardingServiceUUID)) {
                onboardingService = service
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "serviceDicsovered"), object: nil)
            }
        }
        
        if (onboardingService != nil) {
            peripheral.discoverCharacteristics(charactersticUUIDs, for: onboardingService)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let characteristics = service.characteristics!
        
        if peripheral != servicePeripheral {
            print("Wrong Peripheral.\n")
            return
        }
        if service != onboardingService {
            print("Wrong Service.\n")
            return
        }
        if error != nil {
            print("Error \(error)\n")
            return
        }
        
        for characteristic: CBCharacteristic in characteristics {
            
            if characteristic.uuid.isEqual(CBUUID(string: Constants.STATUS_CHARACTERISTIC_UUID)) {
                print("Discovered WIFI Status Characteristic")
            }
            if characteristic.uuid.isEqual(CBUUID(string: Constants.DETAILED_STATUS_CHARACTERISTIC_UUID)) {
                print("Discovered WIFI Status Characteristic")
                peripheral.setNotifyValue(false, for: characteristic)
            }
        }
    }
    
    func sendModuleDisconnectedNotification() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "module_disconnected_or_poweredoff"), object: nil)
    }
    
    // MARK: -
    // MARK: Characteristics interaction
    
    func writeCharacteristic(_ charUUID: String, value: String) {
        var characterstic: CBCharacteristic?
        if servicePeripheral == nil || onboardingService == nil {
            print("Peripheral or service is nil!")
            return
        }
        
        //Navigating to Dashboard as the module is disconnected (Powered off)
        if onboardingService.characteristics == nil {
            self.sendModuleDisconnectedNotification()
            return
        }
        
        for characteristic: CBCharacteristic in onboardingService.characteristics! {
            if characteristic.uuid.isEqual(CBUUID(string: charUUID)) {
                characterstic = characteristic
            }
        }
        
        if characterstic == nil {
            print("Cannot write on a nil characterstic")
            return
        }
        
        let data = value.data(using: String.Encoding.utf8)
        servicePeripheral.writeValue(data!, for: characterstic!, type: CBCharacteristicWriteType.withResponse)
    }
    
    func readCharacteristic(_ charUUID: String) {
        var characterstic: CBCharacteristic?
        if servicePeripheral == nil || onboardingService == nil {
            return
        }
        
        //Navigating to Dashboard as the module is disconnected (Powered off)
        if onboardingService.characteristics == nil {
            self.sendModuleDisconnectedNotification()
            return
        }
        
        for characteristic: CBCharacteristic in onboardingService.characteristics! {
            if characteristic.uuid.isEqual(CBUUID(string: charUUID)) {
                characterstic = characteristic
            }
        }
        
        if characterstic == nil {
            print("Cannot read  a nil characterstic")
            return
        }
        
        servicePeripheral.readValue(for: characterstic!)
    }
    
    func notifyCharacteristic(_ charUUID: String, value: Bool) {
        var characterstic: CBCharacteristic?
        if servicePeripheral == nil || onboardingService == nil {
            return
        }
        
        //Navigating to Dashboard as the module is disconnected (Powered off)
        if onboardingService.characteristics == nil {
            self.sendModuleDisconnectedNotification()
            return
        }
        
        print("onboardingService.characteristics = \(onboardingService.characteristics)")
        for characteristic: CBCharacteristic in onboardingService.characteristics! {
            if characteristic.uuid.isEqual(CBUUID(string: charUUID)) {
                characterstic = characteristic
            }
        }
        if characterstic == nil {
            print("Cannot set notify for  a nil characterstic")
            return
        }
        servicePeripheral.setNotifyValue(value, for: characterstic!)
    }
    
    
    /**
     Callback for characteristic update
     using this call back for following:
     Notifications are sent when the following values are updated: IPADDRESS_CHARACTERISTIC_UUID, DID_CHARACTERISTIC_UUID, WIFI_DATA_CHARACTERISTIC_UUID
     */
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        var notifyStateChange = true

        if peripheral != servicePeripheral {
            print("Wrong peripheral\n")
            return
        }
        
        if error != nil {
            print("Error \(error)\n")
            return
        }
        
        let data = characteristic.value!
        print("Data updated : \(String(data: data, encoding: .utf8) )")
        
        let status = String(data: data, encoding: .utf8)
        
        if characteristic.uuid.uuidString.isEqual(Constants.IPADDRESS_CHARACTERISTIC_UUID) {
            self.ipAddress = status!
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIF_IP_ADDRESS_READ), object: nil)
        }
        if characteristic.uuid.uuidString.isEqual(Constants.DID_CHARACTERISTIC_UUID) {
            self.onboardingDeviceId = status!
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIF_DEVICE_ID_READ), object: nil)
        }
        if characteristic.uuid.uuidString.isEqual(Constants.WIFI_DATA_CHARACTERISTIC_UUID) {
            wifiSSIDData = data
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIF_WIFI_DATA_READ), object: nil)
        }
        if characteristic.uuid.uuidString.isEqual(Constants.DEVICE_TYPE_ID_CHARACTERISTIC_UUID) {
            deviceTypeId = status!
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIF_DTID_READ), object: nil)
            notifyStateChange = false
        }

        if notifyStateChange {
            delegate?.stateChanged(status!)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Did write value \(characteristic), \(error)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("Updated notification state for charaterstic: \(characteristic) , \(error?.localizedDescription)")
    }
    
    func getWifiSSIDdata() -> Data {
        return wifiSSIDData
    }
}
