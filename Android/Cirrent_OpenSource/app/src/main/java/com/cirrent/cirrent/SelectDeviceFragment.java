package com.cirrent.cirrent;

import android.app.Activity;
import android.content.Context;
import android.content.DialogInterface;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v7.app.AlertDialog;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.InputMethodManager;
import android.widget.AdapterView;
import android.widget.BaseAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.ListView;
import com.cirrent.cirrentsdk.CirrentService;
import com.cirrent.cirrentsdk.CirrentType;
import com.cirrent.cirrentsdk.CompletionHandler;
import com.cirrent.cirrentsdk.Device;
import com.squareup.picasso.Picasso;

import org.json.JSONObject;

import java.util.ArrayList;


public class SelectDeviceFragment extends Fragment {

    public class DeviceAdapter extends BaseAdapter {
        private Context mContext;
        private LayoutInflater mInflater;
        private ArrayList<Device> mDataSource;

        public DeviceAdapter(Context context, ArrayList<Device> items) {
            mContext = context;
            mDataSource = items;
            mInflater = (LayoutInflater) mContext.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        }

        @Override
        public int getCount() {
            return mDataSource.size();
        }

        @Override
        public Object getItem(int position) {
            return mDataSource.get(position);
        }

        @Override
        public long getItemId(int position) {
            return position;
        }

        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            // Get view for row item
            final Device device = (Device) getItem(position);
            View rowView;

