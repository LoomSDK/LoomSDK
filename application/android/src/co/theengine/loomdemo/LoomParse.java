package co.theengine.loomdemo;

import android.app.Application;
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
    private static Context     _context;


    ///handles initialization of the Loom Mobile class
    public static void onCreate(Application app)
    {
        _context = app;

        String appID = app.getString(R.string.parseAppID);
        String clientKey = app.getString(R.string.parseClientKey);
        Log.d("Loom", "Initialize Parse... AppID: " + appID + "  ClientKey: " + clientKey);

        ///initialize Parse for our application
        Parse.initialize(app, appID, clientKey);

        ///initialize Push Notifications service
        PushService.setDefaultPushCallback(app, LoomDemo.class);
        ParseInstallation.getCurrentInstallation().saveInBackground();
    }


    ///initializes Parse with the app and client IDs
    public static boolean startUp(String appID, String clientKey)
    {
//TODO: likely remove this and have the C++ code just do nothing instead; wait until we see what happens with iOS Parse 1st        
        //Dummy function as Parse is started up in OnCreate above
        return true;
    }
	
	///Allows user to pull the installation ID from Loom for registration functionality.
	public static String getInstallationID()
	{
		String installId = ParseInstallation.getCurrentInstallation().getInstallationId();
		
		return installId;
	}
	
	///Allows uer to pull the installation's objectId for registration functionality.
	public static String getInstallationObjectID()
	{
		String objectId = ParseInstallation.getCurrentInstallation().getObjectId();
		
		return objectId;
	}
		///DoubleDoodle special case function that updates the custom userId property.
	public static String updateInstallationUserID(String userId)
	{
		ParseInstallation installation = ParseInstallation.getCurrentInstallation();
		
		installation.put("userId",userId);
				
		installation.saveInBackground();
		
		return("Installation saving data.");
	}
}
