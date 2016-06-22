/*
===========================================================================
Loom SDK
Copyright 2011, 2012, 2013 
The Game Engine Company, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 
===========================================================================
*/

package loom.admob
{
    /**
     *  Represents an AdMob Interstitial (fullscreen) ad. The class allows the creation and display of
     *  Interstitial ads via AdMob (www.google.com/ads/admob/).
     *
     *  InterstitialAd is currently supported on Android and iOS.
     */
    final public native class InterstitialAd
    {
        /**
         *  Creates an Interstitial ad and sends a request. It is recommended that
         *  Interstitial ads are not reused. It is also recommended to only show the 
         *  Interstitial ad when it is ready by calling show() only after a call to onAdReceived
         *  has be made.
         *
         *  Before creating the InterstitialAd Publisher.initialize() must be called.
         *
         *  @param adUnitId The Ad Unit ID to use when requesting the interstitial ad. Looks like "ca-app-pub-XXXXXXXXXXXXXXX/XXXXXXXXXX".
         */
        public native function InterstitialAd(adUnitId:String);

        public native function load();

        /**
         *  Shows the interstitial ad. Should only be called once.
         */
        public native function show();
        
        /**
         *  Called when the ad had been received from AdMob. When this delegate is called
         *  is the best time to call show().
         */
        public native var onAdReceived:NativeDelegate;
        
        /**
         *  Called when the response from AdMob is an error instead of an ad. This should
         *  be handled gracefully.
         */
        public native var onAdError:NativeDelegate;
    }
}