package co.theengine.loomdemo;

import android.util.Log;
import android.util.Base64;
import android.os.Bundle;
import android.content.Intent;
import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.ApplicationInfo;
import android.content.pm.Signature;

import com.facebook.Session;
import com.facebook.SessionState;
import com.facebook.Settings;

import java.util.List;
import java.util.Arrays;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import android.content.pm.PackageManager.NameNotFoundException;
import android.util.Log;

import org.cocos2dx.lib.Cocos2dxGLSurfaceView;

public class LoomFacebook {

	// Loom.Facebook API
	public static boolean openSessionWithReadPermissions(String permissionsString) {
		if(checkFacebookAppId(mLoomDemo)) {
			Session session = Session.getActiveSession();
			if (!session.isOpened() && !session.isClosed()) {
				List<String> permissions = Arrays.asList(permissionsString.split(",|\\s+|,\\s+"));
				session.openForRead(new Session.OpenRequest(mLoomDemo).setCallback(mStatusCallback).setPermissions(permissions));
			} else {
				Session.openActiveSession(mLoomDemo, true, mStatusCallback);
			}
			return true;
		}
		return false;
	}

	public static boolean requestNewPublishPermissions(String permissionsString) {
		Session session = Session.getActiveSession();
		if (!checkFacebookAppId(mLoomDemo) || session.isOpened()) {
			List<String> permissions = Arrays.asList(permissionsString.split(",|\\s+|,\\s+"));
			session.requestNewPublishPermissions(new Session.NewPermissionsRequest(mLoomDemo, permissions));
			return true;
		}
		return false;
	}

	public static String getAccessToken() {
		return Session.getActiveSession().getAccessToken();
	}

	// Internal use
	public static void onCreate(LoomDemo loomDemo, Bundle savedInstanceState) {
		setLoomDemo(loomDemo);
		Session session = Session.getActiveSession();
		if (session == null) 
		{
			if (savedInstanceState != null) 
			{
				session = Session.restoreSession(mLoomDemo, null, mStatusCallback, savedInstanceState);
			}
			
			if (session == null) 
			{
				session = new Session(mLoomDemo);
			}
			
			Session.setActiveSession(session);
			
			if (session.getState().equals(SessionState.CREATED_TOKEN_LOADED)) 
			{
				session.openForRead(new Session.OpenRequest(mLoomDemo).setCallback(mStatusCallback));
			}
		}	
	}

	public static void onStart(LoomDemo loomDemo) {
		setLoomDemo(loomDemo);
		Session.getActiveSession().addCallback(mStatusCallback);
	}

	public static void onStop(LoomDemo loomDemo) {
		setLoomDemo(loomDemo);
		Session.getActiveSession().removeCallback(mStatusCallback);
	}

	public static void onSaveInstanceState(LoomDemo loomDemo, Bundle outState) {
		setLoomDemo(loomDemo);
		Session session = Session.getActiveSession();
		Session.saveSession(session, outState);
	}

	public static void onActivityResult(LoomDemo loomDemo, int requestCode, int resultCode, Intent data) {
		setLoomDemo(loomDemo);
		Session.getActiveSession().onActivityResult(mLoomDemo, requestCode, resultCode, data);
	}

	private static class SessionStatusCallback implements Session.StatusCallback 
	{
		@Override
		public void call(Session _session, SessionState state, Exception exception) 
		{
			final Session session = _session;
			LoomDemo.logDebug("Pre-notifying Facebook on thread ID " + Thread.currentThread().getId());

			Cocos2dxGLSurfaceView.mainView.queueEvent(new Runnable() {
				@Override
				public void run() {
					final String sessionStateString = (session.isOpened() ? "OPENED" : (session.isClosed() ? "CLOSED" : "CREATED"));
					final String sessionPermissionsString = (session.isOpened() ? session.getPermissions().toString() : "");
					LoomDemo.logDebug("Notifying Facebook on thread ID " + Thread.currentThread().getId());
					nativeStatusCallback(sessionStateString, sessionPermissionsString);
					LoomCarrot.setAccessToken(getAccessToken());
				}
			});
		}
	}

	private static void setLoomDemo(LoomDemo loomDemo) {
		mLoomDemo = loomDemo;
	}

	public static String getFacebookAppId(Context context) {

        // --------------------------
        try {
			PackageInfo packageInfo = context.getPackageManager().getPackageInfo(context.getPackageName(), PackageManager.GET_SIGNATURES);
	    	for (Signature signature : packageInfo.signatures) {
		        MessageDigest md = MessageDigest.getInstance("SHA");
		        md.update(signature.toByteArray());
		        LoomDemo.logDebug("KeyHash: " + Base64.encodeToString(md.digest(), Base64.DEFAULT));
	        }
		} catch (NameNotFoundException e) {
	        LoomDemo.logDebug("KeyHash: (NameNotFoundException)");
		} catch (NoSuchAlgorithmException e) {
	        LoomDemo.logDebug("KeyHash: (NoSuchAlgorithmException)");
		}        
        // --------------------------

		String facebookAppId = null;
		try {
			ApplicationInfo ai = context.getPackageManager().getApplicationInfo(
				context.getPackageName(), PackageManager.GET_META_DATA);
			if (ai.metaData != null) {
				facebookAppId = ai.metaData.getString(Session.APPLICATION_ID_PROPERTY);
			}
		} catch (PackageManager.NameNotFoundException e) {
			// facebookAppId stays null
		}
		return facebookAppId;
	}

	private static boolean checkFacebookAppId(Context context) {
		// Sanity check for a valid application id
		String facebookAppId = getFacebookAppId(context);
		LoomDemo.logDebug("facebookAppId: " + facebookAppId);

		if(facebookAppId == null || facebookAppId.isEmpty() || facebookAppId.trim().isEmpty()) {
			LoomDemo.logDebug("No Facebook Application Id defined. Alter your 'loom.config' file, or 'application/android/res/values/strings.xml' file to use Loom.Facebook functionality.");
			return false;
		}

		return true;
	}

	private static Session.StatusCallback mStatusCallback = new SessionStatusCallback();
	private static native void nativeStatusCallback(String sessionState, String sessionPermissions);

	private static LoomDemo mLoomDemo;

}
