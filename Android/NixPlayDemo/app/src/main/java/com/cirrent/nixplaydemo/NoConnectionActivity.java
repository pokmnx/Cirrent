package com.cirrent.nixplaydemo;

import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.os.Bundle;
import android.os.Handler;
import android.support.v7.app.AppCompatActivity;

public class NoConnectionActivity extends AppCompatActivity {

    Handler handler;
    Runnable runnable;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.no_connection_layout);
        this.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);

        handler = new Handler();
        runnable = new Runnable() {
            @Override
            public void run() {
                final boolean bConnectToGoogle = MainActivity.isAvailableToConnectGoogle();
                final boolean bConnectToCirrent = MainActivity.isAvailableToConnectCirrent();

                if (bConnectToGoogle == true) {
                    Intent intent = new Intent(NoConnectionActivity.this, ConnectGoogleActivity.class);
                    NoConnectionActivity.this.startActivity(intent);
                    handler.removeCallbacksAndMessages(null);
                }
                else if (bConnectToCirrent == true) {
                    Intent intent = new Intent(NoConnectionActivity.this, ConnectCirrentActivity.class);
                    NoConnectionActivity.this.startActivity(intent);
                    handler.removeCallbacksAndMessages(null);
                }
                else {
                    handler.postDelayed(runnable, 2000);
                }
            }
        };
        handler.postDelayed(runnable, 2000);
    }


}
