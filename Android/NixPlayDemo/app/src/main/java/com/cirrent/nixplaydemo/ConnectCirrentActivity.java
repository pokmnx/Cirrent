package com.cirrent.nixplaydemo;

import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.os.Bundle;
import android.os.Handler;
import android.support.v7.app.AppCompatActivity;


public class ConnectCirrentActivity extends AppCompatActivity {

    Handler handler;
    Runnable runnable;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.connect_cirrent_layout);
        this.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);

        handler = new Handler();
        runnable = new Runnable() {
            @Override
            public void run() {
                final boolean bConnectToGoogle = MainActivity.isAvailableToConnectGoogle();
                final boolean bConnectToCirrent = MainActivity.isAvailableToConnectCirrent();

                if (bConnectToGoogle == true) {
                    Intent intent = new Intent(ConnectCirrentActivity.this, ConnectGoogleActivity.class);
                    ConnectCirrentActivity.this.startActivity(intent);
                    handler.removeCallbacksAndMessages(null);
                }
                else if (bConnectToCirrent == true) {
                    handler.postDelayed(runnable, 2000);
                }
                else {
                    Intent intent = new Intent(ConnectCirrentActivity.this, NoConnectionActivity.class);
                    ConnectCirrentActivity.this.startActivity(intent);
                    handler.removeCallbacksAndMessages(null);
                }
            }
        };
        handler.postDelayed(runnable, 2000);
    }


}
