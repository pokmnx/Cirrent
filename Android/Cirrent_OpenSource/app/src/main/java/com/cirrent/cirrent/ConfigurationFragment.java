package com.cirrent.cirrent;

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.InputMethodManager;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;

import com.cirrent.cirrentsdk.CirrentService;


public class ConfigurationFragment extends Fragment {

    private View rootView = null;

    public ConfigurationFragment() {

    }

    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        rootView = inflater.inflate(R.layout.configuration_layout, container, false);

        TextView appIDText = (TextView) rootView.findViewById(R.id.appID);
        final EditText softAPEditText = (EditText) rootView.findViewById(R.id.softap_ssid);

        appIDText.setText(SampleCloudService.sharedService().ownerID);
        softAPEditText.setText(CirrentService.sharedService().getSoftAPSSID());

        softAPEditText.requestFocus();
        InputMethodManager imm = (InputMethodManager) MainActivity.currentActivity.getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.showSoftInput(softAPEditText, InputMethodManager.SHOW_IMPLICIT);

        Button done = (Button) rootView.findViewById(R.id.doneButton);
        Button signout = (Button) rootView.findViewById(R.id.signoutButton);

        done.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                String softAPSSID = softAPEditText.getText().toString();
                if (softAPSSID != null && softAPSSID.length() > 0) {
                    CirrentService.sharedService().setSoftAPSSID(softAPSSID);
                }

                MainActivity.currentActivity.showScreen(MainActivity.SCREEN.MANAGE_DEVICE);
            }
        });

        signout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                SampleCloudService.sharedService().signOut();
                MainActivity.currentActivity.showScreen(MainActivity.SCREEN.LOGIN);
            }
        });

        setupUI(rootView);

        return rootView;
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
