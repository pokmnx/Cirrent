package com.cirrent.cirrentsdk;


import android.content.Context;
import android.content.SharedPreferences;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.wifi.ScanResult;
import android.net.wifi.WifiConfiguration;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Handler;
import android.os.StrictMode;
import android.telephony.TelephonyManager;
import android.text.TextUtils;
import android.text.format.Formatter;
import android.util.Base64;
import android.util.Log;
import com.loopj.android.http.JsonHttpResponseHandler;
import cz.msebera.android.httpclient.Header;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import java.net.InetAddress;
import java.nio.charset.Charset;
import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.spec.X509EncodedKeySpec;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.Random;
import javax.crypto.Cipher;
import static android.content.Context.WIFI_SERVICE;

/**
 * CirrentService.java - Cirrent Service Class
 * @author  Cirrent
 */

public class CirrentService {
    private static CirrentService sharedService = null;
    private Context mContext = null;
    private SharedPreferences mPrefs = null;
    private SharedPreferences.Editor mEditor = null;

    private static String defaultSoftAPSSID = "wcm-softap";

    public Model model;

    public CirrentService() {

    }

    /**
     * Retrieve Singleton Instance
     * @return A Singleton Instance
     */
    public static CirrentService sharedService() {
        if (sharedService == null) {
            sharedService = new CirrentService();
        }
        return sharedService;
    }

    /**
     * Set Context For CirrentService
     * <p>You should set this context before you use the CirrentService object</p>
     * @param context application context
     */
    public void setContext(Context context) {
        mContext = context;
        if (mContext == null) return;

        APIService.sharedService().setContext(mContext);
        LogService.sharedService().setContext(mContext);
        mPrefs = mContext.getSharedPreferences(Constants.PREF_KEY, 0);
        mEditor = mPrefs.edit();
        APIService.sharedService().startLocationService();
    }

    private boolean bSupportSoftAP = true;

    /**
     * Specifies whether the SDK should default to SoftAP if the device cannot be found via the cloud
     * (Defaults to true).
     * @param bSupport
     */
    public void supportSoftAP(boolean bSupport) {
        bSupportSoftAP = bSupport;
    }

    /**
     * Returns the SSID of the SoftAP network
     * <p></p>This method is used to show the network to which the phone is connected when it connect to SoftAP to communicate with the device.
     * @return the SSID of the SoftAP network
     */
    public String getSoftAPSSID() {
        if (mPrefs == null) return defaultSoftAPSSID;

        String softApSSID = mPrefs.getString(Constants.SOFTAP_SSID_KEY, defaultSoftAPSSID);
        return softApSSID;
    }

    /**
     * Changes the SSID of the SoftAP network
     * <p>For production apps, the SoftAP SSID should never be changed (as it needs to match the SSID being broadcast by the product)
     * For testing purposes, it is convenient to be able to change the SoftAP SSID, so this method is provided.
     * @param ssid
     */
    public void setSoftAPSSID(String ssid) {
        if (ssid == null || ssid.length() == 0) return;
        if (mEditor == null) return;

        mEditor.putString(Constants.SOFTAP_SSID_KEY, ssid);
        mEditor.commit();
    }

