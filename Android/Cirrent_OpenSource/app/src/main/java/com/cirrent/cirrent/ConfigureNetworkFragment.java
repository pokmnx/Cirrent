package com.cirrent.cirrent;

import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.support.v4.app.Fragment;
import android.text.method.HideReturnsTransformationMethod;
import android.text.method.PasswordTransformationMethod;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.InputMethodManager;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.Spinner;
import android.widget.TextView;

import com.cirrent.cirrentsdk.CirrentService;
import com.cirrent.cirrentsdk.CirrentType;
import com.cirrent.cirrentsdk.CompletionHandler;
import com.cirrent.cirrentsdk.LogService;
import com.cirrent.cirrentsdk.Model;
import com.cirrent.cirrentsdk.Network;

import java.util.ArrayList;

public class ConfigureNetworkFragment extends Fragment {
    private View rootView = null;

    EditText passwordInput;
    CheckBox showPassword;
    Button connectButton;
    Spinner networkList;
    TextView networkPasswordText;
    Network selectedNetwork;

    public ConfigureNetworkFragment() {

    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        rootView = inflater.inflate(R.layout.connect_layout, container, false);

        passwordInput = (EditText) rootView.findViewById(R.id.networkPassword);
        showPassword = (CheckBox) rootView.findViewById(R.id.showPasswordCheckBox);
        connectButton = (Button) rootView.findViewById(R.id.networkConnectButton);
        networkList = (Spinner) rootView.findViewById(R.id.networkList);
        networkPasswordText = (TextView) rootView.findViewById(R.id.networkpassword_text);

        final ArrayList<Network> networks = CirrentService.sharedService().model.getNetworks();
        if (networks == null || networks.size() == 0) {
            ProgressView.sharedView().showToast(getContext(), "" +
                    "Sorry, the device does not see any networks. You will need to manually enter the network information.");
            Handler handler = new Handler();
            long delay = 1000;
            handler.postDelayed(new Runnable() {
                @Override
                public void run() {
                    MainActivity.currentActivity.showScreen(MainActivity.SCREEN.ADD_DEVICE);
                }
            }, delay);
        }
        else {
            ArrayList<String> nameArray = new ArrayList<String>();
            int selectedIndex = 0;
            String ssid = CirrentService.sharedService().getCurrentSSID();
            if (CirrentService.sharedService().isOnZipKeyNetwork() == false) {
                if (ssid == null && CirrentService.sharedService().isOnCellularNetwork() == false) {
                    ProgressView.sharedView().showToast(getContext(), "Your phone is offline. Please check your network setting and try again.");
                    Handler handler = new Handler();
                    long delay = 1000;
                    handler.postDelayed(new Runnable() {
                        @Override
                        public void run() {
                            MainActivity.currentActivity.showScreen(MainActivity.SCREEN.ADD_DEVICE);
                        }
                    }, delay);
                    return rootView;
                }

                if (ssid == null) {
                    if (selectedNetwork == null && networks != null && networks.size() > 0) {
                        selectedNetwork = networks.get(0);
                        selectedIndex = 0;
                    }
                }
                else {
                    for (int i = 0; i < networks.size(); i++) {
                        Network net = networks.get(i);
                        if (net.getSSID() != null && net.getSSID().length() > 0) {
                            nameArray.add(net.getSSID());
                        }
                        if (net.getSSID() != null && net.getSSID().compareTo(ssid) == 0) {
                            selectedNetwork = net;
                            selectedIndex = i;
                        }
                    }

                    if (selectedNetwork == null && networks.size() > 0) {
                        selectedNetwork = networks.get(0);
                        selectedIndex = 0;
                    }
                }
            }
            else {
                for (int i = 0; i < networks.size(); i++) {
                    Network net = networks.get(i);
                    if (net.getSSID() != null && net.getSSID().length() > 0) {
                        nameArray.add(net.getSSID());
                    }

                    if (MainActivity.softAPBeforeSSID != null && MainActivity.softAPBeforeSSID.compareTo(net.getSSID()) == 0) {
                        selectedNetwork = net;
                        selectedIndex = i;
                    }
                }

                if (selectedNetwork == null && networks.size() > 0) {
                    selectedNetwork = networks.get(0);
                    selectedIndex = 0;
                }
            }

            ArrayAdapter<String> adapter = new ArrayAdapter<String>(getContext(), android.R.layout.simple_spinner_item, nameArray);
            adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
            networkList.setAdapter(adapter);
            networkList.setSelection(selectedIndex);

            networkList.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
                @Override
                public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                    selectedNetwork = networks.get(position);
                    if (selectedNetwork == null) {
                        return;
                    }
                    if (selectedNetwork.getFlags() != null && selectedNetwork.getFlags().compareTo("[ESS]") == 0) {
                        selectedNetwork.setOpen(true);
                        passwordInput.setVisibility(View.INVISIBLE);
                        showPassword.setVisibility(View.INVISIBLE);
                        networkPasswordText.setVisibility(View.INVISIBLE);
                    }
                    else {
                        selectedNetwork.setOpen(false);
                        passwordInput.setVisibility(View.VISIBLE);
                        showPassword.setVisibility(View.VISIBLE);
                        networkPasswordText.setVisibility(View.INVISIBLE);
                    }
                }

                @Override
                public void onNothingSelected(AdapterView<?> parent) {

                }
            });

            showPassword.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    if (showPassword.isChecked() == true) {
                        passwordInput.setTransformationMethod(HideReturnsTransformationMethod.getInstance());
                    }
                    else {
                        passwordInput.setTransformationMethod(PasswordTransformationMethod.getInstance());
                    }
                    passwordInput.setSelection(passwordInput.getText().length());
                }
            });

            connectButton.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    if (selectedNetwork != null) {
                        if (selectedNetwork.getFlags().compareTo("[ESS]") == 0) {
                            selectedNetwork.setOpen(true);
                            passwordInput.setText("");
                        }
                        else {
                            selectedNetwork.setOpen(false);
                        }

                        if (selectedNetwork.isOpen() == false && passwordInput.getText().toString().length() == 0) {
                            ProgressView.sharedView().showToast(getContext(), "Please enter your network password.");
                            return;
                        }

                        CirrentService.sharedService().model.setSelectedNetwork(selectedNetwork);
                        CirrentService.sharedService().model.setSelectedNetworkPassword(passwordInput.getText().toString());
                        String ssid = selectedNetwork.getSSID();
                        LogService.sharedService().debug("Private Network to connect to " + ssid);

                        if (selectedNetwork.isOpen() == false && passwordInput.getText().toString().length() < 8) {
                            ProgressView.sharedView().showToast(getContext(), "Please recheck your network password. It should be at least 8 characters.");
                            return;
                        }

                        sendCredential();
                    }
                    else {
                        ProgressView.sharedView().showToast(getContext(), "Please select a network and enter its password.");
                    }
                }
            });
        }

        setupUI(rootView);
        return rootView;
    }

    void sendCredential() {
        ProgressView.sharedView().show(getContext());
        Model model = CirrentService.sharedService().model;
        CirrentService.sharedService().putPrivateCredentials(SampleCloudService.sharedService(), model.getSelectedDevice().getDeviceId(), new CompletionHandler(){
            @Override
            public void putCredentialCompletion(CirrentType.CREDENTIAL_RESPONSE response, ArrayList<String> credentials) {
                if (response == CirrentType.CREDENTIAL_RESPONSE.SUCCESS) {
                    String netSSID = CirrentService.sharedService().model.getSelectedNetwork().getSSID();
                    String logStr = String.format("ssid=%s;psk_len=%s;source=%s", netSSID, passwordInput.getText().toString(),netSSID);
                    LogService.sharedService().log(LogService.Event.USER_CREDS, logStr);
                    LogService.sharedService().putLog(SampleCloudService.sharedService().manage_token);
                    ProgressView.sharedView().dismiss();
                    MainActivity.currentActivity.showScreen(MainActivity.SCREEN.PROGRESSING);
                }
                else {
                    LogService.sharedService().putLog(SampleCloudService.sharedService().manage_token);
                    ProgressView.sharedView().showToast(getContext(), "Sending Credential Failed");
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
