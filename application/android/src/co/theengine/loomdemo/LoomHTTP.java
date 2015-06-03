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

import android.util.Log;

/**
 * Java Class that exposes Android async HTTP calls
 */
public class LoomHTTP 
{
    private static final String TAG = "LoomHTTP";
    private static final int MAX_CONCURRENT_HTTP_REQUESTS = 128;

    private static Activity             _context;
    private static AsyncHttpClient[]    clients = new AsyncHttpClient[MAX_CONCURRENT_HTTP_REQUESTS];
    

    /** Initializes the HTTP clients */
    public static void onCreate(Activity ctx)
    {
        //store context for later use
        _context = ctx;

        //make sure client array is initialized to null
        for(int i=0;i<MAX_CONCURRENT_HTTP_REQUESTS;i++)
        {
            clients[i] = null;
        }
    }

    
    public static int send(final String url, String httpMethod, final long callback, final long payload, byte[] body, final String responseCacheFile, final boolean base64EncodeResponseData, boolean followRedirects)
    {
        //find and store client
        int index = 0;
        while (clients[index] != null && (index < MAX_CONCURRENT_HTTP_REQUESTS)) {index++;}
        if(index == MAX_CONCURRENT_HTTP_REQUESTS)
        {
            return -1;
        }
        
        AsyncHttpClient client = new AsyncHttpClient();
        clients[index] = client;
 
        // iterate over the headers and set them in the client
        Set<String> keys = headers.keySet();
        for(String key: keys){
            client.addHeader(key, (String)headers.get(key));
        }
        
        // clear the headers after each send();
        headers.clear();

        SendTask sendTask = new SendTask();
        sendTask.url = url;
        sendTask.httpMethod = httpMethod;
        sendTask.callback = callback;
        sendTask.payload = payload;
        sendTask.body = body;
        sendTask.responseCacheFile = responseCacheFile;
        sendTask.base64EncodeResponseData = base64EncodeResponseData;
        sendTask.followRedirects = followRedirects;
        sendTask.client = client;
        Thread t = new Thread(sendTask);
    	t.start();
        
    	return index;
    }
    
    static class SendTask implements Runnable {
    	public String url;
    	public String httpMethod;
    	public long callback;
    	public long payload;
    	public byte[] body;
    	public String responseCacheFile;
    	public boolean base64EncodeResponseData;
    	public boolean followRedirects;
    	public AsyncHttpClient client;
    	SendTask() {}
    	public void run() {
            final Activity activity = _context;
            
            // Set up for saving to response cache file if desired.
            File trySaveFile = null;
            try
            {
                trySaveFile = new File(responseCacheFile);
            }
            catch(Exception e)
            {
                Log.d(TAG, "Failed to open responseCacheFile " + responseCacheFile);
            }
            final File savedFile = trySaveFile;
            
            String[] allowedTypes = new String[] { 
                ".*" // Match anything.
            };
            
            BinaryHttpResponseHandler handler = new BinaryHttpResponseHandler(allowedTypes) 
            {
 
                @Override
 
                public void onSuccess(byte[] binaryData) 
                {
 
                    if (responseCacheFile != null && responseCacheFile.length() > 0)
                    {
                        Log.d(TAG, "Caching HTTP response to '" + responseCacheFile + "'");
                        try {
                            BufferedOutputStream bos = new BufferedOutputStream(new FileOutputStream(savedFile));
                            bos.write(binaryData);
                            bos.flush();
                            bos.close();
                            Log.d(TAG, "file written...");
                        }
                        catch (Exception e)
                        {
                            Log.d(TAG, "file write failed...");
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
 
                    // TODO: does this require queueEvent?
                    activity.runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            // Log.d(TAG, "Main view thread submitting '" + rfResponse + "'' from queue!");
                            LoomHTTP.onSuccess(rfResponse, callback, payload);
                        }
                    });
                }
 
                @Override
                public void onFailure(Throwable error, byte[] binaryData) 
                {
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
                public void onFailure(Throwable error, String content) 
                {
                    final String fContent = content;
 
                    Log.d("LoomHTTP", "Failed request with message: " + content);
 
                    // TODO: does this require queueEvent?
                    activity.runOnUiThread(new Runnable() {
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
                    client.get(_context, url, handler);
                }
                else if(httpMethod.equals("POST"))
                {
                    ByteArrayEntity bodyEntity = new ByteArrayEntity(body);
                    client.post(_context, url, bodyEntity, headers.get("Content-Type"), handler);
                }
                else
                {
                    // TODO: does this require queueEvent?
                    activity.runOnUiThread(new Runnable() 
                    {
                        @Override
                        public void run() 
                        {
                            onFailure("Error: Unknown HTTP Method", callback, payload);
                        }
                    });
                }           
            }
            catch(Exception e)
            {
                Log.d("LoomHTTP", "Failed to make request due to: " + e.toString());
                // TODO: does this require queueEvent?
                activity.runOnUiThread(new Runnable() 
                {
                    @Override
                    public void run() {
                        onFailure("Error: exception caught when posting request!", callback, payload);
                    }
                });
            }
    	}
    }


    /**
     *  Cancels a client request
     */
    public static boolean cancel(int index)
    {
        if ((index == -1) || clients[index] == null)
        {
            return false;
        }
        clients[index].cancelRequests(_context, true);
        return true;
    }

    /**
    *  Remove client request at index from array
    */
    public static void complete(int index)
    {
        if(index != -1)
        {
            clients[index] = null;
        }
    }

    /**
     *  Adds a header to the headers list, which will be consumed when send() is called.
     */
    public static void addHeader(String key, String value)
    {
        headers.put(key, value);
    }
    
    public static void addHeaders(String[] kvPairs)
    {
        int len = kvPairs.length;
        if ((len & 1) != 0) throw new AssertionError("Header key-value pair array does not have an even length");
        for (int i = 0; i < len; i += 2) {
            headers.put(kvPairs[i], kvPairs[i+1]);
        }
    }

    public static boolean isConnected()
    {
        // Via http://stackoverflow.com/a/8845364/809422
        boolean haveConnectedWifi = false;
        boolean haveConnectedMobile = false;

        ConnectivityManager cm = (ConnectivityManager)_context.getSystemService(Context.CONNECTIVITY_SERVICE);
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
