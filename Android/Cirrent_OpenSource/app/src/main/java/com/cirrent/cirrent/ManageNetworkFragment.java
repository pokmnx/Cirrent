package com.cirrent.cirrent;

import android.content.Context;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ListView;
import android.widget.TextView;

import com.cirrent.cirrentsdk.CirrentService;
import com.cirrent.cirrentsdk.CirrentType;
import com.cirrent.cirrentsdk.CompletionHandler;
import com.cirrent.cirrentsdk.KnownNetwork;
import com.cirrent.cirrentsdk.Network;
import com.daimajia.swipe.SwipeLayout;
import com.daimajia.swipe.adapters.BaseSwipeAdapter;

import java.util.ArrayList;

public class ManageNetworkFragment extends Fragment {

    View rootView;
    public SampleCloudService.SampleDevice device;

    public class NetworkAdapter extends BaseSwipeAdapter {
        private Context mContext;
        private LayoutInflater mInflater;
        private ArrayList<KnownNetwork> mDataSource;

        public NetworkAdapter(Context context, ArrayList<KnownNetwork> items) {
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
            View rowView = mInflater.inflate(R.layout.managenetworkcell_layout, parent, false);
            SwipeLayout swipeLayout = (SwipeLayout) rowView.findViewById(getSwipeLayoutResourceId(position));
            final KnownNetwork network = (KnownNetwork) getItem(position);
            final Button delete = (Button) rowView.findViewById(R.id.delete_network);

            delete.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    ProgressView.sharedView().show(getContext(), "Removing Network from your device...");
                    Network net = new Network();
                    net.setSSID(network.getSSID());
                    net.setSecurity(network.getSecurity());
                    net.setRoamingID(network.getRoamingID());

                    CirrentService.sharedService().deleteNetwork(SampleCloudService.sharedService(), device.deviceID, net, new CompletionHandler(){
                        @Override
                        public void completion(CirrentType.RESPONSE response) {
                            ProgressView.sharedView().dismiss();
                            if (response == CirrentType.RESPONSE.SUCCESS) {
                                mDataSource.remove(position);
                                notifyDataSetChanged();
                            }
                            else {
                                ProgressView.sharedView().showToast(getContext(), "Failed Removing Network from your device.");
                            }
                        }
                    });
                }
            });

            TextView networkName = (TextView) rowView.findViewById(R.id.network_name);
            networkName.setText(network.getSSID() + " - " + network.getStatus());

            return rowView;
        }
    }

    ListView mNetworkListView;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        rootView = inflater.inflate(R.layout.managenetwork_layout, container, false);

        mNetworkListView = (ListView) rootView.findViewById(R.id.network_listview);
        ProgressView.sharedView().show(getContext());
        CirrentService.sharedService().getKnownNetworks(SampleCloudService.sharedService(), device.deviceID, new CompletionHandler(){
            @Override
            public void getNetworkCompletion(CirrentType.RESPONSE response, ArrayList<KnownNetwork> networks) {
                ProgressView.sharedView().dismiss();
                if (networks != null) {
                    NetworkAdapter adapter = new NetworkAdapter(getContext(), networks);
                    mNetworkListView.setAdapter(adapter);
                }
            }
        });
        return rootView;
    }

}
