package co.theengine.loomdemo;

import android.app.Activity;
import android.content.Context;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.util.Log;
import android.util.Base64;
import android.os.HandlerThread;
import android.os.Handler;
import android.os.Message;
import android.os.Looper;

import com.loopj.android.http.AsyncHttpClient;
import com.loopj.android.http.BinaryHttpResponseHandler;
import com.loopj.android.http.RequestHandle;

import java.util.Hashtable;
import java.util.Set;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.UnsupportedEncodingException;
import java.io.StringWriter;
import java.io.PrintWriter;

import org.apache.http.Header;
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
    private static SendTask[]    tasks = new SendTask[MAX_CONCURRENT_HTTP_REQUESTS];
    private static SendTaskThread    background;
    // java representation of headers. These are cleared after each send() call.
    protected static Hashtable<String, String> headers = new Hashtable<String, String>();

    /** Initializes the HTTP tasks */
    public static void onCreate(Activity ctx)
    {
        //store context for later use
        _context = ctx;

        background = new SendTaskThread("HTTP Master");

        //make sure client array is initialized to null
        for(int i=0;i<MAX_CONCURRENT_HTTP_REQUESTS;i++)
        {
            SendTask st = new SendTask();
            st.index = i;
            st.busy = false;
            st.cancel = false;
            tasks[i] = st;
        }
    }

    
    public static int send(final String url, String httpMethod, final long callback, final long payload, byte[] body, final String responseCacheFile, final boolean base64EncodeResponseData, boolean followRedirects)
    {
        SendTask st = null;
        
        int index = 0;
        while (index < MAX_CONCURRENT_HTTP_REQUESTS) {
            st = tasks[index];
            if (!st.busy) break;
            index++;
        }
        
        if(index == MAX_CONCURRENT_HTTP_REQUESTS)
        {
            return -1;
        }
        
        st.busy = true;
        st.url = url;
        st.httpMethod = httpMethod;
        st.callback = callback;
        st.payload = payload;
        st.body = body;
        st.responseCacheFile = responseCacheFile;
        st.base64EncodeResponseData = base64EncodeResponseData;
        st.followRedirects = followRedirects;
        st.headers.putAll(headers);
        
        // Most of the time is spent here, up to and exceeding 1ms
        background.post(st);
        
        // clear the headers after each send();
        headers.clear();
        
        return index;
    }
    
    static class SendTaskThread extends HandlerThread
    {
        private SendTaskHandler handler;
    
        public SendTaskThread(String name)
        {
            super(name);
            start();
            handler = new SendTaskHandler(getLooper());
        }
    
        public void post(SendTask st)
        {
            handler.post(st);
        }
        
        public void cancel(SendTask st)
        {
            handler.sendEmptyMessage(st.index);
            handler.removeCallbacks(st);
        }
    }
    
    static class SendTaskHandler extends Handler
    {
        public SendTaskHandler(Looper looper)
        {
            super(looper);
        }
        
        @Override
        public void handleMessage(Message msg)
        {
            int index = msg.what;
            tasks[index].cancel();
        }
    }
    
    static class SendTask implements Runnable
    {
        protected static AsyncHttpClient client;
        
        public int index;
        
        public boolean busy;
        public boolean cancel;
        
        public String url;
        public String httpMethod;
        public long callback;
        public long payload;
        public byte[] body;
        public String responseCacheFile;
        public boolean base64EncodeResponseData;
        public boolean followRedirects;
        public Hashtable<String, String> headers;
        
        protected File savedFile;
        protected Activity activity;
        protected RequestHandle requestHandle;
        
        protected BinaryHttpResponseHandler handler = new BinaryHttpResponseHandler()
        {
            
            @Override
            public String[] getAllowedContentTypes() {
                return new String[]{".*"};
            }
            
            @Override
            public void onSuccess(int statusCode, Header[] headers, byte[] binaryData) 
            {
            
                if (savedFile != null)
                {
                    Log.d(TAG, "Caching HTTP response to '" + responseCacheFile + "'");
                    try {
                        BufferedOutputStream bos = new BufferedOutputStream(new FileOutputStream(savedFile));
                        bos.write(binaryData);
                        bos.flush();
                        bos.close();
                        Log.d(TAG, "File written...");
                    }
                    catch (Exception e)
                    {
                        Log.e(TAG, "File write failed...");
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
                
                success(fResponse);
            }
            
            @Override
            public void onFailure(int statusCode, Header[] headers, byte[] errorResponse, Throwable error)
            {
                String content;
                
                if (errorResponse == null) {
                    content = "";
                } else {
                    if (base64EncodeResponseData)
                    {
                        content = Base64.encodeToString(errorResponse, Base64.NO_WRAP | Base64.NO_PADDING);
                    }
                    else
                    {
                        try {
                            content = new String(errorResponse, "UTF8");
                        } catch (UnsupportedEncodingException e) {
                            throw new AssertionError("UTF-8 is unknown");
                        }
                    }
                }
            
                onFailure(statusCode, headers, content, error);
            }
            
            @Override
            public void onCancel()
            {
                Log.i(TAG, index+" cancel response");
            }
            
            public void onFailure(int statusCode, Header[] headers, String errorResponse, Throwable error) 
            {
                failure("request failed ("+statusCode+"): "+errorResponse);   
            }
            
        };
        
        SendTask() {
            headers = new Hashtable<String, String>();
        }
        
        public void run()
        {
            if (client == null) client = new AsyncHttpClient();
            
            activity = _context;
            
            // General setup
            
            // Iterate over the headers and set them in the client
            Set<String> keys = headers.keySet();
            client.removeAllHeaders();
            for(String key: keys){
                client.addHeader(key, (String)headers.get(key));
            }
            headers.clear();
            
            // Set up for saving to response cache file if desired.
            File trySaveFile = null;
            if (responseCacheFile != null && responseCacheFile.length() > 0) {
                try
                {
                    trySaveFile = new File(responseCacheFile);
                }
                catch(Exception e)
                {
                    trySaveFile = null;
                    Log.e(TAG, "Failed to open responseCacheFile " + responseCacheFile);
                }
            }
            savedFile = trySaveFile;
            
            // Set up response handler
            
            
            
            
            // Engage!
            
            try
            {
                if (httpMethod.equals("GET"))
                {
                    requestHandle = client.get(_context, url, handler);
                }
                else if (httpMethod.equals("POST"))
                {
                    ByteArrayEntity bodyEntity = new ByteArrayEntity(body);
                    requestHandle = client.post(_context, url, bodyEntity, headers.get("Content-Type"), handler);
                }
                else
                {
                    failure("unknown HTTP method: "+httpMethod);
                }           
            }
            catch(Exception e)
            {
                StringWriter errors = new StringWriter();
                e.printStackTrace(new PrintWriter(errors));
                failure("exception caught while posting request: " + e + errors.toString());
            }
            
            Log.d(TAG, index + " send running");
            
        }
        
        
        protected void success(final String response)
        {
            Log.d(TAG, index + " send success");
            final int index = this.index;
            final long callback = this.callback;
            final long payload = this.payload;
            // TODO: does this require queueEvent?
            activity.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    Log.d(TAG, index + " main success " + response.length() + " bytes, callback=" + callback + " payload=" + payload);
                    LoomHTTP.onSuccess(response, callback, payload);
                    LoomHTTP.complete(index);
                }
            });
            finish();
        }
        
        protected void failure(final String msg)
        {
            Log.d(TAG, index + " send failure");
            Log.w(TAG, "Failed to make request due to: " + msg);
            final int index = this.index;
            final long callback = this.callback;
            final long payload = this.payload;
            // TODO: does this require queueEvent?
            activity.runOnUiThread(new Runnable() 
            {
                @Override
                public void run() {
                    LoomHTTP.onFailure("Error: "+msg, callback, payload);
                    LoomHTTP.complete(index);
                }
            });
            finish();
        }
        
        protected void cancel()
        {
            Log.d(TAG, index + " cancel received");
            if (requestHandle == null) return;
            boolean success = requestHandle.cancel(true);
            Log.d(TAG, index + " cancel finished="+success);
            if (success) finish();
        }
        
        protected void finish()
        {
            url = null;
            httpMethod = null;
            callback = -1;
            payload = -1;
            body = null;
            responseCacheFile = null;
            base64EncodeResponseData = false;
            followRedirects = false;
            requestHandle = null;
            savedFile = null;
            Log.d(TAG, index + " finished");
        }
        
        
    }


    /**
     *  Cancels a request
     */
    public static boolean cancel(int index)
    {
        if (index == -1) return false;
        Log.d(TAG, index + " cancel requested");
        SendTask st = tasks[index];
        if (!st.busy) return false;
        background.cancel(st);
        return true;
    }

    /**
    *  Complete a request
    */
    public static void complete(int index)
    {
        if (index == -1) return;
        SendTask st = tasks[index];
        st.busy = false;
        st.cancel = false;
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
}
