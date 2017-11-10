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
import android.widget.Toast;


public class LoginFragment extends Fragment {

    private View rootView = null;
    private EditText emailInput = null;
    private EditText passwordInput = null;

    private boolean bLoggedBefore = false;

    public LoginFragment() {

    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        rootView = inflater.inflate(R.layout.login_layout, container, false);

        emailInput = (EditText) rootView.findViewById(R.id.emailInput);
        passwordInput = (EditText) rootView.findViewById(R.id.passwordInput);
        Button loginButton = (Button) rootView.findViewById(R.id.loginButton);

        SampleCloudService.sharedService().setContext(getContext());

        String username = SampleCloudService.sharedService().getUsername();
        String password = SampleCloudService.sharedService().getPassword();

        if (username != null && password != null) {
            emailInput.setText(username);
            passwordInput.setText(password);
            bLoggedBefore = true;
            login(username, password);
        }
        else {
            bLoggedBefore = false;
        }

        loginButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                InputMethodManager imm = (InputMethodManager) MainActivity.currentActivity.getSystemService(Context.INPUT_METHOD_SERVICE);
                imm.hideSoftInputFromWindow(emailInput.getWindowToken(), 0);

                String username = emailInput.getText().toString();
                String password = passwordInput.getText().toString();

                if (username.length() == 0 || password.length() == 0) {
                    Toast.makeText(MainActivity.currentActivity, "Wrong Email or Password", Toast.LENGTH_LONG).show();
                    return;
                }

                login(username, password);
            }
        });

        setupUI(rootView);

        return rootView;
    }

    void login(String username, String password) {
        ProgressView.sharedView().show(getContext(), "Logging In...");
        SampleCloudService.sharedService().login(username, password, new SampleCloudService.SampleCompletionHandler() {
            @Override
            public void completion(boolean bSuccess) {
                ProgressView.sharedView().dismiss();
                if (bSuccess == true) {
                    if (bLoggedBefore == true) {
                        MainActivity.currentActivity.showScreen(MainActivity.SCREEN.MANAGE_DEVICE);
                    }
                    else {
                        MainActivity.currentActivity.showScreen(MainActivity.SCREEN.CONFIGURE);
                    }
                }
                else {
                    Toast.makeText(MainActivity.currentActivity, "We had a problem signing you in. Please try again.", Toast.LENGTH_LONG).show();
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
