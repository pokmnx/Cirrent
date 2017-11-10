package com.cirrent.cirrentsdk;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;

public class Model {
    ArrayList<Device> devices;
    Device selectedDevice;
    ArrayList<Network> networks;
    Network selectedNetwork;
    String selectedNetworkPassword;
    String ssid;
    String credentialId;
    ProviderKnownNetwork providerNetwork;
    ProviderKnownNetwork selectedProvider;
    String providerName;
    String zipkeyhotspot;

    String bssid;
    String scdKey;
    String softAPIp;
    boolean GCN;

    public ArrayList<Device> getDevices() {
        return devices;
    }

    public Device getSelectedDevice() {
        return selectedDevice;
    }

    public boolean setSelectedDevice(Device device) {
        selectedDevice = device;
        return true;
    }

    public String getSSID() {
        return ssid;
    }

    public String getCredentialId() {
        return credentialId;
    }

    public ProviderKnownNetwork getProviderNetwork() {
        return providerNetwork;
    }

    public ProviderKnownNetwork getSelectedProvider() {
        return selectedProvider;
    }

    public String getProviderName() {
        return providerName;
    }

    public void setProviderName(String providerName) {
        this.providerName = providerName;
    }

    public String getZipkeyhotspot() {
        return zipkeyhotspot;
    }

    public void setSelectedProvider(ProviderKnownNetwork provider) {
        selectedProvider = provider;
    }

    public Network getSelectedNetwork() {
        return selectedNetwork;
    }

    public void setSelectedNetwork(Network network) {
        this.selectedNetwork = network;
    }

    public void setSelectedNetworkPassword(String password) {
        selectedNetworkPassword = password;
    }

    void setBssid(String bssid) {
        String[] list = bssid.split(":");
        String newBssid = new String ();
        for (String str : list) {
            if (str.length() != 2) {
                str = "0" + str;
            }

            newBssid += str;
        }
        this.bssid = newBssid;
    }

    public void setCredentialId(String credentialId) {
        this.credentialId = credentialId;
    }

    boolean hasDevices() {
        if (devices != null && devices.size() > 0) {
            return true;
        }
        return false;
    }

    Device getFirstDevice() {
        if (hasDevices() == true) {
            return devices.get(0);
        }
        return null;
    }

    Device getDevice(String deviceID) {
        if (devices == null || devices.size() == 0) {
            return null;
        }

        for (Device device : devices) {
            if (device.deviceId.compareTo(deviceID) == 0) {
                return device;
            }
        }
        return null;
    }

    void setSoftAPNetworks(JSONArray array) {
        ArrayList<Network> updatedNetworks = new ArrayList<Network>();
        for (int i = 0; i < array.length(); i++) {
            JSONObject object = null;
            Network network = new Network();
            try {
                object = array.getJSONObject(i);

                try {
                    network.ssid = object.getString("ssid");
                }catch (JSONException e){
                    e.printStackTrace();
                    network.ssid = "";
                }

                try {
                    network.bssid = object.getString("bssid");
                }catch (JSONException e){
                    e.printStackTrace();
                    network.bssid = "";
                }

                try {
                    network.frequency = object.getInt("frequency");
                }catch (JSONException e){
                    e.printStackTrace();
                    network.frequency = 0;
                }

                try {
                    network.flags = object.getString("flags");
                }catch (JSONException e){
                    e.printStackTrace();
                    network.flags = "";
                }

                try {
                    network.signalLevel = object.getInt("signal_level");
                }catch (JSONException e){
                    e.printStackTrace();
                    network.signalLevel = 0;
                }

                try {
                    network.anqp_roaming_consortium = object.getString("anqp_roaming_consortium");
                }catch (JSONException e){
                    e.printStackTrace();
                    network.anqp_roaming_consortium = "";
                }

                try {
                    network.capabilities = object.getInt("capabilities");
                }catch (JSONException e){
                    e.printStackTrace();
                    network.capabilities = 0;
                }

                try {
                    network.quality = object.getInt("quality");
                }catch (JSONException e){
                    e.printStackTrace();
                    network.quality = 0;
                }

                try {
                    network.noise_level = object.getInt("noise_level");
                }catch (JSONException e){
                    e.printStackTrace();
                    network.noise_level = 0;
                }

                try {
                    network.information_element = object.getString("information_element");
                }catch (JSONException e){
                    e.printStackTrace();
                    network.information_element = "";
                }

                updatedNetworks.add(network);
            } catch (JSONException e) {
                e.printStackTrace();
                updatedNetworks.add(network);
            }
        }
        this.networks = updatedNetworks;
    }

    void setSoftAPNetworks(ArrayList<Network> networks) {
        ArrayList<Network> updatedNetworks = new ArrayList<Network>();

        for (Network net : networks) {
            Network newNet = new Network();
            newNet.bssid = net.bssid;
            newNet.ssid = net.ssid;
            newNet.flags = net.flags;
            updatedNetworks.add(newNet);
        }

        this.networks = updatedNetworks;
    }

