package co.theengine.loomdemo;

import android.net.Uri;
import android.content.Context;
import android.content.Intent;
import android.app.Activity;
import android.media.MediaPlayer;
import android.media.MediaPlayer.OnCompletionListener;
import android.media.MediaPlayer.OnErrorListener;
import android.media.MediaPlayer.OnPreparedListener;
import android.widget.RelativeLayout;
import android.widget.VideoView;
import android.widget.MediaController;
import android.view.ViewGroup;
import android.view.MotionEvent;
import android.view.View.OnTouchListener;
import android.view.SurfaceView;
import java.io.File;
import java.text.SimpleDateFormat;
import java.util.Date;
import android.os.Environment;
import android.util.Log;
import android.view.View;
import android.view.KeyEvent;
import android.graphics.Color;

import org.libsdl.app.SDLActivity;
//import org.libsdl.app.SDLSurface;

/**
 * Java Class that exposes Android fullscreen video playback
 */
public class LoomVideo
{
    ///constants
    public static final int             Scale_None = 0;
    public static final int             Scale_Fill = 1;
    public static final int             Scale_FitAspect = 2;
    public static final int             Controls_Show = 0;
    public static final int             Controls_Hide = 1;
    public static final int             Controls_StopOnTouch = 2;
    public static final int             Video_Resume_Offset = 500;
    private static final String         TAG = "LoomVideo";


    ///private vars
    private static ViewGroup        _rootView = null;
    private static VideoView        _videoView = null;
    private static MediaController  _mediaController = null;
    private static Activity         _context = null;
    private static String           _videoFile = null;
    private static int              _controlMode = Controls_Show;
    private static int              _scaleMode = Scale_None;
    private static int              _bgColor = Color.TRANSPARENT;
    private static int              _suspendedVideoPos = 0;
    private static boolean          _isPlaying = false;
    private static boolean          _isPaused = false;



    ///class to implement the listerer interfaces to act upon video states
    public static class VideoListeners implements OnCompletionListener, OnErrorListener, OnTouchListener, OnPreparedListener
    {
        @Override
        public void onCompletion(MediaPlayer mp) 
        {
            Log.d(TAG, "Video Completed!");

            ///cleans up playback
            cleanup();

            ///fire native callback noting completion
            deferNativeCallback(1, "success");
        }    

        @Override
        public boolean onError(MediaPlayer mp, int what, int extra) 
        {
            Log.d(TAG, "Video Failed!");

            ///cleans up playback
            cleanup();

            ///create error string
            String message = "error";
            switch(what)
            {
                case 1://MediaPlayer.MEDIA_ERROR_UNKNOWN:
                    message += " unknown: possible issues";
                    message += " :video dimesions too large";
                    message += " :unsupported video format";
                    message += " :unable to find video";
                    message += " :corrupted video file";
                    break;
                case 100://MedaiPlayer.MEDIA_ERROR_SERVER_DIED:
                    message += " server died ";
                    break;
            }
            switch(extra)
            {
                case -1004://MediaPlayer.MEDIA_ERROR_IO:
                    message += ":io error";
                    break;
                case -1007://MediaPlayer.MEDIA_ERROR_MALFORMED:
                    message += ":malformed data error";
                    break;
                case -1010://MediaPlayer.MEDIA_ERROR_UNSUPPORTED:
                    message += ":unsupported format error";
                    break;
                case -110://MediaPlayer.MEDIA_ERROR_TIMED_OUT:
                    message += ":time out error";
                    break;
                default:
                    message += ":extra code-> " + extra;
                    break;
            }
        
            ///fire failed delegate
            deferNativeCallback(0, message);

            return true;
        }


        @Override
        public boolean onTouch(View v, MotionEvent event)
        {
            ///only care about touch events
            if(event.getActionMasked() == MotionEvent.ACTION_DOWN)
            {
                ///stop playback on touch if video flags indiated that
                if(_controlMode == Controls_StopOnTouch)
                {
                    _videoView.stopPlayback();
                    onCompletion(null);
                    Log.d(TAG, "Video Skipped!");
                }
                else if(_controlMode == Controls_Show)
                {
                    ///take over manual show/hide of the mediaController to avoid strange auto-showing 
                    ///of the controls on secondary playbacks if setMediaController() has a videoView 
                    ///set when their playback starts
                    if(_mediaController.isShowing())
                    {
                        ///hide controls
                        _mediaController.hide();
                        _videoView.setMediaController(null);
                        _mediaController.setAnchorView(null);
                    }
                    else
                    {
                        ///show controls
                        _videoView.setMediaController(_mediaController);
                        _mediaController.setAnchorView(_videoView);
                        _mediaController.show();
                    }
                }
            }

            ///swallow the touch
            return true;
        }


        @Override
        public void onPrepared(MediaPlayer mp)
        {
            Log.d(TAG, "Video Prepared");
            _videoView.requestFocus();

            ///set the layout of the video to the user specs
            _videoView.setLayoutParams(getLayout(mp.getVideoWidth(), mp.getVideoHeight()));  
            _videoView.invalidate();
            _videoView.requestLayout();

            ///set root color for outside of the video play area to make it visible (if desired) now
            _rootView.setBackgroundColor(_bgColor);
        }
    } 



