package co.theengine.loomdemo;

import android.content.Context;
import android.content.Intent;
import android.app.Activity;
import android.os.Environment;
import android.os.Build;
import android.util.Log;
import android.provider.Settings.System;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;

import net.hockeyapp.android.CrashManager;
import net.hockeyapp.android.UpdateManager;


/**
 * Java Class that exposes HockeyApp Crash Reporting
 */
public class LoomHockeyApp
{
    ///vars
    private static Activity     _context;
    private static boolean      _initialized;
    private static String       _appID;

    private static final String TAG = "LoomHockeyApp";
    private static final String HOCKEYAPP_APPID_KEY = "net.hockeyapp.AppID";


//TEMP: until the CustomURL PR has landed
private static String getMetadataString(Context context, String key) 
{
    String metadata = null;
    try 
    {
        ApplicationInfo ai = context.getPackageManager().getApplicationInfo(context.getPackageName(), 
                                                                            PackageManager.GET_META_DATA);
        if (ai.metaData != null) 
        {
            metadata = ai.metaData.getString(key);
        }
    } 
    catch (PackageManager.NameNotFoundException e) {}
    return metadata;
}



    ///handles initialization of the Loom HockeyApp class
    public static void onCreate(Activity ctx)
    {
        _context = ctx;
        _initialized = false;
        _appID = null;

        //look for a HockeyApp AppId
        // _appID = LoomDemo.getMetadataString(loomDemo, HOCKEYAPP_APPID_KEY);
_appID = getMetadataString(_context, HOCKEYAPP_APPID_KEY);
Log.d(TAG, "Initialize HockeyApp... AppID: " + _appID);
        if((_appID != null) && !_appID.isEmpty() && !_appID.trim().isEmpty())
        {
            _initialized = true;
            Log.d(TAG, "HockeyApp Initialized!");
        }
    }


    ///cleans up the Mobile class on exit
    public static void onResume()
    {
        if(_initialized)
        {
            ///check for crashes
            CrashManager.register(_context, _appID);
        }
    } 
}
