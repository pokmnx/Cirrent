package com.cirrent.cirrentsdk;

import android.content.Context;
import com.loopj.android.http.JsonHttpResponseHandler;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;

import cz.msebera.android.httpclient.Header;

public class LogService {

    public enum Event {
        APP_START,
        TOKEN_RECEIVED,
        TOKEN_ERROR,
        LOCATION,
        LOCATION_ERROR,
        WIFI_SCAN,
        WIFI_SCAN_ERROR,
        DEVICES_RECEIVED,
        DEVICE_SELECTED,
        DEVICE_BOUND,
        PROVIDER_CREDS,
        USER_CREDS,
        STATUS,
        STATUS_ERROR,
        SOFTAP,
        SOFTAP_ERROR,
        SOFTAP_SCREEN,
        SOFTAP_JOINED,
        SOFTAP_DROP,
        SOFTAP_LONG_DURATION,
        CREDS_TIMEOUT,
        CLOUD_CONNECTION_ERROR,
        JOINED_FAILED,
        SUCCESS,
        EXIT,
        DEBUG
    }

    class Log {
        Date date;
        String event;
        String details;

        public Log() {
            date = new Date();
        }

        public String getLogString() {
            String logString = "";

            DateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ");
            Calendar cal = Calendar.getInstance();
            logString = dateFormat.format(date);
            logString += "|" + event + "|";
            logString += details;

            return logString;
        }
    }

    private ArrayList<Log> logArrayList = new ArrayList<Log>();
    private static LogService service = null;
    private Context mContext;
    private String token;

    private final String LOG_FILE_NAME = "log.txt";
    private static File logFile;

    public LogService() {

    }

    /**
     * Singleton Instance for LogService
     * @return
     */

    public static LogService sharedService() {
        if (service == null) {
            service = new LogService();
        }
        return service;
    }

    /**
     * Set Context For LogService
     * You should set this context before you use LogService object
     * @param context
     */

    public void setContext(Context context) {
        mContext = context;
        if (mContext != null) {
            logFile = new File(mContext.getFilesDir(), LOG_FILE_NAME);
        }
    }

    /**
     * Log Event and Data
     * @param event
     * @param data
     */

    public void log(Event event, String data) {
        Log lg = new Log();
        switch (event) {
            case APP_START:
                lg.event = "APP-START";
                break;
            case TOKEN_RECEIVED:
                lg.event = "TOKEN-RECEIVED";
                break;
            case TOKEN_ERROR:
                lg.event = "TOKEN-ERROR";
                break;
            case LOCATION:
                lg.event = "LOCATION";
                break;
            case LOCATION_ERROR:
                lg.event = "LOCATION-ERROR";
                break;
            case WIFI_SCAN:
                lg.event = "WIFI-SCAN";
                break;
            case WIFI_SCAN_ERROR:
                lg.event = "WIFI-SCAN-ERROR";
                break;
            case DEVICES_RECEIVED:
                lg.event = "TOKEN-RECEIVED";
                break;
            case DEVICE_SELECTED:
                lg.event = "DEVICE-SELECTED";
                break;
            case DEVICE_BOUND:
                lg.event = "DEVICE-BOUND";
                break;
            case PROVIDER_CREDS:
                lg.event = "PROVIDER-CREDS";
                break;
            case USER_CREDS:
                lg.event = "USER-CREDS";
                break;
            case STATUS:
                lg.event = "STATUS";
                break;
            case STATUS_ERROR:
                lg.event = "STATUS-ERROR";
                break;
            case SOFTAP:
                lg.event = "SOFTAP";
                break;
            case SOFTAP_ERROR:
                lg.event = "SOFTAP-ERROR";
                break;
            case SOFTAP_SCREEN:
                lg.event = "SOFTAP-SCREEN";
                break;
            case SOFTAP_JOINED:
                lg.event = "SOFTAP-JOINED";
                break;
            case SOFTAP_DROP:
                lg.event = "SOFTAP-DROP";
                break;
            case SOFTAP_LONG_DURATION:
                lg.event = "SOFTAP-LONG-DURATION";
                break;
            case CREDS_TIMEOUT:
                lg.event = "CREDS-TIMEOUT";
                break;
            case CLOUD_CONNECTION_ERROR:
                lg.event = "CLOUD-CONNECTION-ERROR";
                break;
            case JOINED_FAILED:
                lg.event = "JOINED-FAILED";
                break;
            case SUCCESS:
                lg.event = "SUCCESS";
                break;
            case EXIT:
                lg.event = "EXIT";
                break;
            case DEBUG:
                lg.event = "DEBUG";
                break;
        }
        lg.details = data;
        logArrayList.add(lg);

        android.util.Log.d(lg.event, lg.details);
    }

