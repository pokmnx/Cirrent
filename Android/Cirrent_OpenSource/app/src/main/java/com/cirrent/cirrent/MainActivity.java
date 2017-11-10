package com.cirrent.cirrent;

import android.content.Context;
import android.content.pm.ActivityInfo;
import android.os.Bundle;
import android.os.Handler;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentManager;
import android.support.design.widget.NavigationView;
import android.support.v4.view.GravityCompat;
import android.support.v4.widget.DrawerLayout;
import android.support.v7.app.ActionBarDrawerToggle;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.FrameLayout;

import com.cirrent.cirrentsdk.CirrentService;
import com.cirrent.cirrentsdk.CirrentType;
import com.cirrent.cirrentsdk.CompletionHandler;

import java.util.ArrayList;
import java.util.Objects;

import static com.cirrent.cirrent.MainActivity.SCREEN.ADD_DEVICE;
import static com.cirrent.cirrent.MainActivity.SCREEN.ADD_NETWORK;
import static com.cirrent.cirrent.MainActivity.SCREEN.CONFIGURE;
import static com.cirrent.cirrent.MainActivity.SCREEN.LOGIN;
import static com.cirrent.cirrent.MainActivity.SCREEN.MANAGE_DEVICE;
import static com.cirrent.cirrent.MainActivity.SCREEN.MANAGE_NETWORK;

