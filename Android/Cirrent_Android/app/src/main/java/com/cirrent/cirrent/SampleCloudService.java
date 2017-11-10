package com.cirrent.cirrent;

import android.content.Context;
import android.content.SharedPreferences;

import com.cirrent.cirrentsdk.LogService;
import com.loopj.android.http.AsyncHttpClient;
import com.loopj.android.http.JsonHttpResponseHandler;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;

import cz.msebera.android.httpclient.entity.ContentType;
import cz.msebera.android.httpclient.entity.StringEntity;
import cz.msebera.android.httpclient.Header;

public class SampleCloudService {

    private static SampleCloudService sharedService = null;
    private Context mContext = null;
    private static AsyncHttpClient client = new AsyncHttpClient();

    private static String TOKEN_URL = "https://go.cirrent.com/cloud/token/search";
    private static String apiURL = "https://go.cirrent.com/cloud/";
    private static String PREF_KEY = "prefs";

    private static String USERNAME_KEY = "username";
    private static String PASSWORD_KEY = "password";

    private static final int TIME_OUT = 10000;
    private static final int CONNECTIONS = 1;
    String appID;
    String username;
    String password;

    String manage_token = null;
    String search_token = null;
    String bind_token = null;

    boolean bindedDevice = false;

    public SampleCloudService() {

    }

    public static SampleCloudService sharedService() {
        if (sharedService == null) {
            sharedService = new SampleCloudService();
            client.setTimeout(TIME_OUT);
            client.setConnectTimeout(TIME_OUT);
            client.setResponseTimeout(TIME_OUT);
            client.setMaxConnections(CONNECTIONS);
        }

        return sharedService;
    }

    public void setContext(Context context) {
        mContext = context;
    }

    void saveLogInInfo(String username, String password) {
        if (mContext == null) return;

        this.username = username;
        this.password = password;
        this.appID = username;

        SharedPreferences prefs = mContext.getSharedPreferences(PREF_KEY, 0);
        SharedPreferences.Editor editor = prefs.edit();

        editor.putString(USERNAME_KEY, username);
        editor.putString(PASSWORD_KEY, password);

        editor.commit();
    }

    String getUsername() {
        if (mContext == null) return null;

        SharedPreferences prefs = mContext.getSharedPreferences(PREF_KEY, 0);
        String username = prefs.getString(USERNAME_KEY, null);
        return username;
    }

    String getPassword() {
        if (mContext == null) return null;

        SharedPreferences prefs = mContext.getSharedPreferences(PREF_KEY, 0);
        String password = prefs.getString(PASSWORD_KEY, null);
        return password;
    }

    void login(final String username, final String password, final SampleCompletionHandler handler) {
        this.username = username;
        this.password = password;
        getSearchToken(new SampleCompletionHandler(){
            @Override
            public void completionGetSearchToken(boolean bSuccess) {
                if (bSuccess == true) {
                    saveLogInInfo(username, password);
                }
                handler.completion(bSuccess);
            }
        });
    }

    void signOut() {
        username = null;
        password = null;
        manage_token = null;
        search_token = null;
        bind_token = null;
        appID = null;

        SharedPreferences prefs = mContext.getSharedPreferences(PREF_KEY, 0);
        SharedPreferences.Editor editor = prefs.edit();

        editor.remove(USERNAME_KEY);
        editor.remove(PASSWORD_KEY);

        editor.commit();
    }

