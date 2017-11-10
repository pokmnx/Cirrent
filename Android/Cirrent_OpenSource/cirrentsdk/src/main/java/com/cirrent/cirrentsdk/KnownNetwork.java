package com.cirrent.cirrentsdk;

public class KnownNetwork {
    String credentialID;
    String ssid;
    String roamingID;
    String bssid;
    String status;
    int priority;
    String security;
    String source;

    public String getSSID() {
        return ssid;
    }

    public String getStatus() {
        return status;
    }

    public String getRoamingID() {return roamingID;}

    public String getSecurity() {return security;}
}
