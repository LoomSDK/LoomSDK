/******************************************************************************
 *  This program is protected under international and U.S. copyright laws as
 *  an unpublished work. This program is confidential and proprietary to the
 *  copyright owners. Reproduction or disclosure, in whole or in part, or the
 *  production of derivative works therefrom without the express permission of
 *  the copyright owners is prohibited.
 *
 *                 Copyright (C) 2013 by Dolby Laboratories,
 *                             All rights reserved.
 ******************************************************************************/
package com.dolby;

import android.app.Activity;
import android.util.Log;

import com.dolby.dap.DolbyAudioProcessing;
import com.dolby.dap.OnDolbyAudioProcessingEventListener;


/**
 * This is an implementation of the Dolby Audio Processing API library.
 */
public class DolbyAudio  
{
    private static final String                 TAG = "LoomDolbyAudio";

    // This constant is to show that depending on your application's logic.
    // You might choose to handle pause/resume Dolby Audio Processing session
    // in the application's activity onPause/onResume methods.
    private static final boolean                RESTORE_SYSTEM_DOLBY_CONFIG_WHEN_IN_BACKGROUND = true;

    // Handle to Dolby Audio Processing
    private static DolbyAudioProcessing        _dolbyAudioProcessing;

    // Internal flag to maintain the connection status
    private static boolean                     _isDolbyAudioProcessingConnected = false;

    // Internal flag to maintain visibility status
    private static boolean                     _isActivityInForeground = false;

    ///our context
    private static Activity                     _context = null;
    


    ///class to implement the listerer interfaces for Dolby Audio
    public static class DolbyAudioListeners implements OnDolbyAudioProcessingEventListener
    {
         /******************************************************************************
         * Following methods provide an implementation of the listener interface
         * {@link com.dolby.ds.OnDolbyAudioProcessingEventListener}
         ******************************************************************************/
        @Override
        public void onEnabled(boolean on) 
        {
            Log.i(TAG, "onEnabled(" + on + ")");
        }

        @Override
        public void onProfileSelected(int profile)
        {
            Log.i(TAG, "onProfileSelected(" + profile + ")");
        }

        @Override
        public void onClientConnected()
        {
            Log.d(TAG, "onClientConnected()");

            // Dolby Audio Processing has connected
            _isDolbyAudioProcessingConnected = true;
        }

        @Override
        public void onClientDisconnected()
        {
            Log.w(TAG, "onClientDisconnected()");

            // Application's Dolby Audio Processing handle has been abnormally disconnected from the system service
            _isDolbyAudioProcessingConnected = false;

            // The application tries to establish connection again by releasing the current handle and initializing again
            if(isProcessingSupported()) 
            {
                try 
                {
                    // Release Dolby Audio Processing resource
                    _dolbyAudioProcessing.releaseDolbyAudioProcessing();
                } 
                catch(IllegalStateException ex) 
                {
                    handleIllegalStateException(ex);
                } 
                catch(RuntimeException ex) 
                {
                    handleRuntimeException(ex);
                }

                ///re-init!
                onCreate(_context);
            }
        }   
    }




    /** This method obtains a handle to Dolby Audio Processing */
    public static void onCreate(Activity context)
    {
        Log.d(TAG, "onCreate");

        _context = context;
        
        // Obtain the handle to Dolby Audio Processing 
        // NOTE: DolbyAudioProcessing objects should not be used until onClientConnected() is called.
        DolbyAudioListeners dolbyListeners = new DolbyAudioListeners();
        try
        {
            _dolbyAudioProcessing = DolbyAudioProcessing.getDolbyAudioProcessing(_context, dolbyListeners);
        }
        catch(IllegalStateException ex) 
        {
            handleIllegalStateException(ex);
        } 

        // Not all Android devices have Dolby Audio Processing integrated. So DolbyAudioProcessing may not be available.
        if(_dolbyAudioProcessing == null) 
        {
            Log.d(TAG, "Dolby Audio Processing not available on this device.");
        }
    }


    /** Called when the activity is finishing or being destroyed by the system */
    public static void onDestroy()
    {
        Log.d(TAG, "onDestroy");

        // Release Dolby Audio Processing resource
        if(isProcessingSupported())
        {
            try
            {
                _dolbyAudioProcessing.releaseDolbyAudioProcessing();
                _dolbyAudioProcessing = null;
            } 
            catch(IllegalStateException ex)
            {
                handleIllegalStateException(ex);
            } 
            catch(RuntimeException ex) 
            {
                handleRuntimeException(ex);
            }
        }
    }


    public static void onStart()
    {
        ///NOTE: Dolby Example code uses onStart for some reason... Could/should we use onResume instead? 
        Log.d(TAG, "onStart()");

        _isActivityInForeground = true;

        // Resume Dolby Audio Processing session
        // If the application Paused the Dolby Audio Processing session before, then Dolby Audio Processing 
        // configuration will be restored to the state it was Paused in
        try 
        {
            if(_isDolbyAudioProcessingConnected) 
            {
                Log.d(TAG, "onStart() : resumeSession()");
                _dolbyAudioProcessing.restartSession(RESTORE_SYSTEM_DOLBY_CONFIG_WHEN_IN_BACKGROUND);
            }
        } 
        catch(IllegalStateException ex) 
        {
            handleIllegalStateException(ex);
        } 
        catch(RuntimeException ex) 
        {
            handleRuntimeException(ex);
        }
    }