    void getSearchToken(final SampleCompletionHandler handler) {
        getRequest(TOKEN_URL, new JSONObject(), new JsonHttpResponseHandler() {
            @Override
            public void onSuccess(int statusCode, Header[] headers, JSONObject response) {
                try {
                    String token = response.getString("token");
                    LogService.sharedService().log(LogService.Event.TOKEN_RECEIVED, "Type=SEARCH;value=" + token);
                    search_token = token;
                    handler.completionGetSearchToken(true);
                } catch (JSONException e) {
                    e.printStackTrace();
                    LogService.sharedService().log(LogService.Event.TOKEN_ERROR, "Error=PARSE_JSON_ERROR");
                    handler.completionGetSearchToken(false);
                }
            }

            @Override
            public void onFailure(int statusCode, Header[] headers, Throwable throwable, JSONObject errorResponse) {
                if (statusCode == 0) {
                    LogService.sharedService().log(LogService.Event.CLOUD_CONNECTION_ERROR, "");
                }
                else if (statusCode == 401) {
                    LogService.sharedService().log(LogService.Event.TOKEN_ERROR, "Error=Unauthorized - authentication credentials are invalid");
                }
                else if (statusCode == 404) {
                    LogService.sharedService().log(LogService.Event.TOKEN_ERROR, "Error=Device id is not recognized or is not associated with the user's account");
                }
                else {
                    LogService.sharedService().log(LogService.Event.TOKEN_ERROR, "Error=Invalid Status " + statusCode);
                }
                handler.completionGetSearchToken(false);
            }
        });
    }

    public class SampleDevice {
        String deviceID = null;
        String friendlyName = null;
        String name = null;
        String imageURL = null;
    }

    public static class SampleCompletionHandler {
        public void completionGetSearchToken(boolean bSuccess){}
        public void completionGetDevices(ArrayList<SampleDevice> devices) {}
        public void completionBindDevice(boolean bSuccess) {}
        public void completionResetDevice(boolean bSuccess){}
        public void completion(boolean bSuccess){}
    }

    public void getDevices(final SampleCompletionHandler handler) {
        String url = apiURL + "/devices";
        getRequest(url, new JSONObject(), new JsonHttpResponseHandler() {
            @Override
            public void onSuccess(int statusCode, Header[] headers, JSONObject response) {
                try {
                    manage_token = response.getString("manage_token");
                    JSONArray deviceArray = response.getJSONArray("devices");
                    ArrayList<SampleDevice> devices = new ArrayList<SampleDevice>();
                    for (int i = 0; i < deviceArray.length(); i++) {
                        JSONObject deviceData = deviceArray.getJSONObject(i);
                        SampleDevice device = getDeviceFromJson(deviceData);
                        devices.add(device);
                    }
                    handler.completionGetDevices(devices);
                }catch (JSONException e) {
                    e.printStackTrace();
                    LogService.sharedService().debug("SampleCloud - ");
                    handler.completionGetDevices(null);
                }
            }

            @Override
            public void onFailure(int statusCode, Header[] headers, Throwable throwable, JSONObject errorResponse) {
                if (statusCode == 0) {
                    LogService.sharedService().log(LogService.Event.CLOUD_CONNECTION_ERROR, "");
                }
                else if (statusCode == 401) {
                    LogService.sharedService().log(LogService.Event.TOKEN_ERROR, "Error=Unauthorized - authentication credentials are invalid");
                }
                else if (statusCode == 404) {
                    LogService.sharedService().log(LogService.Event.TOKEN_ERROR, "Error=Device id is not recognized or is not associated with the user's account");
                }
                else {
                    LogService.sharedService().log(LogService.Event.TOKEN_ERROR, "Error=Invalid Status " + statusCode);
                }
                LogService.sharedService().debug("SampleCloud - Get Devices Failed - Invalid Status " + statusCode);
                handler.completionGetDevices(null);
            }
        });
    }

