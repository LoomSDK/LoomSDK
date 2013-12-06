package co.theengine.loomdemo;

import android.content.Context;
import android.content.Intent;
import android.app.Activity;
import android.os.Environment;
import android.util.Log;
import android.provider.Settings.System;


/**
 * Java Class that exposes miscellaneous Android mobile platform support
 */
public class LoomMobile
{
    private static Activity     _context;



    ///handles initialization of the Loom Mobile class
    public static void onCreate(Activity ctx)
    {
        _context = ctx;
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
}
