package com.cirrent.cirrentsdk;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.net.ConnectivityManager;
import android.net.wifi.ScanResult;
import android.os.Bundle;
import android.os.Handler;
import android.support.v4.app.ActivityCompat;
import android.telephony.TelephonyManager;
import android.util.Log;

import com.loopj.android.http.AsyncHttpClient;
import com.loopj.android.http.JsonHttpResponseHandler;
import com.loopj.android.http.RequestParams;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.List;

import cz.msebera.android.httpclient.entity.ContentType;
import cz.msebera.android.httpclient.entity.StringEntity;

class APIService {
    private final String endPoint = "https://app.cirrentsystems.com/2016-01/";
    private final String ENVIRONMENT_URL = endPoint + "environment";
    private final String DEVICES_URL = endPoint + "devices";
    private final String LOG_URL = endPoint + "log/";

    private static AsyncHttpClient client = new AsyncHttpClient();
    private static APIService sharedService = sharedService();
    private Context mContext = null;
    private LocationManager locationManager;
    private CirrentLocationListener locationListener;
    private Location currentLocation = null;
    public boolean bEndLocation = false;

    private static final int TIME_OUT = 70000;
    private final int PHONE_STATE_REQUEST = 1002;
    private final int FINE_LOCATION_REQUEST = 1003;

    private boolean bStart = false;

    APIService() {

    }

    static APIService sharedService() {
        if (sharedService == null) {
            sharedService = new APIService();
            client.setTimeout(TIME_OUT);
            client.setConnectTimeout(TIME_OUT);
            client.setResponseTimeout(TIME_OUT);
        }
        return sharedService;
    }

    void setContext(Context context) {
        this.mContext = context;
    }

    boolean uploadEnvironment(String searchToken, String appID, Model model, List<ScanResult> scanList, JsonHttpResponseHandler handler) {
        JSONObject location_object = new JSONObject();
        JSONObject req_object = new JSONObject();

        if (currentLocation == null) {
            try {
                req_object.put("appID", appID);
            } catch (JSONException e) {
                e.printStackTrace();
                return false;
            }
        }
        else {
            try {
                location_object.put("latitude", currentLocation.getLatitude());
                location_object.put("longitude", currentLocation.getLongitude());
                location_object.put("accuracy", currentLocation.getAccuracy());
                location_object.put("ssid", model.ssid);
                location_object.put("bssid", model.bssid);
                String logStr = String.format("Lat=%f;Long=%f", currentLocation.getLatitude(), currentLocation.getLongitude());
                LogService.sharedService().log(LogService.Event.LOCATION, logStr);
                req_object.put("location", location_object);
                req_object.put("ssid", model.ssid);
                req_object.put("bssid", model.bssid);
                req_object.put("appID", appID);
            } catch (JSONException e) {
                e.printStackTrace();
                return false;
            }
        }
/*
        if (scanList != null && scanList.size() > 0) {
            JSONArray wifiScans = new JSONArray();
            for (int i = 0; i < scanList.size(); i++) {
                ScanResult scan = scanList.get(i);
                JSONObject wifi = new JSONObject();
                try {
                    wifi.put("ssid", scan.SSID);
                } catch (JSONException e) {
                    e.printStackTrace();
                }

                try {
                    wifi.put("bssid", scan.BSSID);
                } catch (JSONException e) {
                    e.printStackTrace();
                }

                try {
                    wifi.put("frequency", scan.frequency);
                } catch (JSONException e) {
                    e.printStackTrace();
                }

                try {
                    wifi.put("flags", scan.capabilities);
                } catch (JSONException e) {
                    e.printStackTrace();
                }

                try {
                    wifi.put("signal_level", scan.level);
                } catch (JSONException e) {
                    e.printStackTrace();
                }

                try {
                    wifi.put("anqp_roaming_consortium", scan.SSID);
                } catch (JSONException e) {
                    e.printStackTrace();
                }

                try {
                    wifi.put("capabilities", scan.capabilities);
                } catch (JSONException e) {
                    e.printStackTrace();
                }

                try {
                    wifi.put("quality", scan.SSID);
                } catch (JSONException e) {
                    e.printStackTrace();
                }

                try {
                    wifi.put("noise_level", scan.SSID);
                } catch (JSONException e) {
                    e.printStackTrace();
                }

                try {
                    wifi.put("information_element", scan.SSID);
                } catch (JSONException e) {
                    e.printStackTrace();
                }

                wifiScans.put(wifi);
            }

            if (wifiScans.length() > 0) {
                try {
                    req_object.put("wifi_scans", wifiScans);
                }
                catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        }

*/

        if (model != null && model.ssid != null && model.ssid.length() > 0 && model.bssid != null && model.bssid.length() > 0) {
            JSONObject wifi_object = new JSONObject();
            try {
                wifi_object.put("bssid", model.bssid);
                wifi_object.put("ssid", model.ssid);
                JSONArray wifi_array = new JSONArray();
                wifi_array.put(wifi_object);
                req_object.put("wifi_scans", wifi_array);
            } catch (JSONException e) {
                e.printStackTrace();
                return false;
            }
        }

        putRequest(searchToken, ENVIRONMENT_URL, req_object, handler);
        logAPICall(ENVIRONMENT_URL);

        return true;
    }

