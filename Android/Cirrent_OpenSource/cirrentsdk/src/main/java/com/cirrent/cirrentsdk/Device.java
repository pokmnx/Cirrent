package com.cirrent.cirrentsdk;

/**
 * Java Class defined Device
 */

public class Device {
    String  deviceId;
    String imageURL;
    String providerAttribution;
    String providerAttributionLogo;
    String providerAttributionLearnMoreURL;
    String friendlyName;
    boolean identifyingActionEnabled;
    String identifyingActionDescription;
    boolean userActionEnabled;
    String userActionDescription;
    boolean confirmedOwnerShip;

    int idDeviceType;
    String macAddress;
    int idDeviceId;
    double uptime;
    ProviderKnownNetwork provider_known_network;

    public String getDeviceId() {
        return deviceId;
    }

    public String getImageURL() {
        return imageURL;
    }

    public String getProviderAttribution() {
        return providerAttribution;
    }

    public String getProviderAttributionLogo() {
        return providerAttributionLogo;
    }

    public String getProviderAttributionLearnMoreURL() {
        return providerAttributionLearnMoreURL;
    }

    public boolean isIdentifyingActionEnabled() {
        return identifyingActionEnabled;
    }

    public String getIdentifyingActionDescription() {
        return identifyingActionDescription;
    }

    public String getFriendlyName() {
        return friendlyName;
    }

    public boolean isUserActionEnabled() {
        return userActionEnabled;
    }

    public boolean isConfirmedOwnerShip() {
        return confirmedOwnerShip;
    }

    public String getUserActionDescription() {
        return userActionDescription;
    }


}
