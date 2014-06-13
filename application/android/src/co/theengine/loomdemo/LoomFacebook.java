package co.theengine.loomdemo;

import android.app.Activity;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.util.Log;
import android.util.Base64;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.content.Intent;
import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.ApplicationInfo;
import android.content.pm.Signature;

import com.facebook.android.Facebook.DialogListener;
import com.facebook.Session;
import com.facebook.SessionState;
import com.facebook.Settings;
import com.facebook.widget.WebDialog;
import com.facebook.FacebookException;
import com.facebook.FacebookRequestError;
import com.facebook.FacebookRequestError.Category;
import com.facebook.FacebookServiceException;
import com.facebook.FacebookOperationCanceledException;
import com.facebook.widget.WebDialog.RequestsDialogBuilder;


import java.util.List;
import java.util.Arrays;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import android.content.pm.PackageManager.NameNotFoundException;
import android.util.Log;

import java.text.DateFormat;
import java.text.SimpleDateFormat;

import org.cocos2dx.lib.Cocos2dxGLSurfaceView;



// Loom.Facebook API
public class LoomFacebook 
{
    private static final String TAG = "LoomFacebook";

    private static Session.StatusCallback mStatusCallback = new SessionStatusCallback();
    private static native void sessionStatusCallback(int sessionState, String sessionPermissions, int errorCode);
    private static LoomDemo mLoomDemo;
 
    protected static ViewGroup rootLayout;
    protected static Activity activity;
    protected static Handler handler;



