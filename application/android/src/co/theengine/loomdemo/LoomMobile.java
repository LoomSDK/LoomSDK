package co.theengine.loomdemo;

import android.content.Context;
import android.content.Intent;
import android.app.Activity;
import android.os.Environment;
import android.os.Vibrator;
import android.os.Build;
import android.util.Log;
import android.provider.Settings.System;


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

    ///vars
    private static Activity     _context;
    private static Vibrator     _vibrator;
    private static boolean      _canVibrate;



    ///handles initialization of the Loom Mobile class
    public static void onCreate(Activity ctx)
    {
        _context = ctx;
        _vibrator = (Vibrator)_context.getSystemService(Context.VIBRATOR_SERVICE);
        _canVibrate = false;
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
}
