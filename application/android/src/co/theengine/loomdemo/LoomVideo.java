package co.theengine.loomdemo;

import android.net.Uri;
import android.content.Context;
import android.content.Intent;
import android.app.Activity;
import android.media.MediaPlayer;
import android.media.MediaPlayer.OnCompletionListener;
import android.media.MediaPlayer.OnErrorListener;
import android.widget.RelativeLayout;
import android.widget.VideoView;
import android.widget.MediaController;
import android.view.ViewGroup;
import java.io.File;
import java.text.SimpleDateFormat;
import java.util.Date;
import android.os.Environment;
import android.util.Log;
import android.view.View;
import android.graphics.Color;

import org.cocos2dx.lib.Cocos2dxGLSurfaceView;



public class LoomVideo
{
    ///constants
    public static final int           Controls_Show = 0;
    public static final int           Controls_Hide = 1;
    public static final int           Controls_StopOnTouch = 2;
    public static final int           Scale_None = 0;
    public static final int           Scale_Fill = 1;
    public static final int           Scale_FitAspect = 2;


    ///private vars
    private static ViewGroup    _rootView = null;
    private static VideoView    _videoView = null;
    private static Activity     _context = null;



    ///class to implement the listerer interfaces to act upon video states
    public static class VideoListeners implements OnCompletionListener, OnErrorListener
    {
        @Override
        public void onCompletion(MediaPlayer mp) 
        {
             Log.d("Loom", "Video Completed!");

             ///remove the video view from the root
            _rootView.removeView(_videoView);
            _rootView.setBackgroundColor(Color.TRANSPARENT);

            ///fire native callback noting completion
            deferNativeCallback(1, "complete");
        }    

        @Override
        public boolean onError(MediaPlayer mp, int what, int extra) 
        {
            Log.d("Loom", "Video Failed!");

            ///remove the video view from the root
            _rootView.removeView(_videoView);
            _rootView.setBackgroundColor(Color.TRANSPARENT);

            ///create error string
            String message = "error";
            message += (what == 1/*MediaPlayer.MEDIA_ERROR_UNKNOWN*/) ? " unknown: " : " server died: ";
            switch(extra)
            {
                case -1004://MediaPlayer.MEDIA_ERROR_IO:
                    message += "io error";
                    break;
                case -1007://MediaPlayer.MEDIA_ERROR_MALFORMED:
                    message += "malformed data error";
                    break;
                case -1010://MediaPlayer.MEDIA_ERROR_UNSUPPORTED:
                    message += "unsupported format error";
                    break;
                case -110://MediaPlayer.MEDIA_ERROR_TIMED_OUT:
                    message += "time out error";
                    break;
            }
        
            ///TODO: fire failed delegate
            deferNativeCallback(0, message);

///TODO: does true/false matter?
            return true;
        }  
    }



    ///handles initialization of the Loom Video class
    public static void init(ViewGroup parentView)
    {
        ///store some data for later
        _rootView = parentView;
        _context = (Activity)_rootView.getContext();

        ///create video view to play videos on and set initial data for it
        _videoView = new VideoView(_context);
        _videoView.setZOrderOnTop(true);
        _videoView.setVisibility(View.VISIBLE);
        _videoView.setBackgroundColor(Color.TRANSPARENT);
        _videoView.setKeepScreenOn(true);

        ///set up listeners to the view to react to events
        VideoListeners videoListeners = new VideoListeners();
        _videoView.setOnCompletionListener(videoListeners);
        _videoView.setOnErrorListener(videoListeners);
///TODO: OnTouch?        
    }



    ///start playing a video
    public static void playFullscreen(String file, int scaleMode, int controlMode, int bgColor)
    {
///TODO: figure out none / fit aspect
        ///set layout of the video view based on the layout flags
        RelativeLayout.LayoutParams layoutParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.MATCH_PARENT, 
                                                                                    RelativeLayout.LayoutParams.MATCH_PARENT);

        switch(scaleMode)
        {
            case Scale_None:
                layoutParams.addRule(RelativeLayout.CENTER_IN_PARENT);
                break;
            case Scale_Fill:
                layoutParams.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM);
                layoutParams.addRule(RelativeLayout.ALIGN_PARENT_TOP);
                layoutParams.addRule(RelativeLayout.ALIGN_PARENT_LEFT);
                layoutParams.addRule(RelativeLayout.ALIGN_PARENT_RIGHT);
                break;
            case Scale_FitAspect:
                layoutParams.addRule(RelativeLayout.CENTER_IN_PARENT);
                break;
        }
        _videoView.setLayoutParams(layoutParams);

        ///add video view to the parent view with the desired layout
        _rootView.addView(_videoView, layoutParams);
        _videoView.requestFocus();

        ///if specified, create media controller and link it with the video view
        switch(controlMode)
        {
            case Controls_Show:
                MediaController mediaController = new MediaController(_context);
                mediaController.setAnchorView(_videoView);
                mediaController.setMediaPlayer(_videoView);
                _videoView.setMediaController(mediaController);
                break;
            case Controls_Hide:
///TODO: Can set to null?            
                _videoView.setMediaController(null);
                break;
            case Controls_StopOnTouch:
                _videoView.setMediaController(null);
///TODO: Set up touch listener                
                break;
        }

        ///set root color for outside of the video play area
        _rootView.setBackgroundColor(bgColor);

        ///send the video URI to the video view
        ///NOTE: Both of these methods, either with the raw ID or /raw/filename_noext seem to work
        // int videoResourceID = _context.getResources().getIdentifier(file, "raw", _context.getPackageName());
        // Uri videoUri = Uri.parse("android.resource://" + _context.getPackageName() + "/" + videoResourceID);        
        Uri videoUri = Uri.parse("android.resource://" + _context.getPackageName() + "/raw/" + file);
        _videoView.setVideoURI(videoUri);

        ///start our video
        _videoView.start();
    }  



    // ________________________________________________
    // Native
    // ________________________________________________
    private static void deferNativeCallback(int type, String data)
    {
        final int fType = type;
        final String fData = data;

        Cocos2dxGLSurfaceView.mainView.queueEvent(new Runnable() {
            @Override
            public void run() {
                nativeCallback(fType, fData);
            }
        });
    }
    private static native void nativeCallback(int type, String data);    
}