public class MainActivity extends AppCompatActivity
        implements NavigationView.OnNavigationItemSelectedListener {

    private final int SPLASH_DISPLAY_LENGTH = 2000;
    public static MainActivity currentActivity;

    public enum SCREEN {
        LOGIN,
        CONFIGURE,
        MANAGE_DEVICE,
        ADD_DEVICE,
        MANAGE_NETWORK,
        ADD_NETWORK,
        SELECT_DEVICE,
        CONNECT_DETAIL,
        CONNECT,
        PROGRESSING,
        SUCCESS
    }

    public SCREEN currentScreen;
    public Fragment currentFragment;
    public Context currentContext;
    public static String softAPBeforeSSID = null;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
        currentActivity = this;
        ProgressView.sharedView().setContext(currentActivity);
        CirrentService.sharedService().setContext(currentActivity);

        setContentView(R.layout.splash_layout);
        new Handler().postDelayed(new Runnable(){
            @Override
            public void run() {
                startMainScreen();
            }
        }, SPLASH_DISPLAY_LENGTH);
    }

    void startMainScreen() {
        initNavigation();
        showScreen(LOGIN);
    }

    void initNavigation() {
        setContentView(R.layout.activity_main);
        Toolbar toolbar;
        toolbar = (Toolbar) findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        DrawerLayout drawer = (DrawerLayout) findViewById(R.id.drawer_layout);
        ActionBarDrawerToggle toggle = new ActionBarDrawerToggle(
                MainActivity.this, drawer, toolbar, R.string.navigation_drawer_open, R.string.navigation_drawer_close);
        drawer.setDrawerListener(toggle);
        toggle.syncState();
        NavigationView navigationView = (NavigationView) findViewById(R.id.nav_view);
        navigationView.setNavigationItemSelectedListener(MainActivity.this);
        FrameLayout contentMainLayout;
        contentMainLayout = (FrameLayout) findViewById(R.id.content_main);
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        outState.putString("WORKAROUND_FOR_BUG_19917_KEY", "WORKAROUND_FOR_BUG_19917_VALUE");
        super.onSaveInstanceState(outState);
    }

    @Override
    public void onBackPressed() {
        switch (currentScreen) {
            case LOGIN:
            case CONFIGURE:
            case CONNECT_DETAIL:
            case SELECT_DEVICE:
            case CONNECT:
            case PROGRESSING:
            case SUCCESS:
            case ADD_DEVICE:
                break;
            case MANAGE_DEVICE:
                showScreen(ADD_DEVICE);
                break;
            case MANAGE_NETWORK:
                showScreen(MANAGE_DEVICE);
                break;
            case ADD_NETWORK:
                SampleCloudService.SampleDevice device = ((AddNetworkFragment) currentFragment).device;
                ArrayList<Object> params = new ArrayList<>();
                params.add(device);
                showScreen(MANAGE_NETWORK, params);
                break;
            default:
                break;
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.main, menu);
        addButton = (MenuItem) menu.findItem(R.id.add_device);
        return true;
    }

    MenuItem addButton;
    void showAddDeviceButton(boolean bShow) {
        if (addButton == null) {
            return;
        }

        if (bShow == true) {
            addButton.setVisible(true);
        }
        else {
            addButton.setVisible(false);
        }
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        int id = item.getItemId();

        if (id == R.id.add_device) {
            if (currentScreen == MANAGE_DEVICE) {
                showScreen(ADD_DEVICE);
            }
            else if (currentScreen == MANAGE_NETWORK) {
                ArrayList<Object> deviceList = new ArrayList<Object>();
                SampleCloudService.SampleDevice device = ((ManageNetworkFragment) currentFragment).device;
                deviceList.add(device);
                showScreen(ADD_NETWORK, deviceList);
            }
        }

        return super.onOptionsItemSelected(item);
    }

    @SuppressWarnings("StatementWithEmptyBody")
    @Override
    public boolean onNavigationItemSelected(MenuItem item) {
        int id = item.getItemId();

        if (id == R.id.nav_configuration) {
            showScreen(CONFIGURE);
        }
        else if (id == R.id.nav_startover) {
            String ssid = CirrentService.sharedService().getCurrentSSID();
            String softApSSID = CirrentService.sharedService().getSoftAPSSID();

            if (ssid != null && softApSSID != null && ssid.contains(softApSSID) == true) {
                CirrentService.sharedService().forgetSoftAPNetwork();
                if (softAPBeforeSSID != null) {
                    CirrentService.sharedService().connectToWifi(softAPBeforeSSID);
                }
            }
            showScreen(MANAGE_DEVICE);
        }

        DrawerLayout drawer = (DrawerLayout) findViewById(R.id.drawer_layout);
        drawer.closeDrawer(GravityCompat.START);
        return true;
    }

    public void showScreen(SCREEN screen) {
        showScreen(screen, null);
    }

    public void showScreen(SCREEN screen, ArrayList<Object> params) {
        Fragment fragment = null;

        showAddDeviceButton(false);
        switch (screen) {
            case LOGIN:
                fragment = new LoginFragment();
                this.setTitle("Settings");
                break;
            case CONFIGURE:
                fragment = new ConfigurationFragment();
                this.setTitle("Settings");
                break;
            case MANAGE_DEVICE:
                showAddDeviceButton(true);
                fragment = new ManageDeviceFragment();
                this.setTitle("Manage Device");
                break;
            case ADD_DEVICE:
                fragment = new AddDeviceFragment();
                this.setTitle("Setup");
                break;
            case CONNECT_DETAIL:
                fragment = new SetupDeviceFragment();
                this.setTitle("Get Connected");
                break;
            case SELECT_DEVICE:
                fragment = new SelectDeviceFragment();
                this.setTitle("Setup");
                break;
            case CONNECT:
                fragment = new ConfigureNetworkFragment();
                this.setTitle("Get Connected");
                break;
            case PROGRESSING:
                fragment = new ProgressingFragment();
                ((ProgressingFragment)fragment).previousScreen = currentScreen;
                this.setTitle("Get Connected");
                break;
            case SUCCESS:
                fragment = new SuccessFragment();
                this.setTitle("Success");
                break;
            case MANAGE_NETWORK:
                showAddDeviceButton(true);
                fragment = new ManageNetworkFragment();
                this.setTitle("Manage Network");
                if (params != null && params.size() > 0) {
                    SampleCloudService.SampleDevice device = (SampleCloudService.SampleDevice) params.get(0);
                    ((ManageNetworkFragment) fragment).device = device;
                }
                break;
            case ADD_NETWORK:
                fragment = new AddNetworkFragment();
                if (params != null && params.size() > 0) {
                    SampleCloudService.SampleDevice device = (SampleCloudService.SampleDevice) params.get(0);
                    ((AddNetworkFragment) fragment).device = device;
                }
                this.setTitle("Add Network");
                break;
            default:
                break;
        }

        if (fragment == null)
            return;

        currentScreen = screen;
        currentFragment = fragment;

        FragmentManager manager = getSupportFragmentManager();
        manager.beginTransaction().replace(R.id.content_main, fragment).commitAllowingStateLoss();
    }
}
