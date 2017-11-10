package com.cirrent.cirrentsdk;

/**
 * RESPONSE TYPE when called Cirrent Cloud
 */

public class CirrentType {

    /**
     * Standard RESPONSE from Cirrent Cloud
     */

    public enum RESPONSE {
        SUCCESS,
        FAILED_NO_RESPONSE,
        FAILED_INVALID_STATUS,
        FAILED_INVALID_TOKEN
    }

    /**
     * RESPONSE for finding nearby devices from Cloud
     */

    public enum FIND_DEVICE_RESULT {
        SUCCESS,
        FAILED_NETWORK_OFFLINE,
        FAILED_LOCATION_NOT_PERMITTED,
        FAILED_LOCATION_DISABLED,
        FAILED_UPLOAD_ENVIRONMENT,
        FAILED_NO_DEVICE,
        FAILED_NO_RESPONSE,
        FAILED_INVALID_STATUS,
        FAILED_INVALID_TOKEN,
        FAILED_PARSE_JSON
    }

    /**
     * RESPONSE for joining status to device from Cloud
     */

    public enum JOINING_STATUS {
        JOINED,
        RECEIVED_CREDS,
        ATTEMPTING_TO_JOIN,
        OPTIMIZING_CONNECTION,
        TIMED_OUT,
        TIMED_OUT_TRIED_API,
        FAILED,
        GET_DEVICE_STATUS_FAILED,
        SELECTED_DEVICE_NIL,
        FAILED_NO_RESPONSE,
        FAILED_INVALID_STATUS,
        FAILED_INVALID_TOKEN,
        NOT_SOFTAP_NETWORK
    }

    /**
     * RESPONSE after put credentials to device
     */

    public enum CREDENTIAL_RESPONSE {
        SUCCESS,
        FAILED_NO_RESPONSE,
        FAILED_INVALID_STATUS,
        FAILED_INVALID_TOKEN,
        NOT_SOFTAP
    }

    /**
     * SOFTAP RESPONSE
     */

    public enum SOFTAP_RESPONSE {
        SUCCESS_WITH_SOFTAP,
        FAILED_NOT_GET_SOFTAP_IP,
        FAILED_NOT_SOFTAP_SSID,
        FAILED_SOFTAP_NO_RESPONSE,
        FAILED_SOFTAP_INVALID_STATUS,
        FAILED_NOT_SUPPORT_SOFTAP
    }
}
