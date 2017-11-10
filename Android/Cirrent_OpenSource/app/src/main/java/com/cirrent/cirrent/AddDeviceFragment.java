package com.cirrent.cirrent;

import android.os.Bundle;
import android.os.Handler;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.TextView;

import com.cirrent.cirrentsdk.CirrentService;
import com.cirrent.cirrentsdk.CirrentType;
import com.cirrent.cirrentsdk.CompletionHandler;
import com.cirrent.cirrentsdk.Device;
import java.util.ArrayList;

public class AddDeviceFragment extends Fragment {

    View rootView;
    TextView currentNetworkView;

    public AddDeviceFragment() {

    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        rootView = inflater.inflate(R.layout.adddevice_layout, container, false);

        currentNetworkView = (TextView) rootView.findViewById(R.id.current_network);
        currentNetworkView.setVisibility(View.INVISIBLE);

        CirrentService.sharedService().setOwnerIdentifier(SampleCloudService.sharedService().ownerID);

        ImageButton addButton = (ImageButton) rootView.findViewById(R.id.addDevice);
        addButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                MainActivity.softAPBeforeSSID = CirrentService.sharedService().getCurrentSSID();
                ProgressView.sharedView().show(getContext(), "Finding nearby devices...");
                CirrentService.sharedService().findDevice(SampleCloudService.sharedService(), new CompletionHandler(){
                    @Override
                    public void findDeviceCompletion(CirrentType.FIND_DEVICE_RESULT result, ArrayList<Device> devices) {
                        ProgressView.sharedView().dismiss();
                        if (result == CirrentType.FIND_DEVICE_RESULT.SUCCESS) {
                            ArrayList<String> deviceIDs = new ArrayList<String>();
                            for (int i = 0; i < devices.size(); i++) {
                                Device device = devices.get(i);
                                deviceIDs.add(device.getDeviceId());
                            }

                            MainActivity.currentActivity.showScreen(MainActivity.SCREEN.SELECT_DEVICE);
                        }
                        else if (result == CirrentType.FIND_DEVICE_RESULT.FAILED_LOCATION_DISABLED) {
                            ProgressView.sharedView().showToast(getContext(), "Location Service should be enabled. Please enable location services.");
                        }
                        else if (result == CirrentType.FIND_DEVICE_RESULT.FAILED_LOCATION_NOT_PERMITTED) {
                            ProgressView.sharedView().showToast(getContext(), "You don't allow to use location service, Please allow this app to use location service.");
                        }
                        else if (result == CirrentType.FIND_DEVICE_RESULT.FAILED_NETWORK_OFFLINE) {
                            ProgressView.sharedView().showToast(getContext(), "You need to be online to set up your device. Please connect your phone.");
                        }
                        else {
                            ProgressView.sharedView().showToast(getContext(), "Sorry. We couldn't find your device yet, Let's try another approach.");
                            Handler handler = new Handler();
                            Runnable runnable = new Runnable() {
                                @Override
                                public void run() {
                                    goWithSoftAP();
                                }
                            };

                            long delay = 1000;
                            handler.postDelayed(runnable, delay);
                        }
                    }
                });
            }
        });

        CirrentService.sharedService().forgetSoftAPNetwork();
        return rootView;
    }

    void goWithSoftAP() {
        MainActivity.softAPBeforeSSID = CirrentService.sharedService().getCurrentSSID();
        ProgressView.sharedView().show(getContext(), "Contacting your device over SoftAP network...");
        CirrentService.sharedService().connectToSoftAPNetwork(new CompletionHandler(){
            @Override
            public void completion(CirrentType.RESPONSE response) {
                if (response == CirrentType.RESPONSE.SUCCESS) {
                    CirrentService.sharedService().processSoftAP(new CompletionHandler(){
                        @Override
                        public void softAPCompletion(CirrentType.SOFTAP_RESPONSE response) {
                            switch (response) {
                                case SUCCESS_WITH_SOFTAP:
                                    ProgressView.sharedView().dismiss();
                                    MainActivity.currentActivity.showScreen(MainActivity.SCREEN.CONNECT);
                                    break;
                                case FAILED_NOT_GET_SOFTAP_IP:
                                case FAILED_NOT_SOFTAP_SSID:
                                case FAILED_SOFTAP_INVALID_STATUS:
                                case FAILED_SOFTAP_NO_RESPONSE:
                                    ProgressView.sharedView().dismiss();
                                    ProgressView.sharedView().showToast(getContext(), "Failed to connect to your device's SoftAP network");
                                    break;
                            }
                        }
                    });
                }
                else {
                    ProgressView.sharedView().dismiss();
                    ProgressView.sharedView().showToast(getContext(), "Sorry. We couldn't find any SoftAP network.");
                }
            }
        });
    }
}
