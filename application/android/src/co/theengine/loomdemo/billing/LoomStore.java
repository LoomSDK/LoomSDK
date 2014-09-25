package co.theengine.loomdemo.billing;

import co.theengine.loomdemo.LoomDemo;

import java.util.ArrayList;

import org.json.JSONException;
import org.json.JSONObject;

import com.android.vending.billing.IInAppBillingService;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentSender.SendIntentException;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.os.RemoteException;
import android.util.Log;

import org.cocos2dx.lib.Cocos2dxGLSurfaceView;

/**
 * Provides Store functionality for Loom apps.
 * 
 * See platformStore.h and Store.ls for details on the Loom Store API.
 *
 * If you want to add support for other Android stores, this is the place to do
 * it.
 *
 * Known limitations: can't handle continuations of product/transaction data.
 */
public class LoomStore 
{

    // ________________________________________________
    // Constants
    // ________________________________________________
    public static final int INTENT_CODE = 1001;
    private static final String ITEM_ID_LIST = "ITEM_ID_LIST";
    private static final String TAG = "LoomStore";
    private static final String BILLING_INTENT = "com.android.vending.billing.InAppBillingService.BIND";
    
    // Billing response codes.
    private static final int BILLING_RESPONSE_RESULT_OK = 0;
    private static final int BILLING_RESPONSE_RESULT_USER_CANCELED = 1;
    private static final int BILLING_RESPONSE_RESULT_BILLING_UNAVAILABLE = 3;
    private static final int BILLING_RESPONSE_RESULT_ITEM_UNAVAILABLE = 4;
    private static final int BILLING_RESPONSE_RESULT_DEVELOPER_ERROR = 5;
    private static final int BILLING_RESPONSE_RESULT_ERROR = 6;
    private static final int BILLING_RESPONSE_RESULT_ITEM_ALREADY_OWNED = 7;
    private static final int BILLING_RESPONSE_RESULT_ITEM_NOT_OWNED = 8;
    

    // Callback type values.
    private static final int DETAILS_FAILURE=0;
    private static final int DETAILS_SUCCESS=1;
    private static final int PURCHASE_SUCCESS=2;
    private static final int PURCHASE_FAILURE=3;
    private static final int CONSUME_SUCCESS=4;
    private static final int CONSUME_FAILURE=5;
    private static final int DETAILS_COMPLETED=6;


    // ________________________________________________
    // Public
    // ________________________________________________

    /**
     * Helper to resolve a billing response code to a message.
     */
    public static String getResponseCodeMessage(int responseCode)
    {
        switch (responseCode) {
        case BILLING_RESPONSE_RESULT_OK:
            return "Success";
        case BILLING_RESPONSE_RESULT_USER_CANCELED:
            return "User pressed back or canceled a dialog";
        case BILLING_RESPONSE_RESULT_BILLING_UNAVAILABLE:
            return "Billing API version is not supported for the type requested";
        case BILLING_RESPONSE_RESULT_ITEM_UNAVAILABLE:
            return "Requested product is not available for purchase";
        case BILLING_RESPONSE_RESULT_DEVELOPER_ERROR:
            return "Invalid arguments provided to the API. This error can also indicate that the application was not correctly signed or properly set up for In-app Billing in Google Play, or does not have the necessary permissions in its manifest";
        case BILLING_RESPONSE_RESULT_ERROR:
            return "Fatal error during the API action";
        case BILLING_RESPONSE_RESULT_ITEM_ALREADY_OWNED:
            return "Failure to purchase since item is already owned";
        case BILLING_RESPONSE_RESULT_ITEM_NOT_OWNED:
            return "Failure to consume since item is not owned";
        default:
            return "Unknown response from the server";
        }
    }
    
