package co.theengine.loomdemo;

import android.content.Context;
import android.content.Intent;
import android.app.Activity;
import android.os.Environment;
import android.util.Log;
import android.provider.Settings.System;


public class LoomMobile
{
    private static Activity     _context;
    private static int          _originalTimeout;




    public static void init(Activity ctx)
    {
        _context = ctx;

        ///store original screen timeout to reset at application end
        _originalTimeout = System.getInt(_context.getContentResolver(), System.SCREEN_OFF_TIMEOUT, -1);
    }
    

    public static void kill()
    {
        Log.d("Loom", "KILL LoomMobile");

        ///reset the original screen timeout on the system
        System.putInt(_context.getContentResolver(), System.SCREEN_OFF_TIMEOUT, _originalTimeout);
    }


    public static void setScreenTimeout(int timeout)
    {
        Log.d("Loom", "setScreenTimeout: " + timeout);

        ///set new screen timeout to use... -1 means "never"
        System.putInt(_context.getContentResolver(), System.SCREEN_OFF_TIMEOUT, timeout);
    }    
}
