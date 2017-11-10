package com.cirrent.stresstest;

import android.app.ProgressDialog;
import android.os.Handler;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.Toast;

import com.cirrent.cirrentsdk.CirrentService;
import com.cirrent.cirrentsdk.CirrentType;
import com.cirrent.cirrentsdk.CompletionHandler;
import com.cirrent.cirrentsdk.LogService;
import com.cirrent.cirrentsdk.Network;

import java.util.ArrayList;
import java.util.Timer;
import java.util.TimerTask;

public class MainActivity extends AppCompatActivity {

    ProgressDialog mProgressDialog;
    String softApSSID = "wcm-softap";
    String validSSID = "ZipKey-PSK";
    String validCred = "Cirrent1";
    String invalidSSID = "Unknown-Office-WiFi";
    String invalidCred = "BadKey1234";
    String token = "";

    Handler findHandler;
    Runnable findRunnable;
    Handler connectHandler;
    Runnable connectRunnable;
    Handler invalidConnectHandler;
    Runnable invalidConnectRunnable;

    class StepOneListener implements View.OnClickListener {

        @Override
        public void onClick(View v) {
            connectToSoftAp();
        }

        public void joinToSoftAp() {
            MainActivity.this.show("Getting device joining status ...");
            connectHandler = new Handler();
            final long delay = 5000;
            connectRunnable = new Runnable() {
                @Override
                public void run() {
                    CirrentService.sharedService().getDeviceJoiningSoftApStatus(new CompletionHandler(){
                        @Override
                        public void joiningCompletion(CirrentType.JOINING_STATUS status) {
                            if (status == CirrentType.JOINING_STATUS.JOINED) {
                                MainActivity.this.dismiss();
                                connectHandler.removeCallbacksAndMessages(null);
                                Toast.makeText(MainActivity.this, "TEST 1 PASSED - device joined private network.", Toast.LENGTH_LONG).show();
                                CirrentService.sharedService().forgetSoftApNetwork();
                                LogService.sharedService().putLog(token);
                            }
                            else {
                                connectHandler.postDelayed(connectRunnable, delay);
                            }
                        }
                    });
                }
            };
            connectHandler.post(connectRunnable);
        }

