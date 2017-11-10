import Foundation

/// ProviderKnownNetwork - if the user's phone is on a private network for which the provider has the credentials
/// the user can be given an option to have the provider provision the network (instead of requiring the user to 
/// manually enter the credentials).
///
public class ProviderKnownNetwork {
    var providerName:String = ""
    var ssid:String = ""
    var providerLogo:String = ""
    var providerUUID:String = ""
    
    /// Get the name of the provider who can provision this network
    ///
    /// - Returns: the name of the provider
    public func getProviderName() -> String {
        return providerName
    }
    
    /// Get the SSID of the network that the provider can provision
    ///
    /// - Returns: SSID
    public func getSSID() -> String {
        return ssid
    }
    
    /// Get the logo to show for this provider (a URL to an image)
    ///
    /// - Returns: logo URL
    public func getProviderLogo() -> String {
        return providerLogo
    }
    
    /// Gets the unique id for this provider. This will be passed into the PutProviderCredentials call
    ///
    /// - Returns: UUID
    public func getProviderUUID() -> String {
        return providerUUID
    }
}

/// The device that the app is onboarding
public class Device : NSObject {
    var deviceId:String = ""
    var imageURL:String = ""
    var provider_known_network:ProviderKnownNetwork? = nil
    var identifyingActionEnabled:Bool = false
    var identifyingActionDescription:String = ""
    var userActionEnabled:Bool = false
    var userActionDescription:String = ""
    var confirmedOwnerShip:Bool = false
    var providerAttribution:String = ""
    var providerAttributionLogo:String = ""
    var providerAttributionLearnMoreURL:String = ""
    var idDeviceType:Int = -1
    var macAddress:String = ""
    var idDeviceId:Int = -1
    var uptime:Double = 0
    
    /// The name the user has assigned to this device
    public var friendlyName:String {
        get {
            if deviceId == "" {
                return "unnamed device"
            }
            let name = UserDefaults.standard.string(forKey: deviceId + "_friendlyName")
            if name == nil || name == "" {
                return deviceId
            }
            return name!
        }
        set(name) {
            if name != "" && deviceId != "" {
                UserDefaults.standard.set(name, forKey: deviceId + "_friendlyName")
            }
        }
    }
    
    /// A picture of the device
    ///
    /// - Returns: URL to image
    public func getImageURL() -> String {
        return imageURL
    }
    
    /// Unique ID for this device
    ///
    /// - Returns: the unique device id
    public func getDeviceID() -> String {
        return deviceId
    }
    
    /// If a provider helped to onboard this device (by letting it join the provider's ZipKey network
    /// this field will be populated with the name of the provider whose ZipKey network was used
    ///
    /// - Returns: name of provider
    public func getProviderAttribution() -> String {
        return providerAttribution
    }
    
    /// If a provider helped to onboard this device (by letting it join the provider's ZipKey network
    /// this field will be populated with a URL pointing to the logo of the provider whose ZipKey network was used
    ///
    /// - Returns: URL to logo
    public func getProviderAttributionLogo() -> String {
        return providerAttributionLogo
    }
    
    /// If a provider helped to onboard this device (by letting it join the provider's ZipKey network
    /// this field will be populated with a URL pointing a site where the user can learn more about this provider
    ///
    /// - Returns: URL to learn-more website
    public func getProviderAttributionLearnMoreURL() -> String {
        return providerAttributionLearnMoreURL
    }
    
    /// Indicates whether this device can support the identify-action. If true, the user can be given the option to
    /// have the device perform an identify-action (e.g play a sound or flash a light)
    ///
    /// - Returns: true if identify-action is enabled for this device, false otherwise
    public func getIdentifyingActionEnabled() -> Bool {
        return identifyingActionEnabled
    }
    
    /// If this device can support the identify-action, returns a textual description of the identify action
    /// so that the user knows what to look for (e.g. a sound will play).
    ///
    /// - Returns: string describing the identify action
    public func getIdentifyingActionDescription() -> String {
        return identifyingActionDescription
    }
    
    /// Indicates whether this device can support the user-action. If true, the user is required to take some
    /// action on the device before they can proceed to onboarding the device. 
    ///
    /// - Returns: true if user-action is enabled for this device, false otherwise
    public func getUserActionEnabled() -> Bool {
        return userActionEnabled
    }
    
    /// Returns true if the user confirmed ownership (by performing the user action)
    ///
    /// - Returns: true if ownership was confirmed, false otherwise
    public func getConfirmedOwnerShip() -> Bool {
        return confirmedOwnerShip
    }
    
    /// If this device can support the user-action, returns a textual description of the user action
    /// so that the user knows they are expected to do (e.g. push volume-up button on the device).
    ///
    /// - Returns: string describing the user action
    public func getUserActionDescription() -> String {
        return userActionDescription
    }
    