    /**
     * Called when the purchase Intent is finished to process its results.
     */ 
    public static void handleActivityResponse(int resultCode, Intent data) 
    {
        // Parse the bundle.
        int responseCode = data.getIntExtra("RESPONSE_CODE", 0);
        String purchaseData = data.getStringExtra("INAPP_PURCHASE_DATA");
        String dataSignature = data.getStringExtra("INAPP_DATA_SIGNATURE");
        
        // Report failure.    
        if (resultCode != Activity.RESULT_OK) 
        {
            deferNativeCallback(PURCHASE_FAILURE, getResponseCodeMessage(resultCode));
            return;
        }

        // Parse and report the results.
        try 
        {
           JSONObject jo = new JSONObject(purchaseData);
           String sku = jo.getString("productId");
           
            // Construct JSON that Loom expects.
            JSONObject output = new JSONObject();
            output.put("productId", sku);
            output.put("transactionId", jo.getString("orderId"));
            output.put("transactionDate", jo.getString("purchaseTime"));
            output.put("successful", 1);
            deferNativeCallback(PURCHASE_SUCCESS, output.toString());

            // Attempt to consume it automatically.
            Log.i(TAG, "Auto-consuming purchase of SKU " + sku + ", signature is " + dataSignature);
            _service.consumePurchase(3, _activity.getPackageName(), dataSignature);
        }
        catch (JSONException e) 
        {
            deferNativeCallback(PURCHASE_FAILURE, e.getMessage());
        } 
        catch (RemoteException e) 
        {
            deferNativeCallback(PURCHASE_FAILURE, e.getMessage());
        }
    }
    
    /**
     * Attach to an Activity to get access to the billing service.
     */
    public static void bind(Activity activity) 
    {
        _activity = activity;
        _billingAllowed = LoomDemo.checkPermission(_activity, "android.permission.BILLING");
        if(_billingAllowed)
        {
            _activity.bindService(new Intent(BILLING_INTENT), _serviceConnection,
                    Context.BIND_AUTO_CREATE);
        }
        else
        {
            Log.i(TAG, "Billing permission 'android.permission.BILLING' not found in the AndroidManifest. Billing Support will not be initialized.");
        }
    }

    /**
     * Clean up attachment to Activity.
     */
    public static void unbind() 
    {
        if (_billingAllowed && (_serviceConnection != null))
        {
            _activity.unbindService(_serviceConnection);
        }
    }

    /**
     * Returns true if IAP is active and we can process purchases.
     */
    public static boolean isAvailable()
    {
        if(!_billingAllowed)
        {
            return false;
        }

        try
        {
            Log.i(TAG, "Billing availability check!");
            Log.i(TAG, "   - Package name = " + _activity.getPackageName());
            int response = _service.isBillingSupported(3, _activity.getPackageName(), "inapp");
            Log.i(TAG, "   - Response code = " + response);

            // Uncomment to clear the purchased test item every time.
            //_service.consumePurchase(3, _activity.getPackageName(), "inapp:" + _activity.getPackageName() + ":android.test.purchased");

            return response == BILLING_RESPONSE_RESULT_OK;
        }
        catch(Exception e)
        {
            return false;
        }
    }

    /**
     * Called to trigger the product purchase Intent.
     */
    public static void purchaseProduct(String sku) 
    {
        try 
        {
            Bundle buyIntent = _service.getBuyIntent(3, _activity.getPackageName(), sku, "inapp", "");
            handlePurchaseResponse(buyIntent);
        } catch (RemoteException e) 
        {
            deferNativeCallback(PURCHASE_FAILURE, e.getMessage());
        }
    }

    /**
     * Loads all the product information requested via calls to pushProduct.
     */
    public static void loadProducts() 
    {
        Bundle querySkus = new Bundle();
        querySkus.putStringArrayList(ITEM_ID_LIST, _products);

        // make a synchronous request for now
        try 
        {
            Log.i(TAG, "Loading product details!");
            Log.i(TAG, "   - Package name = " + _activity.getPackageName());
            Log.i(TAG, "   - SKUs = " + _products.toString());
            Bundle bundle = _service.getSkuDetails(3, _activity.getPackageName(), "inapp", querySkus);
            handleLoadProductsResponse(bundle);
            Log.i(TAG, "   - Done!");
        } 
        catch (RemoteException e) 
        {
            Log.i(TAG, "   x Failed: " + e.getMessage());
            deferNativeCallback(DETAILS_FAILURE, e.getMessage());
        }
        
        _products.clear();
    }
    
    /**
     * Note a product by string ID to be looked up via loadProducts.
     */
    public static void pushProduct(String productId)
    {
        _products.add(productId);
    }