            if (device.isIdentifyingActionEnabled() == true) {
                rowView = mInflater.inflate(R.layout.devicecell_identify_action, parent, false);
                Button identifyActionButton = (Button) rowView.findViewById(R.id.identify_youself_button);

                identifyActionButton.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View view) {
                        CirrentService.sharedService().identifyYourself(SampleCloudService.sharedService(), device.getDeviceId(), new CompletionHandler(){
                            @Override
                            public void completion(CirrentType.RESPONSE response) {
                                if (response == CirrentType.RESPONSE.SUCCESS) {
                                    ProgressView.sharedView().showToast(getContext(), device.getIdentifyingActionDescription());
                                }
                                else {
                                    ProgressView.sharedView().showToast(getContext(), "Identify Yourself Failed.");
                                }
                            }
                        });
                    }
                });
            }
            else {
                rowView = mInflater.inflate(R.layout.devicecell_layout, parent, false);
            }

            ImageView userActionCheckmark = (ImageView) rowView.findViewById(R.id.user_action_checkmark);
            final EditText deviceAlias = (EditText) rowView.findViewById(R.id.device_alias_name);
            ImageView deviceImageView = (ImageView) rowView.findViewById(R.id.deviceImageView);
            deviceAlias.setText(device.getFriendlyName());

            String imageURL = device.getImageURL();
            Picasso.with(MainActivity.currentActivity).load(imageURL).into(deviceImageView);

            if (device.isUserActionEnabled() == true) {
                userActionCheckmark.setVisibility(View.VISIBLE);
                if (device.isConfirmedOwnerShip() == true) {
                    userActionCheckmark.setImageResource(R.drawable.checkmark);
                }
                else {
                    userActionCheckmark.setImageResource(R.drawable.unchecked);
                }
            }
            else {
                userActionCheckmark.setVisibility(View.INVISIBLE);
            }

            deviceAlias.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    final EditText inputView = new EditText(MainActivity.currentActivity);
                    final String alias = deviceAlias.getText().toString();
                    inputView.setText(alias);
                    inputView.setSelection(alias.length());

                    inputView.requestFocus();
                    InputMethodManager imm = (InputMethodManager) MainActivity.currentActivity.getSystemService(Context.INPUT_METHOD_SERVICE);
                    imm.showSoftInput(inputView, InputMethodManager.SHOW_IMPLICIT);

                    new AlertDialog.Builder(MainActivity.currentActivity).setTitle("Change Device Name").setMessage(null).setView(inputView).setPositiveButton("Change", new DialogInterface.OnClickListener() {
                        @Override
                        public void onClick(DialogInterface dialog, int which) {
                            if (inputView.getText().toString().length() > 0) {
                                String newAlias = inputView.getText().toString();
                                CirrentService.sharedService().setFriendlyNameForDevice(device, newAlias);
                                notifyDataSetChanged();
                                dialog.dismiss();
                            }
                            else {
                                notifyDataSetChanged();
                                dialog.cancel();
                            }
                        }
                    }).setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
                        @Override
                        public void onClick(DialogInterface dialog, int which) {
                            dialog.cancel();
                            notifyDataSetChanged();
                        }
                    }).show();
                }
            });

            return rowView;
        }
    }

    View rootView;
    ListView mDeviceListView;
    ArrayList<Device> devices;

    public SelectDeviceFragment() {

    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        rootView = inflater.inflate(R.layout.selectdevice_layout, container, false);

        Button goSoftAPButton = (Button) rootView.findViewById(R.id.gosoftap_button);
        goSoftAPButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                goWithSoftAP();
            }
        });

        devices = CirrentService.sharedService().model.getDevices();
        mDeviceListView = (ListView) rootView.findViewById(R.id.deviceList);

        String[] deviceNames = new String[devices.size()];
        for (int i = 0; i < devices.size(); i++) {
            Device dev = devices.get(i);
            deviceNames[i] = dev.getDeviceId();
        }

        DeviceAdapter listAdapter = new DeviceAdapter(getContext(), devices);
        mDeviceListView.setAdapter(listAdapter);

        mDeviceListView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                Device device = devices.get(position);
                if (device.isUserActionEnabled() == false) {
                    ProgressView.sharedView().show(getContext());
                    selectDeviceAndAskStatus(device);
                }
                else {
                    if (device.isConfirmedOwnerShip() == true) {
                        CirrentService.sharedService().stopPollForUserAction();
                        ProgressView.sharedView().show(getContext());
                        selectDeviceAndAskStatus(device);
                    }
                    else {
                        if (device.getUserActionDescription() != null && device.getUserActionDescription().length() > 0) {
                            ProgressView.sharedView().showToast(getContext(), device.getUserActionDescription());
                        }
                        else {
                            ProgressView.sharedView().showToast(getContext(), "Waiting for you to confirm this is your device...");
                        }
                    }
                }
            }
        });

        CirrentService.sharedService().pollForUserAction(SampleCloudService.sharedService(), new CompletionHandler() {
            @Override
            public void pollUserActionCompletion(Device device, String userAction) {
                final Device userActionDevice = device;
                if (devices != null && devices.size() > 0) {
                    for (int i = 0; i < devices.size(); i++) {
                        Device dev = devices.get(i);
                        if (dev.getDeviceId().compareTo(device.getDeviceId()) == 0) {
                            final int index = i;
                            MainActivity.currentActivity.runOnUiThread(new Runnable() {
                                @Override
                                public void run() {
                                    View view = mDeviceListView.getChildAt(index - mDeviceListView.getFirstVisiblePosition());
                                    ImageView userActionCheckmark = (ImageView) view.findViewById(R.id.user_action_checkmark);
                                    if (userActionCheckmark != null) {
                                        if (userActionDevice.isConfirmedOwnerShip() == true) {
                                            userActionCheckmark.setImageResource(R.drawable.checkmark);
                                        }
                                        else {
                                            userActionCheckmark.setImageResource(R.drawable.unchecked);
                                        }
                                    }
                                }
                            });
                        }
                    }
                }
            }
        });

        setupUI(rootView);

        return rootView;
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        CirrentService.sharedService().stopPollForUserAction();
    }

    void selectDeviceAndAskStatus(final Device device) {
        ArrayList<String> deviceIDs = new ArrayList<String>();
        deviceIDs.add(device.getDeviceId());

        SampleCloudService.sharedService().bindDevice(device.getDeviceId(), device.getFriendlyName(), new SampleCloudService.SampleCompletionHandler(){
            @Override
            public void completionBindDevice(boolean bSuccess) {
                if (bSuccess == true) {
                    CirrentService.sharedService().bindDevice(SampleCloudService.sharedService(), device.getDeviceId(), new CompletionHandler(){
                        @Override
                        public void completion(CirrentType.RESPONSE response) {
                            if (response != CirrentType.RESPONSE.SUCCESS) {
                                ProgressView.sharedView().showToast(getContext(), "There is some problem on the device. Try again.");
                            }
                            else {
                                SampleCloudService.sharedService().bindedDevice = true;
                                SampleCloudService.sharedService().getBoundDevices(new SampleCloudService.SampleCompletionHandler(){
                                    @Override
                                    public void completionGetBoundDevices(ArrayList<SampleCloudService.SampleDevice> devices) {
                                        if (devices != null && devices.size() > 0) {
                                            ProgressView.sharedView().dismiss();

                                            CirrentService.sharedService().getDeviceStatus(SampleCloudService.sharedService(), device.getDeviceId(), new CompletionHandler(){
                                                @Override
                                                public void getStatusCompletion(CirrentType.RESPONSE response, JSONObject status) {
                                                    if (response == CirrentType.RESPONSE.SUCCESS) {
                                                        MainActivity.currentActivity.showScreen(MainActivity.SCREEN.CONNECT_DETAIL);
                                                    }
                                                    else {
                                                        ProgressView.sharedView().showToast(getContext(), "There is some problem on the device. Try again.");
                                                    }
                                                }
                                            });
                                        }
                                        else {
                                            ProgressView.sharedView().showToast(getContext(), "There is some problem on the device. Try again.");
                                        }
                                    }
                                });
                            }
                        }
                    });
                }
                else {
                    ProgressView.sharedView().showToast(getContext(), "There is some problem on the device. Try again.");
                }
            }
        });
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
                                    ProgressView.sharedView().showToast(getContext(), "Failed to connect to your device's SoftAp network");
                                    break;
                            }
                        }
                    });
                }
                else {
                    ProgressView.sharedView().dismiss();
                    ProgressView.sharedView().showToast(getContext(), "Sorry. We couldn't find any SoftAp network.");
                }
            }
        });
    }

    public static void hideSoftKeyboard(Activity activity) {
        InputMethodManager inputMethodManager =
                (InputMethodManager) activity.getSystemService(
                        Activity.INPUT_METHOD_SERVICE);
        if (activity.getCurrentFocus() != null && activity.getCurrentFocus().getWindowToken() != null) {
            inputMethodManager.hideSoftInputFromWindow(
                    activity.getCurrentFocus().getWindowToken(), 0);
        }
    }


    public void setupUI(View view) {

        // Set up touch listener for non-text box views to hide keyboard.
        if (!(view instanceof EditText)) {
            view.setOnTouchListener(new View.OnTouchListener() {
                public boolean onTouch(View v, MotionEvent event) {
                    hideSoftKeyboard(MainActivity.currentActivity);
                    return false;
                }
            });
        }

        //If a layout container, iterate over children and seed recursion.
        if (view instanceof ViewGroup) {
            for (int i = 0; i < ((ViewGroup) view).getChildCount(); i++) {
                View innerView = ((ViewGroup) view).getChildAt(i);
                setupUI(innerView);
            }
        }
    }
}