    public func verifyWith(accountID:String?) -> Bool {
        if accountID == nil {
            return false
        }
        
        let accountStr:String = accountID! + "_"
        let range = deviceId.range(of: accountStr)
        if range == nil {
            return false
        }
        
        if range!.lowerBound == deviceId.startIndex {
            deviceId.removeSubrange(range!)
            return true
        }
        
        return false
    }
}

/// A network that is provisioned on the device
public class KnownNetwork : NSObject {
    /// The SSID of the network
    public var ssid:String = ""
    
    /// The priority of this network. The device will join the highest priority network that it can see.
    public var priority:Int = -1
    var credentialID:String = ""
    var roamingID:String = ""
    var bssid:String = ""
    var status:String = ""
    var security:String = ""
    var source:String = ""
    
    public func getStatus() -> String {
        return status
    }
}

/// A network in the wi-fi scan list
public class Network : NSObject {
    /// The SSID for the network the device can see
    public var ssid:String = ""
    /// The network flags (e.g. security type)
    public var flags:String = ""
    /// Whether this is an open or secure network
    public var open:Bool = false
    
    var priority:Int = 200
    var bssid:String = ""
    var frequency:UInt = 0
    var signalLevel:Int = -1
    var roamingID:String = ""
    var security:String = ""
    var status:String = ""
    var source:String = ""
    var anqp_roaming_consortium:String = ""
    var capabilities:UInt = 0
    var quality:UInt = 0
    var noise_level:Int = -1
    var information_element:String = ""
}

public class DeviceStatus :NSObject {
    var knownNetworks:[KnownNetwork] = [KnownNetwork]()
    var wifiScans:[Network] = [Network]()
    var bound:Bool = false
    var timeStamp:Date? = nil
    
    public func getKnownNetworks() -> [KnownNetwork] {
        return knownNetworks
    }
    
    public func getWifiScans() -> [Network] {
        return wifiScans
    }
    
    public func isBound() -> Bool {
        return bound
    }
    
    public func getTimeStamp() -> Date? {
        return timeStamp
    }
}

/// Data structure for Cirrent SDK
public class Model {
    public var selectedDevice: Device? = nil
    public var selectedNetwork: Network? = nil
    public var selectedNetworkPassword: String? = nil
    public var credentialId: String? = nil
    public var providerName: String? = nil
    public var selectedProvider:ProviderKnownNetwork? = nil
    
    var devices: [Device] = [Device]()
    var networks: [Network] = [Network]()
    var ssid: String? = nil
    var zipkeyhotspot: String? = nil
    var GCN:Bool = false
    var providerNetwork:ProviderKnownNetwork? = nil
    var bssid: String? = nil
    var scdKey: String? = nil
    var SoftAPIp:String? = nil
    
    /// Returns true if device is on a ZipKey network
    ///
    /// - Returns: true if on ZipKey network
    public func isOnZipKeyNetwork() -> Bool {
        return GCN
    }
    
    /// Gets the SSID of the network the phone is on
    ///
    /// - Returns: SSID
    public func getSSID() -> String? {
        return ssid
    }
    
    /// Gets the list of nearby devices
    ///
    /// - Returns: List of devices that are nearby, turned on recently and unclaimed
    public func getDevices() -> [Device]? {
        return devices
    }
    
    /// Gets the name of the provider provisioning this network
    ///
    /// - Returns: provider name
    public func getProviderName() -> String? {
        return providerName
    }
    
    /// Gets the name of the ZipKey hotspot that this device joined
    ///
    /// - Returns: name of ZipKey network
    public func getZipKeyHotSpot() -> String? {
        return zipkeyhotspot
    }
    
    /// Gets information about the provider that can provision this private network
    ///
    /// - Returns: ProviderKnownNetwork structure for this provider
    public func getProviderNetwork() -> ProviderKnownNetwork? {
        return providerNetwork
    }
    
    public func setProviderNetwork(network:ProviderKnownNetwork?) {
        providerNetwork = network
    }
    
    func hasDevices() -> Bool {
        if devices.count > 0 {
            return true
        }
        return false
    }
    
    func getFirstDevice() -> Device? {
        if hasDevices() {
            return devices[0]
        }
        return nil
    }
    
    func getDevice(deviceID:String) -> Device? {
        if devices.count == 0 {
            return nil
        }
        
        for dev in devices {
            if dev.deviceId == deviceID {
                return dev
            }
        }
        
        return nil
    }
    
