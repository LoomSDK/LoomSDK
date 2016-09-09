package co.theengine.loomplayer;

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
import java.nio.charset.Charset;

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

    
    public static int send(final String url, String httpMethod, final long callback, final long payload, byte[] body, final String responseCacheFile, boolean followRedirects)
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
        
        public long bytesWritten;
        public long bytesTotal;
        
        public boolean busy;
        public boolean cancel;
        
        public boolean running;
        
        public String url;
        public String httpMethod;
        public long callback;
        public long payload;
        public byte[] body;
        public String responseCacheFile;
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
            public void onProgress(long written, long total) 
            {
                bytesWritten = written;
                bytesTotal = total;
            }
            
            @Override
            public void onSuccess(int statusCode, Header[] headers, byte[] binaryData) 
            {
            
                if (savedFile != null)
                {
                    try {
                        BufferedOutputStream bos = new BufferedOutputStream(new FileOutputStream(savedFile));
                        bos.write(binaryData);
                        bos.flush();
                        bos.close();
                    }
                    catch (Exception e)
                    {
                        throw new AssertionError("HTTP Response could not be cached.");
                    }
                }
                
                success(binaryData);
            }
            
            @Override
            public void onFailure(int statusCode, Header[] headers, byte[] binaryData, Throwable error)
            {
                // TODO: return status code (probably on success too)
                // In general we should probably just return the failure message untampered,
                // as they're sometimes useful pages that you might want to access, parse or display.
                failure(binaryData);
            }
            
            @Override
            public void onCancel()
            {
            }
            
        };
        
        SendTask() {
            headers = new Hashtable<String, String>();
            running = false;
        }
        
        public void run()
        {
            if (running) {
                Log.w(TAG, index + " task already running, overriding");
            }
            if (url == null) {
                Log.w(TAG, index + " ran uninitialized");
                return;
            }
            running = true;
            
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
            
        }
        
        
        protected void success(final byte[] response)
        {
            if (response == null) Log.w(TAG, index + " send success response null!");
            final int index = this.index;
            final long callback = this.callback;
            final long payload = this.payload;
            // TODO: does this require queueEvent?
            activity.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    if (callback != -1 && payload != -1) {
                        LoomHTTP.onSuccess(response, callback, payload);
                        LoomHTTP.complete(index);
                    } else {
                        Log.w(TAG, index + " main invalid callback or payload, written " + bytesWritten + " total " + bytesTotal);
                    }
                }
            });
            finish();
        }
        
        protected void failure(final String msg)
        {
            failure(msg.getBytes(Charset.forName("UTF-8")));
        }
        
        protected void failure(final byte[] response)
        {
            if (response == null) Log.w(TAG, index + " send failure response null!");
            final byte[] binaryData = response == null ? new byte[0] : response;
            Log.w(TAG, index + " send failure");
            final int index = this.index;
            final long callback = this.callback;
            final long payload = this.payload;
            // TODO: does this require queueEvent?
            activity.runOnUiThread(new Runnable() 
            {
                @Override
                public void run() {
                    LoomHTTP.onFailure(binaryData, callback, payload);
                    LoomHTTP.complete(index);
                }
            });
            finish();
        }
        
        protected void cancel()
        {
            if (requestHandle == null) return;
            boolean success = requestHandle.cancel(true);
            finish();
        }
        
        protected void finish()
        {
            running = false;
            url = null;
            httpMethod = null;
            callback = -1;
            payload = -1;
            body = null;
            responseCacheFile = null;
            followRedirects = false;
            requestHandle = null;
            savedFile = null;
        }
        
        
    }


    /**
     *  Cancels a request
     */
    public static boolean cancel(int index)
    {
        if (index == -1) return false;
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
    
    private static native void onSuccess(byte[] data, long callback, long payload);
    private static native void onFailure(byte[] data, long callback, long payload);
}
