package co.theengine.loomdemo;

import android.app.Activity;
import android.content.Context;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.util.Log;
import android.util.Base64;

import com.loopj.android.http.AsyncHttpClient;
import com.loopj.android.http.BinaryHttpResponseHandler;

import java.util.Hashtable;
import java.util.Set;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.UnsupportedEncodingException;

import org.apache.http.entity.ByteArrayEntity;

import org.cocos2dx.lib.Cocos2dxGLSurfaceView;

import android.util.Log;

/**
 * Java Class that exposes Android async HTTP calls
 */
public class LoomHTTP 
{
    public static void send(final String url, String httpMethod, final long callback, final long payload, byte[] body, final String responseCacheFile, final boolean base64EncodeResponseData, boolean followRedirects)
    {
        final Activity activity = LoomAdMob.activity;
        AsyncHttpClient client = new AsyncHttpClient();

        String[] allowedTypes = new String[] { 
            ".*" // Match anything.
        };

        // iterate over the headers and set them in the client
        Set<String> keys = headers.keySet();
        for(String key: keys){
            client.addHeader(key, (String)headers.get(key));
        }

        // Set up for saving to response cache file if desired.
        File trySaveFile = null;
        try
        {
            trySaveFile = new File(responseCacheFile);
        }
        catch(Exception e)
        {
            LoomDemo.logDebug("Failed to open responseCacheFile " + responseCacheFile);
        }
        final File savedFile = trySaveFile;

        BinaryHttpResponseHandler handler = new BinaryHttpResponseHandler(allowedTypes) {

            @Override

            public void onSuccess(byte[] binaryData) {

                if (responseCacheFile != null && responseCacheFile.length() > 0)
                {
                    LoomDemo.logDebug("Caching HTTP response to '" + responseCacheFile + "'");
                    try {
                        BufferedOutputStream bos = new BufferedOutputStream(new FileOutputStream(savedFile));
                        bos.write(binaryData);
                        bos.flush();
                        bos.close();
                        LoomDemo.logDebug("file written...");
                    }
                    catch (Exception e)
                    {
                        LoomDemo.logDebug("file write failed...");
                        throw new AssertionError("HTTP Response could not be cached.");
                    }
                }

                final String fResponse;

                if (base64EncodeResponseData)
                {
                    fResponse = Base64.encodeToString(binaryData, Base64.NO_WRAP | Base64.NO_PADDING);
                }
                else
                {
                    try {
                        fResponse = new String(binaryData, "UTF8");
                    } catch (UnsupportedEncodingException e) {
                        throw new AssertionError("UTF-8 is unknown");
                    }
                }

                final String rfResponse = fResponse;

                Cocos2dxGLSurfaceView.mainView.queueEvent(new Runnable() {
                    @Override
                    public void run() {
                        //Log.d("LoomHTTP", "Main view thread submitting '" + rfResponse + "'' from queue!");
                        LoomHTTP.onSuccess(rfResponse, callback, payload);
                    }
                });

            }

            @Override
            public void onFailure(Throwable error, byte[] binaryData) {

                String content;

                if (base64EncodeResponseData)
                {
                    content = Base64.encodeToString(binaryData, Base64.NO_WRAP | Base64.NO_PADDING);
                }
                else
                {
                    try {
                        content = new String(binaryData, "UTF8");
                    } catch (UnsupportedEncodingException e) {
                        throw new AssertionError("UTF-8 is unknown");
                    }
                }

                onFailure(error, content);
            } 

            @Override
            public void onFailure(Throwable error, String content) {

                final String fContent = content;

                Log.d("LoomHTTP", "Failed request with message: " + content);

                Cocos2dxGLSurfaceView.mainView.queueEvent(new Runnable() {
                    @Override
                    public void run() {
                        LoomHTTP.onFailure(fContent, callback, payload);
                    }
                });
            } 
        };

        try
        {
            if(httpMethod.equals("GET"))
            {
                client.get(url, handler);
            }
            else if(httpMethod.equals("POST"))
            {
                ByteArrayEntity bodyEntity = new ByteArrayEntity(body);
                client.post(null, url, bodyEntity, headers.get("Content-Type"), handler);
            }
            else
            {
                Cocos2dxGLSurfaceView.mainView.queueEvent(new Runnable() 
                {
                    @Override
                    public void run() {
                        onFailure("Error: Unknown HTTP Method", callback, payload);
                    }
                });
            }           
        }
        catch(Exception e)
        {
            Log.d("LoomHTTP", "Failed to make request due to: " + e.toString());
            Cocos2dxGLSurfaceView.mainView.queueEvent(new Runnable() 
            {
                @Override
                public void run() {
                    onFailure("Error: exception caught when posting request!", callback, payload);
                }
            });
        }

        
        // clear the headers after each send();
        headers.clear();
    
    }

    /**
     *  Adds a header to the headers list, which will be consumed when send() is called.
     */
    public static void addHeader(String key, String value)
    {
        headers.put(key, value);
    }

    public static boolean isConnected()
    {
        // Via http://stackoverflow.com/a/8845364/809422
        boolean haveConnectedWifi = false;
        boolean haveConnectedMobile = false;

        ConnectivityManager cm = (ConnectivityManager) LoomAdMob.activity.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo[] netInfo = cm.getAllNetworkInfo();
        for (NetworkInfo ni : netInfo) {
            if (ni.getTypeName().equalsIgnoreCase("WIFI"))
                if (ni.isConnectedOrConnecting())
                    haveConnectedWifi = true;
            if (ni.getTypeName().equalsIgnoreCase("MOBILE"))
                if (ni.isConnectedOrConnecting())
                    haveConnectedMobile = true;
        }
        return haveConnectedWifi || haveConnectedMobile;

    }
    
    private static native void onSuccess(String data, long callback, long payload);
    private static native void onFailure(String data, long callback, long payload);

    // java representation of headers. These are cleared after each send() call.
    protected static Hashtable<String, String> headers = new Hashtable<String, String>();
}