    ///handles initialization of the Loom Video class
    public static void onCreate(ViewGroup parentView)
    {
        ///store some data for later
        _rootView = parentView;
        _context = (Activity)_rootView.getContext();

        ///create video view to play videos on and set initial data for it
        _videoView = new VideoView(_context)
        {
            ///intercept the Back Button
            @Override
            public boolean dispatchKeyEvent (KeyEvent event)
            {
                if(event.getKeyCode() == KeyEvent.KEYCODE_BACK)
                {
                    ///we don't want KEYCODE_BACK to do anything unless we are StopOnTouch
                    if(_controlMode == Controls_StopOnTouch)
                    {
                        _videoView.stopPlayback();
                        cleanup();

                        ///fire native callback noting completion
                        deferNativeCallback(1, "success");

                        Log.d(TAG, "Video Skipped!");
                    }
                    return true;
                }
                return super.dispatchKeyEvent(event);
            }
        }
        ;
        _videoView.setZOrderOnTop(true);
        _videoView.setVisibility(View.VISIBLE);
        _videoView.setBackgroundColor(Color.TRANSPARENT);
        _videoView.setKeepScreenOn(true);
        _videoView.setId(1234);            

        ///set up listeners to the view to react to events
        VideoListeners videoListeners = new VideoListeners();
        _videoView.setOnCompletionListener(videoListeners);
        _videoView.setOnErrorListener(videoListeners);
        _videoView.setOnTouchListener(videoListeners);
        _videoView.setOnPreparedListener(videoListeners);

        ///create media controller for possible use later on
        _mediaController = new MediaController(_context, true);
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


    ///handle pausing the video if one is playing
    public static void onPause()
    {
        if(_isPlaying)
        {
            _videoView.pause();
            _suspendedVideoPos = _videoView.getCurrentPosition();            

            ///push back position a bit to account for delay to show the view on restart, so that none of the video is missed
            _suspendedVideoPos -= Video_Resume_Offset;
            if(_suspendedVideoPos < 0)
            {
                _suspendedVideoPos = 0;
            }
            _isPaused = true;
            Log.d(TAG, "Pausing Video Playback at position: " + _suspendedVideoPos);
        }
    }


    ///handle resuming the video
    public static void onResume()
    {
        if(_isPaused)
        {
            _videoView.seekTo(_suspendedVideoPos);
            _videoView.start();
            _isPaused = false;
            Log.d(TAG, "Resuming Video Playback at position: " + _suspendedVideoPos);
        }
    }


    ///handle destroying the video
    public static void onDestroy()
    {
        if(_isPlaying)
        {
            _videoView.stopPlayback();
            cleanup();
            _mediaController = null;
            _videoView = null;
            Log.d(TAG, "Stopping Video Playback onDestroy");
        }
    }


    ///internal function for playing a video
    private static void playFSInternal(String file, int scaleMode, int controlMode, int bgColor)
    {
        Log.d(TAG, "Video Play Fullscreen: " + file + " " + scaleMode + " " + controlMode + " " + bgColor);

        ///store some vars
        _videoFile = file;
        _scaleMode = scaleMode;
        _controlMode = controlMode;
        _bgColor = bgColor;

        ///ignore gravity to try and stop the stupid retarded video view from stupid retarded sliding
        ((RelativeLayout)_rootView).setIgnoreGravity(_videoView.getId());

        ///hide the root until the video is ready to play
        _rootView.setBackgroundColor(Color.TRANSPARENT);

        ///send the video URI to the video view
        ///NOTE: Both of these methods, either with the raw ID or /raw/filename_noext seem to work
             // int videoResourceID = _context.getResources().getIdentifier(file, "raw", _context.getPackageName());
             // Uri videoUri = Uri.parse("android.resource://" + _context.getPackageName() + "/" + videoResourceID);        
        Uri videoUri = Uri.parse("android.resource://" + _context.getPackageName() + "/raw/" + file);
        _videoView.setVideoURI(videoUri);
        _rootView.addView(_videoView);
        _videoView.start();
        _isPlaying = true;
    }  


    ///shared cleanup function for when a video has finished playing
    private static void cleanup()
    {
        _isPlaying = false;

        ///clean up the media controller
        if(_mediaController != null)
        {
            if(_mediaController.isShowing())
            {
                _mediaController.hide();
            }
            _videoView.setMediaController(null);
            _mediaController.setAnchorView(null);    
        }

         ///remove the video view from the root
        _rootView.removeView(_videoView);
        _rootView.setBackgroundColor(Color.TRANSPARENT);

        ///give focus back to the main surface view after we have removed the video view 
        // TODO: reimplement
        //SDLActivity.getSurface().requestFocus();
    }


    ///sets the layout for the video
    private static RelativeLayout.LayoutParams getLayout(int videoWidth, int videoHeight)
    {
        RelativeLayout.LayoutParams layoutParams = null;

        ///set layout of the video view based on the layout flags
        switch(_scaleMode)
        {
            case Scale_None:
                if((videoWidth > 0) && (videoHeight > 0))
                {
                    layoutParams = new RelativeLayout.LayoutParams(videoWidth, videoHeight);
                }
                else
                {
                    ///fallback incase of invalid video dimensions
                    layoutParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.WRAP_CONTENT, RelativeLayout.LayoutParams.WRAP_CONTENT);                    
                }
                layoutParams.addRule(RelativeLayout.CENTER_IN_PARENT);
                break;
            case Scale_Fill:
                layoutParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.MATCH_PARENT);
                layoutParams.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM);
                layoutParams.addRule(RelativeLayout.ALIGN_PARENT_TOP);
                layoutParams.addRule(RelativeLayout.ALIGN_PARENT_LEFT);
                layoutParams.addRule(RelativeLayout.ALIGN_PARENT_RIGHT);
                break;
            case Scale_FitAspect:
                layoutParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.MATCH_PARENT);
                layoutParams.addRule(RelativeLayout.CENTER_IN_PARENT);
                break;
        }

        return layoutParams;
    }


    // ________________________________________________
    // Native
    // ________________________________________________
    private static void deferNativeCallback(int type, String data)
    {
        final int fType = type;
        final String fData = data;

        // TODO: does this require queueEvent?
        _context.runOnUiThread(new Runnable() 
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