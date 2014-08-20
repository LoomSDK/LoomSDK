title: Store API
description: In-app payments API.
!------

## The Loom Store API

Loom supports in-app payment (IAP) on iOS and Android. 

Store support is provided via the `loom.store.Store` class. A "dummy" store implementation is provided for testing your app on platforms that don't provide a payment API. The StoreExample (in the examples zip) shows usage of the Store API.

Please be aware that using the store API requires that you have an active development account on your chosen platform(s) as well as signed legal agreements, an application ID, store items, certificates, and so on. We will discuss the basics of preparing for IAP development on supported platforms as well as using the Loom Store API.

## Scope

Today's mobile and desktop platforms offer powerful in-app purchase APIs. However, they can also be complicated to master, and time consuming to address when building multiplatform applications. Loom's goal is to provide a pragmatic store API which allows triggering purchases of consumable and non-consumable items and retrieving store information.

Future updates may include support for subscriptions, receipt validation, and downloadable content through store APIs, but these features are not currently included (as of sprint 27).

## Using the Loom Store API

There are three steps to using the Store API. First, initialize your callbacks and initialize the store:

~~~as3
Store.onProduct += myProductHandler;
Store.onTransaction += myTransactionHandler;
Store.initialize();
~~~

If you want to use the dummy provider for testing, and not the native store API (if present), pass the identifier to initialize: `Store.initialize("dummy");`. Note that when you call `initialize`, you may get transaction callbacks immediately. Some platforms (Android, iOS) queue transactions when your app is inactive and provide them at startup. (For instance, suppose payment was resolved while the app wasn't running.) Others (Android) re-report items that the user owns at app startup. Your code should be prepared to handle this case.

Second, you need to request product information. This is localized, up to date product information served by the native store API. Some platforms (iOS) will reject your app if you do not request product information before attempting to purchase. Here is how to request product information:

~~~as3
Store.listProducts([
   "co.theengine.loomdemo.billing.managedproduct", 
   "co.theengine.loomdemo.billing.unmanaged",
   "co.theengine.loomdemo.billing.subscription"
   "co.theengine.loomdemo.billing.testconsumable",
   ], onCompleteList);
~~~

You provide an array of product identifiers (as strings). `Store.onProduct` will be fired for each product's information; being passed an instance of `Loom.Store.Product`. If a product is unavailable, no data is returned. After all the products are returned, `onCompleteList` is fired. It's bad practice to call `listProducts` multiple times.

Once you have product information, you can populate your store UI with prices, titles, descriptions, and so on from the product callbacks.

Third, you will want to trigger purchases for the user when they click on buy buttons or otherwise indicate they wish to purchase. Store interactions use a native UI, so all that happens is you trigger a purchase then wait to know when the UI is gone, and then for a transaction to come through. Requesting a purchase looks like this:

~~~as3
Store.requestPurchase("co.theengine.loomdemo.billing.testconsumable", onPurchaseUIComplete);
~~~

You will receive two callbacks (assuming a successful purchase) - `onPurchaseUIComplete` will be called when the purchase UI goes away, and later, `Store.onTransaction` will be fired with a new instance of `Loom.Store.Transaction` containing details on the successful transaction, including the product ID purchased.

## Testing the Loom Store API with the Dummy Store Provider

If you are on a platform without Loom Store API support, then `Store.available` will always return false and `Store.providerName` will be "Null". However, you may want to test the purchase process. Or, you may want to test the purchase process on device without fully configuring your app for IAP, signing legal documents, etc.

You can do this by using the dummy store provider.  It is implemented in `DummyStoreProvider.ls` and simulates a functioning store API. It always returns data for every product and always allows purchases. To use the dummy provider, simply pass `Store.DUMMY_PROVIDER` to `Store.initialize` - ie, `Store.initialize(Store.DUMMY_PROVIDER);` instead of `Store.initialize();`. Then use the Store API as normal.

There are some caveats. Dummy store results are instant, but on real stores they can take seconds or minutes to occur. Therefore, you can write brittle code against the dummy store. Also, the dummy data returned by the dummy store is fixed and formulaic.

## Using the Loom Store API on Google Play

To use the Loom Store API with Google Play's in app payment API, you must first set up an Android application that is ready to accept IAP on the [Google Play Developer Console](https://play.google.com/apps/publish). We highly recommend reading the [official Google documentation on the Google Play In-app Billing API](http://developer.android.com/google/play/billing/index.html) before proceeding.

The Android documentation on [testing in-app purchases using your own product IDs](http://developer.android.com/google/play/billing/billing_testing.html#billing-testing-real) walks you through the steps required to be able to test your application. 

Once you have the developer console set up, there are a few more steps:

1. Make sure your product IDs are included in your calls to `Store.listProducts` and `Store.requestPurchase`. 
2. Confirm your `app_id` in `loom.config` matches what you specified in the Google Play Developer Console. 
3. You will need to build release version of your game's APK by following the instructions in Devices > Loom And Devices > Deploying to Android. Upload this to the Google Play Developer Console. Google Play uses this to validate your application.
4. Deploy and run your APK on a real device - the emulator does not support testing IAP.

Loom currently uses Android Billing API version 3.

## Using the Loom Store API on iOS

Before you can test on iOS, you need to fully complete setting up your iTunes Connect account. We recommend the [iTunes Connect Developer Guide](https://itunesconnect.apple.com/docs/iTunesConnect_DeveloperGuide.pdf) for a full discussion of this. The required steps include providing bank account information, accepting iOS store contracts, providing tax information. You also need to create an app and populate it with IAP products. You do not need to upload a binary of your application, however.

If you fail to fully complete all of this (see [Technical Note TN2259](https://developer.apple.com/library/ios/#technotes/tn2009/tn2259.html
) for a full walkthrough and very useful troubleshooting section), iTunes Connect will not serve product information and you will not be able to successfully request purchases. It may take iTunes Connect a few hours to successfully serve information and accept purchases even if you have completed all steps successfully.

You will need to set your `app_id` in `loom.config` to match your app's bundle ID (without the alphanumerix prefix) in order to be able to successfully use the store API.

## Troubleshooting

Expect it to take a few hours to get everything set up for Android and iOS IAP assuming you already have a valid developer account with both. Be patient and methodical and double check everything.

For easiest development and maintenance you want to use the same application/bundle ID and product IDs on all platforms. The Loom Store API is designed for this use case. However, it may not be possible to do this (for instance you may have different existing IDs or the store might enforce naming conventions). In this case, you can detect the provider name (using `Store.providerName`) and switch to different product IDs depending on the store you're using. In the case of different application IDs you might have to modify loom.config before doing final builds.

Use `adb logcat` or the XCode Organizer to see the system log for your device. Because IAP can be painful to debug, we have left lots of debug output in the platofmr code for the Loom Store API, so reviewing the log can give useful insights. 

We found [this thread](https://devforums.apple.com/thread/23344?tstart=0) on the Apple support forums very helpful for debugging our iOS woes.

Don't be shy about asking for help on the forums, either!

## Loom Store API Design

This is an advanced discussion of the details of Loom's Store API's design. It will be useful to people who want to debug it, extend the API, or add support for new stores.

Like most of Loom's native APIs, the store is built from a few key pieces. First, there is a low level C api (in `loom/common/platform/platformStore.h`) which is implemented on each supported platform. On iOS, it uses the StoreKit Objective C API. On Android, it uses JNI to call a Java implementation using the Google Play Store billing APIs. Additional stores could be added by either adding a new implementation of the `platformStore.h` functions, or by extending an existing implementation (for instance, modifying `LoomStore.java` to talk to an alternate store API in addition to the Play API). 

The common interface defined in `platformStore.h` simplifies implementation of the second piece, which is the LoomScript bindings - `lmStore.cpp` contains this code. The C API is designed to be easy to implement, and the LoomScript bindings surface that to the scripting layer.

The third and last piece is the LoomScript layer (`Store.ls` and friends) which implements a convenient and easy to use API on top of the easy to implement C API.
