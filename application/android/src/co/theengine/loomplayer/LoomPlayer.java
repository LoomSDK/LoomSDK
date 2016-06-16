/****************************************************************************
Copyright (c) 2010-2012 cocos2d-x.org

http://www.cocos2d-x.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
 ****************************************************************************/
package co.theengine.loomplayer;

import android.app.ActivityManager;
import android.content.Context;
import android.content.res.Configuration;
import android.content.res.AssetManager;
import android.content.pm.ConfigurationInfo;
import android.content.pm.PackageManager;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager.NameNotFoundException;
import android.content.ActivityNotFoundException;
import android.os.Bundle;
import android.util.DisplayMetrics;
import android.util.Log;
import android.widget.FrameLayout;
import android.widget.RelativeLayout;
import android.view.Display;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;
import android.view.WindowManager;
import android.view.View;
import android.view.ViewTreeObserver.OnGlobalLayoutListener;
import android.content.Intent;
import android.graphics.Rect;
import android.media.AudioManager;
import android.media.MediaScannerConnection;

import java.io.File;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;

import android.net.Uri;
import android.os.Environment;
import co.theengine.loomplayer.billing.LoomStore;

import com.dolby.DolbyAudio;

import org.libsdl.app.SDLActivity;

public class LoomPlayer extends SDLActivity {
	
    public static LoomPlayer instance = null;
    
    private static String packageName;
    
    public static String getActivityPackageName()
    {
    	return packageName;
    }
    
    public static String getActivityWritablePath()
    {
    	return Environment.getExternalStorageDirectory().getAbsolutePath() + "/";
    }
    
    public static String getActivitySettingsPath()
    {
    	return getContext().getFilesDir().getAbsolutePath() + "/";
    }
    
    public static int getProfile() {
        //Determine screen size
        if ((getContext().getResources().getConfiguration().screenLayout & Configuration.SCREENLAYOUT_SIZE_MASK) == Configuration.SCREENLAYOUT_SIZE_LARGE) {     
            return 3;
        }
        else if ((getContext().getResources().getConfiguration().screenLayout & Configuration.SCREENLAYOUT_SIZE_MASK) == Configuration.SCREENLAYOUT_SIZE_NORMAL) {     
            return 2;
        } 
        else if ((getContext().getResources().getConfiguration().screenLayout & Configuration.SCREENLAYOUT_SIZE_MASK) == Configuration.SCREENLAYOUT_SIZE_SMALL) {     
            return 1;
        }
        else {
            return 0;
        }
    }
    
    public static float getDPI() 
    {
        // Return approximate DPI.
        DisplayMetrics metrics = new DisplayMetrics();
        WindowManager wm = (WindowManager) getContext().getSystemService(Context.WINDOW_SERVICE);
        Display display = wm.getDefaultDisplay();
        display.getMetrics(metrics);
        return metrics.densityDpi;
    }
    
    public static String getMetadataString(Context context, String key) 
    {
        String metaString = null;
        try 
        {
            ApplicationInfo ai = context.getPackageManager().getApplicationInfo(context.getPackageName(), 
                                                                                    PackageManager.GET_META_DATA);
            if (ai.metaData != null) 
            {
                return ai.metaData.getString(key);
            }
        } 
        catch (PackageManager.NameNotFoundException e) {}
        return null;
    }
    
    public static boolean openURL(String url)
    {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setData(Uri.parse(url));
        try {
            getContext().startActivity(intent);
        } catch (ActivityNotFoundException e) {
            return false;
        }
        return true;
    }
    