    /**
     * Query existing product ownership.
     */
    public static void queryInventory()
    {
        Log.i(TAG, "Querying purchases.");

        Bundle bundle;
        try
        {
            bundle = _service.getPurchases(3, _activity.getPackageName(), "inapp", null);
        }
        catch(RemoteException e)
        {
            Log.e(TAG, "Failed to get purchases.");
            return;
        }

        ArrayList<String> purchases = bundle.getStringArrayList("INAPP_PURCHASE_DATA_LIST");
        ArrayList<String> dataSignatures = bundle.getStringArrayList("INAPP_DATA_SIGNATURE_LIST");

        for(String purchaseData : purchases)
        {
            JSONObject jo = null;
            try
            {
                jo = new JSONObject(purchaseData);
            }
            catch(Exception e)
            {
                Log.e(TAG, "Failed to parse inventory purchase data!");
                continue;
            }

            Log.i(TAG, "saw inventory data: " + purchaseData);

            try
            {
                // Construct JSON that Loom expects.
                JSONObject output = new JSONObject();
                output.put("productId", jo.getString("productId"));
                output.put("transactionId", jo.getString("orderId"));
                output.put("transactionDate", jo.getString("purchaseTime"));
                output.put("successful", 1);
                deferNativeCallback(PURCHASE_SUCCESS, output.toString());
            }
            catch(Exception e)
            {
                Log.e(TAG, "Failed to pass through inventory purchase data.");
            }
        }

        // Attempt to consume all purchases.
        for(String dataSignature : dataSignatures)
        {
            // Attempt to consume it to clean up lingering non-consumables.
            Log.i(TAG, "Consuming purchase with dataSignature = " + dataSignature);
            try
            {
                _service.consumePurchase(3, _activity.getPackageName(), dataSignature);
            }
            catch(Exception e)
            {
                Log.e(TAG, "   - Failed! Due to: " + e.toString());
            }
        }
                
    }

    // ________________________________________________
    // Private
    // ________________________________________________
    private static ArrayList<String> _products = new ArrayList<String>();
    private static Activity _activity;
    private static boolean _billingAllowed;
    private static IInAppBillingService _service;
    private static ServiceConnection _serviceConnection = new ServiceConnection() {
        @Override
        public void onServiceDisconnected(ComponentName name) {
            _service = null;
        }

        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            _service = IInAppBillingService.Stub.asInterface(service);
            deferNativeCallback(PURCHASE_SUCCESS,
                    "LoomStore setup success");
        }
    };
    
    /**
     * Process the results from a loadProducts call and dispatch to native.
     */
    private static void handleLoadProductsResponse(Bundle bundle)
    {
        Log.i(TAG, "Got product details response!");
        int response = bundle.getInt("RESPONSE_CODE");
        Log.i(TAG, "   - RESPONSE_CODE = " + response);
        if (response != BILLING_RESPONSE_RESULT_OK) 
        {
            Log.i(TAG, "   x FAILED.");
            deferNativeCallback(DETAILS_FAILURE, getResponseCodeMessage(response));
            return;
        }

       ArrayList<String> responseList = bundle.getStringArrayList("DETAILS_LIST");
       Log.i(TAG, "   - Got details in bundle!");

        // Pass the products back.         
        for (String thisResponse : responseList)
        {
            Log.i(TAG, "   - " + thisResponse);
            deferNativeCallback(DETAILS_SUCCESS, thisResponse);
        }
        Log.i(TAG, "   - DONE!");
        deferNativeCallback(DETAILS_COMPLETED, null);
    }
    
    /**
     * Handle the results from a purchase request.
     */
    private static void handlePurchaseResponse(Bundle bundle) 
    {
        int response = bundle.getInt("RESPONSE_CODE");
        if (response == 0)
        {
           PendingIntent pendingIntent = bundle.getParcelable("BUY_INTENT");
           try 
           {
            _activity.startIntentSenderForResult(pendingIntent.getIntentSender(),
                       INTENT_CODE, new Intent(), Integer.valueOf(0), Integer.valueOf(0),
                       Integer.valueOf(0));
            } catch (SendIntentException e) 
            {
                deferNativeCallback(PURCHASE_FAILURE, e.getMessage());
            }
        }
        else
        {
            deferNativeCallback(PURCHASE_FAILURE, getResponseCodeMessage(response));
        }
        
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
