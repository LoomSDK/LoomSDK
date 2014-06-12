package co.theengine.loomdemo;

import android.util.Log;
import android.os.Bundle;
import android.content.Intent;
import android.content.Context;
import android.content.pm.PackageManager;
import android.content.pm.ApplicationInfo;

import com.CarrotInc.Carrot.Carrot;

import org.cocos2dx.lib.Cocos2dxGLSurfaceView;


public class LoomTeak 
{
    public static final String TEAK_KEY_PROPERTY = "com.teak.AppSecret";

    static Carrot mTeak;



    public static void onCreate(LoomDemo loomDemo, String facebookAppId) 
    {
        if(mTeak == null) 
        {
            String teakKey = getTeakKey(loomDemo);

            if((teakKey != null) && !teakKey.isEmpty() && !teakKey.trim().isEmpty() &&
                (facebookAppId != null) && !facebookAppId.isEmpty() && !facebookAppId.trim().isEmpty()) 
            {
                mTeak = new Carrot(loomDemo, facebookAppId, teakKey);
                mTeak.setHandler(new Carrot.Handler() 
                {
                    @Override
                    public void authenticationStatusChanged(int authStatus) 
                    {
                        final int _authStatus = authStatus;
                        Cocos2dxGLSurfaceView.mainView.queueEvent(new Runnable() 
                        {
                            @Override
                            public void run() 
                            {
                                authStatusCallback(_authStatus);
                            }
                        });
                    }
                });
            }
        }
    }


    public static void onDestroy() 
    {
        if(mTeak != null) 
        {
            mTeak.close();
            mTeak = null;
        }
    }


    private static String getTeakKey(Context context) 
    {
        String teakKey = null;
        try 
        {
            ApplicationInfo ai = context.getPackageManager().getApplicationInfo(context.getPackageName(), 
                                                                                PackageManager.GET_META_DATA);
            if (ai.metaData != null) 
            {
                teakKey = ai.metaData.getString(TEAK_KEY_PROPERTY);
            }
        } 
        catch (PackageManager.NameNotFoundException e)
        {
            // teakKey stays null
        }
        return teakKey;
    }



    public static void setAccessToken(String accessToken) 
    {
        if(mTeak != null) 
        {
            mTeak.setAccessToken(accessToken);
        }
    }

    public static int getStatus() 
    {
        if(mTeak != null) 
        {
            return mTeak.getStatus();
        }
        return -1;
    }

    public static boolean postAchievement(String achievementId) 
    {
        if(mTeak != null) 
        {
            return mTeak.postAchievement(achievementId);
        }
        return false;
    }

    public static boolean postHighScore(int score) 
    {
        if(mTeak != null) 
        {
            return mTeak.postHighScore(score);
        }
        return false;
    }

    public static boolean postAction(String actionId, String objectInstanceId) 
    {
        if(mTeak != null) 
        {
            return mTeak.postAction(actionId, objectInstanceId);
        }
        return false;
    }


    private static native void authStatusCallback(int authStatus);
}
