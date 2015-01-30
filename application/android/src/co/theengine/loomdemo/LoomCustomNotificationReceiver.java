package co.theengine.loomdemo;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;

import com.parse.ParsePushBroadcastReceiver;



public class LoomCustomNotificationReceiver extends ParsePushBroadcastReceiver 
{
    private static final String TAG = "LoomCustomNotificationReceiver";


    @Override
    public void onPushOpen(Context context, Intent intent) 
    {
        //handle custom notification data
        LoomMobile.processNotificationData(intent.getExtras());

        //create a new Intent for LoomDemo and let it go!
        Intent i = new Intent(context, LoomDemo.class);
        i.putExtras(intent.getExtras());
        i.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        context.startActivity(i);
    }
}
