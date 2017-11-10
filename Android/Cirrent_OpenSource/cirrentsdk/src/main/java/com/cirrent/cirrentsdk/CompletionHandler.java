package com.cirrent.cirrentsdk;


import android.util.Log;
import org.json.JSONObject;
import java.util.ArrayList;

public class CompletionHandler {

    public CompletionHandler() {

    }

    public void completion(CirrentType.RESPONSE response) {
        Log.d("CompletionHandler", "completion(RESPONSE response) called. But not overrided.");
    }

    public void completion(CirrentType.RESPONSE response, JSONObject status) {
        Log.d("CompletionHandler", "process(RESPONSE response, JSONObject status) called. But not overrided.");
    }

    public void pollUserActionCompletion(Device device, String userAction) {
        Log.d("CompletionHandler", "pollUserActionCompletion(CirrentType.RESPONSE response, Device device, String userAction) called. But not overrided.");
    }

    public void putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE response, ArrayList<String> credentials) {
        Log.d("CompletionHandler", "putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE, ArrayList<String> credentials) called. But not overrided.");
    }

    public void joiningCompletion(CirrentType.JOINING_STATUS status) {
        Log.d("CompletionHandler", "joiningCompletion(CirrentType.JOINING_STATUS status) called. But not overrided.");
    }

    public void findDeviceCompletion(CirrentType.FIND_DEVICE_RESULT result, ArrayList<Device> devices) {
        Log.d("CompletionHandler", "findDeviceCompletion(CirrentType.FIND_DEVICE_RESULT result, ArrayList<Device> devices) called. But not overrided.");
    }

    public void getStatusCompletion(CirrentType.RESPONSE response, JSONObject status) {
        Log.d("CompletionHandler", "getStatusCompletion(CirrentType.RESPONSE response, JSONObject status) called. But not overrided.");
    }

    public void softAPCompletion(CirrentType.SOFTAP_RESPONSE response) {
        Log.d("CompletionHandler", "softAPCompletion(CirrentType.SOFTAP_RESPONSE response) called. But not overrided.");
    }

    public void getNetworkCompletion(CirrentType.RESPONSE response, ArrayList<KnownNetwork> networks) {
        Log.d("CompletionHandler", "getNetworkCompletion(CirrentType.RESPONSE response, ArrayList<KnownNetwork> networks) called. But not overrided.");
    }
}