    /**
     * Log Debug data
     * @param data
     */

    public void debug(String data) {
        log(Event.DEBUG, data);
    }

    /**
     * Remove All logs from local storage
     */

    private void purge() {
        logArrayList.clear();

        FileOutputStream outputStream;
        String emptyStr = "";
        try {
            outputStream = mContext.openFileOutput(LOG_FILE_NAME, Context.MODE_PRIVATE);
            outputStream.write(emptyStr.getBytes());
            outputStream.close();
            android.util.Log.e("LogService", "Success to purge log file.");
        } catch (Exception e) {
            e.printStackTrace();
            android.util.Log.e("LogService", e.toString());
        }
    }

    /**
     * Save logs to local storage
     */

    public void saveLogs() {
        if (logArrayList == null || logArrayList.size() == 0) {
            return;
        }

        String entireStr = "";
        String fileStr = "";

        for (int i = 0; i < logArrayList.size(); i++) {
            Log log = logArrayList.get(i);
            String logStr = log.getLogString();
            fileStr += logStr + "\\n";
        }

        try {
            InputStream inputStream = mContext.openFileInput(LOG_FILE_NAME);

            if (inputStream != null) {
                InputStreamReader inputStreamReader = new InputStreamReader(inputStream);
                BufferedReader bufferedReader = new BufferedReader(inputStreamReader);
                String receiveString = "";
                StringBuilder stringBuilder = new StringBuilder();

                while ((receiveString = bufferedReader.readLine()) != null) {
                    stringBuilder.append(receiveString);
                }

                inputStream.close();
                entireStr = stringBuilder.toString();
                entireStr += fileStr;

                FileOutputStream outputStream;

                try {
                    outputStream = mContext.openFileOutput(LOG_FILE_NAME, Context.MODE_PRIVATE);
                    outputStream.write(entireStr.getBytes());
                    outputStream.close();
                    android.util.Log.e("LogService", "Success to save Logs to log file.");
                } catch (Exception e) {
                    e.printStackTrace();
                    android.util.Log.e("LogService", e.toString());
                }
            }
            else {
                android.util.Log.e("LogService", "Failed to Open InputStream from log file.");
            }
        }
        catch (FileNotFoundException e) {
            e.printStackTrace();
            android.util.Log.e("LogService", e.toString());
        } catch (IOException e) {
            e.printStackTrace();
            android.util.Log.e("LogService", e.toString());
        }
    }

    /**
     * Upload log to Cloud, if fail to upload log to cloud, save the logs to local storage
     * @param fileStr
     */

