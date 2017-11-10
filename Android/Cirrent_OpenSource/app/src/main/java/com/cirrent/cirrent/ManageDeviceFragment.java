package com.cirrent.cirrent;

import android.content.Context;
import android.content.DialogInterface;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v7.app.AlertDialog;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.InputMethodManager;
import android.widget.AdapterView;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import com.cirrent.cirrentsdk.CirrentService;
import com.cirrent.cirrentsdk.CirrentType;
import com.cirrent.cirrentsdk.CompletionHandler;
import com.daimajia.swipe.SwipeLayout;
import com.daimajia.swipe.adapters.BaseSwipeAdapter;
import com.squareup.picasso.Picasso;

import org.json.JSONException;

import java.util.ArrayList;


public class ManageDeviceFragment extends Fragment {
    public class DeviceAdapter extends BaseSwipeAdapter {
        private Context mContext;
        private LayoutInflater mInflater;
        private ArrayList<SampleCloudService.SampleDevice> mDataSource;

        public DeviceAdapter(Context context, ArrayList<SampleCloudService.SampleDevice> items) {
            mContext = context;
            mDataSource = items;
            mInflater = (LayoutInflater) mContext.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        }

        @Override
        public int getSwipeLayoutResourceId(int position) {
            return R.id.swipe;
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
        public void fillValues(int position, View convertView) {

        }

        @Override
        public View generateView(final int position, ViewGroup parent) {
            View rowView = mInflater.inflate(R.layout.managedevicecell_layout, parent, false);
            final SwipeLayout swipeLayout = (SwipeLayout) rowView.findViewById(getSwipeLayoutResourceId(position));
            final SampleCloudService.SampleDevice device = (SampleCloudService.SampleDevice) getItem(position);

            final Button delete = (Button) rowView.findViewById(R.id.delete_device);
            delete.setTag(position);
            delete.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    final int pos = (Integer) v.getTag();
                    final SampleCloudService.SampleDevice device = (SampleCloudService.SampleDevice) getItem(pos);
                    ProgressView.sharedView().show(getContext(), "Removing Device from your account...");
                    SampleCloudService.sharedService().resetDevice(device.deviceID, new SampleCloudService.SampleCompletionHandler() {
                        @Override
                        public void completionResetDevice(boolean bSuccess) {
                            ProgressView.sharedView().dismiss();
                            if (bSuccess == true) {
                                CirrentService.sharedService().resetDevice(SampleCloudService.sharedService(), device.deviceID, new CompletionHandler(){
                                    @Override
                                    public void completion(CirrentType.RESPONSE response) {
                                        if (response == CirrentType.RESPONSE.SUCCESS) {
                                            MainActivity.currentActivity.runOnUiThread(new Runnable() {
                                                @Override
                                                public void run() {
                                                    ArrayList<SampleCloudService.SampleDevice> list = new ArrayList<SampleCloudService.SampleDevice>();
                                                    for (int i = 0; i < mDataSource.size(); i++) {
                                                        if (i != pos) {
                                                            list.add(mDataSource.get(i));
                                                        }
                                                    }
                                                    DeviceAdapter adapter = new DeviceAdapter(getContext(), list);
                                                    mDeviceListView.setAdapter(adapter);
                                                    notifyDataSetChanged();
                                                }
                                            });
                                        }
                                        else {
                                            ProgressView.sharedView().showToast(getContext(), "Failed Removing device from your account.");
                                            swipeLayout.close();
                                        }
                                    }
                                });
                            }
                            else {
                                ProgressView.sharedView().showToast(getContext(), "Failed Removing device from your account.");
                                swipeLayout.close();
                            }
                        }
                    });
                }
            });

            final Button edit = (Button) rowView.findViewById(R.id.edit_device);
            edit.setTag(position);
            edit.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    final int pos = (Integer) v.getTag();
                    final SampleCloudService.SampleDevice device = (SampleCloudService.SampleDevice) getItem(pos);
                    final EditText inputView = new EditText(MainActivity.currentActivity);
                    inputView.setText(device.getFriendlyName());
                    inputView.setSelection(device.friendlyName.length());
                    inputView.requestFocus();
                    InputMethodManager imm = (InputMethodManager) MainActivity.currentActivity.getSystemService(Context.INPUT_METHOD_SERVICE);
                    imm.showSoftInput(inputView, InputMethodManager.SHOW_IMPLICIT);

                    new AlertDialog.Builder(MainActivity.currentActivity).setTitle("Custom Device Name").setMessage(null).setView(inputView).setPositiveButton("Save", new DialogInterface.OnClickListener() {
                        @Override
                        public void onClick(DialogInterface dialog, int which) {
                            if (inputView.getText().toString().length() > 0) {
                                device.setFriendlyName(inputView.getText().toString());
                                notifyDataSetChanged();
                                dialog.dismiss();
                            }
                            else {
                                notifyDataSetChanged();
                                dialog.cancel();
                            }
                            swipeLayout.close();
                        }
                    }).setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
                        @Override
                        public void onClick(DialogInterface dialog, int which) {
                            notifyDataSetChanged();
                            dialog.cancel();
                            swipeLayout.close();
                        }
                    }).show();
                }
            });

            ImageView deviceImageView = (ImageView) rowView.findViewById(R.id.device_imageView);
            TextView friendlyNameView = (TextView) rowView.findViewById(R.id.friendly_name);
            TextView companyNameView = (TextView) rowView.findViewById(R.id.device_company_name);
            TextView typeNameView = (TextView) rowView.findViewById(R.id.device_type_name);

            Picasso.with(MainActivity.currentActivity).load(device.imageURL).into(deviceImageView);

            friendlyNameView.setText(device.getFriendlyName());
            if (device.name != null && device.name.compareTo("null") != 0) {
                companyNameView.setText(device.name);
            }

            if (device.deviceID != null && device.name.compareTo("null") != 0) {
                typeNameView.setText(device.deviceID);
            }

            return rowView;
        }
    }

    public ManageDeviceFragment() {

    }

    View rootView;
    ListView mDeviceListView;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        rootView = inflater.inflate(R.layout.managedevice_layout, container, false);
        mDeviceListView = (ListView) rootView.findViewById(R.id.device_listview);

        ProgressView.sharedView().show(getContext());
        SampleCloudService.sharedService().getBoundDevices(new SampleCloudService.SampleCompletionHandler() {
            @Override
            public void completionGetBoundDevices(ArrayList<SampleCloudService.SampleDevice> devices) {
                ProgressView.sharedView().dismiss();
                if (devices == null) {
                    MainActivity.currentActivity.showScreen(MainActivity.SCREEN.ADD_DEVICE);
                }
                else {
                    Context context = getContext();
                    if (context != null) {
                        final DeviceAdapter adapter = new DeviceAdapter(context, devices);
                        mDeviceListView.setAdapter(adapter);
                        mDeviceListView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
                            @Override
                            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                                SampleCloudService.SampleDevice device = (SampleCloudService.SampleDevice) adapter.getItem(position);
                                ArrayList<Object> params = new ArrayList<Object>();
                                params.add(device);
                                MainActivity.currentActivity.showScreen(MainActivity.SCREEN.MANAGE_NETWORK, params);
                            }
                        });
                    }
                    else {
                        MainActivity.currentActivity.showScreen(MainActivity.SCREEN.ADD_DEVICE);
                    }
                }
            }
        });

        return rootView;
    }
}
