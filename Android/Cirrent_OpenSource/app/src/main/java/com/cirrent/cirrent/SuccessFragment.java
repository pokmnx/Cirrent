package com.cirrent.cirrent;

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import com.cirrent.cirrentsdk.CirrentService;
import com.cirrent.cirrentsdk.Device;
import com.cirrent.cirrentsdk.LogService;
import com.squareup.picasso.Picasso;

public class SuccessFragment extends Fragment {

    private View rootView = null;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        rootView = inflater.inflate(R.layout.success_layout, container, false);

        MainActivity.currentActivity.currentContext = getContext();

        ImageView providerImageView = (ImageView) rootView.findViewById(R.id.providerimage);
        TextView connectedTextView = (TextView) rootView.findViewById(R.id.connected_label);
        TextView learnMoreTextView = (TextView) rootView.findViewById(R.id.learn_more_url);

        String deviceID = CirrentService.sharedService().model.getSelectedDevice().getDeviceId();
        String ssid = CirrentService.sharedService().model.getSelectedNetwork().getSSID();

        String logStr = "Type=";
        learnMoreTextView.setVisibility(View.INVISIBLE);

        if (CirrentService.sharedService().model.getSelectedProvider() != null) {
            providerImageView.setVisibility(View.VISIBLE);
            String providerSSID = CirrentService.sharedService().model.getSelectedProvider().getProviderName();
            Picasso.with(MainActivity.currentActivity).load(CirrentService.sharedService().model.getSelectedProvider().getProviderLogo()).into(providerImageView);
            String message = String.format("Your %s is now connected to your private, secure %s network: %s", deviceID, providerSSID, ssid);
            connectedTextView.setText(message);
            logStr += "PROVIDER";
        }
        else {
            providerImageView.setVisibility(View.INVISIBLE);
            Device device = CirrentService.sharedService().model.getSelectedDevice();

            if (device.getProviderAttribution() != null && device.getProviderAttribution().length() > 0) {
                String providerAttribution = device.getProviderAttribution();
                String connectedSSID = CirrentService.sharedService().model.getSelectedNetwork().getSSID();
                String message = String.format("An %s Hotspot was used to accelerate your connection to %s", providerAttribution, connectedSSID);
                connectedTextView.setText(message);

                if (device.getProviderAttributionLogo() != null && device.getProviderAttributionLogo().length() > 0) {
                    providerImageView.setVisibility(View.VISIBLE);
                    Picasso.with(MainActivity.currentActivity).load(device.getProviderAttributionLogo()).into(providerImageView);
                }

                if (device.getProviderAttributionLearnMoreURL() != null && device.getProviderAttributionLearnMoreURL().length() > 0) {
                    learnMoreTextView.setVisibility(View.VISIBLE);
                    learnMoreTextView.setText(device.getProviderAttributionLearnMoreURL());
                }
            }
            else {
                String message = String.format("Your %s is now connected to your private network: %s", deviceID, ssid);
                connectedTextView.setText(message);
            }

            if (CirrentService.sharedService().isOnZipKeyNetwork() == false) {
                logStr += "USER-CREDS";
            }
            else {
                logStr += "SOFTAP";
            }
        }

        LogService.sharedService().log(LogService.Event.SUCCESS, logStr);

        String token;
        if (SampleCloudService.sharedService().manage_token != null)
            token = SampleCloudService.sharedService().manage_token;
        else if (SampleCloudService.sharedService().search_token != null)
            token = SampleCloudService.sharedService().search_token;
        else
            token = SampleCloudService.sharedService().bind_token;

        LogService.sharedService().putLog(token);

        return rootView;
    }
}
