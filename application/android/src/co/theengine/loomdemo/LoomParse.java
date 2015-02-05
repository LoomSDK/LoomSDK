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
import android.provider.Settings.Secure;

import com.parse.Parse;
import com.parse.ParseAnalytics;
import com.parse.ParseInstallation;


/**
 * Java Class that exposes the Parse Social Library for Android
 */
public class LoomParse
{
    private static final String TAG = "LoomParse";
    private static final String PARSE_APPID_KEY = "com.parse.ApplicationId";
    private static final String PARSE_CLIENTKEY_KEY = "com.parse.ClientKey";

    ///vars
    private static Context     _context;
    private static boolean     _initialized = false;


    ///handles initialization of the Loom Mobile class
    public static void onCreate(Application app)
    {
        _context = app;

        String appID = LoomDemo.getMetadataString(app, PARSE_APPID_KEY);
        String clientKey = LoomDemo.getMetadataString(app, PARSE_CLIENTKEY_KEY);
        // Log.d(TAG, "Initialize Parse... AppID: " + appID + "  ClientKey: " + clientKey);

        // if invalid strings or error on initialize, make sure to set _initialized = false
        _initialized = false;
        if((appID != null) && (clientKey != null) && !appID.isEmpty() && !clientKey.isEmpty())
        {
            ///NOTE: If your AndroidManifest specifies the com.parse.PushService but you do not call 
            ///         Parse.initialize (ie. no valid appId or clientKey) then your application *will* 
            ///         crash as soon as a Push Notification is detected

            ///initialize Parse for our application
            Parse.initialize(app, appID, clientKey);

            ParseInstallation installation = ParseInstallation.getCurrentInstallation();
            //set Android ID as the UniqueID for this installation to avoid bug with re-installs
            String androidId = Secure.getString(app.getContentResolver(), Secure.ANDROID_ID);
            installation.put("UniqueId", androidId);

            installation.saveInBackground();
            Log.d("LoomParse", "Completed initialization of Parse. InstallationID: " + installation.getInstallationId());
            _initialized = true;
        }
    }


    ///returns if Parse was able to to initialize at startup or not
    public static boolean isActive()
    {
        return _initialized;
    }

	
	///Allows user to pull the installation ID from Loom for registration functionality.
	public static String getInstallationID()
	{
        if(_initialized)
        {
            ParseInstallation installation = ParseInstallation.getCurrentInstallation();
            if(installation != null)
            {
                return installation.getInstallationId();
            }
        }
        return null;
	}
	
	///Allows user to pull the installation's objectId for registration functionality.
	public static String getInstallationObjectID()
	{
        if(_initialized)
        {
            ParseInstallation installation = ParseInstallation.getCurrentInstallation();
            if(installation != null)
            {
                return installation.getObjectId();
            }
        }
        return null;
	}
	
    ///Updates the custom userId property.
	public static boolean updateInstallationUserID(String userId)
    {
        if(_initialized)
        {
            ParseInstallation installation = ParseInstallation.getCurrentInstallation();
            if(installation != null)
            {
                installation.put("userId", userId); 
                installation.saveInBackground();
                return true;
            }
        }
        return false;
	}
}
