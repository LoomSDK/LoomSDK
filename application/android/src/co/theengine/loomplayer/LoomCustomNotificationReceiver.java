package co.theengine.loomplayer;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;

import com.parse.ParsePushBroadcastReceiver;


/**
 * Java Class that extends the ParsePushBroadcastReceiver so we can access the data 
 * attached to the notification and then have access to it at a later time.
 */
public class LoomCustomNotificationReceiver extends ParsePushBroadcastReceiver 
{
    private static final String TAG = "LoomCustomNotificationReceiver";


    @Override
    public void onPushOpen(Context context, Intent intent) 
    {
        //handle custom notification data
        LoomMobile.processNotificationData(intent.getExtras());

        //create a new Intent for LoomPlayer and let it go!
        Intent i = new Intent(context, LoomPlayer.class);
        i.putExtras(intent.getExtras());
        i.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        context.startActivity(i);
    }
}