    void getDevicesInRange(String searchToken, String appID, JsonHttpResponseHandler handler) {
        String url = endPoint + "devices";
        RequestParams params = new RequestParams();
        params.add("ownerID", appID);
        getRequest(searchToken, url, params, handler);
        logAPICall(url);
    }

    void identifyYourself(String searchToken, String deviceID, JsonHttpResponseHandler handler) {
        String url = DEVICES_URL + "/" + deviceID + "/identify_yourself";
        putRequest(searchToken, url, new RequestParams(), handler);
        logAPICall(url);
    }

    void getDeviceStatus(String manageToken, String deviceID, JsonHttpResponseHandler handler) {
        String url = DEVICES_URL + "/" + deviceID + "/status";
        getRequest(manageToken, url, new RequestParams(), handler);
        logAPICall(url);
    }

    void bindDevice(String bindToken, JsonHttpResponseHandler handler) {
        String url = DEVICES_URL + "/bind";
        putRequest(bindToken, url, new RequestParams(), handler);
        logAPICall(url);
    }

    void resetDevice(String manageToken, String deviceID, JsonHttpResponseHandler handler) {
        String url = DEVICES_URL + "/" + deviceID + "/reset";
        putRequest(manageToken, url, new RequestParams(), handler);
        logAPICall(url);
    }

    void getUserActionPerformedStatus(String searchToken, String deviceID, JsonHttpResponseHandler handler) {
        String url = DEVICES_URL + "/" + deviceID + "/user_action_performed";
        getRequest(searchToken, url, new RequestParams(), handler);
    }

    void putProviderCredentials(String manageToken, String appID, String deviceID, String providerID, JsonHttpResponseHandler handler) {
        String url = DEVICES_URL + "/" + deviceID;
        url += "/owner/" + appID + "/provider_private_network/" + providerID;
        putRequest(manageToken, url, new RequestParams(), handler);
        logAPICall(url);
    }

    boolean deviceJoinNetwork(String manageToken, String deviceID, Network network, String password, JsonHttpResponseHandler handler) {
        String security = getSecurityProtocol(network);
        if (security == null) {
            log("Device Join Network Failed - Security Protocol is Nil");
            return false;
        }

        JSONObject object = new JSONObject();
        JSONArray array = new JSONArray();
        try {
            object.put("ssid", network.ssid);
            object.put("security", security);
            object.put("priority", 200);

            if (password != null && password.length() != 0) {
                object.put("pre_shared_key", password);
            }

            array.put(object);
            String url = endPoint + "devices/" + deviceID + "/private_network";
            putRequest(manageToken, url, array, handler);
            logAPICall(url);
        } catch (JSONException e) {
            e.printStackTrace();
            return false;
        }
        return true;
    }

