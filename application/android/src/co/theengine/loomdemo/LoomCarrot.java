package co.theengine.loomdemo;

import android.util.Log;
import android.os.Bundle;
import android.content.Intent;
import android.content.Context;
import android.content.pm.PackageManager;
import android.content.pm.ApplicationInfo;

import com.gocarrot.android.Carrot;

import org.cocos2dx.lib.Cocos2dxGLSurfaceView;

//SOCIALTODO: LFL: likely move over to new Teak API eventually
public class LoomCarrot 
{
    static Carrot mCarrot;

    
	public static final String CARROT_KEY_PROPERTY = "com.gocarrot.CarrotAppSecret";


	public static void onDestroy() 
    {
		if(mCarrot != null) 
        {
			mCarrot.close();
			mCarrot = null;
		}
	}

	public static void onCreate(LoomDemo loomDemo) 
    {
		if(mCarrot == null) 
        {
//SOCIALTODO: LFL: Need LoomFacebook to get the AppId!!!            
			String facebookAppId = null;//LoomFacebook.getFacebookAppId(loomDemo);
			String carrotKey = getCarrotKey(loomDemo);

			if(carrotKey != null && !carrotKey.isEmpty() && !carrotKey.trim().isEmpty() &&
				facebookAppId != null && !facebookAppId.isEmpty() && !facebookAppId.trim().isEmpty()) {
				mCarrot = new Carrot(loomDemo, facebookAppId, carrotKey);

				mCarrot.setHandler(new Carrot.Handler() 
				{
					@Override
					public void authenticationStatusChanged(int authStatus) 
					{
						final int _authStatus = authStatus;
						Cocos2dxGLSurfaceView.mainView.queueEvent(new Runnable() {
							@Override
							public void run() {
								String authStatusString = Carrot.getAuthStatusString(_authStatus);
								nativeStatusCallback(authStatusString);
							}
						});
					}
				});
			}
		}
	}

	public static void setAccessToken(String accessToken) 
    {
		if(mCarrot != null) {
			mCarrot.setAccessToken(accessToken);
		}
	}

	public static String getStatus() 
    {
		if(mCarrot != null) {
			return Carrot.getAuthStatusString(mCarrot.getStatus());
		}
		return null;
	}

	public static boolean postAchievement(String achievementId) 
    {
		if(mCarrot != null) {
			return mCarrot.postAchievement(achievementId);
		}
		return false;
	}

	public static boolean postHighScore(int score) 
    {
		if(mCarrot != null) {
			return mCarrot.postHighScore(score);
		}
		return false;
	}

	public static boolean postAction(String actionId, String objectInstanceId) 
    {
		if(mCarrot != null) {
			return mCarrot.postAction(actionId, objectInstanceId);
		}
		return false;
	}

	private static String getCarrotKey(Context context) 
    {
		String carrotKey = null;
		try {
			ApplicationInfo ai = context.getPackageManager().getApplicationInfo(
				context.getPackageName(), PackageManager.GET_META_DATA);
			if (ai.metaData != null) {
				carrotKey = ai.metaData.getString(CARROT_KEY_PROPERTY);
			}
		} catch (PackageManager.NameNotFoundException e) {
			// carrotKey stays null
		}
		return carrotKey;
	}



    private static native void nativeStatusCallback(String authStatus);
}