    public ArrayList<Network> getNetworks() {
        for (Network net : networks) {
            if (net.ssid != null && net.ssid.length() != 0) {
                net.ssid = net.ssid.replace("\\s", "");
            }
        }

        ArrayList<Network> updatedNetworks = new ArrayList<Network>();
        for (Network net : networks) {
            if (net.ssid != null && net.ssid.length() != 0 && net.ssid.compareTo("null") != 0 && net.ssid.indexOf(0) == -1 && net.ssid.contains(CirrentService.sharedService().getSoftAPSSID()) != true) {
                boolean bExist = false;
                for (Network network : updatedNetworks) {
                    if (network.ssid == null || network.ssid.length() == 0) {
                        continue;
                    }
                    if (network.ssid.compareTo(net.ssid) == 0) {
                        bExist = true;
                        break;
                    }
                }
                if (bExist == false) {
                    updatedNetworks.add(net);
                }
            }
        }

        networks = updatedNetworks;

        Collections.sort(networks, new Comparator<Network>() {
            @Override
            public int compare(Network lhs, Network rhs) {
                return lhs.ssid.compareTo(rhs.ssid);
            }
        });

        return networks;
    }

    void setSoftAPIp(String ip) {
        String[] ind = ip.split("\\.");
        String newIP = "";
        int index = 0;
        while (index < ind.length - 1) {
            newIP += ind[index];
            newIP += ".";
            index += 1;
        }
        newIP += "1";
        this.softAPIp = newIP;
    }

    void setNetworks(JSONArray data) {
        this.networks = new ArrayList<Network>();
        if (data == null) {
            return;
        }
        for (int i = 0; i < data.length(); i++) {
            JSONObject object = null;
            Network network = new Network();
            try {
                object = data.getJSONObject(i);

                try{
                    network.ssid = object.getString("ssid");
                }catch (JSONException e) {
                    e.printStackTrace();
                    network.ssid = "";
                }

                try {
                    network.bssid = object.getString("bssid");
                }catch (JSONException e){
                    e.printStackTrace();
                    network.bssid = "";
                }

                try {
                    network.frequency = object.getInt("frequency");
                }catch (JSONException e){
                    e.printStackTrace();
                    network.frequency = 0;
                }

                try {
                    network.flags = object.getString("flags");
                }catch (JSONException e){
                    e.printStackTrace();
                    network.flags = "";
                }

                try {
                    network.signalLevel = object.getInt("signal_level");
                }catch (JSONException e){
                    e.printStackTrace();
                    network.signalLevel = 0;
                }

                try {
                    network.anqp_roaming_consortium = object.getString("anqp_roaming_consortium");
                }catch (JSONException e){
                    e.printStackTrace();
                    network.anqp_roaming_consortium = "";
                }

                try {
                    network.capabilities = object.getInt("capabilities");
                }catch (JSONException e){
                    e.printStackTrace();
                    network.capabilities = 0;
                }

                try {
                    network.quality = object.getInt("quality");
                }catch (JSONException e){
                    e.printStackTrace();
                    network.quality = 0;
                }

                try {
                    network.noise_level = object.getInt("noise_level");
                }catch (JSONException e){
                    e.printStackTrace();
                    network.noise_level = 0;
                }

                try {
                    network.information_element = object.getString("information_element");
                }catch (JSONException e){
                    e.printStackTrace();
                    network.information_element = "";
                }

                this.networks.add(network);
            } catch (JSONException e) {
                e.printStackTrace();
                if (network.ssid != null && network.ssid.length() != 0 && network.ssid.compareTo("null") != 0 && network.ssid.indexOf('\0') == -1) {
                    this.networks.add(network);
                }
            }
        }
    }

    void setDevices(ArrayList<Device> devices) {
        this.devices = new ArrayList<Device>();

        for (int i = 0; i < devices.size(); i++) {
            Device orgDev = devices.get(i);
            Device newDev = new Device();
            newDev.deviceId = orgDev.deviceId;
            newDev.idDeviceId = orgDev.idDeviceId;
            newDev.idDeviceType = orgDev.idDeviceType;
            newDev.imageURL = orgDev.imageURL;
            newDev.macAddress = orgDev.macAddress;
            newDev.uptime = orgDev.uptime;
            newDev.confirmedOwnerShip = orgDev.confirmedOwnerShip;
            newDev.friendlyName = orgDev.friendlyName;
            newDev.identifyingActionEnabled = orgDev.identifyingActionEnabled;
            newDev.identifyingActionDescription = orgDev.identifyingActionDescription;
            newDev.userActionEnabled = orgDev.userActionEnabled;
            newDev.userActionDescription = orgDev.userActionDescription;
            newDev.providerAttribution = orgDev.providerAttribution;
            newDev.providerAttributionLogo = orgDev.providerAttributionLogo;
            newDev.providerAttributionLearnMoreURL = orgDev.providerAttributionLearnMoreURL;

            if (orgDev.provider_known_network != null) {
                newDev.provider_known_network = new ProviderKnownNetwork();
                newDev.provider_known_network.providerLogo = orgDev.provider_known_network.providerLogo;
                newDev.provider_known_network.providerName = orgDev.provider_known_network.providerName;
                newDev.provider_known_network.providerUUID = orgDev.provider_known_network.providerUUID;
                newDev.provider_known_network.ssid = orgDev.provider_known_network.ssid;
            }

            this.devices.add(newDev);
        }
    }
}