    /**
     * Check Connectivity To Intenet
     * @return
     */
    private boolean isNetworkConnected() {
        StrictMode.ThreadPolicy policy = new StrictMode.ThreadPolicy.Builder().permitAll().build();
        StrictMode.setThreadPolicy(policy);

        try {
            InetAddress ipAddr = InetAddress.getByName("google.com"); //You can replace it with your name
            return !ipAddr.equals("");
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * Returns true if the phone is on the cellular network, false otherwise.
     * @return true if on cellular, false if not
     */
    public boolean isOnCellularNetwork() {
        if (mContext == null) return false;

        ConnectivityManager cm = (ConnectivityManager) mContext.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo ni = cm.getActiveNetworkInfo();
        if (ni != null && ni.getType() == ConnectivityManager.TYPE_MOBILE)
            return true;

        return false;
    }

    /**
     * Removes the softAP SSID from the list of networks known in the phone. This is to avoid having the phone accidentally
     * re-associate to the SoftAP SSID.
     */
    public void forgetSoftAPNetwork() {

        if (isNetworkConnected() == false) return;

        if (bSupportSoftAP == false) return;

        if (mContext == null) return;

        WifiManager wifiManager = (WifiManager) mContext.getSystemService(Context.WIFI_SERVICE);
        List<WifiConfiguration> list = wifiManager.getConfiguredNetworks();
        for(WifiConfiguration i : list ) {

            String ssid = i.SSID;
            if (ssid.startsWith("\"") && ssid.endsWith("\"")){
                ssid = ssid.substring(1, ssid.length()-1);
            }

            if (ssid != null && ssid.contains(CirrentService.sharedService.getSoftAPSSID()) == true) {
                wifiManager.removeNetwork(i.networkId);
                wifiManager.saveConfiguration();
            }
        }
    }

    /**
     * Check Location Service is enabled
     * @return
     */
    private boolean isLocationEnabled() {
        return APIService.sharedService().isLocationEnabled();
    }

    /**
     * Check the user permit location service
     * @return
     */
    private boolean isLocationPermitted() {
        return APIService.sharedService().isLocationPermitted();
    }

    /**
     * Generate UUID
     * @return
     */
    private static String generateUUID() {
        String pattern = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx";
        Calendar c = Calendar.getInstance();
        double secs = c.get(Calendar.SECOND);

        String uuid = new String();

        for (char ch : pattern.toCharArray()) {
            Random rand = new Random();
            int r = (((int)secs + rand.nextInt() * 16) % 16) | 0;
            secs = Math.floor(secs / 16);
            if (ch == 'x') {
                uuid += String.format("%X", r);
            }
            else if (ch == 'y') {
                int val = r & 0x3 | 0x8;
                uuid += String.format("%X", val);
            }
            else {
                uuid += String.format("%c", ch);
            }
        }

        return uuid;
    }


    private List<ScanResult> scanList;
    /**
     * Returns the SSID of the network to which the phone is currently connected
     * <p>This method can be used if you wish to indicate to which network the phone is currently connected.
     * This can be useful to show the user when the phone is on the SoftAP network.</p>
     * @return SSID
     */
    public String getCurrentSSID() {

        if (mContext == null) {
            return null;
        }

        String ssid = null;
        ConnectivityManager connManager = (ConnectivityManager) mContext.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo networkInfo = connManager.getNetworkInfo(ConnectivityManager.TYPE_WIFI);
        if (networkInfo.isConnected()) {
            final WifiManager wifiManager = (WifiManager) mContext.getSystemService(Context.WIFI_SERVICE);

            wifiManager.startScan();
            scanList = wifiManager.getScanResults();
            String logStr = "Scan=";
            for (ScanResult res : scanList) {
                if (res.SSID.startsWith("\"") && res.SSID.endsWith("\"")){
                    res.SSID = res.SSID.substring(1, res.SSID.length()-1);
                }
                if (res.BSSID.startsWith("\"") && res.BSSID.endsWith("\"")){
                    res.BSSID = res.BSSID.substring(1, res.BSSID.length()-1);
                }
                logStr += String.format("ssid=%s,bssid=%s;", res.SSID, res.BSSID);
            }
            LogService.sharedService().log(LogService.Event.WIFI_SCAN, logStr);

            final WifiInfo connectionInfo = wifiManager.getConnectionInfo();

            if (connectionInfo != null && !TextUtils.isEmpty(connectionInfo.getSSID())) {
                ssid = connectionInfo.getSSID();
                if (ssid.startsWith("\"") && ssid.endsWith("\"")){
                    ssid = ssid.substring(1, ssid.length()-1);
                }
            }
            else {
                LogService.sharedService().log(LogService.Event.WIFI_SCAN_ERROR, "Error=Couldn't get connection info.");
            }
        }
        else {
            LogService.sharedService().log(LogService.Event.WIFI_SCAN_ERROR, "Error=Network is offline.");
        }

        return ssid;
    }

    /**
     * Returns the BSSID of the network to which the phone is currently connected
     * @return
     */
    private String getCurrentBSSID() {

        if (mContext == null) {
            return null;
        }

        String ssid = null;
        ConnectivityManager connManager = (ConnectivityManager) mContext.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo networkInfo = connManager.getNetworkInfo(ConnectivityManager.TYPE_WIFI);
        if (networkInfo.isConnected()) {
            final WifiManager wifiManager = (WifiManager) mContext.getSystemService(Context.WIFI_SERVICE);
            final WifiInfo connectionInfo = wifiManager.getConnectionInfo();
            if (connectionInfo != null && !TextUtils.isEmpty(connectionInfo.getSSID())) {
                ssid = connectionInfo.getBSSID();
            }
        }

        return ssid;
    }

    private String ownerID = null;
    /**
     * Sets the owner id, which is used by the Cirrent cloud to match the location of the owner to the location of the devices,
     * when looking for nearby devices. Can be the user's login, or any unique string.  This string only needs to be unique while
     * the app is running (from the time the user's location is uploaded to the time at which nearby devices are identified).
     * If no identifier is passed in, this method will generate its own unique identifier.
     * @param identifier
     * @return returns the owner identifier.
     */

    public String setOwnerIdentifier(String identifier) {
        if (mContext == null || mPrefs == null || mEditor == null) {
            return null;
        }

        if (identifier == null || identifier.length() == 0) {
            String uuid = mPrefs.getString(Constants.UUID_KEY, null);
            if (uuid == null || uuid.length() == 0) {
                TelephonyManager tManager = (TelephonyManager) mContext.getSystemService(Context.TELEPHONY_SERVICE);
                uuid = tManager.getDeviceId();
                if (uuid == null || uuid.length() == 0) {
                    uuid = generateUUID();
                }
                mEditor.putString(Constants.UUID_KEY, uuid);
                mEditor.commit();
            }
            ownerID = uuid;
            return uuid;
        }
        else {
            mEditor.putString(Constants.UUID_KEY, identifier);
            mEditor.commit();
            ownerID = identifier;
            return identifier;
        }
    }

    /**
     * Init Model
     */
    private void initModel() {
        model = new Model();
        model.ssid = getCurrentSSID();
        model.bssid = getCurrentBSSID();
    }

    /**
     * Upload Environment to Cirrent Cloud
     * @param searchToken
     * @param handler
     */
    private void uploadEnvironment(String searchToken, final CompletionHandler handler) {
        String appID = setOwnerIdentifier(null);

        APIService.sharedService().uploadEnvironment(searchToken, appID, model, scanList, new JsonHttpResponseHandler() {
            @Override
            public void onSuccess(int statusCode, Header[] headers, JSONObject response) {
                handler.completion(CirrentType.RESPONSE.SUCCESS);
            }

            @Override
            public void onFailure(int statusCode, Header[] headers, Throwable throwable, JSONObject errorResponse) {
                if (statusCode == 0) {
                    LogService.sharedService().log(LogService.Event.CLOUD_CONNECTION_ERROR, "");
                    handler.completion(CirrentType.RESPONSE.FAILED_NO_RESPONSE);
                }
                else if (statusCode == 401) {
                    LogService.sharedService().debug("Upload Environment Failed - INVALID_TOKEN");
                    handler.completion(CirrentType.RESPONSE.FAILED_INVALID_TOKEN);
                }
                else {
                    String logStr = String.format("Upload Environment Failed - %d", statusCode);
                    LogService.sharedService().debug(logStr);
                    handler.completion(CirrentType.RESPONSE.FAILED_INVALID_STATUS);
                }
            }
        });
    }

    /**
     *  Uploads location of mobile app and finds nearby devices.
     *<p>This function is the first method to be called during the on-boarding process. It will find nearby discoverable devices in the Cirrent cloud. It will first upload the location of the phone, and then look for devices of the correct type, that are nearby, and that have not been claimed. It will return a list of nearby devices.
     *<p>Results:
     *<p>SUCCESS - at least one nearby device was found from the Cirrent cloud - the list of nearby devices is returned.  If more than one, you can present the list to the user and have them select the one(s) they want to onboard.
     *<p>FAILED_NETWORK_OFFLINE - a nearby device could not be found because the phone is offline - prompt the user to connect their phone to the internet and try again.
     *<p>FAILED_LOCATION_DISABLED - a nearby device could not be found because the phone is on cellular, and the location is not available - prompt the user to turn on location services or connect to Wi-Fi and try again.
     *<p>FAILED_UPLOAD_ENVIRONMENT - a nearby device could not be found because the SDK was unable to upload the environment to the Cirrent cloud (this is likely to be a temporary problem, so retry)
     *<p>FAILED_INVALID_TOKEN - a nearby device could not be found because the SDK was using an invalid token.  Recheck your cloud's API key and secret to ensure they match what is configured in the Cirrent cloud for your account and confirm that the SDK is being given the correct token, with the correct scope (SEARCH) for this call.
     *<p>FAILED_NO_DEVICE - no nearby devices were found. This is most likely due to the device not being in range of a ZipKey network, or not being turned on recently. Go to SoftAP or other local onboarding instead.
     *<p>FAILED_NO_RESPONSE - no response from the Cirrent cloud. This is most likely due to a network connectivity problem. Try moving to a better network.
     *<p>FAILED_INVALID_STATUS - unexpected response from the Cirrent cloud.
     *
     * @param tokenHandler The token handler being used to authenticate this request
     * @param handler   The handler that is called when the method completes.
     */

    public void findDevice(TokenHandler tokenHandler, final CompletionHandler handler) {
        tokenHandler.getToken(TokenHandler.TOKEN_TYPE.SEARCH, null, new TokenHandler.GetTokenCompletionHandler() {
            @Override
            public void getTokenCompleted(final String searchToken) {
                if (searchToken == null) {
                    LogService.sharedService().debug("Find Devices Failed: Error=Search Token is nil");
                    handler.findDeviceCompletion(CirrentType.FIND_DEVICE_RESULT.FAILED_INVALID_TOKEN, null);
                    return;
                }

                boolean networkConnected = isNetworkConnected();
                boolean isOnCelluarNetwork = isOnCellularNetwork();
                if (networkConnected == false && isOnCelluarNetwork == false) {
                    handler.findDeviceCompletion(CirrentType.FIND_DEVICE_RESULT.FAILED_NETWORK_OFFLINE, null);
                    return;
                }

                boolean locationEnabled = isLocationEnabled();
                if (locationEnabled == false) {
                    LogService.sharedService().log(LogService.Event.LOCATION_ERROR, "Error=Location Service is disabled");
                    handler.findDeviceCompletion(CirrentType.FIND_DEVICE_RESULT.FAILED_LOCATION_DISABLED, null);
                    return;
                }

                boolean locationPermitted = isLocationPermitted();
                if (locationPermitted == false) {
                    LogService.sharedService().log(LogService.Event.LOCATION_ERROR, "Error=User didn't permit Location Service");
                    handler.findDeviceCompletion(CirrentType.FIND_DEVICE_RESULT.FAILED_LOCATION_NOT_PERMITTED, null);
                    return;
                }

                setOwnerIdentifier(null);
                initModel();

                if ((model == null || model.ssid == null || model.bssid == null) && isOnCellularNetwork() == false) {
                    handler.findDeviceCompletion(CirrentType.FIND_DEVICE_RESULT.FAILED_NETWORK_OFFLINE, null);
                    return;
                }

                if (isLocationEnabled() == false) {
                    LogService.sharedService().log(LogService.Event.LOCATION_ERROR, "Error=Location Service is Disabled.");
                    handler.findDeviceCompletion(CirrentType.FIND_DEVICE_RESULT.FAILED_LOCATION_DISABLED, null);
                    return;
                }

                if (isLocationPermitted() == false) {
                    LogService.sharedService().log(LogService.Event.LOCATION_ERROR, "Error=Location Service is not Permitted.");
                    handler.findDeviceCompletion(CirrentType.FIND_DEVICE_RESULT.FAILED_LOCATION_DISABLED, null);
                    return;
                }

                uploadEnvironment(searchToken, new CompletionHandler() {
                    @Override
                    public void completion(CirrentType.RESPONSE response) {
                        if (response != CirrentType.RESPONSE.SUCCESS) {
                            LogService.sharedService().debug("Find Devices Failed - UPLOAD_ENVIRONMENT_FAILED - TRYING AGAIN");
                            handler.findDeviceCompletion(CirrentType.FIND_DEVICE_RESULT.FAILED_UPLOAD_ENVIRONMENT, null);
                        }
                        else {
                            findNearByDevices(searchToken, new CompletionHandler() {
                                @Override
                                public void findDeviceCompletion(CirrentType.FIND_DEVICE_RESULT result, ArrayList<Device> devices) {
                                    if (result != CirrentType.FIND_DEVICE_RESULT.SUCCESS) {
                                        handler.findDeviceCompletion(result, null);
                                    }
                                    else {
                                        String logStr = "";
                                        for (Device device : devices) {
                                            logStr += "id=" + device.deviceId + ";";
                                        }
                                        LogService.sharedService().log(LogService.Event.DEVICES_RECEIVED, logStr);
                                        handler.findDeviceCompletion(result, devices);
                                    }
                                }
                            });
                        }
                    }
                });
            }
        });
    }

    /**
     * If the phone did not find any device in the Cirrent cloud, then go with SoftAP way automatically
     * @param handler
     */
    private void goWithSoftAP(CompletionHandler handler) {
        CirrentService.sharedService().connectToSoftAPNetwork(new CompletionHandler(){
            @Override
            public void completion(CirrentType.RESPONSE response) {
                if (response == CirrentType.RESPONSE.SUCCESS) {
                    CirrentService.sharedService().processSoftAP(new CompletionHandler(){
                        @Override
                        public void softAPCompletion(CirrentType.SOFTAP_RESPONSE response) {
                            switch (response) {
                                case SUCCESS_WITH_SOFTAP:

                                    break;
                                case FAILED_NOT_GET_SOFTAP_IP:
                                case FAILED_NOT_SOFTAP_SSID:
                                case FAILED_SOFTAP_INVALID_STATUS:
                                case FAILED_SOFTAP_NO_RESPONSE:

                                    break;
                            }
                        }
                    });
                }
                else {

                }
            }
        });
    }

    private int maxRetryCount = 6;
    private Runnable findDeviceRunnable;
    private Handler findDeviceHandler;

    /**
     * Find nearby devices
     * @param searchToken
     * @param handler
     */
    private void findNearByDevices(final String searchToken, final CompletionHandler handler) {
        findDeviceHandler = new Handler();
        findDeviceRunnable = new Runnable() {
            @Override
            public void run() {
                getDevicesInRange(searchToken, new CompletionHandler() {

                    @Override
                    public void findDeviceCompletion(CirrentType.FIND_DEVICE_RESULT result, ArrayList<Device> devices) {
                        if (result != CirrentType.FIND_DEVICE_RESULT.SUCCESS) {
                            if (maxRetryCount > 0) {
                                maxRetryCount -= 1;
                                LogService.sharedService().debug("Get Device In Range Failed - " + maxRetryCount);
                                findDeviceHandler.postDelayed(findDeviceRunnable, Constants.FIND_DEVICE_DELAY);
                            }
                            else {
                                maxRetryCount = 6;
                                findDeviceHandler.removeCallbacksAndMessages(null);
                                handler.findDeviceCompletion(result, null);
                            }
                        }
                        else {
                            findDeviceHandler.removeCallbacksAndMessages(null);
                            model.setDevices(devices);
                            handler.findDeviceCompletion(CirrentType.FIND_DEVICE_RESULT.SUCCESS, devices);
                        }
                    }
                });
            }
        };
        findDeviceHandler.post(findDeviceRunnable);
    }

    /**
     * Get nearby devices
     * @param searchToken
     * @param handler
     */
    private void getDevicesInRange(final String searchToken, final CompletionHandler handler) {
        String appID = setOwnerIdentifier(null);
        APIService.sharedService().getDevicesInRange(searchToken, appID, new JsonHttpResponseHandler() {
            @Override
            public void onSuccess(int statusCode, Header[] headers, JSONObject response) {
                JSONArray array;
                try {
                    array = response.getJSONArray("devices");
                }
                catch (JSONException e) {
                    LogService.sharedService().debug("Get Devices In Range Failed - " + e.toString());
                    handler.findDeviceCompletion(CirrentType.FIND_DEVICE_RESULT.FAILED_PARSE_JSON, null);
                    return;
                }

                if (array == null || array.length() == 0) {
                    handler.findDeviceCompletion(CirrentType.FIND_DEVICE_RESULT.FAILED_NO_DEVICE, null);
                    return;
                }

                ArrayList<Device> deviceArray = new ArrayList<Device>();
                String logString = "";

                for (int i = 0; i < array.length(); i++) {
                    try {
                        JSONObject object = array.getJSONObject(i);
                        Device dev = getDeviceFromJsonObject(object);
                        deviceArray.add(dev);
                        logString += "id=" + dev.deviceId + ";";
                    }
                    catch (JSONException e) {
                        LogService.sharedService().debug("Get Devices In Range Failed - " + e.toString());
                        handler.findDeviceCompletion(CirrentType.FIND_DEVICE_RESULT.FAILED_PARSE_JSON, null);
                        return;
                    }
                }

                LogService.sharedService().log(LogService.Event.DEVICES_RECEIVED, logString);
                LogService.sharedService().putLog(searchToken);

                handler.findDeviceCompletion(CirrentType.FIND_DEVICE_RESULT.SUCCESS, deviceArray);
            }

            @Override
            public void onFailure(int statusCode, Header[] headers, Throwable throwable, JSONObject errorResponse) {
                if (statusCode == 0) {
                    LogService.sharedService().log(LogService.Event.CLOUD_CONNECTION_ERROR, "");
                    handler.findDeviceCompletion(CirrentType.FIND_DEVICE_RESULT.FAILED_NO_RESPONSE, null);
                }
                else if (statusCode == 401) {
                    LogService.sharedService().debug("Get Devices In Range Failed - INVALID_TOKEN");
                    handler.findDeviceCompletion(CirrentType.FIND_DEVICE_RESULT.FAILED_INVALID_TOKEN, null);
                }
                else {
                    String logStr = String.format("Get Devices In Range Failed - INVALID_STATUS:%d", statusCode);
                    LogService.sharedService().debug(logStr);
                    handler.findDeviceCompletion(CirrentType.FIND_DEVICE_RESULT.FAILED_INVALID_STATUS, null);
                }
            }
        });
    }

    /**
     * Get Device Object from Json
     * @param object
     * @return
     */
    private Device getDeviceFromJsonObject(JSONObject object) {
        Device dev = new Device();

        try {
            try {
                dev.deviceId = object.getString("deviceId");
            }catch (JSONException e){
                e.printStackTrace();
                dev.deviceId = "";
            }
            try {
                dev.idDeviceId = object.getInt("idDeviceId");
            }catch (JSONException e){
                e.printStackTrace();
                dev.idDeviceId = 0;
            }
            try {
                dev.idDeviceType = object.getInt("idDeviceType");
            }catch (JSONException e){
                e.printStackTrace();
                dev.idDeviceType = 0;
            }
            try {
                dev.macAddress = object.getString("MACAddr");
            }catch (JSONException e){
                e.printStackTrace();
                dev.macAddress = "";
            }
            try {
                dev.imageURL = object.getString("imageURL");
            }catch (JSONException e){
                e.printStackTrace();
                dev.imageURL = "";
            }
            try {
                dev.uptime = object.getDouble("uptime");
            }catch (JSONException e){
                e.printStackTrace();
                dev.uptime = 0.0;
            }
            try {
                dev.identifyingActionEnabled = object.getBoolean("identifying_action_enabled");
            }catch (JSONException e){
                e.printStackTrace();
                dev.identifyingActionEnabled = false;
            }
            try {
                dev.identifyingActionDescription = object.getString("identifying_action_description");
            }catch (JSONException e){
                e.printStackTrace();
            }
            try {
                dev.userActionEnabled = object.getBoolean("user_action_enabled");
            }catch (JSONException e){
                e.printStackTrace();
                dev.userActionEnabled = false;
            }
            try {
                dev.userActionDescription = object.getString("user_action_description");
            }catch (JSONException e){
                e.printStackTrace();
            }
            try {
                dev.providerAttribution = object.getString("provider_attibution");
            }catch (JSONException e){
                e.printStackTrace();
            }
            try {
                dev.providerAttributionLogo = object.getString("provider_attribution_logo");
            }catch (JSONException e){}
            try {
                dev.providerAttributionLearnMoreURL = object.getString("provider_attribution_learn_mode");
            }catch (JSONException e){}

            if (mPrefs != null) {
                dev.friendlyName = mPrefs.getString(dev.deviceId, dev.deviceId);
            }
/////////////////////////////Should be Changed for Friendly Name////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            JSONArray array = object.getJSONArray("provider_known_network");
            if (array != null && array.length() > 0) {
                dev.provider_known_network = new ProviderKnownNetwork();
                for (int i = 0; i < array.length(); i++) {
                    JSONObject obj = array.getJSONObject(i);
                    try {
                        dev.provider_known_network.ssid = obj.getString("ssid");
                    }catch (JSONException e){e.printStackTrace();}
                    try {
                        dev.provider_known_network.providerName = obj.getString("provider_name");
                    }catch (JSONException e){e.printStackTrace();}
                    try {
                        dev.provider_known_network.providerUUID = obj.getString("provider_uuid");
                    }catch (JSONException e){e.printStackTrace();}
                    try {
                        dev.provider_known_network.providerLogo = obj.getString("provider_logo");
                    }catch (JSONException e){e.printStackTrace();}
                    break;
                }
            }

        } catch (JSONException e) {
            e.printStackTrace();
        }

        return dev;
    }

    /**
     * Save Friendly Name for the device
     * @param device
     * @param newName
     */
    public void setFriendlyNameForDevice(Device device, String newName) {
        if (mEditor != null && device != null && newName != null && newName.length() > 0) {
            mEditor.putString(device.deviceId, newName);
            mEditor.commit();
            device.friendlyName = newName;
        }
    }

    /**
     * This is an optional method that requests that the device perform some identifying action, such as flashing a light or playing a sound.
     *<p>The request is sent to the Cirrent cloud, and the device will perform the action when it checks in with the cloud to see if there are any actions to be performed.
     *<p>Results:
     *<p>SUCCESS - request was sent to the Cirrent cloud.
     *<p>FAILED_NO_RESPONSE - no response from the Cirrent cloud. This is most likely due to a network connectivity problem. Try connecting the phone to a better network and try again.
     *<p>FAILED_INVALID_STATUS - unexpected response from the Cirrent cloud.
     *<p>FAILED_INVALID_TOKEN - the token being presented is invalid, or does not have the right scope for the operation being performed.  identifyYourself requires a SEARCH token.
     *
     * @param tokenHandler the token handler to use to authenticate this request
     * @param deviceID the deviceId for the targetted device
     * @param handler   the handler that is called when the method completes
     */

    public void identifyYourself(TokenHandler tokenHandler, final String deviceID, final CompletionHandler handler) {
        if (model == null || model.devices == null || model.devices.size() == 0) {
            LogService.sharedService().debug(deviceID + "  - Identify Yourself Failed - NO_DEVICE_FOUND");
            handler.completion(CirrentType.RESPONSE.FAILED_NO_RESPONSE);
            return;
        }

        boolean bExist = false;
        for (int i = 0; i < model.devices.size(); i++) {
            Device device = model.devices.get(i);
            if (device.deviceId.compareTo(deviceID) == 0) {
                bExist = true;
                break;
            }
        }

        if (bExist == false) {
            LogService.sharedService().debug(deviceID + " - Identify Yourself Failed - This Device is not nearby.");
            handler.completion(CirrentType.RESPONSE.FAILED_NO_RESPONSE);
            return;
        }

        tokenHandler.getToken(TokenHandler.TOKEN_TYPE.SEARCH, deviceID, new TokenHandler.GetTokenCompletionHandler() {
            @Override
            public void getTokenCompleted(final String searchToken) {
                if (searchToken == null) {
                    LogService.sharedService().debug("Identify Yourself Failed: id=" + deviceID + ",Error=Search Token is nil");
                    handler.completion(CirrentType.RESPONSE.FAILED_INVALID_TOKEN);
                }
                else {
                    APIService.sharedService().identifyYourself(searchToken, deviceID, new JsonHttpResponseHandler() {
                        @Override
                        public void onSuccess(int statusCode, Header[] headers, JSONObject response) {
                            LogService.sharedService().debug(deviceID + " - Identify Yourself Success");
                            handler.completion(CirrentType.RESPONSE.SUCCESS);
                        }

                        @Override
                        public void onFailure(int statusCode, Header[] headers, Throwable throwable, JSONObject errorResponse) {
                            if (statusCode == 0) {
                                LogService.sharedService().log(LogService.Event.CLOUD_CONNECTION_ERROR, "");
                                handler.completion(CirrentType.RESPONSE.FAILED_NO_RESPONSE);
                            }
                            else if (statusCode == 401) {
                                handler.completion(CirrentType.RESPONSE.FAILED_INVALID_TOKEN);
                            }
                            else {
                                handler.completion(CirrentType.RESPONSE.FAILED_INVALID_STATUS);
                            }
                        }
                    });
                }
            }
        });
    }

    /**
     * Deletes a network from a device
     *<p>Results:
     *<p>SUCCESS-the network was successfully deleted
     *<p>FAILED_INVALID_TOKEN - the token being presented is invalid, or does not have the right scope for the operation being performed.  The resetDevice method requires a MANAGE token that includes this device.
     *<p>FAILED_NO_RESPONSE - no response from the Cirrent cloud. This is most likely due to a network connectivity problem. Try connecting the phone to a better network and try again.
     *<p>FAILED_INVALID_STATUS - unexpected response from the Cirrent cloud.
     *
     * @param tokenHandler   The token handler to use to authenticate this request
     * @param deviceID  The device id for the device we are targetting
     * @param network   The network we want to delete
     * @param handler   The handler that is called when the method completes
     */

    public void deleteNetwork(TokenHandler tokenHandler, final String deviceID, final Network network, final CompletionHandler handler) {
        tokenHandler.getToken(TokenHandler.TOKEN_TYPE.MANAGE, deviceID, new TokenHandler.GetTokenCompletionHandler() {
            @Override
            public void getTokenCompleted(String manageToken) {
                if (manageToken == null) {
                    LogService.sharedService().log(LogService.Event.TOKEN_ERROR, "Delete Network Failed: ssid=" + network.ssid + ",Error=ManageToken is nil");
                    handler.completion(CirrentType.RESPONSE.FAILED_INVALID_TOKEN);
                }
                else {
                    APIService.sharedService().deletePrivateNetwork(manageToken, deviceID, network, new JsonHttpResponseHandler() {
                        @Override
                        public void onSuccess(int statusCode, Header[] headers, JSONObject response) {
                            LogService.sharedService().debug("DELETE NETWORK SUCCESS");
                            handler.completion(CirrentType.RESPONSE.SUCCESS);
                        }

                        @Override
                        public void onFailure(int statusCode, Header[] headers, Throwable throwable, JSONObject errorResponse) {
                            if (statusCode == 0) {
                                LogService.sharedService().debug("DELETE NETWORK FAILED - CLOUD_CONNECTION_ERROR");
                                handler.completion(CirrentType.RESPONSE.FAILED_NO_RESPONSE);
                            }
                            else if (statusCode == 401) {
                                LogService.sharedService().debug("DELETE NETWORK FAILED - INVALID_TOKEN");
                                handler.completion(CirrentType.RESPONSE.FAILED_INVALID_TOKEN);
                            }
                            else {
                                LogService.sharedService().debug("DELETE NETWORK FAILED - INVALID_STATUS");
                                handler.completion(CirrentType.RESPONSE.FAILED_INVALID_STATUS);
                            }
                        }
                    });
                }
            }
        });
    }


    /**
     *This method adds a new network to the list of networks provisioned in the device.
     *<p> Note that the device may not join this network immediately. It will get the details about this network when it calls the Cirrent cloud,
     * but will only join the network if this network is higher priority than the network it is currently on, and it loses connectivity
     * to the currently-connected network.</p>
     *<p>Results:
     *<p>SUCCESS-the network was successfully sent to the Cirrent cloud (note the device may download it later)
     *<p>FAILED_INVALID_TOKEN - the token being presented is invalid, or does not have the right scope for the operation being performed.  The bindDevice method requires a BIND token for this device.
     *<p>FAILED_NO_RESPONSE - no response from the Cirrent cloud. This is most likely due to a network connectivity problem. Try connecting the phone to a better network and try again.
     *<p>FAILED_INVALID_STATUS - unexpected response from the Cirrent cloud.
     *
     * @param tokenHandler   The token handler used to authenticate this request
     * @param deviceID  The unique device id for the device being targeted
     * @param network   The SSID and related information for the network being added
     * @param preSharedKey  The preSharedKey for the network being added
     * @param handler   The handler that is called when the method completes
     */

    public void addNetwork(TokenHandler tokenHandler, final String deviceID, final Network network, final String preSharedKey, final CompletionHandler handler) {
        tokenHandler.getToken(TokenHandler.TOKEN_TYPE.MANAGE, deviceID, new TokenHandler.GetTokenCompletionHandler() {
            @Override
            public void getTokenCompleted(final String manageToken) {
                APIService.sharedService().deviceJoinNetwork(manageToken, deviceID, network, preSharedKey, new JsonHttpResponseHandler(){
                    @Override
                    public void onSuccess(int statusCode, Header[] headers, JSONArray response) {
                        LogService.sharedService().debug("ADD NETWORK SUCCESS");
                        handler.completion(CirrentType.RESPONSE.SUCCESS);
                    }

                    @Override
                    public void onFailure(int statusCode, Header[] headers, Throwable throwable, JSONObject errorResponse) {
                        if (statusCode == 0) {
                            LogService.sharedService().debug("ADD NETWORK FAILED - CLOUD_CONNECTION_ERROR");
                            handler.completion(CirrentType.RESPONSE.FAILED_NO_RESPONSE);
                        }
                        else if (statusCode == 401) {
                            LogService.sharedService().debug("ADD NETWORK FAILED - INVALID_TOKEN");
                            handler.completion(CirrentType.RESPONSE.FAILED_INVALID_TOKEN);
                        }
                        else {
                            LogService.sharedService().debug("ADD NETWORK FAILED - INVALID_STATUS");
                            handler.completion(CirrentType.RESPONSE.FAILED_INVALID_STATUS);
                        }
                    }
                });
            }
        });
    }


    /**
     * Finds the networks to which the device can be connected.
     *<p>This method will ask the Cirrent cloud for the most recent device status, which will return the Wi-Fi scan list from the device, and then create a list of the possible networks to which the device can be connected.
     *<p>Results:
     *<p>SUCCESS-successfully gets a list of the possible networks to which the device can be connected
     *<p>FAILED_INVALID_TOKEN - the token being presented is invalid, or does not have the right scope for the operation being performed.  The resetDevice method requires a MANAGE token that includes this device.
     *<p>FAILED_NO_RESPONSE - no response from the Cirrent cloud. This is most likely due to a network connectivity problem. Try connecting the phone to a better network and try again.
     *<p>FAILED_INVALID_STATUS - unexpected response from the Cirrent cloud.
     *
     * @param tokenHandler   The token handler used to authenticate this request
     * @param deviceID  The unique device id for the device being targeted
     * @param handler   The handler that is called when the method completes
     */

    public void getCandidateNetworks(TokenHandler tokenHandler, final String deviceID, final CompletionHandler handler) {
        tokenHandler.getToken(TokenHandler.TOKEN_TYPE.MANAGE, deviceID, new TokenHandler.GetTokenCompletionHandler() {
            @Override
            public void getTokenCompleted(String manageToken) {
                if (manageToken == null) {
                    LogService.sharedService().log(LogService.Event.TOKEN_ERROR, "Get Candidate Networks Failed: id=" + deviceID + ",Error=ManageToken is nil");
                    handler.completion(CirrentType.RESPONSE.FAILED_INVALID_TOKEN);
                }
                else {
                    APIService.sharedService().getDeviceStatus(manageToken, deviceID, new JsonHttpResponseHandler() {
                        @Override
                        public void onSuccess(int statusCode, Header[] headers, JSONObject response) {
                            try {
                                JSONArray wifi_scans = response.getJSONArray("wifi_scans");
                                ArrayList<KnownNetwork> networks = new ArrayList<KnownNetwork>();
                                for (int i = 0; i < wifi_scans.length(); i++) {
                                    try {
                                        JSONObject netData = wifi_scans.getJSONObject(i);
                                        KnownNetwork network = new KnownNetwork();
                                        try {
                                            network.bssid = netData.getString("bssid");
                                        }catch (JSONException e) {
                                            e.printStackTrace();
                                            network.bssid = "";
                                        }
                                        try {
                                            network.ssid = netData.getString("ssid");
                                        }
                                        catch (JSONException e) {
                                            e.printStackTrace();
                                            network.ssid = "";
                                        }
                                        try {
                                            network.security = netData.getString("flags");
                                        }
                                        catch (JSONException e) {
                                            e.printStackTrace();
                                            network.security = "";
                                        }
                                        networks.add(network);
                                    }
                                    catch (JSONException e) {
                                        e.printStackTrace();
                                    }
                                }
                                handler.getNetworkCompletion(CirrentType.RESPONSE.SUCCESS, networks);
                            } catch (JSONException e) {
                                e.printStackTrace();
                                handler.getNetworkCompletion(CirrentType.RESPONSE.FAILED_NO_RESPONSE, null);
                            }
                        }

                        @Override
                        public void onFailure(int statusCode, Header[] headers, Throwable throwable, JSONObject errorResponse) {
                            if (statusCode == 0) {
                                LogService.sharedService().log(LogService.Event.CLOUD_CONNECTION_ERROR, "");
                                handler.getNetworkCompletion(CirrentType.RESPONSE.FAILED_NO_RESPONSE, null);
                            }
                            else if (statusCode == 401) {
                                LogService.sharedService().log(LogService.Event.STATUS_ERROR, "Error=Invalid_Token");
                                handler.getNetworkCompletion(CirrentType.RESPONSE.FAILED_INVALID_TOKEN, null);
                            }
                            else {
                                LogService.sharedService().log(LogService.Event.STATUS_ERROR, "Error=Invalid_Status");
                                handler.getNetworkCompletion(CirrentType.RESPONSE.FAILED_INVALID_STATUS, null);
                            }
                        }
                    });
                }
            }
        });
    }

    /**
     * Gets the list of private networks that are currently configured in the device.
     *<p>This method will ask the Cirrent cloud for the most recent device status, and returns the known network list.
     *<p>Results:
     *<p>SUCCESS-successfully gets a list of the possible networks to which the device can be connected
     *<p>FAILED_INVALID_TOKEN - the token being presented is invalid, or does not have the right scope for the operation being performed.  The resetDevice method requires a MANAGE token that includes this device.
     *<p>FAILED_NO_RESPONSE - no response from the Cirrent cloud. This is most likely due to a network connectivity problem. Try connecting the phone to a better network and try again.
     *<p>FAILED_INVALID_STATUS - unexpected response from the Cirrent cloud.
     *
     * @param tokenHandler   The token handler used to authenticate this request
     * @param deviceID  The unique device id for the device being targeted
     * @param handler   The handler that is called when the method completes
     */

    public void getKnownNetworks(TokenHandler tokenHandler, final String deviceID, final CompletionHandler handler) {
        tokenHandler.getToken(TokenHandler.TOKEN_TYPE.MANAGE, deviceID, new TokenHandler.GetTokenCompletionHandler() {
            @Override
            public void getTokenCompleted(final String manageToken) {
                if (manageToken == null) {
                    LogService.sharedService().log(LogService.Event.TOKEN_ERROR, "Get Known Networks Failed: id=" + deviceID + ",Error=INVALID_TOKEN");
                    handler.getNetworkCompletion(CirrentType.RESPONSE.FAILED_INVALID_TOKEN, null);
                }
                else {
                    APIService.sharedService().getDeviceStatus(manageToken, deviceID, new JsonHttpResponseHandler(){
                        @Override
                        public void onSuccess(int statusCode, Header[] headers, JSONObject response) {
                            try {
                                JSONArray wifi_scans = response.getJSONArray("known_networks");
                                ArrayList<KnownNetwork> networks = new ArrayList<KnownNetwork>();
                                for (int i = 0; i < wifi_scans.length(); i++) {
                                    try {
                                        JSONObject netData = wifi_scans.getJSONObject(i);
                                        KnownNetwork network = new KnownNetwork();
                                        try {
                                            network.bssid = netData.getString("bssid");
                                        }catch (JSONException e) {
                                            e.printStackTrace();
                                            network.bssid = "";
                                        }
                                        try {
                                            network.ssid = netData.getString("ssid");
                                        }catch (JSONException e) {
                                            e.printStackTrace();
                                            network.ssid = "";
                                        }
                                        try {
                                            network.priority = netData.getInt("priority");
                                        }catch (JSONException e) {
                                            e.printStackTrace();
                                            network.priority = 0;
                                        }
                                        try {
                                            network.credentialID = netData.getString("credential_id");
                                        }catch (JSONException e) {
                                            e.printStackTrace();
                                            network.credentialID = "";
                                        }
                                        try {
                                            network.security = netData.getString("security");
                                        }catch (JSONException e) {
                                            e.printStackTrace();
                                            network.security = "";
                                        }
                                        try {
                                            network.source = netData.getString("source");
                                        }catch (JSONException e) {
                                            e.printStackTrace();
                                            network.source = "";
                                        }
                                        try {
                                            network.roamingID = netData.getString("roaming_id");
                                        }catch (JSONException e) {
                                            e.printStackTrace();
                                            network.roamingID = "";
                                        }
                                        try {
                                            network.status = netData.getString("status");
                                        }catch (JSONException e) {
                                            e.printStackTrace();
                                            network.status = "";
                                        }

                                        if (network.source.compareTo("NetworkConfig") != 0) {
                                            networks.add(network);
                                        }
                                    }
                                    catch (JSONException e) {
                                        e.printStackTrace();
                                    }
                                }
                                handler.getNetworkCompletion(CirrentType.RESPONSE.SUCCESS, networks);
                            } catch (JSONException e) {
                                e.printStackTrace();
                                handler.getNetworkCompletion(CirrentType.RESPONSE.FAILED_NO_RESPONSE, null);
                            }
                        }

                        @Override
                        public void onFailure(int statusCode, Header[] headers, Throwable throwable, JSONObject errorResponse) {
                            if (statusCode == 0) {
                                LogService.sharedService().log(LogService.Event.CLOUD_CONNECTION_ERROR, "");
                                handler.getNetworkCompletion(CirrentType.RESPONSE.FAILED_NO_RESPONSE, null);
                            }
                            else if (statusCode == 401) {
                                LogService.sharedService().log(LogService.Event.STATUS_ERROR, "Error=Invalid_Token");
                                handler.getNetworkCompletion(CirrentType.RESPONSE.FAILED_INVALID_TOKEN, null);
                            }
                            else {
                                LogService.sharedService().log(LogService.Event.STATUS_ERROR, "Error=Invalid_Status");
                                handler.getNetworkCompletion(CirrentType.RESPONSE.FAILED_INVALID_STATUS, null);
                            }
                        }
                    });
                }
            }
        });
    }

    /**
     * Get Device Status
     * Gets more detailed status about the device (e.g. networks it can see).
     *<p>This method is called after the user has selected the device. It takes as input the device id for the selected device, and queries the Cirrent cloud for the most recent device status. The device status will include the Wi-Fi scan list from the device, which can be used to show the user a drop-down list of the networks the device can see.
     *<p>Results:
     *<p>SUCCESS - device status was received from the Cirrent cloud.
     *<p>FAILED_INVALID_TOKEN - the token being presented is invalid, or does not have the right scope for the operation being performed.  getDeviceStatus requires a MANAGE token that includes this device.
     *<p>FAILED_NO_RESPONSE - no response from the Cirrent cloud. This is most likely due to a network connectivity problem. Try connecting the phone to a better network and try again.
     *<p>FAILED_INVALID_STATUS - unexpected response from the Cirrent cloud.
     *
     * @param tokenHandler   The token handler used to authenticate this request
     * @param deviceID  The device id whose status is being requested
     * @param handler   The handler that is called when the method completes
     */

    public void getDeviceStatus(final TokenHandler tokenHandler, final String deviceID, final CompletionHandler handler) {
        tokenHandler.getToken(TokenHandler.TOKEN_TYPE.MANAGE, deviceID, new TokenHandler.GetTokenCompletionHandler() {
            @Override
            public void getTokenCompleted(final String manageToken) {
                if (manageToken == null) {
                    tokenHandler.getToken(TokenHandler.TOKEN_TYPE.ANY, deviceID, new TokenHandler.GetTokenCompletionHandler() {
                        @Override
                        public void getTokenCompleted(String token) {
                            LogService.sharedService().log(LogService.Event.TOKEN_ERROR, "Get Device Status Failed Error=INVALID_TOKEN");
                            LogService.sharedService().putLog(token);
                            handler.getStatusCompletion(CirrentType.RESPONSE.FAILED_INVALID_TOKEN, null);
                        }
                    });
                }
                else {
                    APIService.sharedService().getDeviceStatus(manageToken, deviceID, new JsonHttpResponseHandler() {
                        @Override
                        public void onSuccess(int statusCode, Header[] headers, JSONObject response) {
                            String logString = "json=" + response.toString();
                            LogService.sharedService().log(LogService.Event.STATUS, logString);
                            LogService.sharedService().putLog(manageToken);

                            model.GCN = true;

                            try {
                                JSONArray wifi_scans = response.getJSONArray("wifi_scans");
                                model.setNetworks(wifi_scans);

                                Device device = model.getDevice(deviceID);
                                if (device.provider_known_network != null) {
                                    model.providerNetwork = new ProviderKnownNetwork();
                                    model.providerNetwork.ssid = device.provider_known_network.ssid;
                                    model.providerNetwork.providerLogo = device.provider_known_network.providerLogo;
                                    model.providerNetwork.providerName = device.provider_known_network.providerName;
                                    model.providerNetwork.providerUUID = device.provider_known_network.providerUUID;
                                }
                            } catch (JSONException e) {
                                e.printStackTrace();
                                model.setNetworks(null);
                            }

                            handler.getStatusCompletion(CirrentType.RESPONSE.SUCCESS, response);
                        }

                        @Override
                        public void onFailure(int statusCode, Header[] headers, Throwable throwable, JSONObject errorResponse) {
                            if (statusCode == 0) {
                                LogService.sharedService().log(LogService.Event.CLOUD_CONNECTION_ERROR, "");
                                LogService.sharedService().putLog(manageToken);
                                handler.getStatusCompletion(CirrentType.RESPONSE.FAILED_NO_RESPONSE, null);
                            }
                            else if (statusCode == 401) {
                                LogService.sharedService().log(LogService.Event.STATUS_ERROR, "Error=INVALID_TOKEN");
                                LogService.sharedService().putLog(manageToken);
                                handler.getStatusCompletion(CirrentType.RESPONSE.FAILED_INVALID_TOKEN, null);
                            }
                            else {
                                LogService.sharedService().log(LogService.Event.STATUS_ERROR, "Error=INVALID_STATUS");
                                LogService.sharedService().putLog(manageToken);
                                handler.getStatusCompletion(CirrentType.RESPONSE.FAILED_INVALID_STATUS, null);
                            }
                        }
                    });
                }
            }
        });
    }

    private static Handler userActionPollHandler;
    private static Runnable userActionPollRunnable;
    private static long USER_ACTION_POLL_DELAY = 3000;

    /**
     * Optional method to wait for user to take some action on the device, such as pressing a button, to confirm they are on-boarding the correct device
     * <p>If the product requires user action, this method is called to poll to see if the user has taken the action on the device.
     * <p>Results:
     * <p>SUCCESS-user action was received
     * <p>FAILED_NO_RESPONSE-the mobile app timed out waiting for the user action to be performed
     *
     * @param tokenHandler   The token used to authenticate this request
     * @param handler   The handler that is called when the method completes
     */

    public void pollForUserAction(TokenHandler tokenHandler, final CompletionHandler handler) {
        if (model == null || model.devices == null || model.devices.size() == 0) {
            return;
        }

        tokenHandler.getToken(TokenHandler.TOKEN_TYPE.SEARCH, null, new TokenHandler.GetTokenCompletionHandler() {
            @Override
            public void getTokenCompleted(final String searchToken) {
                if (searchToken == null) {
                    return;
                }
                else {
                    userActionPollHandler = new Handler();
                    userActionPollRunnable = new Runnable() {
                        @Override
                        public void run() {
                            for (int i = 0; i < model.devices.size(); i++) {
                                final Device device = model.devices.get(i);
                                if (device.userActionEnabled == false) continue;

                                getUserActionPerformedStatus(searchToken, device, new CompletionHandler(){
                                    @Override
                                    public void pollUserActionCompletion(Device device, String userAction) {
                                        if (device != null && userAction != null) {
                                            device.confirmedOwnerShip = true;
                                            handler.pollUserActionCompletion(device, userAction);
                                        }
                                    }
                                });
                            }
                            userActionPollHandler.postDelayed(userActionPollRunnable, USER_ACTION_POLL_DELAY);
                        }
                    };

                    userActionPollHandler.post(userActionPollRunnable);
                }
            }
        });
    }

    /**
     * Checks to see if the user took some action on the device, such as pressing a button, to confirm they are on-boarding the correct device.
     * <p>If the product requires user action, the method pollForUserAction will call this method to check if the user completed the action. The method will then report back to pollForUserAction by passing in the device if the user did take action and null for the device if the user did not.
     * <p>Results:
     * <p>SUCCESS-the action from the user was successfully detected
     * @param searchToken   The token used to authenticate this request
     * @param device    The unique device id for the device being targeted
     * @param handler   The handler that is called when the method completes
     */
    private void getUserActionPerformedStatus(String searchToken, final Device device, final CompletionHandler handler) {
        APIService.sharedService().getUserActionPerformedStatus(searchToken, device.deviceId, new JsonHttpResponseHandler() {
            @Override
            public void onSuccess(int statusCode, Header[] headers, JSONObject response) {
                try {
                    int stCode = response.getInt("code");
                    String message = response.getString("message");
                    if (stCode == 200) {
                        LogService.sharedService().debug(device.deviceId + " " + message);
                        handler.completion(CirrentType.RESPONSE.SUCCESS);
                        handler.pollUserActionCompletion(device, message);
                    }
                    else {
                        LogService.sharedService().debug(device.deviceId + " " + message);
                        handler.pollUserActionCompletion(null, message);
                    }
                }catch (JSONException e) {
                    e.printStackTrace();
                    LogService.sharedService().debug(device.deviceId + " JSON Parse Error");
                    handler.pollUserActionCompletion(null, null);
                }
            }

            @Override
            public void onFailure(int statusCode, Header[] headers, Throwable throwable, JSONObject errorResponse) {
                if (statusCode == 0) {
                    LogService.sharedService().log(LogService.Event.CLOUD_CONNECTION_ERROR, "");
                    handler.pollUserActionCompletion(null, null);
                }
                else if (statusCode == 401) {
                    LogService.sharedService().debug(device.deviceId + " Get User Action Performed Status Failed - Invalid Token");
                }
                else {
                    LogService.sharedService().debug(device.deviceId + " Get User Action Performed Status Failed - Invalid Status");
                }
                handler.pollUserActionCompletion(null, null);
            }
        });
    }

    /**
     * Optional method to stop waiting for the user action to be reported by the device.
     * <p>This tells the SDK to cancel the timer controlling how long to poll for the user action. This might be necessary if the user selects a different device, for example.
     */
    public void stopPollForUserAction() {
        if (userActionPollHandler != null) {
            userActionPollHandler.removeCallbacksAndMessages(null);
        }
    }

    /**
     *This method binds the device, so it is considered 'claimed' by this user, and will no longer be discoverable by other users looking for nearby devices.
     * <p>Cirrent keeps track of whether a device is discoverable or not, but does not keep track of which user has bound the device. That is managed in the product cloud.
     *<p>Results:
     *<p>SUCCESS - the device state is now bound.
     *<p>FAILED_INVALID_TOKEN - the token being presented is invalid, or does not have the right scope for the operation being performed.  The bindDevice method requires a BIND token for this device.
     *<p>FAILED_NO_RESPONSE - no response from the Cirrent cloud. This is most likely due to a network connectivity problem. Try connecting the phone to a better network and try again.
     *<p>FAILED_INVALID_STATUS - unexpected response from the Cirrent cloud.
     *
     * @param tokenHandler   The token handler used to authenticate this request
     * @param deviceID  ID of the device that will be bound (no longer discoverable)
     * @param handler   The handler that is called when the method completes
     */

    public void bindDevice(TokenHandler tokenHandler, final String deviceID, final CompletionHandler handler) {
        if (model == null) {
            LogService.sharedService().debug("Bind Device Failed - Model is null");
            handler.completion(CirrentType.RESPONSE.FAILED_NO_RESPONSE);
            return;
        }

        tokenHandler.getToken(TokenHandler.TOKEN_TYPE.BIND, deviceID, new TokenHandler.GetTokenCompletionHandler() {
            @Override
            public void getTokenCompleted(String bindToken) {
                if (bindToken == null) {
                    LogService.sharedService().log(LogService.Event.TOKEN_ERROR, "Bind Device Failed: Error=BindToken is nil");
                    return;
                }
                APIService.sharedService().bindDevice(bindToken, new JsonHttpResponseHandler() {
                    @Override
                    public void onSuccess(int statusCode, Header[] headers, JSONObject response) {
                        LogService.sharedService().log(LogService.Event.DEVICE_BOUND, "id=" + deviceID);
                        model.selectedDevice = model.getDevice(deviceID);
                        handler.completion(CirrentType.RESPONSE.SUCCESS);
                    }

                    @Override
                    public void onFailure(int statusCode, Header[] headers, Throwable throwable, JSONObject errorResponse) {
                        if (statusCode == 0) {
                            LogService.sharedService().log(LogService.Event.CLOUD_CONNECTION_ERROR, "");
                            handler.completion(CirrentType.RESPONSE.FAILED_NO_RESPONSE);
                        }
                        else if (statusCode == 401) {
                            LogService.sharedService().debug("Bind Device Failed - INVALID_TOKEN");
                            handler.completion(CirrentType.RESPONSE.FAILED_INVALID_STATUS);
                        }
                        else {
                            LogService.sharedService().debug("Bind Device Failed - INVALID_STATUS");
                            handler.completion(CirrentType.RESPONSE.FAILED_INVALID_STATUS);
                        }
                    }
                });
            }
        });
    }

    /**
     * This method resets the device state in the Cirrent cloud, so it is no longer considered 'claimed' by this user, and will be discoverable by other users looking for nearby devices.
     *<p>The Cirrent cloud will also discard any status it has for this device (known networks, wi-fi scans etc.).
     *<p>Results:
     *<p>SUCCESS - the device state is now discoverable.
     *<p>FAILED_INVALID_TOKEN - the token being presented is invalid, or does not have the right scope for the operation being performed.  The resetDevice method requires a MANAGE token that includes this device.
     *<p>FAILED_NO_RESPONSE - no response from the Cirrent cloud. This is most likely due to a network connectivity problem. Try connecting the phone to a better network and try again.
     *<p>FAILED_INVALID_STATUS - unexpected response from the Cirrent cloud.
     *
     * @param tokenHandler   The token handler used to authenticate this request
     * @param deviceID  The identifier for the device being reset
     * @param handler   The handler that is called when the method completes
     */

    public void resetDevice(TokenHandler tokenHandler, final String deviceID, final CompletionHandler handler) {
        tokenHandler.getToken(TokenHandler.TOKEN_TYPE.MANAGE, deviceID, new TokenHandler.GetTokenCompletionHandler() {
            @Override
            public void getTokenCompleted(String manageToken) {
                if (manageToken == null) {
                    LogService.sharedService().log(LogService.Event.TOKEN_ERROR, "Reset Device Failed: id=" + deviceID + ",Error=ManageToken is nil");
                    handler.completion(CirrentType.RESPONSE.FAILED_INVALID_TOKEN);
                }
                else {
                    APIService.sharedService().resetDevice(manageToken, deviceID, new JsonHttpResponseHandler() {
                        @Override
                        public void onSuccess(int statusCode, Header[] headers, JSONObject response) {
                            LogService.sharedService().debug("Reset Device Success");
                            handler.completion(CirrentType.RESPONSE.SUCCESS);
                        }

                        @Override
                        public void onFailure(int statusCode, Header[] headers, Throwable throwable, JSONObject errorResponse) {
                            model.selectedDevice = null;
                            if (statusCode == 0) {
                                LogService.sharedService().log(LogService.Event.CLOUD_CONNECTION_ERROR, "");
                                handler.completion(CirrentType.RESPONSE.FAILED_NO_RESPONSE);
                                return;
                            }
                            else if (statusCode == 401) {
                                LogService.sharedService().debug("Reset Device Failed - INVALID_TOKEN");
                                handler.completion(CirrentType.RESPONSE.FAILED_INVALID_TOKEN);
                                return;
                            }
                            else {
                                String logStr = String.format("Reset Device Failed - INVALID_STATUS:%d", statusCode);
                                LogService.sharedService().debug(logStr);
                                handler.completion(CirrentType.RESPONSE.FAILED_INVALID_STATUS);
                                return;
                            }
                        }
                    });
                }
            }
        });
    }

    /**
     * Instructs Cirrent to get private credentials from broadband provider and store them in Cirrent cloud, to be fetched by the selected device.
     *<p>If the app is on a private network for which the broadband provider has credentials, you can let the user choose to have the provider deliver the credentials to the Cirrent cloud, instead of having the user enter the private network credentials manually. (The app need only call one of putPrivateCredentials or putProviderCredentials.)
     *<p>Results:
     *<p>SUCCESS - the credentials were received by the Cirrent cloud.
     *<p>FAILED_INVALID_TOKEN - the token being presented is invalid, or does not have the right scope for the operation being performed. putProviderCredentials requires a MANAGE token that includes this device.
     *<p>FAILED_NO_RESPONSE - there was no response from the Cirrent cloud.
     *<p>FAILED_INVALID_STATUS - unexpected response from the Cirrent cloud.
     *
     * @param tokenHandler   The token handler used to authenticate this request
     * @param deviceID  id of device that the credentials are for
     * @param providerUDID  The identifier for the provider who will provision these credentials (this parameter was provided in the findDevice call).
     * @param handler   The handler that is called when the method completes
     */

    public void putProviderCredentials(TokenHandler tokenHandler, final String deviceID, final String providerUDID, final CompletionHandler handler) {
        setOwnerIdentifier(null);
        tokenHandler.getToken(TokenHandler.TOKEN_TYPE.MANAGE, deviceID, new TokenHandler.GetTokenCompletionHandler() {
            @Override
            public void getTokenCompleted(String manageToken) {
                if (manageToken == null) {
                    LogService.sharedService().debug("Put Provider Network Failed: providerUDID=" + providerUDID + ",Error=OwnerID is missed");
                    handler.putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE.FAILED_INVALID_TOKEN, null);
                }
                else {
                    APIService.sharedService().putProviderCredentials(manageToken, ownerID, deviceID, providerUDID, new JsonHttpResponseHandler() {
                        @Override
                        public void onSuccess(int statusCode, Header[] headers, JSONArray response) {
                            ArrayList<String> creds = new ArrayList<String>();
                            for (int i = 0; i < response.length(); i++) {
                                String cred = null;
                                try {
                                    cred = (String) response.get(i);
                                    creds.add(cred);
                                } catch (JSONException e) {
                                    e.printStackTrace();
                                }
                            }

                            LogService.sharedService().debug("Put Provider Network Credentials=" + response.toString());
                            if (creds.size() != 0) {
                                handler.putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE.SUCCESS, creds);
                            }
                            else {
                                handler.putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE.FAILED_NO_RESPONSE, null);
                            }
                        }

                        @Override
                        public void onFailure(int statusCode, Header[] headers, Throwable throwable, JSONObject errorResponse) {
                            if (statusCode == 0) {
                                LogService.sharedService().log(LogService.Event.CLOUD_CONNECTION_ERROR, "");
                                handler.putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE.FAILED_NO_RESPONSE, null);
                            }
                            else if (statusCode == 401) {
                                LogService.sharedService().debug("Put Provider Network Failed - INVALID_TOKEN");
                                handler.putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE.FAILED_INVALID_TOKEN, null);
                            }
                            else {
                                String logStr = String.format("Put Provider Network Failed - INVALID_STATUS:%d", statusCode);
                                LogService.sharedService().debug(logStr);
                                handler.putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE.FAILED_INVALID_STATUS, null);
                            }
                        }
                    });
                }
            }
        });
    }


    private Handler joiningHandler;
    private Runnable joiningRunnable;
    private long joiningDelay = 5000;
    private static int index = 1;
    private static int joiningIndex = 1;
    private static int waitTime = 12;

    /**
     * Check to see how the device is doing, as the device joins the private network.
     *This method is used to get status updates from the device, via the Cirrent cloud, while the device is moving from the ZipKey network to the private network. The getDeviceJoiningStatus method may call the callback handler more than once, to give updated statuses as the device goes through the onboarding process.
     *<p>Results:
     *<p>RECEIVED_CREDS - The device has downloaded the private network credentials from the Cirrent cloud.
     *<p>ATTEMPTING_TO_JOIN - The device is about to drop off the ZipKey network and attempt to join the private network.
     *<p>OPTIMIZING_CONNECTION - The device is confirming that the private network connection works.
     *<p>JOINED - The device has successfully joined the private network.
     *<p>FAILED - The device failed to join the private network. This is most likely due to the credentials being invalid. Prompt the user to re-enter the private network credentials.
     *<p>TIMED_OUT - the mobile app timed out while waiting for the device to  join the private network. This is most likely due to the device being unable to rejoin the ZipKey network to provide a status update.  Go to SoftAP or other local onboarding instead.
     *<p>NOT_SOFTAP_NETWORK - If joining via the SoftAP network, the phone fell off the SoftAP network. Prompt the user to put the phone back on the SoftAP network.
     *<p>FAILED_INVALID_TOKEN - the token being presented is invalid, or does not have the right scope for the operation being performed.  getDeviceJoiningStatus requires a MANAGE token that includes this device.
     *
     * @param tokenHandler   The token handler used to authenticate this request
     * @param deviceID  id of device whose status we are checking
     * @param handler   The handler to be called when status updates are received
     */

    public void getDeviceJoiningStatus(final TokenHandler tokenHandler, final String deviceID, final CompletionHandler handler) {
        tokenHandler.getToken(TokenHandler.TOKEN_TYPE.MANAGE, deviceID, new TokenHandler.GetTokenCompletionHandler() {
            @Override
            public void getTokenCompleted(final String manageToken) {
                index = 1;
                joiningIndex = 1;
                waitTime = 12;

                joiningHandler = new Handler();
                joiningRunnable = new Runnable() {
                    @Override
                    public void run() {
                        if (model.GCN == true) {
                            if (model.selectedDevice == null) {
                                LogService.sharedService().debug("JOINING - Selected Device is Nil");
                                handler.joiningCompletion(CirrentType.JOINING_STATUS.SELECTED_DEVICE_NIL);
                                joiningHandler.removeCallbacksAndMessages(null);
                                return;
                            }

                            if (manageToken == null) {
                                LogService.sharedService().debug("JOINING - Get Device Status Failed - INVALID_TOKEN");
                                handler.joiningCompletion(CirrentType.JOINING_STATUS.FAILED_INVALID_TOKEN);
                                joiningHandler.removeCallbacksAndMessages(null);
                                return;
                            }

                            getDeviceStatus(tokenHandler, deviceID, new CompletionHandler(){
                                @Override
                                public void getStatusCompletion(CirrentType.RESPONSE response, JSONObject status) {
                                    if (response == CirrentType.RESPONSE.FAILED_NO_RESPONSE) {
                                        LogService.sharedService().log(LogService.Event.CLOUD_CONNECTION_ERROR, "");
                                        handler.joiningCompletion(CirrentType.JOINING_STATUS.FAILED_NO_RESPONSE);
                                        joiningHandler.removeCallbacksAndMessages(null);
                                    }
                                    else if (response == CirrentType.RESPONSE.FAILED_INVALID_STATUS) {
                                        LogService.sharedService().debug("JOINING - Get Device Status Failed - INVALID_STATUS");
                                        handler.joiningCompletion(CirrentType.JOINING_STATUS.FAILED_INVALID_STATUS);
                                        joiningHandler.removeCallbacksAndMessages(null);
                                    }
                                    else if (response == CirrentType.RESPONSE.FAILED_INVALID_TOKEN) {
                                        LogService.sharedService().debug("JOINING - Get Device Status Failed - INVALID_TOKEN");
                                        handler.joiningCompletion(CirrentType.JOINING_STATUS.FAILED_INVALID_TOKEN);
                                        joiningHandler.removeCallbacksAndMessages(null);
                                    }
                                    else {
                                        index += 1;
                                        if (index > waitTime) {
                                            joiningHandler.removeCallbacksAndMessages(null);
                                            String logStr = String.format("ssid=%s;credentialID=%s", model.ssid, model.credentialId);
                                            LogService.sharedService().log(LogService.Event.CREDS_TIMEOUT, logStr);
                                            handler.joiningCompletion(CirrentType.JOINING_STATUS.TIMED_OUT);
                                            return;
                                        }

                                        if (status == null) {
                                            LogService.sharedService().debug("JOINING - Failed - GET DEVICE STATUS FAILED");
                                            handler.joiningCompletion(CirrentType.JOINING_STATUS.GET_DEVICE_STATUS_FAILED);
                                            joiningHandler.removeCallbacksAndMessages(null);
                                            return;
                                        }

                                        LogService.sharedService().debug("Credential - " + model.credentialId);

                                        JSONArray knownNetworks = null;
                                        try {
                                            knownNetworks = status.getJSONArray("known_networks");
                                        }catch (JSONException e) {
                                            e.printStackTrace();
                                        }

                                        if (knownNetworks != null && knownNetworks.length() > 0) {
                                            for (int i = 0; i < knownNetworks.length(); i++) {
                                                JSONObject network = null;
                                                try {
                                                    network = knownNetworks.getJSONObject(i);
                                                }catch (JSONException e) {e.printStackTrace(); continue;}

                                                if (network == null) {
                                                    continue;
                                                }

                                                try {
                                                    String net_ssid = network.getString("ssid");
                                                    String net_status = network.getString("status");
                                                    String net_cred = network.getString("credential_id");
                                                    String ssid = CirrentService.sharedService().model.selectedNetwork.ssid;
                                                    String credential = CirrentService.sharedService.model.credentialId;

                                                    if (net_ssid.compareTo(ssid) == 0 && net_status.compareTo("JOINED") == 0 && net_cred.compareTo(credential) == 0) {
                                                        LogService.sharedService().debug("JOINING - Success");
                                                        handler.joiningCompletion(CirrentType.JOINING_STATUS.JOINED);
                                                        joiningHandler.removeCallbacksAndMessages(null);
                                                        return;
                                                    }
                                                    else if (net_ssid.compareTo(ssid) == 0 && net_status.compareTo("JOINING") == 0 && net_cred.compareTo(credential) == 0) {
                                                        if (joiningIndex == 1) {
                                                            LogService.sharedService().debug("JOINING - Received Creds");
                                                            handler.joiningCompletion(CirrentType.JOINING_STATUS.RECEIVED_CREDS);
                                                            waitTime = 34;
                                                        }

                                                        if (joiningIndex == 2) {
                                                            LogService.sharedService().debug("JOINING - Attempting To Join");
                                                            handler.joiningCompletion(CirrentType.JOINING_STATUS.ATTEMPTING_TO_JOIN);
                                                        }

                                                        if (joiningIndex == 3) {
                                                            LogService.sharedService().debug("JOINING - Optimizing Connection");
                                                            handler.joiningCompletion(CirrentType.JOINING_STATUS.OPTIMIZING_CONNECTION);
                                                        }
                                                        joiningIndex += 1;
                                                    }
                                                    else if (net_ssid.compareTo(ssid) == 0 && (net_status.compareTo("DISCONNECTED") == 0 || net_status.compareTo("FAILED") == 0) && net_cred.compareTo(credential) == 0) {
                                                        String logStr = String.format("ssid=%s;credentialID=%s", model.selectedNetwork.ssid, model.credentialId);
                                                        if (model.selectedProvider == null) {
                                                            logStr += "provider_network=false";
                                                        }
                                                        else {
                                                            logStr += "provider_network=true";
                                                        }
                                                        LogService.sharedService().log(LogService.Event.JOINED_FAILED, logStr);
                                                        handler.joiningCompletion(CirrentType.JOINING_STATUS.FAILED);
                                                        joiningHandler.removeCallbacksAndMessages(null);
                                                        return;
                                                    }

                                                } catch (JSONException e) {
                                                    e.printStackTrace();
                                                    continue;
                                                }
                                            }
                                        }
                                    }
                                }
                            });
                        }
                        else {
                            if (bSupportSoftAP == false) {
                                LogService.sharedService().debug("JOINING SOFTAP - Failed - This app not support SOFTAP");
                                handler.joiningCompletion(CirrentType.JOINING_STATUS.FAILED);
                                joiningHandler.removeCallbacksAndMessages(null);
                                return;
                            }

                            String ssid = getCurrentSSID();
                            if (ssid == null || ssid.contains(getSoftAPSSID()) != true) {
                                LogService.sharedService().debug("JOINING SOFTAP - Failed - NOT_SOFTAP_NETWORK");
                                handler.joiningCompletion(CirrentType.JOINING_STATUS.NOT_SOFTAP_NETWORK);
                                joiningHandler.removeCallbacksAndMessages(null);
                                return;
                            }

                            APIService.sharedService().getSoftAPDeviceStatus(model.softAPIp, new JsonHttpResponseHandler() {
                                @Override
                                public void onSuccess(int statusCode, Header[] headers, JSONObject response) {
                                    index += 1;
                                    if (index > 12) {
                                        LogService.sharedService().debug("JOINING SOFTAP - Failed - TIMED_OUT");
                                        handler.joiningCompletion(CirrentType.JOINING_STATUS.TIMED_OUT);
                                        return;
                                    }

                                    if (response == null) {
                                        LogService.sharedService().debug("JOINING SOFTAP - Failed - GET_DEVICE_STATUS_FAILED");
                                        joiningHandler.removeCallbacksAndMessages(null);
                                        handler.joiningCompletion(CirrentType.JOINING_STATUS.GET_DEVICE_STATUS_FAILED);
                                        return;
                                    }

                                    JSONArray knownNetworks = null;
                                    try {
                                        knownNetworks = response.getJSONArray("known_networks");
                                        for (int i = 0; i < knownNetworks.length(); i++) {
                                            JSONObject network = knownNetworks.getJSONObject(i);
                                            String net_ssid = network.getString("ssid");
                                            String ssid = model.selectedNetwork.ssid;
                                            String net_status = network.getString("status");
                                            if (net_ssid.compareTo(ssid) == 0 && net_status.compareTo("JOINED") == 0) {
                                                LogService.sharedService().log(LogService.Event.SOFTAP_JOINED, "");
                                                handler.joiningCompletion(CirrentType.JOINING_STATUS.JOINED);
                                                joiningHandler.removeCallbacksAndMessages(null);
                                                return;
                                            }
                                            else if (net_ssid.compareTo(ssid) == 0 && net_status.compareTo("FAILED") == 0) {
                                                LogService.sharedService().debug("JOINING SOFTAP - Failed");
                                                handler.joiningCompletion(CirrentType.JOINING_STATUS.FAILED);
                                                joiningHandler.removeCallbacksAndMessages(null);
                                                return;
                                            }
                                        }
                                    }
                                    catch (JSONException e) {
                                        e.printStackTrace();
                                    }
                                }

                                @Override
                                public void onFailure(int statusCode, Header[] headers, Throwable throwable, JSONObject errorResponse) {
                                    if (statusCode == 0) {
                                        LogService.sharedService().debug("JOINING SOFTAP - Failed - NO_RESPONSE");
                                        handler.joiningCompletion(CirrentType.JOINING_STATUS.FAILED_NO_RESPONSE);
                                        joiningHandler.removeCallbacksAndMessages(null);
                                        return;
                                    }
                                    else {
                                        LogService.sharedService().debug("JOINING SOFTAP - Failed - INVALID_STATUS");
                                        handler.joiningCompletion(CirrentType.JOINING_STATUS.FAILED_INVALID_STATUS);
                                        joiningHandler.removeCallbacksAndMessages(null);
                                        return;
                                    }
                                }
                            });
                        }

                        joiningHandler.postDelayed(joiningRunnable, joiningDelay);
                    }
                };

                joiningHandler.post(joiningRunnable);
            }
        });
    }

    /**
     * Upload private Wi-Fi credentials for the specified device.  Note that multiple credentials can be provided, and will be given to the device but there is no guarantee that the device will try to connect to every network specified.
     *<p>Results:
     *<p>SUCCESS - the credentials were received by the Cirrent cloud.
     *<p>FAILED_INVALID_TOKEN - the token being presented is invalid, or does not have the right scope for the operation being performed. putPrivateCredentials requires a MANAGE token that includes this device.
     *<p>FAILED_NO_RESPONSE - there was no response from the Cirrent cloud.
     *<p>FAILED_INVALID_STATUS - unexpected response from the Cirrent cloud.
     *<p>FAILED_NOT_SOFTAP_NETWORK - If joining via the SoftAP network, the phone fell off the SoftAP network. Prompt the user to put the phone back on the SoftAP network.
     *
     * @param tokenHandler   The token handler object used to authenticate this request
     * @param deviceID  id of device to receive the credentials
     * @param handler   The handler that is called when this method completes
     */

    public void putPrivateCredentials(TokenHandler tokenHandler, final String deviceID, final CompletionHandler handler) {
        tokenHandler.getToken(TokenHandler.TOKEN_TYPE.MANAGE, deviceID, new TokenHandler.GetTokenCompletionHandler() {
            @Override
            public void getTokenCompleted(String manageToken) {
                if (model.GCN == true) {
                    model.credentialId = null;
                    if (manageToken == null) {
                        LogService.sharedService().debug("Device Join Network Failed - INVALID_TOKEN");
                        handler.putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE.FAILED_INVALID_TOKEN, null);
                        return;
                    }

                    APIService.sharedService().deviceJoinNetwork(manageToken, model.selectedDevice.deviceId, model.selectedNetwork, model.selectedNetworkPassword, new JsonHttpResponseHandler() {
                        @Override
                        public void onSuccess(int statusCode, Header[] headers, JSONArray response) {
                            ArrayList<String> creds = new ArrayList<String>();
                            for (int i = 0; i < response.length(); i++) {
                                String cred = null;
                                try {
                                    cred = (String) response.get(i);
                                    creds.add(cred);
                                } catch (JSONException e) {
                                    e.printStackTrace();
                                }
                            }

                            if (creds.size() == 0) {
                                LogService.sharedService().debug("Device Join Network Failed - Credential is nil");
                                handler.putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE.FAILED_NO_RESPONSE, creds);
                            }
                            else {
                                model.credentialId = creds.get(0);
                                LogService.sharedService().debug("Device Join Network Success - " + response.toString());
                                handler.putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE.SUCCESS, creds);
                            }
                        }

                        @Override
                        public void onFailure(int statusCode, Header[] headers, Throwable throwable, JSONObject errorResponse) {
                            if (statusCode == 0) {
                                LogService.sharedService().log(LogService.Event.CLOUD_CONNECTION_ERROR, "");
                                handler.putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE.FAILED_NO_RESPONSE, null);
                            }
                            else if (statusCode == 401) {
                                LogService.sharedService().debug("Device Join Network Failed - INVALID_TOKEN");
                                handler.putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE.FAILED_INVALID_TOKEN, null);
                            }
                            else {
                                LogService.sharedService().debug("Device Join Network Failed - INVALID_STATUS");
                                handler.putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE.FAILED_INVALID_STATUS, null);
                            }
                        }
                    });
                }
                else {
                    if (bSupportSoftAP == false) {
                        LogService.sharedService().debug("Send Credential Failed on SoftAP - This app not support SOFTAP");
                        handler.putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE.FAILED_NO_RESPONSE, null);
                        return;
                    }

                    String ssid = getCurrentSSID();
                    if (ssid == null) {
                        LogService.sharedService().debug("Send Credential Failed on SoftAP - SSID is Null");
                        handler.putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE.FAILED_NO_RESPONSE, null);
                        return;
                    }

                    if (ssid.compareTo(getSoftAPSSID()) != 0) {
                        LogService.sharedService().debug("Send Credential Failed on SoftAP - NOT_SOFTAP_NETWORK");
                        handler.putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE.NOT_SOFTAP, null);
                        return;
                    }

                    String enteredPassword = model.selectedNetworkPassword;
                    String encryptedPassword = model.selectedNetworkPassword;

                    if (model.selectedNetwork.flags.compareTo("OPEN") != 0 && model.selectedNetwork.flags.compareTo("[ESS]") != 0) {
                        if (model.scdKey != null) {
                            try{
                                byte[] encryptedData = encryptString(enteredPassword, model.scdKey);
                                encryptedPassword = Base64.encodeToString(encryptedData, Base64.NO_WRAP);
                                Log.e("ENC-PSK", encryptedPassword);
                            }
                            catch (Exception e) {
                                e.printStackTrace();
                                encryptedPassword = model.selectedNetworkPassword;
                            }
                        }
                    }

                    APIService.sharedService().putSoftAPJoinNetwork(model.softAPIp, model.selectedNetwork, model.selectedNetworkPassword, encryptedPassword, new JsonHttpResponseHandler() {
                        @Override
                        public void onFailure(int statusCode, Header[] headers, String responseString, Throwable throwable) {
                            checkResponse(statusCode, responseString);
                        }

                        @Override
                        public void onSuccess(int statusCode, Header[] headers, String responseString) {
                            checkResponse(statusCode, responseString);
                        }

                        void checkResponse(int statusCode, String responseString) {
                            if (statusCode == 200) {
                                ArrayList<String> creds = getCredentials(responseString);
                                if (creds == null) {
                                    LogService.sharedService().debug("Send Credential Failed on SoftAP - CREDENTIAL is null");
                                    handler.putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE.FAILED_NO_RESPONSE, null);
                                }
                                else {
                                    LogService.sharedService().debug("Send Credential Success on SoftAP - " + responseString);
                                    handler.putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE.SUCCESS, creds);
                                }
                            }
                            else if (statusCode == 0) {
                                LogService.sharedService().log(LogService.Event.CLOUD_CONNECTION_ERROR, "");
                                handler.putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE.FAILED_NO_RESPONSE, null);
                            }
                            else {
                                LogService.sharedService().debug("Send Credential Failed on SoftAP - INVALID_STATUS");
                                handler.putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE.FAILED_INVALID_STATUS, null);
                            }
                        }

                        ArrayList<String> getCredentials(String responseStr) {
                            if (responseStr == null || responseStr.length() < 2) {
                                return null;
                            }

                            String str = responseStr.substring(1, responseStr.length() - 1);
                            str = str.replace("\\s+", "");
                            String[] split = str.split(",");

                            ArrayList<String> creds = new ArrayList<String>();
                            for (int i = 0; i < split.length; i++) {
                                creds.add(split[i]);
                            }

                            return creds;
                        }
                    });
                }
            }
        });
    }

    /**
     * Get Ip Address from Wifi
     * @return
     */
    private String getWifiAddress() {
        WifiManager wm = (WifiManager) mContext.getSystemService(WIFI_SERVICE);
        String ip = Formatter.formatIpAddress(wm.getConnectionInfo().getIpAddress());
        return ip;
    }

    private Handler softAPHandler = null;
    private Runnable softAPRunnable = null;
    private final long softAPInterval = 5000;
    private final int MAX_SOFTAP_RETRY_LIMIT = 3;
    private int softAPRetryLeftCount = MAX_SOFTAP_RETRY_LIMIT;

    /**
     *  If the device cannot be found in the cloud, and the app goes into SoftAP mode instead,
     *  this method waits to confirm that the phone is on the SoftAP network,
     *  and then gets information from the device (including the device public key and Wi-Fi scan list)
     *  so that the app can send private network credentials to the device over the SoftAP network;
     * it then queries the device over the SoftAP network for its status;
     * once the status has been received, the mobile app can call putPrivateCredentials,
     * and then getDeviceJoiningStatus, just as if it were communicating via the Cirrent cloud.
     *<p>Results:
     *<p>SUCCESS_WITH_SOFTAP - the mobile app successfully talked to the device over the SoftAP network
     *<p>FAILED_NOT_SOFTAP_SSID - the mobile app wasn't able to associate to the SoftAP SSID.  Try moving the phone closer to the device.
     *<p>FAILED_NOT_GET_SOFTAP_IP - the mobile app was not able to get an IP address on the SoftAP network.  This is likely due to a problem with the device.
     *<p>FAILED_SOFTAP_NO_RESPONSE - the mobile app did not get any response from the device over the SoftAP network.
     *<p>FAILED_SOFTAP_INVALID_STATUS - the mobile app got an invalid response from the Cirrent cloud.
     *
     * @param handler   The handler to be called when this method completes
     */
    public void processSoftAP(final CompletionHandler handler) {
        if (bSupportSoftAP == false) {
            LogService.sharedService().debug("SOFTAP - Failed - This app does not support SOFTAP");
            handler.softAPCompletion(CirrentType.SOFTAP_RESPONSE.FAILED_NOT_SUPPORT_SOFTAP);
            return;
        }

        initModel();
        if (model != null && model.ssid != null && model.ssid.contains(getSoftAPSSID())) {
            String logStr = getScanList();
            LogService.sharedService().log(LogService.Event.SOFTAP, logStr);

            String ipAddress = getWifiAddress();
            if (ipAddress == null || ipAddress.length() == 0 || ipAddress.contains(".") == false) {
                LogService.sharedService().debug("SOFTAP - Failed - SoftAP IP address is not valid");
                handler.softAPCompletion(CirrentType.SOFTAP_RESPONSE.FAILED_NOT_GET_SOFTAP_IP);
                return;
            }

            model.setSoftAPIp(ipAddress);
            LogService.sharedService().debug("SoftAP Ip address - " + model.softAPIp);

            softAPHandler = new Handler();
            softAPRunnable = new Runnable() {
                @Override
                public void run() {
                    String ssid = getCurrentSSID();
                    if (ssid == null || ssid.contains(getSoftAPSSID()) == false) {
                        LogService.sharedService().log(LogService.Event.SOFTAP_DROP, "");
                        handler.softAPCompletion(CirrentType.SOFTAP_RESPONSE.FAILED_NOT_SOFTAP_SSID);
                        softAPHandler.removeCallbacksAndMessages(null);
                        return;
                    }

                    APIService.sharedService().getSoftAPDeviceInfo(model.softAPIp, new JsonHttpResponseHandler() {
                        @Override
                        public void onSuccess(int statusCode, Header[] headers, final JSONObject info) {
                            if (info != null) {
                                try {model.scdKey = info.getString("scd_public_key");}
                                catch (JSONException e) {e.printStackTrace();}

                                Device device = new Device();
                                try {
                                    device.macAddress = info.getString("device_id");
                                    device.deviceId = info.getString("device_id");
                                    model.devices = new ArrayList<Device>();
                                    model.devices.add(device);
                                }
                                catch (JSONException e) {e.printStackTrace();}

                                Device selectedDevice = model.getFirstDevice();
                                if (selectedDevice != null) {
                                    model.selectedDevice = selectedDevice;
                                }

                                APIService.sharedService().getSoftAPDeviceStatus(model.softAPIp, new JsonHttpResponseHandler() {
                                    @Override
                                    public void onSuccess(int statusCode, Header[] headers, final JSONObject status) {
                                        try {
                                            final JSONArray wifiScans = status.getJSONArray("wifi_scans");
                                            JSONArray known_networks = status.getJSONArray("known_networks");
                                            boolean bShouldStopSoftAP = false;

                                            if (known_networks != null) {
                                                for (int i = 0; i < known_networks.length(); i++) {
                                                    JSONObject netData = known_networks.getJSONObject(i);
                                                    if (netData != null) {
                                                        String joinedStatus = netData.getString("status");
                                                        if (joinedStatus.compareTo("JOINED") == 0) {
                                                            bShouldStopSoftAP = true;
                                                            break;
                                                        }
                                                    }
                                                }
                                            }

                                            if (bShouldStopSoftAP == true) {
                                                softAPHandler.removeCallbacksAndMessages(null);
                                                softAPRetryLeftCount = MAX_SOFTAP_RETRY_LIMIT;
                                                APIService.sharedService().dropSoftAP(model.softAPIp, new JsonHttpResponseHandler() {
                                                    @Override
                                                    public void onSuccess(int statusCode, Header[] headers, String responseString) {
                                                        if (responseString.compareTo("WONT-DROP") == 0) {
                                                            LogService.sharedService().debug("SOFTAP - Failed - MEET_ME_IN_CLOUD_FAILED - WONT-DROP");
                                                            successSoftAP(info, wifiScans, handler);
                                                        }
                                                        else if (responseString.compareTo("WILL-DROP") == 0) {
                                                            LogService.sharedService().debug("SOFTAP - Success - SUCCESS_MEET_ME_IN_CLOUD");
                                                            meetMeInCloud(info, wifiScans, handler);
                                                        }
                                                        else {
                                                            LogService.sharedService().debug("SOFTAP - Failed - MEET_ME_IN_CLOUD_FAILED - DROP_FAIL");
                                                            successSoftAP(info, wifiScans, handler);
                                                        }
                                                    }

                                                    @Override
                                                    public void onFailure(int statusCode, Header[] headers, String responseString, Throwable throwable) {
                                                        LogService.sharedService().debug("SOFTAP - Failed - MEET_ME_IN_CLOUD_FAILED");
                                                        successSoftAP(info, wifiScans, handler);
                                                    }
                                                });
                                            }
                                            else {
                                                successSoftAP(info, wifiScans, handler);
                                            }
                                        }
                                        catch (JSONException e) {
                                            e.printStackTrace();
                                        }
                                    }

                                    @Override
                                    public void onFailure(int statusCode, Header[] headers, Throwable throwable, JSONObject errorResponse) {
                                        if (statusCode == 0) {
                                            LogService.sharedService().debug("SOFTAP - Failed - GET_SOFTAP_DEVICE_STATUS_NO_RESPONSE");
                                            if (softAPRetryLeftCount <= 0) {
                                                softAPRetryLeftCount = MAX_SOFTAP_RETRY_LIMIT;
                                                softAPHandler.removeCallbacksAndMessages(null);
                                                handler.softAPCompletion(CirrentType.SOFTAP_RESPONSE.FAILED_SOFTAP_NO_RESPONSE);
                                            }
                                            else {
                                                softAPRetryLeftCount -= 1;
                                                softAPHandler.postDelayed(softAPRunnable, softAPInterval);
                                            }
                                        }
                                        else {
                                            LogService.sharedService().debug("SOFTAP - Failed - GET_SOFTAP_DEVICE_STATUS_INVALID_STATUS:" + statusCode);
                                            if (softAPRetryLeftCount <= 0) {
                                                softAPRetryLeftCount = MAX_SOFTAP_RETRY_LIMIT;
                                                softAPHandler.removeCallbacksAndMessages(null);
                                                handler.softAPCompletion(CirrentType.SOFTAP_RESPONSE.FAILED_SOFTAP_INVALID_STATUS);
                                            }
                                            else {
                                                softAPRetryLeftCount -= 1;
                                                softAPHandler.postDelayed(softAPRunnable, softAPInterval);
                                            }
                                        }
                                    }
                                });
                            }
                            else {
                                LogService.sharedService().debug("SOFTAP - Failed - GET_SOFTAP_DEVICE_INFO_NO_RESPONSE");
                                if (softAPRetryLeftCount <= 0) {
                                    softAPRetryLeftCount = MAX_SOFTAP_RETRY_LIMIT;
                                    softAPHandler.removeCallbacksAndMessages(null);
                                    handler.softAPCompletion(CirrentType.SOFTAP_RESPONSE.FAILED_SOFTAP_NO_RESPONSE);
                                }
                                else {
                                    softAPRetryLeftCount -= 1;
                                    softAPHandler.postDelayed(softAPRunnable, softAPInterval);
                                }
                            }
                        }

                        @Override
                        public void onFailure(int statusCode, Header[] headers, Throwable throwable, JSONObject errorResponse) {
                            if (statusCode == 0) {
                                LogService.sharedService().debug("SOFTAP - Failed - GET_SOFTAP_DEVICE_INFO_NO_RESPONSE");
                                if (softAPRetryLeftCount <= 0) {
                                    softAPRetryLeftCount = MAX_SOFTAP_RETRY_LIMIT;
                                    softAPHandler.removeCallbacksAndMessages(null);
                                    handler.softAPCompletion(CirrentType.SOFTAP_RESPONSE.FAILED_SOFTAP_NO_RESPONSE);
                                }
                                else {
                                    softAPRetryLeftCount -= 1;
                                    softAPHandler.postDelayed(softAPRunnable, softAPInterval);
                                }
                            }
                            else {
                                LogService.sharedService().debug("SOFTAP - Failed - GET_SOFTAP_DEVICE_INFO_INVALID_STATUS:" + statusCode);
                                if (softAPRetryLeftCount <= 0) {
                                    softAPRetryLeftCount = MAX_SOFTAP_RETRY_LIMIT;
                                    softAPHandler.removeCallbacksAndMessages(null);
                                    handler.softAPCompletion(CirrentType.SOFTAP_RESPONSE.FAILED_SOFTAP_INVALID_STATUS);
                                }
                                else {
                                    softAPRetryLeftCount -= 1;
                                    softAPHandler.postDelayed(softAPRunnable, softAPInterval);
                                }
                            }
                        }
                    });
                }
            };
            softAPHandler.post(softAPRunnable);
        }
        else {
            String logStr = "";
            long currentSec = System.currentTimeMillis();

            if (model.ssid == null) {
                logStr = String.format("wanted-ssid=%s;got-ssid=null;timeout=%d", getSoftAPSSID(), currentSec - startTimeSec);
            }
            else {
                logStr = String.format("wanted-ssid=%s;got-ssid=%s;timeout=%d", getSoftAPSSID(), model.ssid, currentSec - startTimeSec);
            }
            LogService.sharedService().log(LogService.Event.SOFTAP_ERROR, logStr);
            handler.softAPCompletion(CirrentType.SOFTAP_RESPONSE.FAILED_NOT_SOFTAP_SSID);
        }
    }

    /**
     * If the phone can communicate with cloud, process with normal flow
     * @param deviceInfo
     * @param wifiScans
     * @param handler
     */
    private void meetMeInCloud(JSONObject deviceInfo, JSONArray wifiScans, CompletionHandler handler) {

        try {
            Device device = new Device();
            device.macAddress = deviceInfo.getString("device_id");
            device.deviceId = deviceInfo.getString("device_id");

            model.GCN = true;
            model.devices = new ArrayList<Device>();
            model.devices.add(device);
            model.selectedDevice = model.getFirstDevice();
            model.setNetworks(wifiScans);

            softAPHandler.removeCallbacksAndMessages(null);
            softAPRetryLeftCount = MAX_SOFTAP_RETRY_LIMIT;
            handler.softAPCompletion(CirrentType.SOFTAP_RESPONSE.SUCCESS_WITH_SOFTAP);
        }
        catch (JSONException e) {
            e.printStackTrace();
            handler.softAPCompletion(CirrentType.SOFTAP_RESPONSE.FAILED_SOFTAP_NO_RESPONSE);
        }
    }

    /**
     * Process when success on SoftAP
     * @param deviceInfo
     * @param wifiScans
     * @param handler
     */
    private void successSoftAP(JSONObject deviceInfo, JSONArray wifiScans, CompletionHandler handler) {
        try {
            Device device = new Device();
            device.macAddress = deviceInfo.getString("device_id");
            device.deviceId = deviceInfo.getString("device_id");

            model.GCN = false;
            model.devices = new ArrayList<Device>();
            model.devices.add(device);
            model.selectedDevice = model.getFirstDevice();
            model.setSoftAPNetworks(wifiScans);

            softAPHandler.removeCallbacksAndMessages(null);
            softAPRetryLeftCount = MAX_SOFTAP_RETRY_LIMIT;
            handler.softAPCompletion(CirrentType.SOFTAP_RESPONSE.SUCCESS_WITH_SOFTAP);
        }
        catch (JSONException e) {
            e.printStackTrace();
            handler.softAPCompletion(CirrentType.SOFTAP_RESPONSE.FAILED_SOFTAP_NO_RESPONSE);
        }
    }


    private Runnable findSoftAPRunnable;
    private Handler findSoftAPHandler;
    private final int MAX_FINDSOFTAP = 6;
    private int findSoftAPLeftCount = MAX_FINDSOFTAP;

    private Handler checkSoftAPHandler = null;
    private Runnable checkSoftAPRunnable = null;
    private final int MAX_CHECKSOFTAP = 10;
    private int checkSoftAPLeftCount = MAX_CHECKSOFTAP;
    private boolean bCheckingSoftAP = false;

    /**
     * Get Wifi Scan List from Android Device
     * @return
     */
    private String getScanList() {
        final WifiManager wifiManager = (WifiManager)mContext.getSystemService(WIFI_SERVICE);
        ConnectivityManager connectivityManager = (ConnectivityManager) mContext.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo networkInfo = connectivityManager.getNetworkInfo(ConnectivityManager.TYPE_WIFI);
        if (networkInfo.isConnected() == false) {
            wifiManager.setWifiEnabled(true);
        }

        final String networkSSID = getSoftAPSSID();
        wifiManager.startScan();
        List<ScanResult> scanList = wifiManager.getScanResults();

        String scanStr = "Scan=";
        for (ScanResult res : scanList) {
            if (res.SSID.startsWith("\"") && res.SSID.endsWith("\"")){
                res.SSID = res.SSID.substring(1, res.SSID.length()-1);
            }

            if (res.BSSID.startsWith("\"") && res.BSSID.endsWith("\"")){
                res.BSSID = res.BSSID.substring(1, res.BSSID.length()-1);
            }

            scanStr += String.format("ssid=%s,bssid=%s;", res.SSID, res.BSSID);
        }

        if (scanList.size() == 0) {
            scanStr = "Scan=NON";
        }

        return scanStr;
    }

    private long startTimeSec;
    private static int softAPScreenCount = 0;

    /**
     * Connect automatically to specific network
     * @param ssid  The WiFi network to join
     */
    public void connectToWifi(String ssid) {
        final WifiManager wifiManager = (WifiManager)mContext.getSystemService(WIFI_SERVICE);
        ConnectivityManager connectivityManager = (ConnectivityManager) mContext.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo networkInfo = connectivityManager.getNetworkInfo(ConnectivityManager.TYPE_WIFI);
        if (networkInfo.isConnected() == false) {
            wifiManager.setWifiEnabled(true);
        }

        final String networkSSID = ssid;
        wifiManager.startScan();
        List<ScanResult> scanList = wifiManager.getScanResults();
        final ArrayList<Integer> networkIDArray = new ArrayList<Integer>();
        for (ScanResult res : scanList) {

            if (res.SSID.startsWith("\"") && res.SSID.endsWith("\"")){
                res.SSID = res.SSID.substring(1, res.SSID.length()-1);
            }

            if (res.SSID.contains(networkSSID) == true) {
                final WifiConfiguration conf = new WifiConfiguration();
                conf.SSID = "\"" + res.SSID + "\"";
                conf.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.NONE);
                conf.status = WifiConfiguration.Status.ENABLED;

                conf.allowedGroupCiphers.set(WifiConfiguration.GroupCipher.TKIP);
                conf.allowedGroupCiphers.set(WifiConfiguration.GroupCipher.CCMP);
                conf.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.NONE);

                conf.allowedPairwiseCiphers.set(WifiConfiguration.PairwiseCipher.TKIP);
                conf.allowedPairwiseCiphers.set(WifiConfiguration.PairwiseCipher.CCMP);

                conf.allowedProtocols.set(WifiConfiguration.Protocol.RSN);
                conf.allowedProtocols.set(WifiConfiguration.Protocol.WPA);
                int networkID = wifiManager.addNetwork(conf);
                networkIDArray.add(networkID);
            }
        }
    }

    /**
     * If the mobile app needs to communicate with the device through the softAP network, this method connects the phone to the softAP network.
     * <p>Results:
     * <p>SUCCESS-the phone successfully joined to the softAP network
     * <p>FAILED_NO_RESPONSE-could not find softAP network
     *
     * @param handler
     */
    public void connectToSoftAPNetwork(final CompletionHandler handler) {
        if (bSupportSoftAP == false) {
            LogService.sharedService().debug("Failed To connect SOFTAP - This app not support SOFTAP");
            handler.completion(CirrentType.RESPONSE.FAILED_NO_RESPONSE);
            return;
        }

        softAPScreenCount += 1;
        LogService.sharedService().log(LogService.Event.SOFTAP_SCREEN, String.format("%d", softAPScreenCount));

        startTimeSec = System.currentTimeMillis();

        final WifiManager wifiManager = (WifiManager)mContext.getSystemService(WIFI_SERVICE);
        ConnectivityManager connectivityManager = (ConnectivityManager) mContext.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo networkInfo = connectivityManager.getNetworkInfo(ConnectivityManager.TYPE_WIFI);
        if (networkInfo.isConnected() == false) {
            wifiManager.setWifiEnabled(true);
        }

        final String networkSSID = getSoftAPSSID();
        wifiManager.startScan();
        List<ScanResult> scanList = wifiManager.getScanResults();
        final ArrayList<Integer> networkIDArray = new ArrayList<Integer>();
        for (ScanResult res : scanList) {

            if (res.SSID.startsWith("\"") && res.SSID.endsWith("\"")){
                res.SSID = res.SSID.substring(1, res.SSID.length()-1);
            }

            if (res.SSID.contains(networkSSID) == true) {
                final WifiConfiguration conf = new WifiConfiguration();
                conf.SSID = "\"" + res.SSID + "\"";
                conf.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.NONE);
                conf.status = WifiConfiguration.Status.ENABLED;

                conf.allowedGroupCiphers.set(WifiConfiguration.GroupCipher.TKIP);
                conf.allowedGroupCiphers.set(WifiConfiguration.GroupCipher.CCMP);
                conf.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.NONE);

                conf.allowedPairwiseCiphers.set(WifiConfiguration.PairwiseCipher.TKIP);
                conf.allowedPairwiseCiphers.set(WifiConfiguration.PairwiseCipher.CCMP);

                conf.allowedProtocols.set(WifiConfiguration.Protocol.RSN);
                conf.allowedProtocols.set(WifiConfiguration.Protocol.WPA);
                int networkID = wifiManager.addNetwork(conf);
                networkIDArray.add(networkID);
            }
        }

        findSoftAPHandler = new Handler();
        findSoftAPRunnable = new Runnable() {
            @Override
            public void run() {
                List<ScanResult> scanList = wifiManager.getScanResults();
                boolean bFindSoftAPName = false;

                for (ScanResult res : scanList) {
                    if (res.SSID.startsWith("\"") && res.SSID.endsWith("\"")){
                        res.SSID = res.SSID.substring(1, res.SSID.length()-1);
                    }

                    if (res.SSID.contains(networkSSID) && bCheckingSoftAP == false) {
                        int index = 0;
                        for (ScanResult result : scanList) {
                            if (res.SSID.startsWith("\"") && res.SSID.endsWith("\"")){
                                res.SSID = res.SSID.substring(1, res.SSID.length()-1);
                            }

                            if (result.SSID.startsWith("\"") && result.SSID.endsWith("\"")){
                                result.SSID = result.SSID.substring(1, result.SSID.length()-1);
                            }

                            if (result.SSID.contains(CirrentService.sharedService().getSoftAPSSID())) {
                                if (res.SSID.compareTo(result.SSID) == 0) {
                                    break;
                                }
                                index += 1;
                            }
                        }

                        int networkID = networkIDArray.get(index);
                        bFindSoftAPName = true;
                        bCheckingSoftAP = true;
                        wifiManager.disconnect();
                        wifiManager.enableNetwork(networkID, true);
                        wifiManager.reconnect();

                        final long checkSoftAPDelay = 1000;
                        checkSoftAPHandler = new Handler();
                        checkSoftAPRunnable = new Runnable() {
                            @Override
                            public void run() {
                                String ssid = CirrentService.sharedService().getCurrentSSID();
                                String SoftAPSSID = CirrentService.sharedService.getSoftAPSSID();
                                if (ssid != null && ssid.contains(SoftAPSSID) == true) {
                                    bCheckingSoftAP = false;
                                    checkSoftAPLeftCount = MAX_CHECKSOFTAP;
                                    checkSoftAPHandler.removeCallbacksAndMessages(null);
                                    findSoftAPHandler.removeCallbacksAndMessages(null);
                                    handler.completion(CirrentType.RESPONSE.SUCCESS);
                                }
                                else {
                                    if (checkSoftAPLeftCount > 0) {
                                        checkSoftAPLeftCount -= 1;
                                        checkSoftAPHandler.postDelayed(checkSoftAPRunnable, checkSoftAPDelay);
                                    }
                                    else {
                                        bCheckingSoftAP = false;
                                        checkSoftAPLeftCount = MAX_CHECKSOFTAP;
                                        checkSoftAPHandler.removeCallbacksAndMessages(null);
                                        if (findSoftAPLeftCount > 0) {
                                            findSoftAPLeftCount -= 1;
                                            findSoftAPHandler.post(findSoftAPRunnable);
                                        }
                                        else {
                                            findSoftAPLeftCount = MAX_FINDSOFTAP;
                                            findSoftAPHandler.removeCallbacksAndMessages(null);
                                            handler.completion(CirrentType.RESPONSE.FAILED_NO_RESPONSE);
                                        }
                                    }
                                }
                            }
                        };
                        checkSoftAPHandler.post(checkSoftAPRunnable);
                    }
                }

                if (bFindSoftAPName == false) {
                    findSoftAPHandler.removeCallbacksAndMessages(null);
                    handler.completion(CirrentType.RESPONSE.FAILED_NO_RESPONSE);
                    return;
                }
            }
        };

        findSoftAPHandler.post(findSoftAPRunnable);
    }

    /**
     * Check whether the device is reachable via the internet or over SoftAP network
     * @return true if reachable via the internet, false if reachable over SoftAP
     */
    public boolean isOnZipKeyNetwork() {
        if (model == null) {
            return true;
        }

        return !(model.GCN);
    }

    /**
     * Load Public Key for RSA encryption
     * @param key
     * @return
     * @throws Exception
     */
    private PublicKey loadPublicKey(String key) throws Exception {
        key = key
                .replace("-----BEGIN PUBLIC KEY-----", "")
                .replace("-----END PUBLIC KEY-----", "")
                .replaceAll("\\s", "").replaceAll("\\n", "");

        // decode to get the binary DER representation
        byte[] publicKeyDER = Base64.decode(key, 0);

        KeyFactory keyFactory = KeyFactory.getInstance("RSA");
        PublicKey publicKey = keyFactory.generatePublic(new X509EncodedKeySpec(publicKeyDER));
        return publicKey;
    }

    /**
     * Encrypt with RSA methods
     * @param data
     * @param key
     * @return
     * @throws Exception
     */
    private byte[] encryptString(String data, String key) throws Exception {
        Cipher cipher = Cipher.getInstance("RSA/NONE/OAEPPadding");
        PublicKey publicKey = loadPublicKey(key);
        cipher.init(Cipher.ENCRYPT_MODE, publicKey);
        byte[] encrypted = cipher.doFinal(data.getBytes(Charset.forName("UTF-8")));
        return encrypted;
    }
}
