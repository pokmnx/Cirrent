package com.cirrent.cirrent;

import android.os.Bundle;
import android.os.Handler;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.TextView;

import com.cirrent.cirrentsdk.CirrentService;
import com.cirrent.cirrentsdk.CirrentType;
import com.cirrent.cirrentsdk.CompletionHandler;
import com.cirrent.cirrentsdk.Device;
import com.cirrent.cirrentsdk.LogService;
import com.cirrent.cirrentsdk.Network;
import com.cirrent.cirrentsdk.ProviderKnownNetwork;
import com.squareup.picasso.Picasso;

import java.util.ArrayList;

public class SetupDeviceFragment extends Fragment {

    View rootView;
    Device device;


    public SetupDeviceFragment() {

    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        rootView = inflater.inflate(R.layout.connectdetail_layout, container, false);

        ImageView deviceImageView = (ImageView) rootView.findViewById(R.id.deviceImageView);
        TextView deviceNameView = (TextView) rootView.findViewById(R.id.deviceName);
        FrameLayout autoGroupLayout = (FrameLayout) rootView.findViewById(R.id.connectAutoGroup);

        Button connectAutoButton = (Button) rootView.findViewById(R.id.connectAutoButton);
        ImageView providerImageView = (ImageView) rootView.findViewById(R.id.providerImageView);
        TextView connectAutoTextView = (TextView) rootView.findViewById(R.id.autoconnectlabel);

        TextView orTextView = (TextView) rootView.findViewById(R.id.or_textview);
        Button connectManualButton = (Button) rootView.findViewById(R.id.connectManualButton);

        device = CirrentService.sharedService().model.getSelectedDevice();
        if (device == null) {
            return rootView;
        }

        deviceNameView.setText(device.getDeviceId());
        Picasso.with(MainActivity.currentActivity).load(device.getImageURL()).into(deviceImageView);

        ProviderKnownNetwork provider = CirrentService.sharedService().model.getProviderNetwork();
        boolean bAutoGo = true;

//hide provider view
        autoGroupLayout.setVisibility(View.INVISIBLE);
        connectAutoButton.setVisibility(View.INVISIBLE);
        connectAutoTextView.setVisibility(View.INVISIBLE);
        orTextView.setVisibility(View.INVISIBLE);
        connectManualButton.setVisibility(View.INVISIBLE);
        providerImageView.setVisibility(View.INVISIBLE);
//

        if (provider != null) {
            boolean bFind = false;
            if (CirrentService.sharedService().model.getSSID() != null) {
                String logStr = String.format("Trying to match. %s, %s", provider.getSsid(), CirrentService.sharedService().model.getSSID());
                LogService.sharedService().debug(logStr);
            }

            if (CirrentService.sharedService().model.getSSID() != null && provider.getSsid().compareTo(CirrentService.sharedService().model.getSSID()) == 0) {
                LogService.sharedService().debug("Yay!! We have a match. " + provider.getSsid());
                LogService.sharedService().debug("Setting the provider in found device " + provider.getProviderName());

                if (CirrentService.sharedService().model.getSSID() != null && provider.getSsid().compareTo(CirrentService.sharedService().model.getSSID()) == 0) {
                    if (provider.getProviderLogo() != null && provider.getProviderLogo().length() > 0) {
                        Picasso.with(MainActivity.currentActivity).load(provider.getProviderLogo()).into(providerImageView);
                    }
                }

                String ssid = CirrentService.sharedService().model.getSSID();
                String buttonText = String.format("Connect Automatically to %s with", ssid);
                connectAutoTextView.setText(buttonText);
                CirrentService.sharedService().model.setSelectedProvider(provider);
                bFind = true;
                bAutoGo = false;

//show proviview
                autoGroupLayout.setVisibility(View.VISIBLE);
                connectAutoButton.setVisibility(View.VISIBLE);
                connectAutoTextView.setVisibility(View.VISIBLE);
                orTextView.setVisibility(View.VISIBLE);
                connectManualButton.setVisibility(View.VISIBLE);
                providerImageView.setVisibility(View.VISIBLE);
//

                connectAutoButton.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        if (CirrentService.sharedService().model.getSelectedProvider() != null) {
                            ProgressView.sharedView().show(getContext());
                            String providerUUID = CirrentService.sharedService().model.getSelectedProvider().getProviderUUID();
                            String deviceID = CirrentService.sharedService().model.getSelectedDevice().getDeviceId();
                            CirrentService.sharedService().putProviderCredentials(SampleCloudService.sharedService(), deviceID, providerUUID, new CompletionHandler(){
                                @Override
                                public void putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE response, ArrayList<String> credentials) {
                                    if (response != CirrentType.CREDENTIAL_RESPONSE.SUCCESS) {
                                        LogService.sharedService().debug("Unable to put provider network, sending to local wifi.");
                                        ProgressView.sharedView().showToast(getContext(), "Unable to put provider network, sending to local wifi.");
                                        Handler handler = new Handler();
                                        long delay = 3000;
                                        handler.postDelayed(new Runnable() {
                                            @Override
                                            public void run() {
                                                MainActivity.currentActivity.showScreen(MainActivity.SCREEN.CONNECT);
                                            }
                                        }, delay);
                                    }
                                    else {
                                        String providerSSID = CirrentService.sharedService().model.getSelectedProvider().getSsid();
                                        String providerName = CirrentService.sharedService().model.getSelectedProvider().getProviderName();

                                        CirrentService.sharedService().model.setCredentialId(credentials.get(0));
                                        CirrentService.sharedService().model.setSelectedNetwork(new Network());
                                        CirrentService.sharedService().model.getSelectedNetwork().setSSID(providerSSID);
                                        CirrentService.sharedService().model.setProviderName(providerName);

                                        String logStr = String.format("ssid=%s;provider=%s", providerSSID, providerName);
                                        LogService.sharedService().log(LogService.Event.PROVIDER_CREDS, logStr);
                                        LogService.sharedService().putLog(SampleCloudService.sharedService().manage_token);

                                        MainActivity.currentActivity.showScreen(MainActivity.SCREEN.PROGRESSING);
                                    }
                                }
                            });
                        }
                    }
                });

                connectManualButton.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        MainActivity.currentActivity.showScreen(MainActivity.SCREEN.CONNECT);
                    }
                });
            }

            if (bFind == false) {
                LogService.sharedService().debug("No provider network. Showing the user we found their device!");
                bAutoGo = true;
            }
        }
        else {
            LogService.sharedService().debug("No provider network. Showing the user we found their device!");
            bAutoGo = true;
        }

        if (bAutoGo == true) {
            if (device.getProviderAttribution() != null && device.getProviderAttribution().length() > 0 && device.getProviderAttributionLogo() != null && device.getProviderAttributionLogo().length() > 0) {
                MainActivity.currentActivity.showScreen(MainActivity.SCREEN.CONNECT);
            }
            else {
                long nextScreenDelay = 3000;
                ProgressView.sharedView().show(getContext(), "Setting Up Your Device...");
                final Handler handler = new Handler();
                handler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        ProgressView.sharedView().dismiss();
                        MainActivity.currentActivity.showScreen(MainActivity.SCREEN.CONNECT);
                    }
                }, nextScreenDelay);
            }
        }

        return rootView;
    }

}
