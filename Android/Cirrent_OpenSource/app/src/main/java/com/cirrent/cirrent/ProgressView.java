package com.cirrent.cirrent;

import android.app.ProgressDialog;
import android.content.Context;
import android.widget.Toast;

public class ProgressView {

    private Context mContext;
    private ProgressDialog mProgressDialog;
    private static ProgressView sharedView = null;

    public ProgressView() {

    }

    public ProgressView(Context context) {
        mContext = context;
    }

    public static ProgressView sharedView() {
        if (sharedView == null) {
            sharedView = new ProgressView();
        }

        return sharedView;
    }

    void setContext(Context context) {
        mContext = context;
    }

    void show(Context context) {
        mContext = context;
        show();
    }

    void show(Context context, String status) {
        mContext = context;
        show(status);
    }

    void show() {
        dismiss();
        if (mContext == null) return;

        if(mProgressDialog == null) {
            mProgressDialog = new ProgressDialog(mContext);
            mProgressDialog.setCancelable(false);
            mProgressDialog.setCanceledOnTouchOutside(false);
            mProgressDialog.show();
        }
    }

    void show(String status) {
        dismiss();
        if (mContext == null) return;

        if(mProgressDialog == null) {
            mProgressDialog = new ProgressDialog(mContext);
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
        if (mContext == null) return;

        if (mProgressDialog != null && mProgressDialog.isShowing()) {
            mProgressDialog.dismiss();
            mProgressDialog = null;
        }
    }

    void showToast(Context context, String message) {
        mContext = context;
        showToast(message);
    }

    void showToast(String message) {
        dismiss();
        if (mContext == null) return;
        Toast.makeText(mContext, message, Toast.LENGTH_LONG).show();
    }
}
