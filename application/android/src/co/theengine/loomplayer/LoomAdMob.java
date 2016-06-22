package co.theengine.loomplayer;

import java.util.Hashtable;
import java.util.Set;

import android.app.Activity;
import android.content.Context;
import android.graphics.Bitmap;
import android.view.ViewGroup;
import android.widget.RelativeLayout;

import com.google.android.gms.ads.*;

/**
 *  Java class that manages Admob instances. This maps directly to the platformAdMob C API
 */
public class LoomAdMob {
    
    private static native void nativeCallback(String data, long callback, long payload, int type);

    private static void deferNativeCallback(String data, long callback, long payload, int type)
    {
        final String fData = data;
        final long fCallback = callback;
        final long fPayload  = payload;
        final int fType = type;
        
        final Activity activity = LoomAdMob.activity;
        // TODO: does this require queueEvent?
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                nativeCallback(fData, fCallback, fPayload, fType);
            }
        });
    }


    public static int createInterstitial(final String adUnitID, final long callback, final long payload)
    {
        final int handle = adViewCounter++;
        final Activity activity = LoomAdMob.activity;
        
        activity.runOnUiThread(new Runnable() {
            
            @Override
            public void run() {
                InterstitialAd inter = new InterstitialAd(activity);
                inter.setAdUnitId(adUnitID);
                LoomAdMob.interstitials.put(handle, inter);

                inter.setAdListener(new AdListener() {

                    @Override
                    public void onAdFailedToLoad(int error) {
                        deferNativeCallback("" + error, callback, payload, 1);
                    }

                    @Override
                    public void onAdLoaded() {
                        deferNativeCallback("", callback, payload, 0);
                    }

                    @Override
                    public void onAdClosed() {
                        super.onAdClosed();
                    }

                    @Override
                    public void onAdLeftApplication() {
                        super.onAdLeftApplication();
                    }

                    @Override
                    public void onAdOpened() {
                        super.onAdOpened();
                    }

                });

                // Create ad request
                AdRequest.Builder builder = new AdRequest.Builder();
                AdRequest adRequest = builder.build();

                inter.loadAd(adRequest);
            }
        });
        
        return handle;
    }

    public static void loadInterstitial(final int handle)
    {
        activity.runOnUiThread(new Runnable() {

            @Override
            public void run() {
                InterstitialAd inter = LoomAdMob.interstitials.get(handle);

                // Initiate a generic request to load it with an ad
                AdRequest.Builder builder = new AdRequest.Builder();
                AdRequest adRequest = builder.build();

                inter.loadAd(adRequest);
            }
        });
    }

    public static void destroyInterstitial(final int handle)
    {
        activity.runOnUiThread(new Runnable() {
            
            @Override
            public void run() {
                LoomAdMob.interstitials.remove(handle);
            }
        });
    }

    public static void showInterstitial(final int handle)
    {
        activity.runOnUiThread(new Runnable() {
            
            @Override
            public void run() {

                InterstitialAd inter = LoomAdMob.interstitials.get(handle);
                if(inter != null)
                    inter.show(); 

            }
        });
    }

    public static void initialize(final String publisherID)
    {
        MobileAds.initialize(LoomAdMob.activity, publisherID);
    }

    public static int create(final String adUnitID, final long callback, final long payload, final int size)
    {
        final int handle = adViewCounter++;
        final ViewGroup layout = rootLayout;
        final Activity activity = LoomAdMob.activity;
        
        activity.runOnUiThread(new Runnable() {
            
            @Override
            public void run() {
                AdView adView = new AdView(activity);
                adView.setAdSize(getSize(size));
                adView.setAdUnitId(adUnitID);
                LoomAdMob.adViews.put(handle, adView);
                adView.setAdListener(new AdListener() {

                    @Override
                    public void onAdFailedToLoad(int error) {
                        deferNativeCallback("" + error, callback, payload, 1);
                    }

                    @Override
                    public void onAdLoaded() {
                        deferNativeCallback("", callback, payload, 0);
                    }

                    @Override
                    public void onAdClosed() {
                        super.onAdClosed();
                    }

                    @Override
                    public void onAdLeftApplication() {
                        super.onAdLeftApplication();
                    }

                    @Override
                    public void onAdOpened() {
                        super.onAdOpened();
                    }

                });
            }
        });
        
        return handle;
    }
    
    public static void load(final int handle)
    {
        activity.runOnUiThread(new Runnable() {

            @Override
            public void run() {
                AdView adView = LoomAdMob.adViews.get(handle);

                        // Initiate a generic request to load it with an ad
                AdRequest.Builder builder = new AdRequest.Builder();
                AdRequest adRequest = builder.build();

                adView.loadAd(adRequest);
            }
        });
    }

    public static void show(final int handle)
    {
        final ViewGroup layout = rootLayout;
        
        activity.runOnUiThread(new Runnable() {
            
            @Override
            public void run() {
                AdView adView = LoomAdMob.adViews.get(handle);

                // Remove from parent if it was on one.
                if(adView.getParent() == layout)
                    layout.removeView(adView);

                layout.addView(adView);
                RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(adView.getLayoutParams());
                params.addRule(RelativeLayout.ALIGN_PARENT_TOP);
                adView.setLayoutParams(params);
            }
        });
    }
    
    public static void hide(final int handle)
    {
        final ViewGroup layout = rootLayout;
        
        activity.runOnUiThread(new Runnable() {
            
            @Override
            public void run() {
                AdView adView = LoomAdMob.adViews.get(handle);
                
                if(adView.getParent() == layout)
                    layout.removeView(adView);
            }
        });
    }
    
    public static void destroy(final int handle)
    {
        final ViewGroup layout = rootLayout;
        
        activity.runOnUiThread(new Runnable() {
            
            @Override
            public void run() {
                AdView adView = LoomAdMob.adViews.get(handle);
                LoomAdMob.adViews.remove(handle);
                
                if(adView != null && adView.getParent() == layout)
                    layout.removeView(adView);
            }
        });
    }
    
    public static void destroyAll()
    {
        final ViewGroup layout = rootLayout;
        
        activity.runOnUiThread(new Runnable() {
            
            @Override
            public void run() {
                Set<Integer> keys = adViews.keySet();
                for(Integer key: keys){
                    AdView adView = LoomAdMob.adViews.remove(key);

                    if(adView != null && adView.getParent() == layout)
                        layout.removeView(adView);
                }

                Set<Integer> keys2 = interstitials.keySet();
                for(Integer key: keys){
                    LoomAdMob.interstitials.remove(key);
                }
            }
        });
    }

    public static void setDimensions(final int handle, final int x, final int y, final int width, final int height)
    {
        activity.runOnUiThread(new Runnable() {
            
            @Override
            public void run() {
                AdView adView = LoomAdMob.adViews.get(handle);
                RelativeLayout.LayoutParams params = (RelativeLayout.LayoutParams)adView.getLayoutParams();
                if(params != null)
                {
                    params.topMargin = y;
                    params.leftMargin = x;
                    params.width = width;
                    params.height = height;
                    adView.setLayoutParams(params);
                }
            }
        });
    }

    public static int[] getDimensions(final int handle)
    {
        final LoomAdMobPayload payload = new LoomAdMobPayload();
        payload.value = new int[4];

        activity.runOnUiThread(new Runnable() {
            
            @Override
            public void run() {
                try {
                    synchronized(payload) {
                        AdView adView = LoomAdMob.adViews.get(handle);
                        RelativeLayout.LayoutParams params = (RelativeLayout.LayoutParams)adView.getLayoutParams();
                        if(params != null)
                        {
                            payload.value[0] = params.leftMargin;
                            payload.value[1] = params.bottomMargin;
                            payload.value[2] = adView.getWidth();
                            payload.value[3] = adView.getHeight();

                            if (payload.value[2] <= 0 || payload.value[3] <= 0) {
                                payload.value[2] = adView.getAdSize().getWidthInPixels(LoomAdMob.activity);
                                payload.value[3] = adView.getAdSize().getHeightInPixels(LoomAdMob.activity);
                            }
                        }


                        payload.notify();
                    }

                } catch (Exception e) {
                    payload.notify();
                }
            }
        });

        try {
            synchronized(payload) {
                payload.wait(100);
                return payload.value;
            }
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        return payload.value;
    }
    
    public static void setRootLayout(ViewGroup value)
    {
        rootLayout = value;
        activity = (Activity)rootLayout.getContext();
    }
    
    protected static AdSize getSize(int size)
    {
        switch(size)
        {
            case 0:
            case 1:
                return AdSize.SMART_BANNER;
            case 2:
                return AdSize.BANNER;
            case 3:
                return AdSize.MEDIUM_RECTANGLE;
            case 4:
                return AdSize.LARGE_BANNER;
            case 5:
                return AdSize.LEADERBOARD;
        }

        return AdSize.SMART_BANNER;
    }

    protected static int adViewCounter = 0;
    protected static ViewGroup rootLayout;
    protected static Activity activity;
    protected static Hashtable<Integer, AdView> adViews = new Hashtable<Integer, AdView>();
    protected static Hashtable<Integer, InterstitialAd> interstitials = new Hashtable<Integer, InterstitialAd>();
}

class LoomAdMobPayload
{
    public int[] value;
}
