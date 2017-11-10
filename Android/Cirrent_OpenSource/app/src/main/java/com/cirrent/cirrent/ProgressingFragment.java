package com.cirrent.cirrent;

import android.os.Bundle;
import android.os.Handler;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import com.cirrent.cirrentsdk.CirrentService;
import com.cirrent.cirrentsdk.CirrentType;
import com.cirrent.cirrentsdk.CompletionHandler;
import com.cirrent.cirrentsdk.Device;
import com.cirrent.cirrentsdk.LogService;
import com.squareup.picasso.Picasso;


public class ProgressingFragment extends Fragment {

    private View rootView = null;
    ImageView deviceImageView;
    TextView networkNameView;
    ImageView providerImageView;
    MainActivity.SCREEN previousScreen;

    public ProgressingFragment() {

    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        rootView = inflater.inflate(R.layout.progressing_layout, container, false);

        deviceImageView = (ImageView) rootView.findViewById(R.id.device_imageView);
        networkNameView = (TextView) rootView.findViewById(R.id.network_name);
        providerImageView = (ImageView) rootView.findViewById(R.id.provider_imageview);

        setDeviceAndProviderImageView();
        getDeviceJoiningStatus();

        return rootView;
    }

    void setDeviceAndProviderImageView() {
        String logStr;
        if (CirrentService.sharedService().model.getProviderName() != null) {
            logStr = String.format("Connecting Screen: provider name: %s", CirrentService.sharedService().model.getProviderName());
            LogService.sharedService().debug(logStr);
        }

        if (CirrentService.sharedService().model.getZipkeyhotspot() != null) {
            logStr = String.format("Connecting Screen: device zipkey hotspot?: %s", CirrentService.sharedService().model.getZipkeyhotspot());
            LogService.sharedService().debug(logStr);
        }

        if (CirrentService.sharedService().model.getSelectedNetwork() != null) {
            networkNameView.setText(CirrentService.sharedService().model.getSelectedNetwork().getSSID());
        }

        providerImageView.setVisibility(View.INVISIBLE);

        String url = CirrentService.sharedService().model.getSelectedDevice().getImageURL();
        if (url != null) {
            Picasso.with(MainActivity.currentActivity).load(url).into(deviceImageView);
        }

        if (CirrentService.sharedService().model.getSelectedProvider() != null) {
            providerImageView.setVisibility(View.VISIBLE);
            String providerLogo = CirrentService.sharedService().model.getSelectedProvider().getProviderLogo();
            if (providerLogo != null) {
                Picasso.with(MainActivity.currentActivity).load(providerLogo).into(providerImageView);
            }
        }
        else {
            Device device = CirrentService.sharedService().model.getSelectedDevice();
            if (device.getProviderAttribution() != null && device.getProviderAttributionLogo() != null && device.getProviderAttribution().length() > 0 && device.getProviderAttributionLogo().length() > 0) {
                providerImageView.setVisibility(View.VISIBLE);
                Picasso.with(MainActivity.currentActivity).load(device.getProviderAttributionLogo()).into(providerImageView);
            }
        }
    }

    void moveToProperScreen(final MainActivity.SCREEN screen) {
        Handler handler = new Handler();
        long delayToNewScreen = 1000;
        handler.postDelayed(new Runnable() {
            @Override
            public void run() {
                MainActivity.currentActivity.showScreen(screen);
            }
        }, delayToNewScreen);
    }

