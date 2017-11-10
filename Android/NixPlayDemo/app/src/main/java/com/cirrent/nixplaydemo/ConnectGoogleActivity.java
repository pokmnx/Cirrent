package com.cirrent.nixplaydemo;

import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Handler;
import android.os.StrictMode;
import android.support.annotation.StringDef;
import android.support.v4.view.AsyncLayoutInflater;
import android.support.v4.view.PagerAdapter;
import android.support.v4.view.ViewPager;
import android.support.v7.app.AppCompatActivity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;

import com.gigamole.infinitecycleviewpager.HorizontalInfiniteCycleViewPager;

import java.util.Timer;
import java.util.TimerTask;


public class ConnectGoogleActivity extends AppCompatActivity {
    class SliderAdapter extends PagerAdapter{
        Context mContext;
        LayoutInflater mLayoutInflater;

        public SliderAdapter(Context context) {
            mContext = context;
            mLayoutInflater = (LayoutInflater) mContext.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        }

        @Override
        public int getCount() {
            return mResources.length;
        }


        @Override
        public boolean isViewFromObject(View view, Object object) {
            return view == ((LinearLayout) object);
        }

        @Override
        public Object instantiateItem(ViewGroup container, int position) {
            View itemView = mLayoutInflater.inflate(R.layout.pager_item, container, false);

            ImageView imageView = (ImageView) itemView.findViewById(R.id.imageView);
            imageView.setImageResource(mResources[position]);

            container.addView(itemView);

            return itemView;
        }

        @Override
        public void destroyItem(ViewGroup container, int position, Object object) {
            container.removeView((LinearLayout) object);
        }

    }

    int[] mResources = {
            R.drawable.first,
            R.drawable.second,
            R.drawable.third
    };

    Handler handler;
    Runnable runnable;
    boolean bConnectToGoogle;
    boolean bConnectToCirrent;
    Timer timer;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.connect_google_layout);
        this.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);

        HorizontalInfiniteCycleViewPager slider = (HorizontalInfiniteCycleViewPager) findViewById(R.id.slider);
        slider.setAdapter(new SliderAdapter(this));
        slider.startAutoScroll(true);

        handler = new Handler();
        runnable = new Runnable() {
            @Override
            public void run() {
                new Thread(new Runnable() {
                    @Override
                    public void run() {
                        bConnectToGoogle = MainActivity.isAvailableToConnectGoogle();
                        bConnectToCirrent = MainActivity.isAvailableToConnectCirrent();

                        runOnUiThread(new Runnable() {
                            @Override
                            public void run() {
                                //MainActivity.this.dismiss();
                                if (bConnectToGoogle == true) {
                                    handler.postDelayed(runnable, 2000);
                                }
                                else if (bConnectToCirrent == true) {
                                    handler.removeCallbacksAndMessages(null);
                                    runOnUiThread(new Runnable() {
                                        @Override
                                        public void run() {
                                            Intent intent = new Intent(ConnectGoogleActivity.this, ConnectCirrentActivity.class);
                                            ConnectGoogleActivity.this.startActivity(intent);
                                        }
                                    });
                                }
                                else {
                                    handler.removeCallbacksAndMessages(null);
                                    runOnUiThread(new Runnable() {
                                        @Override
                                        public void run() {
                                            Intent intent = new Intent(ConnectGoogleActivity.this, NoConnectionActivity.class);
                                            ConnectGoogleActivity.this.startActivity(intent);
                                        }
                                    });
                                }
                            }
                        });
                    }
                }).start();
            }
        };
        handler.postDelayed(runnable, 2000);
    }
}