        public void connectToSoftAp() {
            MainActivity.this.show("TEST 1 - Connecting To SoftAp network " + softApSSID + " ...");
            findHandler = new Handler();
            findRunnable = new Runnable() {
                @Override
                public void run() {
                    CirrentService.sharedService().connectToSoftApNetwork(new CompletionHandler() {
                        @Override
                        public void completion(CirrentType.RESPONSE response) {
                            if (response == CirrentType.RESPONSE.SUCCESS) {
                                MainActivity.this.show("Getting Device Info...");
                                LogService.sharedService().debug("Your phone is on softap network now");
                                findHandler.removeCallbacksAndMessages(null);
                                CirrentService.sharedService().getSoftApDeviceInfo(new CompletionHandler() {
                                    @Override
                                    public void softApCompletion(CirrentType.SOFTAP_RESPONSE response) {
                                        if (response == CirrentType.SOFTAP_RESPONSE.SUCCESS_WITH_SOFTAP) {
                                            MainActivity.this.show("Getting Device Status...");
                                            CirrentService.sharedService().getSoftApDeviceStatus(new CompletionHandler() {
                                                @Override
                                                public void softApCompletion(CirrentType.SOFTAP_RESPONSE response) {
                                                    if (response == CirrentType.SOFTAP_RESPONSE.SUCCESS_WITH_SOFTAP) {
                                                        boolean bFind = false;
                                                        for (int i = 0; i < CirrentService.sharedService().model.getNetworks().size(); i++) {
                                                            Network network = CirrentService.sharedService().model.getNetworks().get(i);
                                                            if (network.ssid.compareTo(validSSID) == 0) {
                                                                CirrentService.sharedService().model.selectedNetwork = network;
                                                                bFind = true;
                                                                break;
                                                            }
                                                        }
                                                        if (bFind == false) {
                                                            CirrentService.sharedService().model.selectedNetwork = CirrentService.sharedService().model.getNetworks().get(0);
                                                        }
                                                        CirrentService.sharedService().model.selectedNetworkPassword = validCred;
                                                        MainActivity.this.show("Sending private credentials to device...");
                                                        CirrentService.sharedService().putPrivateCredentials(null, new CompletionHandler() {
                                                            @Override
                                                            public void putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE response, ArrayList<String> credentials) {
                                                                if (response == CirrentType.CREDENTIAL_RESPONSE.SUCCESS && credentials != null) {
                                                                    runOnUiThread(new Runnable() {
                                                                        @Override
                                                                        public void run() {
                                                                            joinToSoftAp();
                                                                        }
                                                                    });
                                                                }
                                                                else {
                                                                    MainActivity.this.dismiss();
                                                                    Toast.makeText(MainActivity.this, "Couldn't send credentials", Toast.LENGTH_LONG).show();
                                                                }
                                                            }
                                                        });
                                                    }
                                                    else {
                                                        MainActivity.this.dismiss();
                                                        Toast.makeText(MainActivity.this, "Couldn't get SoftAP device status.", Toast.LENGTH_LONG).show();
                                                    }
                                                }
                                            });
                                        }
                                        else {
                                            MainActivity.this.dismiss();
                                            Toast.makeText(MainActivity.this, "Couldn't get SoftAP device info.", Toast.LENGTH_LONG).show();
                                        }
                                    }
                                });
                            }
                            else {
                                LogService.sharedService().debug("Couldn't find SoftAp network. Trying Again");
                                findHandler.postDelayed(findRunnable, 2000);
                            }
                        }
                    });
                }
            };
            findHandler.post(findRunnable);
        }
    }

    class StepTwoListener implements View.OnClickListener {
        @Override
        public void onClick(View v) {
            connectToSoftAp();
        }

        public void joinToSoftAp(CirrentType.CREDENTIAL_RESPONSE response, ArrayList<String> credentials) {
            if (response == CirrentType.CREDENTIAL_RESPONSE.SUCCESS && credentials != null) {
                final long delay = 5000;
                invalidConnectHandler = new Handler();
                invalidConnectRunnable = new Runnable() {
                    @Override
                    public void run() {
                        CirrentService.sharedService().getDeviceJoiningSoftApStatus(new CompletionHandler() {
                            @Override
                            public void joiningCompletion(CirrentType.JOINING_STATUS status) {
                                if (status == CirrentType.JOINING_STATUS.FAILED || status == CirrentType.JOINING_STATUS.NOT_FOUND) {
                                    invalidConnectHandler.removeCallbacksAndMessages(null);
                                    boolean bFind = false;
                                    for (int i = 0; i < CirrentService.sharedService().model.getNetworks().size(); i++) {
                                        Network network = CirrentService.sharedService().model.getNetworks().get(i);
                                        if (network.ssid.compareTo(validSSID) == 0) {
                                            CirrentService.sharedService().model.selectedNetwork = network;
                                            bFind = true;
                                            break;
                                        }
                                    }
                                    CirrentService.sharedService().model.selectedNetworkPassword = validCred;
                                    if (bFind == false) {
                                        CirrentService.sharedService().model.selectedNetwork = CirrentService.sharedService().model.getNetworks().get(0);
                                    }

                                    MainActivity.this.show("Connect failed with invalid credentials. Put Valid Credential Now...");
                                    CirrentService.sharedService().putPrivateCredentials(null, new CompletionHandler() {
                                        @Override
                                        public void putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE response, ArrayList<String> credentials) {
                                            if (response == CirrentType.CREDENTIAL_RESPONSE.SUCCESS && credentials != null) {
                                                MainActivity.this.show("Checking for device joining status...");
                                                connectHandler = new Handler();
                                                connectRunnable = new Runnable() {
                                                    @Override
                                                    public void run() {
                                                        CirrentService.sharedService().getDeviceJoiningSoftApStatus(new CompletionHandler(){
                                                            @Override
                                                            public void joiningCompletion(CirrentType.JOINING_STATUS status) {
                                                                if (status == CirrentType.JOINING_STATUS.JOINED) {
                                                                    MainActivity.this.dismiss();
                                                                    connectHandler.removeCallbacksAndMessages(null);
                                                                    invalidConnectHandler.removeCallbacksAndMessages(null);
                                                                    Toast.makeText(MainActivity.this, "Success - device joined private network.", Toast.LENGTH_LONG).show();
                                                                    CirrentService.sharedService().forgetSoftApNetwork();
                                                                    LogService.sharedService().putLog(token);
                                                                }
                                                                else {
                                                                    connectHandler.postDelayed(connectRunnable, delay);
                                                                }
                                                            }
                                                        });
                                                    }
                                                };
                                                connectHandler.post(connectRunnable);
                                            }
                                            else {
                                                MainActivity.this.dismiss();
                                                Toast.makeText(MainActivity.this, "Couldn't put credentials", Toast.LENGTH_LONG).show();
                                            }
                                        }
                                    });
                                }
                                else if (status == CirrentType.JOINING_STATUS.JOINED) {
                                    MainActivity.this.dismiss();
                                    invalidConnectHandler.removeCallbacksAndMessages(null);
                                    Toast.makeText(MainActivity.this, "TEST 2 - passed - device joined private network", Toast.LENGTH_LONG).show();
                                    CirrentService.sharedService().forgetSoftApNetwork();
                                    LogService.sharedService().putLog(token);
                                }
                                else {
                                    invalidConnectHandler.postDelayed(invalidConnectRunnable, delay);
                                }
                            }
                        });
                    }
                };
                invalidConnectHandler.post(invalidConnectRunnable);
            }
            else {
                MainActivity.this.dismiss();
                Toast.makeText(MainActivity.this, "Couldn't put credentials", Toast.LENGTH_LONG).show();
            }
        }

        public void connectToSoftAp() {
            MainActivity.this.show("TEST 2 - Connecting To SoftAp network " + softApSSID + " ...");
            findHandler = new Handler();
            findRunnable = new Runnable() {
                @Override
                public void run() {
                    CirrentService.sharedService().connectToSoftApNetwork(new CompletionHandler() {
                        @Override
                        public void completion(CirrentType.RESPONSE response) {
                            if (response == CirrentType.RESPONSE.SUCCESS) {
                                MainActivity.this.show("Getting Device Info...");
                                LogService.sharedService().debug("Your phone is on softap network now");
                                findHandler.removeCallbacksAndMessages(null);
                                CirrentService.sharedService().getSoftApDeviceInfo(new CompletionHandler() {
                                    @Override
                                    public void softApCompletion(CirrentType.SOFTAP_RESPONSE response) {
                                        if (response == CirrentType.SOFTAP_RESPONSE.SUCCESS_WITH_SOFTAP) {
                                            MainActivity.this.show("Getting Device Status...");
                                            CirrentService.sharedService().getSoftApDeviceStatus(new CompletionHandler() {
                                                @Override
                                                public void softApCompletion(CirrentType.SOFTAP_RESPONSE response) {
                                                    if (response == CirrentType.SOFTAP_RESPONSE.SUCCESS_WITH_SOFTAP) {

                                                        CirrentService.sharedService().model.selectedNetwork = new Network();
                                                        CirrentService.sharedService().model.selectedNetwork.ssid = invalidSSID;
                                                        CirrentService.sharedService().model.selectedNetwork.flags = "WPA/WPA2-PSK";
                                                        CirrentService.sharedService().model.selectedNetworkPassword = invalidCred;
                                                        MainActivity.this.show("Put Invalid Credential...");
                                                        CirrentService.sharedService().putPrivateCredentials(null, new CompletionHandler() {
                                                            @Override
                                                            public void putCredentialCompletion(final CirrentType.CREDENTIAL_RESPONSE response, final ArrayList<String> credentials) {
                                                                runOnUiThread(new Runnable() {
                                                                    @Override
                                                                    public void run() {
                                                                        joinToSoftAp(response, credentials);
                                                                    }
                                                                });
                                                            }
                                                        });
                                                    }
                                                    else {
                                                        MainActivity.this.dismiss();
                                                        Toast.makeText(MainActivity.this, "Couldn't get SoftAP device status.", Toast.LENGTH_LONG).show();
                                                    }
                                                }
                                            });
                                        }
                                        else {
                                            MainActivity.this.dismiss();
                                            Toast.makeText(MainActivity.this, "Couldn't get SoftAP device info.", Toast.LENGTH_LONG).show();
                                        }
                                    }
                                });
                            }
                            else {
                                findHandler.post(findRunnable);
                                LogService.sharedService().debug("Couldn't find SoftAp network, Trying Again");
                                Toast.makeText(MainActivity.this, "Couldn't find SoftAp network, retrying ...", Toast.LENGTH_LONG).show();
                            }
                        }
                    });
                }
            };
            findHandler.post(findRunnable);
        }
    }

    class Completion {
        public void completed() {

        }

        public void completed(boolean bSuccess) {

        }
    }

    class StepThreeListener implements View.OnClickListener {
        long delayAfterConnect = 30000;
        Handler infoHandler;
        Runnable infoRunnable;

        long delayAfterInfo = 45000;
        Handler statusHandler;
        Runnable statusRunnable;

        long delayAfterStatus = 15000;
        Handler credHandler;
        Runnable credRunnable;

        long delayAfterFail = 120000;

        @Override
        public void onClick(View v) {
            connectToSoftAp(new Completion(){
                @Override
                public void completed() {
                    getDeviceInfo(new Completion(){
                        @Override

                        public void completed(boolean bSuccess) {
                            if (bSuccess == true) {
                                getDeviceStatus(new Completion(){
                                    @Override

                                    public void completed(boolean bSuccess) {
                                        if (bSuccess == true) {

                                            putCredential(false, delayAfterStatus, new Completion() {
                                                @Override

                                                public void completed(boolean bSuccess) {
                                                    if (bSuccess == true) {
                                                        getJoiningStatus(new Completion(){
                                                            @Override
                                                            public void completed(boolean bSuccess) {
                                                                if (bSuccess == true) {
                                                                    CirrentService.sharedService().forgetSoftApNetwork();
                                                                    LogService.sharedService().putLog(token);
                                                                    MainActivity.this.dismiss();
                                                                }
                                                                else {
                                                                    MainActivity.this.show("TEST 3 - wait 120 seconds");

                                                                    putCredential(true, delayAfterFail, new Completion(){
                                                                        @Override

                                                                        public void completed(boolean bSuccess) {
                                                                            if (bSuccess == true) {
                                                                                getJoiningStatus(new Completion(){
                                                                                    @Override
                                                                                    public void completed(boolean bSuccess) {
                                                                                        if (bSuccess == true) {
                                                                                            Toast.makeText(MainActivity.this, "TEST 3 PASSED", Toast.LENGTH_LONG).show();

                                                                                            CirrentService.sharedService().forgetSoftApNetwork();
                                                                                            LogService.sharedService().putLog(token);
                                                                                            MainActivity.this.dismiss();
                                                                                        }
                                                                                    }
                                                                                });
                                                                            }
                                                                        }
                                                                    });
                                                                }
                                                            }
                                                        });
                                                    }
                                                }
                                            });
                                        }
                                    }
                                });
                            }
                        }
                    });
                }
            });
        }

        public void connectToSoftAp(final Completion completion) {
            MainActivity.this.show("TEST 3 - Connecting to SoftAP network " + softApSSID + " ...");
            connectHandler = new Handler();
            connectRunnable = new Runnable() {
                @Override
                public void run() {
                    CirrentService.sharedService().connectToSoftApNetwork(new CompletionHandler() {
                        @Override
                        public void completion(CirrentType.RESPONSE response) {
                            if (response == CirrentType.RESPONSE.SUCCESS) {
                                connectHandler.removeCallbacksAndMessages(null);
                                Toast.makeText(MainActivity.this, "Your Phone is on SoftAP network", Toast.LENGTH_LONG).show();
                                completion.completed();
                            }
                            else {
                                Toast.makeText(MainActivity.this, "Failed to connect SoftAP network. Trying again", Toast.LENGTH_LONG).show();
                                connectHandler.post(connectRunnable);
                            }
                        }
                    });
                }
            };

            connectHandler.post(connectRunnable);
        }

        public void getDeviceInfo(final Completion completion) {
            MainActivity.this.show("Waiting 30 Seconds before getting device info...");

            infoHandler = new Handler();
            infoRunnable = new Runnable() {
                @Override
                public void run() {
                    if (checkSoftAP() == true) {
                        MainActivity.this.show("Getting Device Info...");
                        CirrentService.sharedService().getSoftApDeviceInfo(new CompletionHandler() {
                            @Override
                            public void softApCompletion(CirrentType.SOFTAP_RESPONSE response) {
                                if (response == CirrentType.SOFTAP_RESPONSE.SUCCESS_WITH_SOFTAP) {
                                    completion.completed(true);
                                }
                                else {
                                    MainActivity.this.dismiss();
                                    Toast.makeText(MainActivity.this, "Failed Getting Device Info", Toast.LENGTH_LONG).show();
                                    completion.completed(false);
                                }
                            }
                        });
                    }
                    else {
                        Toast.makeText(MainActivity.this, "Fell Off SoftAP network", Toast.LENGTH_LONG).show();

                        connectToSoftAp(new Completion(){
                            @Override
                            public void completed() {
                                MainActivity.this.show("Getting Device Info...");
                                CirrentService.sharedService().getSoftApDeviceInfo(new CompletionHandler() {
                                    @Override
                                    public void softApCompletion(CirrentType.SOFTAP_RESPONSE response) {
                                        if (response == CirrentType.SOFTAP_RESPONSE.SUCCESS_WITH_SOFTAP) {
                                            Toast.makeText(MainActivity.this, "Got Device Info", Toast.LENGTH_LONG).show();
                                            completion.completed(true);
                                        }
                                        else {
                                            MainActivity.this.dismiss();
                                            Toast.makeText(MainActivity.this, "Failed to get Device Info", Toast.LENGTH_LONG).show();
                                            completion.completed(false);
                                        }
                                    }
                                });
                            }
                        });
                    }
                }
            };
            infoHandler.postDelayed(infoRunnable, delayAfterConnect);
        }

        public boolean checkSoftAP() {
            String ssid = CirrentService.sharedService().getCurrentSSID();
            if (ssid != null && ssid.contains(CirrentService.sharedService().getSoftApSSID()) == true) {
                return true;
            }

            return false;
        }

        public void getDeviceStatus(final Completion completion) {
            MainActivity.this.show("Waiting 45 Seconds to get device status...");
            statusHandler = new Handler();
            statusRunnable = new Runnable() {
                @Override
                public void run() {
                    if (checkSoftAP() == true) {
                        MainActivity.this.show("Getting Device Status...");
                        CirrentService.sharedService().getSoftApDeviceStatus(new CompletionHandler(){
                            @Override
                            public void softApCompletion(CirrentType.SOFTAP_RESPONSE response) {
                                if (response == CirrentType.SOFTAP_RESPONSE.SUCCESS_WITH_SOFTAP) {
                                    Toast.makeText(MainActivity.this, "Got Device Status.", Toast.LENGTH_LONG).show();
                                    completion.completed(true);
                                }
                                else {
                                    MainActivity.this.dismiss();
                                    completion.completed(false);
                                }
                            }
                        });
                    }
                    else {
                        Toast.makeText(MainActivity.this, "Fall Off SoftAP network", Toast.LENGTH_LONG).show();
                        connectToSoftAp(new Completion(){
                            @Override
                            public void completed() {
                                MainActivity.this.show("Getting Device Status...");
                                CirrentService.sharedService().getSoftApDeviceStatus(new CompletionHandler(){
                                    @Override
                                    public void softApCompletion(CirrentType.SOFTAP_RESPONSE response) {
                                        if (response == CirrentType.SOFTAP_RESPONSE.SUCCESS_WITH_SOFTAP) {
                                            Toast.makeText(MainActivity.this, "Got Device Status.", Toast.LENGTH_LONG).show();
                                            completion.completed(true);
                                        }
                                        else {
                                            MainActivity.this.dismiss();
                                            Toast.makeText(MainActivity.this, "Failed Getting Device Status.", Toast.LENGTH_LONG).show();
                                            completion.completed(false);
                                        }
                                    }
                                });
                            }
                        });
                    }
                }
            };
            statusHandler.postDelayed(statusRunnable, delayAfterInfo);
        }

        public void putCredential(final boolean bValid, long delay, final Completion completion) {
            MainActivity.this.show("Waiting " + delay/1000 + " Seconds to get device status...");
            credHandler = new Handler();
            credRunnable = new Runnable() {
                @Override
                public void run() {

                    if (bValid == true) {
                        CirrentService.sharedService().model.selectedNetworkPassword = validCred;
                        boolean bFind = false;
                        for (int i = 0; i < CirrentService.sharedService().model.getNetworks().size(); i++) {
                            Network network = CirrentService.sharedService().model.getNetworks().get(i);
                            if (network.ssid.compareTo(validSSID) == 0) {
                                CirrentService.sharedService().model.selectedNetwork = network;
                                bFind = true;
                                break;
                            }
                        }
                        if (bFind == false) {
                            CirrentService.sharedService().model.selectedNetwork = CirrentService.sharedService().model.getNetworks().get(0);
                        }
                    }
                    else {
                        CirrentService.sharedService().model.selectedNetworkPassword = invalidCred;
                        CirrentService.sharedService().model.selectedNetwork = new Network();
                        CirrentService.sharedService().model.selectedNetwork.ssid = invalidSSID;
                        CirrentService.sharedService().model.selectedNetwork.flags = "WPA/WPA2-PSK";
                        CirrentService.sharedService().model.selectedNetworkPassword = invalidCred;
                    }

                    if (checkSoftAP() == true) {
                        CirrentService.sharedService().putPrivateCredentials(null, new CompletionHandler(){
                            @Override
                            public void putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE response, ArrayList<String> credentials) {
                                if (response == CirrentType.CREDENTIAL_RESPONSE.SUCCESS && credentials != null) {
                                    Toast.makeText(MainActivity.this, "Successfully put Credential.", Toast.LENGTH_LONG).show();
                                    completion.completed(true);
                                }
                                else {
                                    MainActivity.this.dismiss();
                                    Toast.makeText(MainActivity.this, "Failed to put Credential.", Toast.LENGTH_LONG).show();
                                    completion.completed(false);
                                }
                            }
                        });
                    }
                    else {
                        Toast.makeText(MainActivity.this, "Fall Off SoftAP network", Toast.LENGTH_LONG).show();
                        connectToSoftAp(new Completion(){
                            @Override
                            public void completed() {
                                CirrentService.sharedService().putPrivateCredentials(null, new CompletionHandler(){
                                    @Override
                                    public void putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE response, ArrayList<String> credentials) {
                                        if (response == CirrentType.CREDENTIAL_RESPONSE.SUCCESS && credentials != null) {
                                            Toast.makeText(MainActivity.this, "Successfully put Credential.", Toast.LENGTH_LONG).show();
                                            completion.completed(true);
                                        }
                                        else {
                                            MainActivity.this.dismiss();
                                            Toast.makeText(MainActivity.this, "Failed to put Credential.", Toast.LENGTH_LONG).show();
                                            completion.completed(false);
                                        }
                                    }
                                });
                            }
                        });
                    }
                }
            };
            credHandler.postDelayed(credRunnable, delay);
        }

        Handler joiningHandler;
        Runnable joiningRunnable;
        long joiningDelay = 5000;
        public void getJoiningStatus(final Completion completion) {
            joiningHandler = new Handler();
            joiningRunnable = new Runnable() {
                @Override
                public void run() {
                    CirrentService.sharedService().getDeviceJoiningSoftApStatus(new CompletionHandler(){
                        @Override
                        public void joiningCompletion(CirrentType.JOINING_STATUS status) {
                            if (status == CirrentType.JOINING_STATUS.JOINED) {
                                joiningHandler.removeCallbacksAndMessages(null);
                                Toast.makeText(MainActivity.this, "TEST 3 - passed - Connected to private network.", Toast.LENGTH_LONG);
                                completion.completed(true);
                            }
                            else if (status == CirrentType.JOINING_STATUS.FAILED || status == CirrentType.JOINING_STATUS.NOT_FOUND) {
                                joiningHandler.removeCallbacksAndMessages(null);
                                Toast.makeText(MainActivity.this, "TEST 3 - FAIL!!! device did not join private network.", Toast.LENGTH_LONG);
                                completion.completed(false);
                            }
                            else {
                                joiningHandler.postDelayed(joiningRunnable, joiningDelay);
                            }
                        }
                    });
                }
            };
            joiningHandler.post(joiningRunnable);
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        CirrentService.sharedService().setContext(this);
        CirrentService.sharedService().setSoftApSSID(softApSSID);
        CirrentService.sharedService().supportSoftAp(true);

        Button step1 = (Button) findViewById(R.id.step1);
        Button step2 = (Button) findViewById(R.id.step2);
        Button step3 = (Button) findViewById(R.id.step3);

        step1.setOnClickListener(new StepOneListener());
        step2.setOnClickListener(new StepTwoListener());
        step3.setOnClickListener(new StepThreeListener());
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
        if (mProgressDialog != null && mProgressDialog.isShowing() == true) {
            mProgressDialog.dismiss();
            mProgressDialog = null;
        }
    }
}