    void deletePrivateNetwork(String manageToken, String deviceID, Network network, JsonHttpResponseHandler handler) {
        String url = DEVICES_URL + "/" + deviceID + "/private_network";
        JSONObject object = new JSONObject();
        try {
            object.put("ssid", network.ssid);
            object.put("roaming_id", network.roamingID);
            object.put("security", network.security);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        deleteRequest(manageToken, url, object, handler);
        logAPICall(url);
    }

    void getSoftAPDeviceStatus(String softAPIp, JsonHttpResponseHandler handler) {
        RequestParams params = new RequestParams();
        String url = "http://" + softAPIp + "/status";
        StringEntity entity = new StringEntity(params.toString(), ContentType.APPLICATION_JSON);
        client.get(this.mContext, url, entity, ContentType.APPLICATION_JSON.getMimeType(), handler);
        logAPICall(url);
    }

    void getSoftAPDeviceInfo(String softAPIp, JsonHttpResponseHandler handler) {
        RequestParams params = new RequestParams();
        String url = "http://" + softAPIp + "/device_info";
        StringEntity entity = new StringEntity(params.toString(), ContentType.APPLICATION_JSON);
        client.get(this.mContext, url, entity, ContentType.APPLICATION_JSON.getMimeType(), handler);
        logAPICall(url);
    }

    boolean putSoftAPJoinNetwork(String softAPIp, Network network, String password, String encryptedPassword, JsonHttpResponseHandler handler) {
        String security = getSecurityProtocol(network);
        if (security == null) {
            LogService.sharedService().debug("Join Network Error: security protocol is nil");
            return false;
        }

        JSONArray array = new JSONArray();
        JSONObject object = new JSONObject();

        try {
            object.put("ssid", network.ssid);
            object.put("security", security);
            object.put("priority", 200);
            if (encryptedPassword != null && encryptedPassword.length() != 0) {
                object.put("encrypted_pre_shared_key", encryptedPassword);
            }
            else {
                object.put("pre_shared_key", password);
            }
            array.put(object);

            String url = "http://" + softAPIp + "/private_network";
            postRequest(null, url, array, handler);
            logAPICall(url);
        } catch (JSONException e) {
            e.printStackTrace();
            return false;
        }

        return true;
    }

    void dropSoftAP(String softAPIp, JsonHttpResponseHandler handler) {
        String url = "http://" + softAPIp + "/drop_softap";
        RequestParams params = new RequestParams();
        putRequest(null, url, params, handler);
        LogService.sharedService().debug(url + " Called");
    }

    boolean uploadLog(String token, String appID, String logStr, JsonHttpResponseHandler handler) {
        String url = LOG_URL + appID;
        JSONObject params = new JSONObject();
        try {
            params.put("file", logStr);
            params.put("filename", "app");
        } catch (JSONException e) {
            e.printStackTrace();
            return false;
        }

        String authStr = getAuthenticate(token);
        if (authStr != null) {
            client.addHeader("Authorization", authStr);
        }

        StringEntity entity = new StringEntity(params.toString(), ContentType.APPLICATION_JSON);
        client.put(this.mContext, url, entity, ContentType.APPLICATION_JSON.getMimeType(), handler);

        return true;
    }

// Private Methods
    private void log(String message) {
        LogService.sharedService().debug(message);
    }

    private void logAPICall(String url) {
        LogService.sharedService().debug(url + " called.");
    }

    private String getSecurityProtocol(Network wifi) {
        if (wifi.flags.contains("WPA/WPA2-PSK") == true)
            return "WPA/WPA2-PSK";
        else if (wifi.flags.contains("WPA2-PSK") == true)
            return "WPA2-PSK";
        else if (wifi.flags.contains("WPA-PSK") == true)
            return "WPA-PSK";
        else if (wifi.flags.contains("WPA2-EAP") == true)
            return "WPA2-EAP";
        else if (wifi.flags.contains("WPA2-ENTERPRISE") == true)
            return "WPA2-ENTERPRISE";
        else if (wifi.flags.contains("WISPR") == true)
            return "WISPR";
        else if (wifi.flags.contains("OPEN") == true)
            return "OPEN";
        else if (wifi.flags.contains("Hs2.0") == true)
            return "Hs2.0";
        else if (wifi.flags.contains("[ESS]") == true)
            return "OPEN";
        return "";
    }

    private void postRequest(String token, String url, RequestParams params, JsonHttpResponseHandler handler) {
        String authStr = getAuthenticate(token);
        if (authStr != null) {
            client.addHeader("Authorization", authStr);
        }

        client.post(url, params, handler);
    }

    private void getRequest(String token, String url, RequestParams params, JsonHttpResponseHandler handler) {
        String authStr = getAuthenticate(token);
        if (authStr != null) {
            client.addHeader("Authorization", authStr);
        }

        client.get(url, params, handler);
    }

    private void putRequest(String token, String url, RequestParams params, JsonHttpResponseHandler handler) {
        String authStr = getAuthenticate(token);
        if (authStr != null) {
            client.addHeader("Authorization", authStr);
        }

        client.put(url, params, handler);
    }

    private void deleteRequest(String token, String url, RequestParams params, JsonHttpResponseHandler handler) {
        String authStr = getAuthenticate(token);
        if (authStr != null) {
            client.addHeader("Authorization", authStr);
        }

        client.delete(url, params, handler);
    }

    private void postRequest(String token, String url, JSONObject object, JsonHttpResponseHandler handler) {
        String authStr = getAuthenticate(token);
        if (authStr != null) {
            client.addHeader("Authorization", authStr);
        }

        StringEntity entity = new StringEntity(object.toString(), ContentType.APPLICATION_JSON);
        client.post(this.mContext, url, entity, ContentType.APPLICATION_JSON.getMimeType(), handler);
    }

    private void getRequest(String token, String url, JSONObject object, JsonHttpResponseHandler handler) {
        String authStr = getAuthenticate(token);
        if (authStr != null) {
            client.addHeader("Authorization", authStr);
        }

        StringEntity entity = new StringEntity(object.toString(), ContentType.APPLICATION_JSON);
        client.get(this.mContext, url, entity, ContentType.APPLICATION_JSON.getMimeType(), handler);
    }

    private void deleteRequest(String token, String url, JSONObject object, JsonHttpResponseHandler handler) {
        String authStr = getAuthenticate(token);
        if (authStr != null) {
            client.addHeader("Authorization", authStr);
        }

        StringEntity entity = new StringEntity(object.toString(), ContentType.APPLICATION_JSON);
        client.delete(this.mContext, url, entity, ContentType.APPLICATION_JSON.getMimeType(), handler);
    }

    private void putRequest(String token, String url, JSONObject object, JsonHttpResponseHandler handler) {
        String authStr = getAuthenticate(token);
        if (authStr != null) {
            client.addHeader("Authorization", authStr);
        }

        StringEntity entity = new StringEntity(object.toString(), ContentType.APPLICATION_JSON);
        client.put(this.mContext, url, entity, ContentType.APPLICATION_JSON.getMimeType(), handler);
    }

    private void putRequest(String token, String url, JSONArray array, JsonHttpResponseHandler handler) {
        String authStr = getAuthenticate(token);
        if (authStr != null) {
            client.addHeader("Authorization", authStr);
        }

        StringEntity entity = new StringEntity(array.toString(), ContentType.APPLICATION_JSON);
        client.put(this.mContext, url, entity, ContentType.APPLICATION_JSON.getMimeType(), handler);
    }

    private void postRequest(String token, String url, JSONArray array, JsonHttpResponseHandler handler) {
        String authStr = getAuthenticate(token);
        if (authStr != null) {
            client.addHeader("Authorization", authStr);
        }

        StringEntity entity = new StringEntity(array.toString(), ContentType.APPLICATION_JSON);
        client.post(this.mContext, url, entity, ContentType.APPLICATION_JSON.getMimeType(), handler);
    }

    private String getAuthenticate(String token) {

        if (bStart == false) {
            bStart = true;
            LogService.sharedService().log(LogService.Event.APP_START, "");
        }

        if (token != null && token.length() > 0) {
            String authStr = "Bearer " + token;
            return authStr;
        }

        return null;
    }



// Location Management
    class CirrentLocationListener implements LocationListener {

        @Override
        public void onLocationChanged(Location location) {
            currentLocation = location;
            String loc = currentLocation.getLatitude() + " " + currentLocation.getLongitude();
            Log.e("LOCATION", loc);

            if (currentLocation.getAccuracy() < 200) {
                endLocationService();
            }
        }
        @Override
        public void onStatusChanged(String s, int i, Bundle bundle) {

        }

        @Override
        public void onProviderEnabled(String s) {

        }

        @Override
        public void onProviderDisabled(String s) {

        }
    }

    private final int LOCATION_TIMEOUT = 10000;
    private boolean bConnectedToWifi = true;
    void startLocationService() {
        if (locationManager == null)
            locationManager = (LocationManager) mContext.getSystemService(Context.LOCATION_SERVICE);
        locationListener = new CirrentLocationListener();

        if (ActivityCompat.checkSelfPermission(mContext, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED && ActivityCompat.checkSelfPermission(mContext, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions((Activity) mContext, new String[]{Manifest.permission.ACCESS_FINE_LOCATION}, FINE_LOCATION_REQUEST);
            return;
        }

        if (ActivityCompat.checkSelfPermission(mContext, Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions((Activity) mContext, new String[]{Manifest.permission.READ_PHONE_STATE}, PHONE_STATE_REQUEST);
            return;
        }

        try {

            ConnectivityManager connectivityManager = (ConnectivityManager) mContext.getSystemService(Context.CONNECTIVITY_SERVICE);
            if (connectivityManager.getActiveNetworkInfo().getType() == ConnectivityManager.TYPE_WIFI) {
                bConnectedToWifi = true;
                locationManager.requestLocationUpdates(LocationManager.NETWORK_PROVIDER, 0, 0, (LocationListener) locationListener);
            }
            else {
                bConnectedToWifi = false;
                locationManager.requestLocationUpdates(LocationManager.GPS_PROVIDER, 0, 0, (LocationListener) locationListener);
            }

            final Handler handler = new Handler();
            handler.postDelayed(new Runnable() {
                @Override
                public void run() {
                    if (currentLocation == null) {
                        endLocationService();
                    }
                    handler.removeCallbacksAndMessages(null);
                }
            }, LOCATION_TIMEOUT);
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void endLocationService()
    {
        try
        {
            bEndLocation = true;
            if (locationListener != null && locationManager != null) {
                locationManager.removeUpdates(locationListener);
            }
            locationManager=null;
            locationListener = null;
        }
        catch(SecurityException e)
        {
            e.printStackTrace();
        }
    }

    boolean isLocationEnabled() {
        if (locationManager == null) {
            locationManager = (LocationManager) mContext.getSystemService(Context.LOCATION_SERVICE);
        }

        if (bConnectedToWifi == true) {
            return locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER);
        }
        else {
            return locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER);
        }
    }

    boolean isLocationPermitted() {
        if (mContext == null) return false;
        return (ActivityCompat.checkSelfPermission(mContext
                , Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) || (ActivityCompat.checkSelfPermission(mContext, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED);
    }
}
