package co.theengine.loomdemo;

import android.net.Uri;
import android.content.Context;
import android.content.Intent;
import android.app.Activity;
import android.provider.MediaStore;
import android.widget.Toast;
import java.io.File;
import java.text.SimpleDateFormat;
import java.util.Date;
import android.os.Environment;
import android.util.Log;


/**
 * Java Class that exposes Android camera functionality
 */
public class LoomCamera
{
    public static final int CAPTURE_IMAGE_ACTIVITY_REQUEST_CODE = 100;
    public static Uri fileUri;

    // Per http://stackoverflow.com/a/13409070/809422
    public static final int MEDIA_TYPE_IMAGE = 1;

    // From http://developer.android.com/guide/topics/media/camera.html#saving-media
    /** Create a File for saving an image or video */
    private static File getOutputMediaFile(int type)
    {
        // To be safe, you should check that the SDCard is mounted
        // using Environment.getExternalStorageState() before doing this.

        File mediaStorageDir = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), "Loom");
        // This location works best if you want the created images to be shared
        // between applications and persist after your app has been uninstalled.

        // Create the storage directory if it does not exist
        if (! mediaStorageDir.exists())
        {
            if (! mediaStorageDir.mkdirs())
            {
                Log.d("Loom", "failed to create directory: " + mediaStorageDir.getAbsolutePath());
                return null;
            }
        }

        // Create a media file name
        String timeStamp = new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date());
        File mediaFile;
        if (type == MEDIA_TYPE_IMAGE)
        {
            mediaFile = new File(mediaStorageDir.getPath() + File.separator + "IMG_"+ timeStamp + ".jpg");
        }
        else 
        {
            Log.d("Loom", "failed to identify media type");
            return null;
        }

        return mediaFile;
    }

    /** Create a file Uri for saving an image or video */
    private static Uri getOutputMediaFileUri(int type)
    {
        File outputFile = getOutputMediaFile(type);
        return Uri.fromFile(outputFile);
    }

    public static void triggerCameraIntent(Activity ctx)
    {
        //if no permission for camera, early out
        if(!LoomDemo.checkPermission(ctx, "android.permission.CAMERA"))
        {
            return;
        }

        // create Intent to take a picture and return control to the calling application
        Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);

        fileUri = getOutputMediaFileUri(MEDIA_TYPE_IMAGE); // create a file to save the image
        //Log.d("Loom", "FILE URI IS " + fileUri);
        intent.putExtra(MediaStore.EXTRA_OUTPUT, fileUri); // set the image file name

        // start the image capture Intent
        ctx.startActivityForResult(intent, CAPTURE_IMAGE_ACTIVITY_REQUEST_CODE);
    }

    public static void onActivityResult(Activity ctx, int requestCode, int resultCode, Intent data) 
    {
        //if no permission for camera, early out
        if(!LoomDemo.checkPermission(ctx, "android.permission.CAMERA"))
        {
            return;
        }

        if (requestCode != CAPTURE_IMAGE_ACTIVITY_REQUEST_CODE)
            return;

        if (resultCode == Activity.RESULT_OK) 
        {
            // Image captured and saved to fileUri specified in the Intent

            // Fire results event.
            LoomDemo.triggerGenericEvent("cameraSuccess", fileUri.getEncodedPath());
        } 
        else if (resultCode == Activity.RESULT_CANCELED) 
        {
            // User cancelled the image capture
            LoomDemo.triggerGenericEvent("cameraFail", "cancel");
        }
        else 
        {
            // Image capture failed, advise user
            LoomDemo.triggerGenericEvent("cameraFail", "fail");
        }
    }    
}