package co.theengine.loomdemo;

import android.content.Context;
import android.content.Intent;
import android.app.Activity;
import android.os.Environment;
import android.os.Vibrator;
import android.os.Build;
import android.util.Log;
import android.provider.Settings.System;

import com.parse.Parse;
import com.parse.ParseAnalytics;
import com.parse.ParseInstallation;
import com.parse.PushService;


/**
 * Java Class that exposes the Parse Social Library for Android
 */
public class LoomParse
{
    ///vars
    private static Activity     _context;



    ///handles initialization of the Loom Mobile class
    public static void onCreate(Activity ctx)
    {
        _context = ctx;
    }


    ///initializes Parse with the app and client IDs
    public static boolean startUp(String appID, String clientKey)
    {
        Log.d("Loom", "Initialize Parse... AppID: " + appID + "  ClientKey: " + clientKey);

        ///initialize Parse for our application
        Parse.initialize(_context, appID, clientKey);

        ///initialize Push Notifications service
        PushService.setDefaultPushCallback(_context, LoomDemo.class);
        ParseInstallation.getCurrentInstallation().saveInBackground();
        
        return true;
    }
}