    // Internal use
    public static void onCreate(LoomDemo loomDemo, Bundle savedInstanceState, ViewGroup value) 
    {   
        rootLayout = value;
        activity = (Activity)rootLayout.getContext();
        handler = new Handler(Looper.getMainLooper());

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
    

    public static void onStart(LoomDemo loomDemo) 
    {
        setLoomDemo(loomDemo);
        Session session = Session.getActiveSession();
        if(session != null)
        {
            session.addCallback(mStatusCallback);
        }
    }


    public static void onStop(LoomDemo loomDemo) 
    {
        setLoomDemo(loomDemo);
        Session session = Session.getActiveSession();
        if(session != null)
        {
            session.removeCallback(mStatusCallback);
        }
    }


    public static void onSaveInstanceState(LoomDemo loomDemo, Bundle outState) 
    {
        setLoomDemo(loomDemo);
        Session session = Session.getActiveSession();
        if(session != null)
        {
            Session.saveSession(session, outState);
        }
    }


    public static void onActivityResult(LoomDemo loomDemo, int requestCode, int resultCode, Intent data) 
    {
        setLoomDemo(loomDemo);
        Session session = Session.getActiveSession();
        if(session != null)
        {
            session.onActivityResult(mLoomDemo, requestCode, resultCode, data);
        }
    }

	public static boolean isPermissionGranted(String permission)
	{
		Session session = Session.getActiveSession();
        List<String> grantedPermissions = session.getPermissions();
        if (grantedPermissions != null) {
            return grantedPermissions.contains(permission);
        }
        return false;
		
	}



    public static boolean isActive() 
    {
        return checkFacebookAppId(mLoomDemo);
    }


	public static boolean openSessionWithReadPermissions(String permissionsString) 
    {
		if(checkFacebookAppId(mLoomDemo)) 
        {
			Session session = Session.getActiveSession();
			if ((session != null) && (!session.isOpened() && !session.isClosed()))
            {
				List<String> permissions = Arrays.asList(permissionsString.split(","));
				session.openForRead(new Session.OpenRequest(mLoomDemo).setCallback(mStatusCallback).setPermissions(permissions));
			}
            else
            {
				Session.openActiveSession(mLoomDemo, true, mStatusCallback);
			}
			return true;
		}
		return false;
	}


	public static boolean requestNewPublishPermissions(String permissionsString) 
    {
        if(checkFacebookAppId(mLoomDemo))
        {
    		Session session = Session.getActiveSession();
    		if ((session != null) && session.isOpened())
            {
    			List<String> permissions = Arrays.asList(permissionsString.split(","));
    			session.requestNewPublishPermissions(new Session.NewPermissionsRequest(mLoomDemo, permissions));
    			return true;
    		}
        }
		return false;
	}


	public static String getAccessToken() 
    {
        Session session = Session.getActiveSession();
		return (session != null) ? session.getAccessToken() : null;
	}


	public static void showFrictionlessRequestDialog(final String recipients, final String title, final String message) 
    {
		handler.post(new Runnable() 
        {
			@Override
			public void run() 
            {
				Bundle params = new Bundle();
				params.putString("title", title);
				params.putString("to", recipients);
				params.putString("message", message);
				params.putString("frictionless", "1");

		        WebDialog.OnCompleteListener listener = new WebDialog.OnCompleteListener() 
                {
		            @Override
		            public void onComplete(Bundle values, FacebookException error) 
                    {
// ... TODO: handle errors...???
		            }
		        };

				WebDialog reqDialog;
		        WebDialog.RequestsDialogBuilder builder = new WebDialog.RequestsDialogBuilder(
		        	activity, 
		        	Session.getActiveSession(), 
		        	params
		        ).setOnCompleteListener(listener);

		        reqDialog = builder.build();
		        reqDialog.show();
		    }
	    });
	}


    public static void closeAndClearTokenInformation()
	{
		Session session = Session.getActiveSession();
        if(session != null)
        {
            session.closeAndClearTokenInformation();
        }
	}


	public static String getExpirationDate(String dateFormat) 
    {
		String returnString;
		Session session = Session.getActiveSession();
		
		if(dateFormat != null)
		{
			DateFormat df = new SimpleDateFormat(dateFormat);
			returnString = df.format(session.getExpirationDate());
		}
		else
        {
			returnString = session.getExpirationDate().toString();
        }			
		return returnString;
	}



	private static class SessionStatusCallback implements Session.StatusCallback 
	{
		@Override
		public void call(Session _session, SessionState state, Exception exception) 
		{
            final Session session = _session;

            //handle errors
			int errorCode = 0;   //NoError
            if(exception != null)
            {
                if(exception instanceof FacebookOperationCanceledException)
                {
                    errorCode = 2;  //UserCancelled
                }
                else if(exception instanceof FacebookServiceException)
                {
                    FacebookRequestError statusError = ((FacebookServiceException)exception).getRequestError();
                    switch(statusError.getCategory())
                    {
                        case AUTHENTICATION_RETRY:
                        case AUTHENTICATION_REOPEN_SESSION:
                            errorCode = 1;  //RetryLogin
                            break;
                        case SERVER:
                            errorCode = 3;  //ApplicationNotPermitted
                            break;
                        case PERMISSION:
                        case THROTTLING:
                        case CLIENT:
                        case BAD_REQUEST:
                        case OTHER:
                            errorCode = 4;  //Unknown
                            break;
                    }
                }
                else
                {
                    errorCode = 4; //Unknown
                }
            }

            final int fErrorCode = errorCode;
			Cocos2dxGLSurfaceView.mainView.queueEvent(new Runnable() 
            {
				@Override
				public void run() 
                {
                    int state = 0;  //Created
                    if(session.isOpened())
                    {
                        state = 1;  //Opened
                    }
                    else if(session.isClosed())
                    {
                        state = 2; //Closed
                    }
					final int sessionState = state;
					final String sessionPermissionsString = (session.isOpened() ? session.getPermissions().toString() : "");
                    
                    Log.d(TAG, "FB SessionStatusCallback: State: " + sessionState + "  Permissions: " + sessionPermissionsString+ "  ErrorCode: " + fErrorCode);
                    sessionStatusCallback(sessionState, sessionPermissionsString, fErrorCode);
				}
			});
		}
	}


	private static void setLoomDemo(LoomDemo loomDemo) 
    {
		mLoomDemo = loomDemo;
	}


	public static String getFacebookAppId(Context context) 
    {
        try 
        {
			PackageInfo packageInfo = context.getPackageManager().getPackageInfo(context.getPackageName(), PackageManager.GET_SIGNATURES);
	    	for (Signature signature : packageInfo.signatures) {
		        MessageDigest md = MessageDigest.getInstance("SHA");
		        md.update(signature.toByteArray());
		        Log.d(TAG, "KeyHash: " + Base64.encodeToString(md.digest(), Base64.DEFAULT));
	        }
		} 
        catch (NameNotFoundException e) 
        {
	        Log.d(TAG, "KeyHash: (NameNotFoundException)");
		} 
        catch (NoSuchAlgorithmException e) 
        {
	        Log.d(TAG, "KeyHash: (NoSuchAlgorithmException)");
		}        
        // --------------------------

		String facebookAppId = null;
		try 
        {
			ApplicationInfo ai = context.getPackageManager().getApplicationInfo(context.getPackageName(), PackageManager.GET_META_DATA);
			if (ai.metaData != null) 
            {
				facebookAppId = ai.metaData.getString(Session.APPLICATION_ID_PROPERTY);
			}
		} 
        catch (PackageManager.NameNotFoundException e) 
        {
			// facebookAppId stays null
		}
		return facebookAppId;
	}

	
    private static boolean checkFacebookAppId(Context context) 
    {
		// Sanity check for a valid application id
		String facebookAppId = getFacebookAppId(context);
		Log.d(TAG, "facebookAppId: " + facebookAppId);

		if(facebookAppId == null || facebookAppId.isEmpty() || facebookAppId.trim().isEmpty()) 
        {
			Log.d(TAG, "No Facebook Application Id defined. Alter your 'loom.config' file, or 'application/android/res/values/strings.xml' file to use Loom.Facebook functionality.");
			return false;
		}
		return true;
	}
}