    public static boolean checkPermission(Context context, String permission)
    {
        int res = context.checkCallingOrSelfPermission(permission);
        return (res == PackageManager.PERMISSION_GRANTED) ? true : false;            
    }    


    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) 
    {
        // Process camera results.
        LoomCamera.onActivityResult(this, requestCode, resultCode, data);

        // Check which request we're responding to
        if (requestCode == LoomStore.INTENT_CODE) 
        {
            LoomStore.handleActivityResponse(resultCode, data);
        }
        else
        {
            super.onActivityResult(requestCode, resultCode, data);
        }
        
        //Process facebook activity result
        LoomFacebook.onActivityResult(this, requestCode, resultCode, data);
    }


    public static void triggerGenericEvent(String type, String payload)
    {
        // Submit callback on proper thread.
        final String fType = type;
        final String fPayload = payload;

        // TODO: does this need queueEvent?
        instance.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                internalTriggerGenericEvent(fType, fPayload);
            }
        });
    }

    private static native void internalTriggerGenericEvent(String type, String payload);
    public native void nativeSetPaths(String apkPath, AssetManager assetManager);
    public native void nativeSetOrientation(String orientation);

    public static void handleGenericEvent(String type, String payload)
    {
        Log.d("Loom", "Saw generic event " + type + " " + payload);
        if(type.equals("cameraRequest"))
        {
            LoomCamera.triggerCameraIntent(instance);
        }
        else if(type.equals("showStatusBar"))
        {
            instance.runOnUiThread(new Runnable() {
                public void run() {
                    instance.getWindow().clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
                    instance.getWindow().addFlags(WindowManager.LayoutParams.FLAG_FORCE_NOT_FULLSCREEN);
                }
            });
        }
        else if(type.equals("hideStatusBar"))
        {
            instance.runOnUiThread(new Runnable() {
                public void run() {
                    instance.getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
                    instance.getWindow().clearFlags(WindowManager.LayoutParams.FLAG_FORCE_NOT_FULLSCREEN);
                }
            });
        }
        else if(type.equals("saveToPhotoLibrary"))
        {
            instance.saveToPhotoLibrary(payload);
        }
    }

    protected void saveToPhotoLibrary(String path)
    {
        // Create a persistent storage location for saved library photos
        File mediaStorageDir = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), "AppPhotoLibrary");

        // Create the storage directory if it does not exist
        if (!mediaStorageDir.exists() && !mediaStorageDir.mkdirs())
        {
            Log.d("Loom", "failed to create directory: " + mediaStorageDir.getAbsolutePath());
            triggerGenericEvent("saveToPhotoLibraryFail", "mediaError");
            return;
        }

        File file = new File(path);
        InputStream in;

        try {
            if (file.exists())
            {
                in = new FileInputStream(file);
            }
            else
            {
                // Check if the file exists in the assets directory.
                AssetManager assetManager = getAssets();
                in = assetManager.open(path);
            }
        } catch (Exception e) {
            // Our file wasn't found apparently, so report error and exit.
            triggerGenericEvent("saveToPhotoLibraryFail", "badPath");
            return;
        }

        String mediaPath = mediaStorageDir + File.separator + path.substring( path.lastIndexOf( File.separator ) + 1 );
        
        try {
            // Copy our target file into our photo directory

            OutputStream out = new FileOutputStream(mediaPath);

            int len;
            byte[] buffer = new byte[1024];

            while ((len = in.read(buffer)) > 0)
            {
                out.write(buffer, 0, len);
            }

            in.close();
            out.close();

        } catch (Exception e) {
            Log.e("Loom", "exception", e);
            triggerGenericEvent("saveToPhotoLibraryFail", "mediaError");
            return;
        }

        // Scan the newly copied file into our MediaStore

        MediaScannerConnection.scanFile(this, new String[] { mediaPath }, null, new MediaScannerConnection.OnScanCompletedListener()
        {
            public void onScanCompleted(String path, Uri uri) {
                triggerGenericEvent("saveToPhotoLibrarySuccess", path);
            }
        });
    }

    private boolean keyboardHidden = true;
    private boolean keyboardIgnoreNextZero = false;

    @Override   
    protected String[] getLibraries() {
        return new String[] {
            "LoomPlayer"
        };
    }
    
    @Override
    protected void onCreate(Bundle savedInstanceState) 
    {
        instance = this;
        
        super.onCreate(savedInstanceState);

        if (mBrokenLibraries) return;

        // get the packageName, it's used to set the resource path
        packageName = getApplication().getPackageName();
        
        String apkFilePath = "";
        ApplicationInfo appInfo = null;
        PackageManager packMgmr = getApplication().getPackageManager();
        try {
            appInfo = packMgmr.getApplicationInfo(packageName, 0);
        } catch (NameNotFoundException e) {
            e.printStackTrace();
            throw new RuntimeException("Unable to locate assets, aborting...");
        }
        apkFilePath = appInfo.sourceDir;
        nativeSetPaths(apkFilePath, getAssets());
        
        if (!detectOpenGLES20())
        {
            Log.d("Loom", "Could not initialize OpenGL ES 2.0 - terminating!");
            finish();
            return;
        }
        
        // FrameLayout
        ViewGroup.LayoutParams framelayout_params = new ViewGroup.LayoutParams(
                                                            ViewGroup.LayoutParams.MATCH_PARENT,
                                                            ViewGroup.LayoutParams.MATCH_PARENT);
        FrameLayout framelayout = new FrameLayout(this);
        framelayout.setLayoutParams(framelayout_params);

        // Cocos2dxEditText layout
        ViewGroup.LayoutParams edittext_layout_params = new ViewGroup.LayoutParams(
                                                                ViewGroup.LayoutParams.MATCH_PARENT,
                                                                ViewGroup.LayoutParams.WRAP_CONTENT);
        //Cocos2dxEditText edittext = new Cocos2dxEditText(this);
        //edittext.setLayoutParams(edittext_layout_params);

        ViewGroup webViewGroup = new RelativeLayout(this);

        // ...add to FrameLayout
        //framelayout.addView(edittext);

        // Make sure we control volume properly.
        setVolumeControlStream(AudioManager.STREAM_MUSIC);

        framelayout.addView(webViewGroup);

        // Set framelayout as the content view
        mLayout.addView(framelayout);

        // give the webview class our layout
        LoomWebView.setRootLayout(webViewGroup);
        LoomAdMob.setRootLayout(webViewGroup);

        // Create Facebook
        LoomFacebook.onCreate(this, savedInstanceState, webViewGroup);

        // Create Teak
        LoomTeak.onCreate(this, LoomFacebook.getFacebookAppId(this));

        // Hook up the store.
        LoomStore.bind(this);

        ///Create HTTP class
        LoomHTTP.onCreate(this);

        ///Create Video View for our layout
        LoomVideo.onCreate(webViewGroup);

        ///Create Mobile class
        LoomMobile.onCreate(this);

        ///Create Sensor class
        LoomSensors.onCreate(this);

        ///attempt to initialize Dolby Audio for this device
        DolbyAudio.onCreate(this);

        // Listen for IME-initiated resizes.
        // Thanks to http://stackoverflow.com/questions/2150078/how-to-check-visibility-of-software-keyboard-in-android
        final View activityRootView = getWindow().getDecorView().findViewById(android.R.id.content);
        Log.d("Loom", "Registering for global layout listener!");
        activityRootView.getViewTreeObserver().addOnGlobalLayoutListener(new ViewTreeObserver.OnGlobalLayoutListener() 
        {
            public void onGlobalLayout() 
            {
                final Rect r = new Rect();
                activityRootView.getWindowVisibleDisplayFrame(r);
                final int heightDiff = activityRootView.getRootView().getHeight() - (r.bottom - r.top);
                
                // Convert the dps to pixels
                final float scale = activityRootView.getContext().getResources().getDisplayMetrics().density;
                final float scaledThreshold = (int) (100 * scale + 0.5f);
                
                if (heightDiff > scaledThreshold)
                {
                    // ignore if not hidden as this is probably an autocomplete bar coming up
                    keyboardHidden = false;
                    triggerGenericEvent("keyboardResize", "" + heightDiff);
                }
                else
                {
                	// We need to ignore the first zero after orientation as Android
                	// seems to report a layout change after orientation
                	// first without a keyboard (heightDiff == 0) and then with the keyboard (> 0)
                	// which would close our keyboard after orientation.
                	// So we just ignore the first layout change and count on the next ones.
                    if (!keyboardHidden && !keyboardIgnoreNextZero) {
                        keyboardHidden = true;
                        // this matches iOS behavior
                        triggerGenericEvent("keyboardResize", ""+0);
                    }
                }
                
                keyboardIgnoreNextZero = false;
             }
        });     
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) 
    {
        super.onConfigurationChanged(newConfig);
        
        if (mBrokenLibraries) return;

        keyboardIgnoreNextZero = true;
        
        if (newConfig.orientation == Configuration.ORIENTATION_LANDSCAPE)
            nativeSetOrientation("landscape");
        else
            nativeSetOrientation("portrait");
    }

    @Override
    protected void onStart() {
        super.onStart();
        if (mBrokenLibraries) return;
        LoomFacebook.onStart(this);
        DolbyAudio.onStart();
    }

    @Override
    protected void onStop() {
        super.onStop();
        if (mBrokenLibraries) return;
        LoomFacebook.onStop(this);
        DolbyAudio.onStop();
    }

    @Override
    protected void onPause() {
        super.onPause();
        if (mBrokenLibraries) return;
        LoomMobile.onPause();
        LoomSensors.onPause();
        LoomVideo.onPause();
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (mBrokenLibraries) return;
        LoomSensors.onResume();
        LoomVideo.onResume();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (mBrokenLibraries) return;
        LoomTeak.onDestroy();
        LoomMobile.onDestroy();
        LoomSensors.onDestroy();
        LoomVideo.onDestroy();
        DolbyAudio.onDestroy();   
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        if (mBrokenLibraries) return;
        LoomFacebook.onSaveInstanceState(this, outState);
    }

    private boolean detectOpenGLES20() 
    {
        ActivityManager am = (ActivityManager) getSystemService(Context.ACTIVITY_SERVICE);
        ConfigurationInfo info = am.getDeviceConfigurationInfo();
        return (info.reqGlEsVersion >= 0x20000);
    }

}
