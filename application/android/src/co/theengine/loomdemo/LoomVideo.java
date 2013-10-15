package co.theengine.loomdemo;

import android.net.Uri;
import android.content.Context;
import android.content.Intent;
import android.app.Activity;
// import android.widget.VideoView;
// import android.widget.MediaController;
import java.io.File;
import java.text.SimpleDateFormat;
import java.util.Date;
import android.os.Environment;
import android.util.Log;

public class LoomVideo
{
    public static final int     VIDEO_PLAYBACK_ACTIVITY_REQUEST_CODE = 200;




    public static void triggerVideoIntent(Activity ctx, String file)
    {
/*        
VideoView videoView = (VideoView)findViewById(R.id.videoView1);

MediaController mediaController = new MediaController(ctx);
mediaController.setAnchor(videoView);

Uri videoFile = Uri.parse("android.resource://" + getPackageName() + "/"  + file);

videoView.setVideoUri(videoFile);
videoView.setMediaController(mediaController);

videoView.start();



videoView = (VideoView) findViewById(R.id.videoView);
videoView.setVisibility(View.VISIBLE);
videoView.setOnCompletionListener(this);
videoView.setVideoURI(Uri.parse(path));
videoView.start();



VideoView video=(VideoView) findViewById(R.id.video);
MediaController mediaController = new MediaController(this);
mediaController.setAnchorView(video);
video.setMediaController(mediaController);
video.setKeepScreenOn(true);
String ourlink = videourl;
video.setVideoPath(ourlink);
video.requestFocus();
video.start();



VideoView video=(VideoView)findViewById(R.id.video);
video.setVideoPath(clip.getAbsolutePath());
MediaController ctlr=new MediaController(this);
ctlr.setMediaPlayer(video);
video.setMediaController(ctlr);
video.requestFocus();
video.start();

*/


        ///NOTE:
        ///Not all devices may have activities set up to support ACTION_VIEW on video/mp4 files that are streamed. 
        ///You should use PackageManager and queryIntentActivities() to confirm whether the startActivity() call will find a match, 
        ///or handle the ActivityNotFoundException that you get.

        ///get the Uri of the video on the device
        int videoResourceID = ctx.getResources().getIdentifier(file, "raw", ctx.getPackageName());
        Uri videoUri = Uri.parse("android.resource://" + ctx.getPackageName() + "/" + videoResourceID);        
        Log.d("Loom", "VIDEO URI IS " + videoUri);

        // create Intent to play the video and return control to the calling application
        Intent intent = new Intent(Intent.ACTION_VIEW, videoUri);

        // start the video playback Intent
        ctx.startActivityForResult(intent, VIDEO_PLAYBACK_ACTIVITY_REQUEST_CODE);
    }


    public static void onActivityResult(Activity ctx, int requestCode, int resultCode, Intent data) 
    {
        if (requestCode != VIDEO_PLAYBACK_ACTIVITY_REQUEST_CODE)
        {
            return;
        }

        Log.d("Loom", "VIDEO RESULT CODE IS " + resultCode);
        if (resultCode == Activity.RESULT_OK) 
        {
            // Fire results event.
            LoomDemo.triggerGenericEvent("videoSuccess", "");
        } 
        else 
        {
            // Video playback failed, advise user
            LoomDemo.triggerGenericEvent("videoFail", "fail");
        }
    }    
}