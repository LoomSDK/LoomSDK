package co.theengine.loomdemo;

import android.content.Context;
import android.content.Intent;
import android.app.Activity;
import android.os.Environment;
import android.os.Vibrator;
import android.os.Build;
import android.util.Log;
import android.provider.Settings.System;
import android.net.Uri;

import org.cocos2dx.lib.Cocos2dxGLSurfaceView;



/**
 * Java Class that exposes miscellaneous Android mobile platform support
 */
public class LoomMobile
{
    //consts
    ///NOTE: Vibration duration / pattern issynced to match the built-in time that iOS uses, as that can't be changed
    private static final int           VIBRATION_DELAY     = 0;  
    private static final int           VIBRATION_DURATION  = 400;  
    private static final int           VIBRATION_SLEEP     = 100;
    private static final long[]        VIBRATION_PATTERN   = { VIBRATION_DELAY, VIBRATION_DURATION, VIBRATION_SLEEP };
    private static final String        MANIFEST_CUSTOM_URI_META_KEY = "co.theengine.loomdemo.CustomURL";

    ///vars
    private static Activity     _context;
    private static Vibrator     _vibrator;
    private static boolean      _canVibrate;
    private static Uri          _customURI = null;



    ///handles initialization of the Loom Mobile class
    public static void onCreate(Activity ctx)
    {
        _context = ctx;

        //vibration initialization
        _canVibrate = false;
        _vibrator = null;
        if(LoomDemo.checkPermission(ctx, "android.permission.VIBRATE"))
        {
            _vibrator = (Vibrator)_context.getSystemService(Context.VIBRATOR_SERVICE);
        }
        if(_vibrator != null)
        {
            ///'hasVibrator' was only added in API 11 (Honeycomb 3.0)
            if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB)
            {
                _canVibrate = _vibrator.hasVibrator();
            }
            else
            {
                ///assume pre-API 11 that if there is a VIBRATOR_SERVICE found, that we can vibrate!
                _canVibrate = true;
            }
        }
        Log.d("Loom", "Vibration supported: " + _canVibrate);

        //see if we have a custom intent scheme URI to snag now for Querying later on
        Intent intent = ctx.getIntent();        
        _customURI = (intent != null) ? intent.getData() : null;
        if(_customURI != null)
        {
            String customURLScheme = LoomDemo.getMetadataString(_context, MANIFEST_CUSTOM_URI_META_KEY);
            if((customURLScheme != null) && (_customURI.getScheme() != null) && !customURLScheme.equalsIgnoreCase(_customURI.getScheme()))
            {
                //not our custom URL scheme so ignore!
                _customURI = null;
            }
            else
            {
                //notify that we've launched via a custom URL
                Cocos2dxGLSurfaceView.mainView.queueEvent(new Runnable() 
                {
                    @Override
                    public void run() 
                    {
                        onOpenedViaCustomURL();
                    }
                });
            }
        }
    }


    ///cleans up the Mobile class on exit
    public static void onDestroy()
    {
        ///make sure that vibration has stopped
        stopVibrate();
    }


    ///handles application pausing cleanup
    public static void onPause()
    {
        ///make sure that vibration has stopped
        stopVibrate();
    }
    

    ///sets whether or not the application root view screen can go to sleep or not
    public static void allowScreenSleep(boolean sleep)
    {
        Log.d("Loom", "Allow Screen Sleep: " + sleep);

        ///run this code on the UI Thread
        final boolean fSleep = sleep;
        _context.runOnUiThread(new Runnable() 
        {
            @Override
            public void run() 
            {
                _context.getWindow().getDecorView().getRootView().setKeepScreenOn(!fSleep);
            }
        });
    }      

    ///tells the device to do a short vibration, if supported by the hardware
    public static void vibrate()
    {
        if(_canVibrate)
        {
            Log.d("Loom", "Vibrate");
            _vibrator.vibrate(VIBRATION_PATTERN, -1);
        }
    }


    ///forces a stop in the vibration
    private static void stopVibrate()
    {
        if(_canVibrate)
        {
            _vibrator.cancel();
        }        
    }


    ///sends text to another android application
    public static boolean shareText(String subject, String text)
    {
        Intent sharingIntent = new Intent(android.content.Intent.ACTION_SEND);
        sharingIntent.setType("text/plain");
        sharingIntent.putExtra(android.content.Intent.EXTRA_SUBJECT, subject);
        sharingIntent.putExtra(android.content.Intent.EXTRA_TEXT, text);

        Intent shareChooserIntent = Intent.createChooser(sharingIntent, "Share via...");
        shareChooserIntent.setFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK);
        if(shareChooserIntent != null)
        {
            _context.startActivity(shareChooserIntent);
            return true;
        }

        return false;
    }    


    ///returns if the application was launched via a Custom URL Scheme
    public static boolean openedWithCustomScheme()
    {
        return (_customURI != null) ? true : false;
    }    


    ///returns the data for a query of the custom scheme data string used to launch the app with, or null if not found / app wasn not launched with a custom URI scheme
    public static String getCustomSchemeQueryData(String queryKey)
    {
        return (_customURI != null) ? _customURI.getQueryParameter(queryKey) : null;
    }    



    ///native delegate stubs
    private static native void onOpenedViaCustomURL();
}