    private void uploadLog(String fileStr) {
        String appID = CirrentService.sharedService().setOwnerIdentifier(null);
        if (token == null || token.length() == 0) {
            android.util.Log.e("LogService", "Uploading Log Failed - INVALID_TOKEN");
            saveLogs();
            return;
        }

        APIService.sharedService().uploadLog(token, appID, fileStr, new JsonHttpResponseHandler() {
            @Override
            public void onSuccess(int statusCode, Header[] headers, JSONObject response) {
                if (statusCode == 200) {
                    android.util.Log.e("Error", "Uploading Logs Success");
                    purge();
                }
                else {
                    android.util.Log.e("Error", "Uploading Logs Failed:" + response.toString());
                    saveLogs();
                }
            }

            @Override
            public void onFailure(int statusCode, Header[] headers, Throwable throwable, JSONObject errorResponse) {
                if (statusCode == 200) {
                    android.util.Log.e("Error", "Uploading Logs Success");
                    purge();
                }
                else {
                    if (errorResponse != null) {
                        android.util.Log.e("Error", "Uploading Logs Failed:" + errorResponse.toString());
                        saveLogs();
                    }
                }
            }

            @Override
            public void onFailure(int statusCode, Header[] headers, String responseString, Throwable throwable) {
                if (statusCode == 200) {
                    android.util.Log.e("Error", "Uploading Logs Success");
                    purge();
                }
                else {
                    android.util.Log.e("Error", "Uploading Logs Failed:" + responseString);
                    saveLogs();
                }
            }
        });
    }

    /**
     * load logs from local storage and upload to cloud
     */

    private void loadAndUploadLogs() {
        if (token == null) {
            android.util.Log.e("LogService", "Failed Uploading saved logs - INVALID_TOKEN");
            return;
        }

        String fileStr = "";

        try {
            InputStream inputStream = mContext.openFileInput(LOG_FILE_NAME);

            if (inputStream != null) {
                InputStreamReader inputStreamReader = new InputStreamReader(inputStream);
                BufferedReader bufferedReader = new BufferedReader(inputStreamReader);
                String receiveString = "";
                StringBuilder stringBuilder = new StringBuilder();

                while ((receiveString = bufferedReader.readLine()) != null) {
                    stringBuilder.append(receiveString);
                }

                inputStream.close();
                fileStr = stringBuilder.toString();
                String appID = CirrentService.sharedService().setOwnerIdentifier(null);
                if (token == null || token.length() == 0) {
                    android.util.Log.e("LogService", "Uploading Log Failed - INVALID_TOKEN");
                    saveLogs();
                    return;
                }

                if (fileStr == null || fileStr.length() == 0) {
                    return;
                }

                APIService.sharedService().uploadLog(token, appID, fileStr, new JsonHttpResponseHandler() {
                    @Override
                    public void onSuccess(int statusCode, Header[] headers, JSONObject response) {
                        if (statusCode == 200) {
                            android.util.Log.e("Error", "Uploading Logs Success");
                            purge();
                        }
                        else {
                            android.util.Log.e("Error", "Uploading Logs Failed:" + response.toString());
                        }
                    }

                    @Override
                    public void onFailure(int statusCode, Header[] headers, Throwable throwable, JSONObject errorResponse) {
                        if (statusCode == 200) {
                            android.util.Log.e("Error", "Uploading Logs Success");
                            purge();
                        }
                        else {
                            if (errorResponse != null) {
                                android.util.Log.e("Error", "Uploading Logs Failed:" + errorResponse.toString());
                            }
                        }
                    }

                    @Override
                    public void onFailure(int statusCode, Header[] headers, String responseString, Throwable throwable) {
                        if (statusCode == 200) {
                            android.util.Log.e("Error", "Uploading Logs Success");
                            purge();
                        }
                        else {
                            android.util.Log.e("Error", "Uploading Logs Failed:" + responseString);
                        }
                    }
                });
            }
        }
        catch (FileNotFoundException e) {
            e.printStackTrace();
            android.util.Log.e("LogService", e.toString());
        } catch (IOException e) {
            e.printStackTrace();
            android.util.Log.e("LogService", e.toString());
        }
    }

    /**
     * Upload logs to cloud
     * @param token
     */

    public void putLog(String token) {
        if (token != null) {
            this.token = token;
        }

        loadAndUploadLogs();

        if (logArrayList == null || logArrayList.size() == 0) {
            return;
        }

        String fileStr = "";
        for (int i = 0; i < logArrayList.size(); i++) {
            String logStr = logArrayList.get(i).getLogString();
            fileStr += logStr + "\\n";
        }

        uploadLog(fileStr);
    }
}
