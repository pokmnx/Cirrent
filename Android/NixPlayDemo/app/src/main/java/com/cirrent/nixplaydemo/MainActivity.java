package com.cirrent.nixplaydemo;

import android.app.ProgressDialog;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.os.Handler;
import android.os.StrictMode;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;

import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.InetAddress;
import java.net.URL;

import static junit.framework.Assert.assertEquals;

public class MainActivity extends AppCompatActivity {

    private ProgressDialog mProgressDialog;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        this.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);

        show("Checking Connectivity...");

        new Thread(new Runnable() {
            @Override
            public void run() {
                final boolean bConnectToGoogle = isAvailableToConnectGoogle();
                final boolean bConnectToCirrent = isAvailableToConnectCirrent();

                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        //MainActivity.this.dismiss();
                        Intent intent;
                        if (bConnectToGoogle == true) {
                            intent = new Intent(MainActivity.this, ConnectGoogleActivity.class);
                        }
                        else {
                            if (bConnectToCirrent == true) {
                                intent = new Intent(MainActivity.this, ConnectCirrentActivity.class);
                            }
                            else {
                                intent = new Intent(MainActivity.this, NoConnectionActivity.class);
                            }
                        }

                        if (intent != null) {
                            MainActivity.this.startActivity(intent);
                        }
                    }
                });
            }
        }).start();
    }

    static public boolean isAvailableToConnectGoogle() {
        String strUrl = "https://google.com";
        return isReachableURL(strUrl);
    }

    static boolean isReachableURL(String strUrl) {
        StrictMode.ThreadPolicy policy = new StrictMode.ThreadPolicy.Builder().permitAll().build();
        StrictMode.setThreadPolicy(policy);

        try {
            URL url = new URL(strUrl);
            HttpURLConnection urlConn = (HttpURLConnection) url.openConnection();
            urlConn.setRequestProperty("User-Agent", "Test");
            urlConn.setRequestProperty("Connection", "close");
            urlConn.setConnectTimeout(3000); //choose your own timeframe
            urlConn.setReadTimeout(4000);
            urlConn.connect();
            if (urlConn.getResponseCode() == HttpURLConnection.HTTP_OK) {
                return true;
            }
            return false;
        } catch (IOException e) {
            System.err.println("Error creating HTTP connection");
            e.printStackTrace();
            return false;
        }
    }

    static public boolean isAvailableToConnectCirrent() {
        String strUrl = "https://dev.cirrentsystems.com";
        return isReachableURL(strUrl);
    }

    void show(String status) {
        if(mProgressDialog == null) {
            mProgressDialog = new ProgressDialog(this);
            if (status != null && status.length() != 0)
                mProgressDialog.setMessage(status);
            mProgressDialog.setCancelable(false);
            mProgressDialog.setCanceledOnTouchOutside(false);
            mProgressDialog.show();
        }
        else {
            if (status != null && status.length() != 0) {
                mProgressDialog.setMessage(status);
            }
        }
    }

    void dismiss() {
        if (mProgressDialog != null) {
            mProgressDialog.dismiss();
        }
    }
}