    public static void onStop()
    {
        ///NOTE: Dolby Example code uses onStop for some reason... Could/should we use onPause instead? 
        Log.d(TAG, "onStop()");

        _isActivityInForeground = false;

        // The application's Activity is exiting the foreground 
        // Dolby Audio Processing session should be paused to allow it to be resumed later
        try 
        {
            if(_isDolbyAudioProcessingConnected) 
            {
                _dolbyAudioProcessing.suspendSession(RESTORE_SYSTEM_DOLBY_CONFIG_WHEN_IN_BACKGROUND);
            }
        } 
        catch(IllegalStateException ex) 
        {
            handleIllegalStateException(ex);
        } 
        catch(RuntimeException ex) 
        {
            handleRuntimeException(ex);
        }
    }

    
    /** Returns the value of the Dolby Audio Profile Profile */
    public static boolean isProcessingSupported()
    {
        return (_dolbyAudioProcessing == null) ? false : true;
    }


    /** Call to set enable state of Dolby audio processing. */
    public static void setProcessingEnabled(boolean enable)
    {
        if(isProcessingSupported()) 
        {
            try
            {
                // Enable/disable Dolby Audio Processing 
                _dolbyAudioProcessing.setAudioProcessingEnabled(enable);
            }
            catch(IllegalStateException ex) 
            {
                handleIllegalStateException(ex);
            }
            catch(RuntimeException ex) 
            {
                handleRuntimeException(ex);
            }
        }
    }


    /** Call to set Dolby audio processing profile selection. */
    public static boolean isProcessingProfileSupported(String profile)
    {
        if(isProcessingSupported()) 
        {
            try 
            {
                if(getProfileIndexForName(profile) != -1)
                {
                    return true;
                }
            }
            catch(IllegalStateException ex)
            {
                handleIllegalStateException(ex);
            }
            catch(IllegalArgumentException ex)
            {
                handleIllegalArgumentException(ex);
            }
            catch(RuntimeException ex) 
            {
                handleRuntimeException(ex);
            }
        }
        return false;
    }


    /** Call to set Dolby audio processing profile selection. */
    public static boolean setProcessingProfile(String profile)
    {
        if(isProcessingSupported()) 
        {
            try 
            {
                ///get the profile index to set bassed on the name provided
                int profileIndex = getProfileIndexForName(profile);

                // Set Dolby Audio Processing profile from the found index
                if(profileIndex != -1)
                {
                    _dolbyAudioProcessing.setProfile(profileIndex);
                    return true;
                }
            }
            catch(IllegalStateException ex)
            {
                handleIllegalStateException(ex);
            }
            catch(IllegalArgumentException ex)
            {
                handleIllegalArgumentException(ex);
            }
            catch(RuntimeException ex) 
            {
                handleRuntimeException(ex);
            }
        }
        return false;
    }


    /** Call to get the index of the currently selected Dolby audio processing profile. */
    public static String getSelectedProfile()
    {
        if(isProcessingSupported())
        {
            try
            {
                int profileIndex = _dolbyAudioProcessing.getSelectedProfile();
                return getProfileName(profileIndex);
            }
            catch(IllegalStateException ex)
            {
                handleIllegalStateException(ex);
            }
            catch(RuntimeException ex) 
            {
                handleRuntimeException(ex);
            }
        }
        
        return "";
    }
 

    /** Call to check if Dolby audio processing is currently enabled. */
    public static boolean isProcessingEnabled()
    {
        if(isProcessingSupported())
        {
            try
            {
                return _dolbyAudioProcessing.isAudioProcessingEnabled();
            }
            catch(IllegalStateException ex)
            {
                handleIllegalStateException(ex);
            }
            catch(RuntimeException ex) 
            {
                handleRuntimeException(ex);
            }
        }
        return false;
    }


    /** Call to get the number of available Dolby audio processing profiles. */
    private static int getNumProfiles()
    {
        int numProfiles = 0;
        if(isProcessingSupported())
        {
            try
            {
                numProfiles = _dolbyAudioProcessing.getNumProfiles();
            }
            catch(IllegalStateException ex)
            {
                handleIllegalStateException(ex);
            }
            catch(RuntimeException ex) 
            {
                handleRuntimeException(ex);
            }
        }
        return numProfiles;
    } 
  

    /** Call to get a string representing the name of a Dolby audio processing profile, given it's index. */
    private static String getProfileName(int profileIndex)
    {
        String profileName = "";
        if(isProcessingSupported())
        {
            try
            {
                profileName = _dolbyAudioProcessing.getProfileName(profileIndex);
            }
            catch(IllegalStateException ex)
            {
                handleIllegalStateException(ex);
            }
            catch(IllegalArgumentException ex)
            {
                handleIllegalArgumentException(ex);
            }
        }
        return profileName;
    }
    
    
    /** finds the index of a given profile name */
    private static int getProfileIndexForName(String profileName)
    {
        ///attempts to find the profile string provided
        for(int i=0;i<getNumProfiles();i++)
        {
            if(profileName.equalsIgnoreCase(getProfileName(i)))
            {
                ///found!
                return i;
            }
        }
        return -1;
    }   


  
    /** Generic handler for IllegalStateException */
    private static void handleIllegalStateException(Exception ex)
    {
        Log.e(TAG, "Dolby Audio Processing is not ready");
        handleGenericException(ex);
    }

    /** Generic handler for IllegalArgumentException */
    private static void handleIllegalArgumentException(Exception ex)
    {
        Log.e(TAG,"One of the passed arguments is invalid");
        handleGenericException(ex);
    }

    /** Generic handler for RuntimeException */
    private static void handleRuntimeException(Exception ex)
    {
        Log.e(TAG, "Internal error occured in Dolby Audio Processing");
        handleGenericException(ex);
    }

    /** Logs out the stack trace associated with the Exception*/
    private static void handleGenericException(Exception ex)
    {
        Log.e(TAG, Log.getStackTraceString(ex));
    }
}
