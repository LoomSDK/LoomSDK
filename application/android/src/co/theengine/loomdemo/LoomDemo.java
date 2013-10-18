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
package co.theengine.loomdemo;

import org.cocos2dx.lib.Cocos2dxActivity;
import org.cocos2dx.lib.Cocos2dxEditText;
import org.cocos2dx.lib.Cocos2dxGLSurfaceView;
import org.cocos2dx.lib.Cocos2dxRenderer;

import android.app.ActivityManager;
import android.content.Context;
import android.content.res.Configuration;
import android.content.pm.ConfigurationInfo;
import android.os.Bundle;
import android.util.Log;
import android.widget.FrameLayout;
import android.widget.RelativeLayout;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.view.View;
import android.view.ViewTreeObserver.OnGlobalLayoutListener;
import android.content.Intent;
import android.graphics.Rect;

import co.theengine.loomdemo.billing.LoomStore;

public class LoomDemo extends Cocos2dxActivity {

	private Cocos2dxGLSurfaceView mGLView;

	public static LoomDemo instance = null;

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
	}

	public static void triggerGenericEvent(String type, String payload)
	{
		// Submit callback on proper thread.
        final String fType = type;
        final String fPayload = payload;

        Cocos2dxGLSurfaceView.mainView.queueEvent(new Runnable() {
            @Override
            public void run() {
                internalTriggerGenericEvent(fType, fPayload);
            }
        });
	}

	private static native void internalTriggerGenericEvent(String type, String payload);

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
	}

	private boolean keyboardHidden = true;

	protected void onCreate(Bundle savedInstanceState) 
	{
		instance = this;

		super.onCreate(savedInstanceState);
		
		if (!detectOpenGLES20())
		{
			Log.d("Loom", "Could not initialize OpenGL ES 2.0 - terminating!");
			finish();
			return;
		}

		// get the packageName, it's used to set the resource path
		String packageName = getApplication().getPackageName();
		super.setPackageName(packageName);

		// FrameLayout
		ViewGroup.LayoutParams framelayout_params = new ViewGroup.LayoutParams(
				ViewGroup.LayoutParams.FILL_PARENT,
				ViewGroup.LayoutParams.FILL_PARENT);
		FrameLayout framelayout = new FrameLayout(this);
		framelayout.setLayoutParams(framelayout_params);

		// Cocos2dxEditText layout
		ViewGroup.LayoutParams edittext_layout_params = new ViewGroup.LayoutParams(
				ViewGroup.LayoutParams.FILL_PARENT,
				ViewGroup.LayoutParams.WRAP_CONTENT);
		Cocos2dxEditText edittext = new Cocos2dxEditText(this);
		edittext.setLayoutParams(edittext_layout_params);        
		
		ViewGroup webViewGroup = new RelativeLayout(this);

		// ...add to FrameLayout
		framelayout.addView(edittext);

		// Cocos2dxGLSurfaceView
		mGLView = new Cocos2dxGLSurfaceView(this);

		// ...add to FrameLayout
		framelayout.addView(mGLView);
		
		framelayout.addView(webViewGroup);

		mGLView.setEGLContextClientVersion(2);
		mGLView.setCocos2dxRenderer(new Cocos2dxRenderer());
		mGLView.setTextField(edittext);

		// Set framelayout as the content view
		setContentView(framelayout);
		
		// give the webview class our layout
		LoomWebView.setRootLayout(webViewGroup);
		LoomAdMob.setRootLayout(webViewGroup);

		// Hook up the store.
		LoomStore.bind(this);

        // Listen for IME-initiated resizes.
        // Thanks to http://stackoverflow.com/questions/2150078/how-to-check-visibility-of-software-keyboard-in-android
        final View activityRootView = framelayout;
        Log.d("Loom", "Registering for global layout listener!");
        activityRootView.getViewTreeObserver().addOnGlobalLayoutListener(new OnGlobalLayoutListener() 
        {
            @Override
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
                    if (keyboardHidden)
                    {
                    	keyboardHidden = false;
                    	triggerGenericEvent("keyboardResize", "" + heightDiff);
                    }

                }
                else
                {
                	if (keyboardHidden)
                		return;

                	keyboardHidden = true;
                	// this matches iOS behavior
                	triggerGenericEvent("keyboardResize", "0");                	

                }


             }
        }); 

	}

	@Override
	public void onConfigurationChanged(Configuration newConfig) 
	{
		super.onConfigurationChanged(newConfig);

		if (newConfig.orientation == Configuration.ORIENTATION_LANDSCAPE)
			nativeSetOrientation("landscape");
		else
			nativeSetOrientation("portrait");
	}

	@Override
	protected void onPause() {
		super.onPause();
		mGLView.onPause();
	}

	@Override
	protected void onResume() {
		super.onResume();
		mGLView.onResume();
	}

	private boolean detectOpenGLES20() 
	{
		ActivityManager am = (ActivityManager) getSystemService(Context.ACTIVITY_SERVICE);
		ConfigurationInfo info = am.getDeviceConfigurationInfo();
		return (info.reqGlEsVersion >= 0x20000);
	}

	public static native void log(String message);
	public static native void logWarn(String message);
	public static native void logError(String message);
	public static native void logDebug(String message);
	public static void logInfo(String message) { log(message); }

	static 
	{
		// Initialize our native library.
		System.loadLibrary("LoomDemo");
	}
}