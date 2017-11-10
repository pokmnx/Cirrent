package com.cirrent.cirrent;

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.text.method.HideReturnsTransformationMethod;
import android.text.method.PasswordTransformationMethod;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.Spinner;
import android.widget.Switch;

import com.cirrent.cirrentsdk.CirrentService;
import com.cirrent.cirrentsdk.CirrentType;
import com.cirrent.cirrentsdk.CompletionHandler;
import com.cirrent.cirrentsdk.KnownNetwork;
import com.cirrent.cirrentsdk.Network;

import java.util.ArrayList;
import java.util.List;

public class AddNetworkFragment extends Fragment {

    View rootView;
    SampleCloudService.SampleDevice device;


    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        rootView = inflater.inflate(R.layout.addnetwork_layout, container, false);

        final Spinner networkList = (Spinner) rootView.findViewById(R.id.network_list);
        final EditText ssidInput = (EditText) rootView.findViewById(R.id.network_ssid);
        final Switch manualSwitch = (Switch) rootView.findViewById(R.id.manual_input_switch);
        final EditText passwordInput = (EditText) rootView.findViewById(R.id.password);
        final Spinner security = (Spinner) rootView.findViewById(R.id.security);
        final Switch showPasswordSwitch = (Switch) rootView.findViewById(R.id.show_password_switch);
        Button addButton = (Button) rootView.findViewById(R.id.add_network);

        ProgressView.sharedView().show(getContext());
        CirrentService.sharedService().getCandidateNetworks(SampleCloudService.sharedService(), device.deviceID, new CompletionHandler(){
            @Override
            public void getNetworkCompletion(CirrentType.RESPONSE response, ArrayList<KnownNetwork> networks) {
                ProgressView.sharedView().dismiss();
                if (response == CirrentType.RESPONSE.SUCCESS && networks != null && networks.size() > 0) {
                    manualSwitch.setEnabled(true);
                    manualSwitch.setChecked(false);

                    List<String> ssidList = new ArrayList<String>();
                    for (int i = 0; i < networks.size(); i++) {
                        KnownNetwork network = networks.get(i);
                        ssidList.add(network.getSSID());
                    }
                    ArrayAdapter<String> dataAdapter = new ArrayAdapter<String>(MainActivity.currentActivity, android.R.layout.simple_spinner_item, ssidList);
                    dataAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
                    networkList.setAdapter(dataAdapter);
                    networkList.setSelection(0);
                    networkList.setVisibility(View.VISIBLE);
                    ssidInput.setVisibility(View.INVISIBLE);
                }
                else {
                    manualSwitch.setEnabled(false);
                    manualSwitch.setChecked(true);
                    networkList.setVisibility(View.INVISIBLE);
                    ssidInput.setVisibility(View.VISIBLE);
                }
            }
        });

        manualSwitch.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (isChecked == true) {
                    networkList.setVisibility(View.INVISIBLE);
                    ssidInput.setVisibility(View.VISIBLE);
                }
                else {
                    networkList.setVisibility(View.VISIBLE);
                    ssidInput.setVisibility(View.INVISIBLE);
                }
            }
        });

        List<String> securityList = new ArrayList<String>();
        securityList.add("WPA2-PSK");
        securityList.add("OPEN");
        ArrayAdapter<String> dataAdapter = new ArrayAdapter<String>(MainActivity.currentActivity, android.R.layout.simple_spinner_item, securityList);
        dataAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        security.setAdapter(dataAdapter);

        security.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                if (position == 0) { // WPA2-PSK
                    passwordInput.setVisibility(View.VISIBLE);
                    showPasswordSwitch.setVisibility(View.VISIBLE);
                }
                else { // OPEN
                    passwordInput.setVisibility(View.INVISIBLE);
                    showPasswordSwitch.setVisibility(View.INVISIBLE);
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {

            }
        });

        showPasswordSwitch.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (isChecked == true) {
                    passwordInput.setTransformationMethod(HideReturnsTransformationMethod.getInstance());
                }
                else {
                    passwordInput.setTransformationMethod(PasswordTransformationMethod.getInstance());
                }
                passwordInput.setSelection(passwordInput.getText().length());
            }
        });

        addButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                String ssid;
                String password = passwordInput.getText().toString();
                String sec = String.valueOf(security.getSelectedItem());
                if (manualSwitch.isChecked() == true) {
                    ssid = ssidInput.getText().toString();
                }
                else {
                    ssid = String.valueOf(networkList.getSelectedItem());
                }

                if (ssid == null || ssid.compareTo("") == 0) {
                    ProgressView.sharedView().showToast(getContext(), "Network Name should not be empty");
                    return;
                }

                Network network = new Network();
                network.setSSID(ssid);
                network.setFlags(sec);
                ProgressView.sharedView().show(getContext());

                CirrentService.sharedService().addNetwork(SampleCloudService.sharedService(), device.deviceID, network, password, new CompletionHandler(){
                    @Override
                    public void completion(CirrentType.RESPONSE response) {
                        ProgressView.sharedView().dismiss();
                        if (response == CirrentType.RESPONSE.SUCCESS) {
                            ArrayList<Object> params = new ArrayList<Object>();
                            params.add(device);
                            MainActivity.currentActivity.showScreen(MainActivity.SCREEN.MANAGE_NETWORK, params);
                        }
                        else {
                            ProgressView.sharedView().showToast(getContext(), "Failed to add network to device.");
                        }
                    }
                });
            }
        });

        return rootView;
    }

}
