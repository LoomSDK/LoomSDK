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
import android.view.MotionEvent;
import android.view.View.OnTouchListener;
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
    public static final int           Scale_None = 0;
    public static final int           Scale_Fill = 1;
    public static final int           Scale_FitAspect = 2;
    public static final int           Controls_Show = 0;
    public static final int           Controls_Hide = 1;
    public static final int           Controls_StopOnTouch = 2;


    ///private vars
    private static ViewGroup    _rootView = null;
    private static VideoView    _videoView = null;
    private static Activity     _context = null;
    private static int          _controlMode = Controls_Show;



    ///class to implement the listerer interfaces to act upon video states
    public static class VideoListeners implements OnCompletionListener, OnErrorListener, OnTouchListener
    {
        @Override
        public void onCompletion(MediaPlayer mp) 
        {
             Log.d("Loom", "Video Completed!");

             ///remove the video view from the root
            _rootView.removeView(_videoView);
            _rootView.setBackgroundColor(Color.TRANSPARENT);

            ///fire native callback noting completion
            deferNativeCallback(1, "success");
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
        
            ///fire failed delegate
            deferNativeCallback(0, message);
            return true;
        }


        @Override
        public boolean onTouch(View v, MotionEvent event)
        {
            ///stop playback on touch if video flags indiated that
            if(_controlMode == Controls_StopOnTouch)
            {
                Log.d("Loom", "Video Skipped!");

                _videoView.stopPlayback();
                onCompletion(null);
                return true;
            }

            ///swallow the event if controls are hidden
            return (_controlMode == Controls_Hide) ? true : false;
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
        _videoView.setOnTouchListener(videoListeners);
    }


    ///start playing a video... wrapper for the main function that does this as we need to do that on the UI Thread
    public static void playFullscreen(String file, int scaleMode, int controlMode, int bgColor)
    {
        final String f = file;
        final int sm = scaleMode;
        final int cm = controlMode;
        final int bgc = bgColor;

        ///run this code on the UI Thread
        _context.runOnUiThread(new Runnable() 
        {
            @Override
            public void run() 
            {
                LoomVideo.playFSInternal(f, sm, cm, bgc);
            }
        });
    }




    ///internal function for playing a video
    private static void playFSInternal(String file, int scaleMode, int controlMode, int bgColor)
    {
        Log.d("Loom", "Video Play Fullscreen: " + file + " " + scaleMode + " " + controlMode + " " + bgColor);

///TODO: Scale_None
        ///set layout of the video view based on the layout flags
        RelativeLayout.LayoutParams layoutParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.WRAP_CONTENT, 
                                                                                    RelativeLayout.LayoutParams.WRAP_CONTENT);

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
        // _videoView.setLayoutParams(layoutParams);

        ///add video view to the parent view with the desired layout
        _rootView.addView(_videoView, layoutParams);
        _videoView.requestFocus();

        ///if specified, create media controller and link it with the video view
        _controlMode = controlMode;
        switch(_controlMode)
        {
            case Controls_Show:
                MediaController mediaController = new MediaController(_context);
                mediaController.setAnchorView(_videoView);
                mediaController.setMediaPlayer(_videoView);
                _videoView.setMediaController(mediaController);
                break;
            case Controls_Hide:
                _videoView.setMediaController(null);
                break;
            case Controls_StopOnTouch:
                _videoView.setMediaController(null);
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

        Cocos2dxGLSurfaceView.mainView.queueEvent(new Runnable() 
        {
            @Override
            public void run() 
            {
                nativeCallback(fType, fData);
            }
        });
    }
    private static native void nativeCallback(int type, String data);    
}