    public void bindDevice(final String deviceID, String friendlyName, final SampleCompletionHandler handler) {
        String url = apiURL + "/bind/" + deviceID;
        JSONObject param = new JSONObject();
        try {
            if (friendlyName != null) {
                param.put("friendly_name", friendlyName);
            }
        }catch (JSONException e) {
            e.printStackTrace();
        }

        postRequest(url, param, new JsonHttpResponseHandler() {
            @Override
            public void onSuccess(int statusCode, Header[] headers, JSONObject response) {
                try {
                    bind_token = response.getString("token");
                }catch (JSONException e) {
                    e.printStackTrace();
                }

                String logStr = "Type=BIND;value=" + bind_token;
                LogService.sharedService().log(LogService.Event.TOKEN_RECEIVED, logStr);
                LogService.sharedService().debug("SampleCloud - Binded Device - DeviceID=" + deviceID);
                handler.completionBindDevice(true);
            }

            @Override
            public void onFailure(int statusCode, Header[] headers, Throwable throwable, JSONObject errorResponse) {
                if (statusCode == 0) {
                    LogService.sharedService().log(LogService.Event.CLOUD_CONNECTION_ERROR, "");
                }
                else if (statusCode == 401) {
                    LogService.sharedService().log(LogService.Event.TOKEN_ERROR, "Error=Unauthorized - authentication credentials are invalid");
                }
                else if (statusCode == 404) {
                    LogService.sharedService().log(LogService.Event.TOKEN_ERROR, "Error=Device id is not recognized or is not associated with the user's account");
                }
                else {
                    LogService.sharedService().log(LogService.Event.TOKEN_ERROR, "Error=Invalid Status " + statusCode);
                }
                LogService.sharedService().debug("SampleCloud - Bind Device Failed - Invalid Status " + statusCode);
                handler.completionBindDevice(false);
            }
        });
    }

    public void resetDevice(final String deviceID, final SampleCompletionHandler handler) {
        String url = apiURL + "/reset/" + deviceID;
        deleteRequest(url, new JsonHttpResponseHandler() {
            @Override
            public void onSuccess(int statusCode, Header[] headers, JSONObject response) {
                LogService.sharedService().debug("SampleCloud - Reset Device - DeviceID=" + deviceID);
                handler.completionResetDevice(true);
            }

            @Override
            public void onFailure(int statusCode, Header[] headers, Throwable throwable, JSONObject errorResponse) {
                String logStr = "SampleCloud - Reset Device Failed - DeviceID:" + deviceID + " ";
                if (statusCode == 0) {
                    LogService.sharedService().log(LogService.Event.CLOUD_CONNECTION_ERROR, "");
                    handler.completionResetDevice(false);
                    return;
                }
                else if (statusCode == 401) {
                    logStr += "Unauthorized - authentication credentials are invalid";
                }
                else if (statusCode == 404) {
                    logStr += "Device id is not recognized or is not associated with the user's account";
                }
                else {
                    logStr += "Invalid Status " + statusCode;
                }
                LogService.sharedService().debug(logStr);
                handler.completionResetDevice(false);
            }
        });
    }

    private SampleDevice getDeviceFromJson(JSONObject data) {
        SampleDevice device = new SampleDevice();
        try {device.deviceID = data.getString("cirrent_device_id");}catch (JSONException e) {e.printStackTrace();}
        try {device.friendlyName = data.getString("friendly_name");}catch (JSONException e) {e.printStackTrace();}
        try {device.name = data.getString("device_type_name");}catch (JSONException e) {e.printStackTrace();}
        try {device.imageURL = data.getString("device_type_image");}catch (JSONException e) {e.printStackTrace();}
        return device;
    }

    private void postRequest(String url, JSONObject object, JsonHttpResponseHandler handler) {
        StringEntity entity = new StringEntity(object.toString(), ContentType.APPLICATION_JSON);
        if (getUsername() == null || getPassword() == null) {
            if (this.username != null && this.password != null) {
                client.setBasicAuth(this.username, this.password);
            }
        }
        else {
            client.setBasicAuth(getUsername(), getPassword());
        }

        client.post(this.mContext, url, entity, ContentType.APPLICATION_JSON.getMimeType(), handler);
    }

    private void getRequest(String url, JSONObject object, JsonHttpResponseHandler handler) {
        StringEntity entity = new StringEntity(object.toString(), ContentType.APPLICATION_JSON);
        if (getUsername() == null || getPassword() == null) {
            if (this.username != null && this.password != null) {
                client.setBasicAuth(this.username, this.password);
            }
        }
        else {
            client.setBasicAuth(getUsername(), getPassword());
        }
        client.get(this.mContext, url, entity, ContentType.APPLICATION_JSON.getMimeType(), handler);
    }

    private void deleteRequest(String url, JsonHttpResponseHandler handler) {
        client.setBasicAuth(getUsername(), getPassword());
        client.delete(this.mContext, url, null, handler);
    }
}
