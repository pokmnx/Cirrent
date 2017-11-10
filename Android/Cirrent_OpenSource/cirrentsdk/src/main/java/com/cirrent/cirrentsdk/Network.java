package com.cirrent.cirrentsdk;

import java.util.ArrayList;

public class Network {
    String ssid;
    String flags;
    boolean open = false;

    String bssid;
    String roamingID;
    int frequency;
    int signalLevel;
    int priority;
    String security;
    String status;
    String source;
    String anqp_roaming_consortium;
    int capabilities;
    int quality;
    int noise_level;
    String information_element;

    public String getSSID() {
        return ssid;
    }

    public void setSSID(String ssid) {
        this.ssid = ssid;
    }

    public void setFlags(String flags) {
        this.flags = flags;
    }

    public String getFlags() {
        return flags;
    }

    public boolean isOpen() {
        return open;
    }

    public void setOpen(boolean open) {
        this.open = open;
    }

    public void setSecurity(String security) {this.security = security;}

    public String getSecurity() {return this.security;}

    public void setRoamingID(String roamingID) {this.roamingID = roamingID;}

    public String getRoamingID() {return this.roamingID;}
}