    func setSoftAPNetworks(data:JSON) {
        let dataArray:[AnyObject] = data.arrayObject! as [AnyObject]
        var updatedNetworks:[Network] = [Network]()
        for net in dataArray {
            let netData:JSON = JSON(net)
            
            let network:Network = Network()
            network.bssid = netData["bssid"].stringValue
            network.ssid = netData["ssid"].stringValue
            network.frequency = netData["frequency"].uIntValue
            network.flags = netData["flags"].stringValue
            network.roamingID = netData["roaming_id"].stringValue
            network.signalLevel = netData["signal_level"].intValue
            network.anqp_roaming_consortium = netData["anqp_roaming_consortium"].stringValue
            network.capabilities = netData["capabilities"].uIntValue
            network.quality = netData["quality"].uIntValue
            network.noise_level = netData["noise_level"].intValue
            network.information_element = netData["information_element"].stringValue
            
            updatedNetworks.append(network)
        }
        self.networks = updatedNetworks
    }
    
    /// Returns the list of Wi-Fi networks that the device can see
    ///
    /// - Returns: List of networks
    public func getNetworks() -> [Network] {
        var updatedNetworks:[Network] = [Network]()
        
        for network in self.networks {
            
            if network.ssid.characters.count != 0 && network.ssid.contains(CirrentService.sharedService.SoftAPSSID) != true {
                network.ssid = network.ssid.trimmingCharacters(in: .whitespaces)
                if network.ssid.characters.count != 0 {
                    var bExist:Bool = false
                    for net in updatedNetworks {
                        if net.ssid == network.ssid {
                            bExist = true
                            break
                        }
                    }
                    
                    if bExist == false {
                        updatedNetworks.append(network)
                    }
                }
            }
        }
        
        self.networks = updatedNetworks
        
        self.networks.sort {
            $0.ssid.lowercased() < $1.ssid.lowercased()
        }
        
        return self.networks
    }
    
    func setSoftAPIp(ip:String) {
        var ind = ip.characters.split(separator: ".")
        var newip:String = ""
        var index = 0
        while index < ind.count - 1 {
            newip += String(ind[index])
            newip += "."
            index += 1
        }
        newip += "1"
        self.SoftAPIp = newip
        self.SoftAPIp = "192.168.1.73:3000"
    }
    
    func setNetworks(data:JSON) {
        
        let dataArray:[AnyObject] = data.arrayObject! as [AnyObject]
        networks = [Network]()
        
        for net in dataArray {
            let netData:JSON = JSON(net)
            
            let network:Network = Network()
            network.bssid = netData["bssid"] != nil ? String(describing: netData["bssid"]) : ""
            network.ssid = netData["ssid"] != nil ? String(describing: netData["ssid"]) : ""
            network.frequency = netData["frequency"] != nil ? UInt(netData["frequency"].intValue) : 0
            network.flags = netData["flags"] != nil ? String(describing: netData["flags"]) : ""
            network.signalLevel = netData["signal_level"] != nil ? netData["signal_level"].intValue : 0
            network.anqp_roaming_consortium = netData["anqp_roaming_consortium"] != nil ? String(describing: netData["anqp_roaming_consortium"]) : ""
            network.capabilities = netData["capabilities"] != nil ? UInt(netData["capabilities"].intValue) : 0
            network.quality = netData["quality"] != nil ? UInt(netData["quality"].intValue) : 0
            network.noise_level = netData["noise_level"] != nil ? netData["noise_level"].intValue : 0
            network.information_element = netData["information_element"] != nil ? String(describing: netData["information_element"]) : ""
            
            networks.append(network)
        }
    }
    
    func setDevices(devices:[Device]) {
        self.devices = [Device]()
        for device in devices {
            let newDevice = Device()
            newDevice.deviceId = device.deviceId
            newDevice.idDeviceId = device.idDeviceId
            newDevice.idDeviceType = device.idDeviceType
            newDevice.imageURL = device.imageURL
            newDevice.macAddress = device.macAddress
            newDevice.uptime = device.uptime
            newDevice.confirmedOwnerShip = device.confirmedOwnerShip
            newDevice.friendlyName = device.friendlyName
            newDevice.identifyingActionEnabled = device.identifyingActionEnabled
            newDevice.identifyingActionDescription = device.identifyingActionDescription
            newDevice.userActionEnabled = device.userActionEnabled
            newDevice.userActionDescription = device.userActionDescription
            newDevice.providerAttribution = device.providerAttribution
            newDevice.providerAttributionLogo = device.providerAttributionLogo
            newDevice.providerAttributionLearnMoreURL = device.providerAttributionLearnMoreURL
            
            if device.provider_known_network != nil {
                newDevice.provider_known_network = ProviderKnownNetwork()
                newDevice.provider_known_network!.providerLogo = device.provider_known_network!.providerLogo
                newDevice.provider_known_network!.providerName = device.provider_known_network!.providerName
                newDevice.provider_known_network!.providerUUID = device.provider_known_network!.providerUUID
                newDevice.provider_known_network!.ssid = device.provider_known_network!.ssid
            }

            self.devices.append(newDevice)
        }
    }
}