    void getDeviceJoiningStatus() {
        String message = String.format("Contacting your device...\nConnecting to %s", CirrentService.sharedService().model.getSelectedNetwork().getSSID());
        Device device = CirrentService.sharedService().model.getSelectedDevice();

        if (CirrentService.sharedService().model.getSelectedProvider() != null) {
            message = String.format("Connecting to %s using", CirrentService.sharedService().model.getSelectedNetwork().getSSID());
        }
        else {
            if (device.getProviderAttribution() != null && device.getProviderAttributionLogo() != null && device.getProviderAttribution().length() > 0 && device.getProviderAttributionLogo().length() > 0) {
                String deviceID = device.getDeviceId();
                String providerAttribution = device.getProviderAttribution();
                message = String.format("Connecting %s to your network via an %s Hotspot", deviceID, providerAttribution);
            }
        }

        String deviceID = CirrentService.sharedService().model.getSelectedDevice().getDeviceId();
        ProgressView.sharedView().show(getContext(), message);
        CirrentService.sharedService().getDeviceJoiningStatus(SampleCloudService.sharedService(), deviceID, new CompletionHandler(){
            @Override
            public void joiningCompletion(CirrentType.JOINING_STATUS status) {
                switch (status) {
                    case JOINED:
                        LogService.sharedService().putLog(SampleCloudService.sharedService().manage_token);
                        ProgressView.sharedView().showToast(getContext(), "Device is connected");
                        moveToProperScreen(MainActivity.SCREEN.SUCCESS);
                        break;
                    case RECEIVED_CREDS:
                        ProgressView.sharedView().show(getContext(), "Connecting device to your network");
                        break;
                    case ATTEMPTING_TO_JOIN:
                        ProgressView.sharedView().show(getContext(), "Attempting to join");
                        break;
                    case OPTIMIZING_CONNECTION:
                        ProgressView.sharedView().show(getContext(), "Checking connectivity...");
                        break;
                    case TIMED_OUT:
                    case TIMED_OUT_TRIED_API:
                        LogService.sharedService().putLog(SampleCloudService.sharedService().manage_token);
                        ProgressView.sharedView().showToast(getContext(), "Let's try again.");
                        moveToProperScreen(MainActivity.SCREEN.ADD_DEVICE);
                        break;
                    case GET_DEVICE_STATUS_FAILED:
                    case FAILED_INVALID_STATUS:
                    case FAILED_INVALID_TOKEN:
                    case SELECTED_DEVICE_NIL:
                    case FAILED_NO_RESPONSE:
                    case FAILED:
                        LogService.sharedService().putLog(SampleCloudService.sharedService().manage_token);
                        ProgressView.sharedView().showToast(getContext(), "Device failed to join. Let's try again.");
                        moveToProperScreen(previousScreen);
                        break;
                    case NOT_SOFTAP_NETWORK:
                        checkStatusFromCloud();
                        break;
                }
            }
        });
    }

    void checkStatusFromCloud() {
/*
        final Device device = CirrentService.sharedService().model.selectedDevice;
        ArrayList<String> deviceIDs = new ArrayList<String>();
        deviceIDs.add(device.deviceId);
        SampleCloudService.sharedService().getToken(SampleCloudService.MANAGE_TOKEN_SCOPE, deviceIDs, new CompletionHandler(){
            @Override
            public void completion(CirrentType.RESPONSE response) {
                if (response != CirrentType.RESPONSE.SUCCESS) {
                    String message = String.format("Please put your phone back on %s Network", CirrentService.sharedService().getSoftAPSSID());
                    ProgressView.sharedView().showToast(getContext(), message);
                    moveToProperScreen(MainActivity.SCREEN.ADD_DEVICE);
                }
                else {
                    CirrentService.sharedService().getDeviceStatus(SampleCloudService.sharedService().manage_token, device, new CompletionHandler(){
                        @Override
                        public void getStatusCompletion(CirrentType.RESPONSE response, JSONObject status) {
                            if (response != CirrentType.RESPONSE.SUCCESS) {
                                String message = String.format("Please put your phone back on %s Network", CirrentService.sharedService().getSoftAPSSID());
                                ProgressView.sharedView().showToast(getContext(), message);
                                moveToProperScreen(MainActivity.SCREEN.ADD_DEVICE);
                            }
                            else {
                                try {
                                    JSONArray knownNetworks = status.getJSONArray("known_networks");
                                    for (int i = 0; i < knownNetworks.length(); i++) {
                                        JSONObject network = knownNetworks.getJSONObject(i);
                                        if (network == null) continue;

                                        String net_status = network.getString("status");
                                        if (net_status != null && net_status.compareTo("JOINED") == 0) {
                                            String ssid = network.getString("ssid");
                                            ProgressView.sharedView().showToast(getContext(), "Device is already joined to " + ssid);
                                            return;
                                        }
                                    }

                                    for (int i = 0; i < knownNetworks.length(); i++) {
                                        JSONObject network = knownNetworks.getJSONObject(i);
                                        if (network == null) continue;

                                        String net_status = network.getString("status");
                                        if (net_status != null && net_status.compareTo("FAILED") == 0) {
                                            ProgressView.sharedView().showToast(getContext(), "Device failed to join. Let's try again.");
                                            moveToProperScreen(previousScreen);
                                            return;
                                        }
                                    }
                                }
                                catch (JSONException e) {
                                    e.printStackTrace();
                                }
                            }
                        }
                    });
                }
            }
        });
*/
    }
}
