package co.theengine.loomplayer;

import android.content.Context;
import android.content.Intent;
import android.app.Activity;
import android.os.Environment;
import android.os.Vibrator;
import android.os.Build;
import android.os.Bundle;
import android.os.Looper;
import android.util.Log;
import android.provider.Settings.System;
import android.net.Uri;

import android.location.Location;  
import android.location.LocationListener;  
import android.location.LocationManager; 

import org.json.JSONObject;
import org.json.JSONException;

import org.libsdl.app.SDLActivity;

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
    private static final String        MANIFEST_CUSTOM_URI_META_KEY = "co.theengine.loomplayer.CustomURL";
    private static final String        TAG = "LoomMobile";

    ///vars
    private static Activity         _context;
    private static Vibrator         _vibrator;
    private static boolean          _canVibrate;
    private static Uri              _customURI = null;
    private static JSONObject       _remoteNotificationData = null;
    private static boolean          _delayedRemoteNotificationDelegate = false;

    private static LocationTracker  _gpsLocation;
    private static LocationTracker  _netLocation;



    ///internal location listener wrapper class
    public static class LocationTracker implements LocationListener 
    {
        private boolean             _isRunning;
        private LocationManager     _locationManager;
        private String              _locationProvider;
        private Location            _lastLocation;


        public LocationTracker(Context context, String managerType) 
        {
            _locationManager = (LocationManager)context.getSystemService(Context.LOCATION_SERVICE);
            _locationProvider = managerType;
            _lastLocation = null;
            _isRunning = false;
        }


        //start updates for this location tracker
        public void startTracking(int minUpdateDistance, int minUpdateInterval)
        {
            if(!_isRunning)
            {
                _isRunning = true;
                _locationManager.requestLocationUpdates(_locationProvider, minUpdateInterval, minUpdateDistance, this, Looper.getMainLooper());
                _lastLocation = null;
            }
        }


        //stop updates for this location tracker
        public void stopTracking()
        {
            if(_isRunning)
            {
                _locationManager.removeUpdates(this);
                _isRunning = false;
            }
        }


        //returns the last tracked location. can be null.
        public Location getLocation()
        {
            return (_lastLocation != null) ? _lastLocation : _locationManager.getLastKnownLocation(_locationProvider);
        }


        //track any change of location
        public void onLocationChanged(Location newLoc)
        {
            _lastLocation = newLoc;
        }


        //invalidate the last location when we have been disabled
        public void onProviderDisabled(String arg0)
        {
            _lastLocation = null;
        }

        //stub functions for the LocationListener interface
        public void onProviderEnabled(String arg0) {}
        public void onStatusChanged(String arg0, int arg1, Bundle arg2) {}
    }



    ///handles initialization of the Loom Mobile class
    public static void onCreate(Activity ctx)
    {
        _context = ctx;

        //vibration initialization
        _canVibrate = false;
        _vibrator = null;
        if(LoomPlayer.checkPermission(ctx, "android.permission.VIBRATE"))
        {
            _vibrator = (Vibrator)_context.getSystemService(Context.VIBRATOR_SERVICE);
        }
        else
        {
            Log.d(TAG, "Vibration permission 'android.permission.VIBRATE' not found in the AndroidManifest. Vibration Support will not be initialized.");
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
        Log.d(TAG, "Vibration supported: " + _canVibrate);

        //prep up our location tracking
        _gpsLocation = null;
        _netLocation = null;
        if(LoomPlayer.checkPermission(ctx, "android.permission.ACCESS_FINE_LOCATION") ||
            LoomPlayer.checkPermission(ctx, "android.permission.ACCESS_COARSE_LOCATION"))
        {
            _gpsLocation = new LocationTracker(_context, LocationManager.GPS_PROVIDER);
            _netLocation = new LocationTracker(_context, LocationManager.NETWORK_PROVIDER);
        }

        //see if we have a custom intent scheme URI to snag now for Querying later on
        Intent intent = ctx.getIntent();        
        _customURI = (intent != null) ? intent.getData() : null;
        if(_customURI != null)
        {
            String customURLScheme = LoomPlayer.getMetadataString(_context, MANIFEST_CUSTOM_URI_META_KEY);
            if((customURLScheme != null) && (_customURI.getScheme() != null) && !customURLScheme.equalsIgnoreCase(_customURI.getScheme()))
            {
                //not our custom URL scheme so ignore!
                _customURI = null;
            }
            else
            {
                //notify that we've launched via a custom URL
                // TODO: does this require queueEvent?
                _context.runOnUiThread(new Runnable() 
                {
                    @Override
                    public void run() 
                    {
                        onOpenedViaCustomURL();
                    }
                });
            }
        }

        //do we need to notify the remote notification delegate now from a potential call before mainView was initialized?
        if(_delayedRemoteNotificationDelegate)
        {
            _delayedRemoteNotificationDelegate = false;
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
        Log.d(TAG, "Allow Screen Sleep: " + sleep);

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
            Log.d(TAG, "Vibrate");
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


    //starts location tracking
    public static void startLocationTracking(int minDist, int minTime)
    {
        if(_gpsLocation != null)
        {
            _gpsLocation.startTracking(minDist, minTime);
        }
        if(_netLocation != null)
        {
            _netLocation.startTracking(minDist, minTime);
        }
    }


    //stops location tracking
    public static void stopLocationTracking()
    {
        if(_gpsLocation != null)
        {
            _gpsLocation.stopTracking();
        }
        if(_netLocation != null)
        {
            _netLocation.stopTracking();
        }
    }


    //returns the latitude and longitude (as two floating point values separated by a space)
    //of the mobile device as a string, or null if no valid location can be found
    public static String getLocation()
    {
        String locString = null;

        //prefer GPS location to NETWORK location
        Location loc = (_gpsLocation != null) ? _gpsLocation.getLocation() : null;
        if(loc == null)
        {
            loc = (_netLocation != null) ? _netLocation.getLocation() : null;
        }
        if(loc != null)
        {
            locString = loc.getLatitude() + " " + loc.getLongitude();
        }
        return locString;
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


    ///returns if the application was launched via a Remote Notification
    public static boolean openedWithRemoteNotification()
    {
        return (_remoteNotificationData != null) ? true : false;
    }    


    ///returns the data for a query of the custom scheme data string used to launch the app with, or null if not found / app wasn not launched with a custom URI scheme
    public static String getCustomSchemeQueryData(String queryKey)
    {
        return (_customURI != null) ? _customURI.getQueryParameter(queryKey) : null;
    }    

    ///returns the data for a key of the remote notification data string used to launch the app with, or null if not found / app wasn not launched via a remote notification
    public static String getRemoteNotificationData(String key)
    {
        if(_remoteNotificationData != null)
        {
            try
            {
                return _remoteNotificationData.getString(key);
            }
            catch(Exception e)
            {
                Log.d(TAG, "Unable to locate Remote Notification Data for key: " + key);
            }            
        }
        return null;
    }    


    ///processes the notification data from our custom handler in LoomCustomNotificationReceiver
    public static void processNotificationData(Bundle bundle)
    {
        if(bundle == null)
        {
            return;
        }

        //store the notification data as our custom payload
        String message = bundle.getString("com.parse.Data");
        Log.d(TAG, "----Remote Notification Payload is: " + message);
        _remoteNotificationData = null;
        try 
        {
            //create our new JSON of the message data
            _remoteNotificationData = new JSONObject(message);

            //fire off the notification delegate if we have a mainView, otherwise delay it until onCreate
            if(((Activity)SDLActivity.getContext()) != null)
            {
                //notify that we've launched via a remote notification launch
                // TODO: does this require queueEvent?
                ((Activity)SDLActivity.getContext()).runOnUiThread(new Runnable() 
                {
                    @Override
                    public void run() 
                    {
                        onOpenedViaRemoteNotification();
                    }
                });  
            }
            else
            {
                _delayedRemoteNotificationDelegate = true;
            }
        } 
        catch (JSONException e) 
        {
            Log.e(TAG, "Unable to create JSONObject for Remote Notification Payload: " + message);
        }
    }


    ///native delegate stubs
    private static native void onOpenedViaCustomURL();
    private static native void onOpenedViaRemoteNotification();
}
