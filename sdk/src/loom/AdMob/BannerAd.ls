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
     *  Represents an AdMob banner ad. The class allows the creation and display of
     *  Banner ads via AdMob (www.google.com/ads/admob/).
     *
     *  BannerAd is currently supported on Android and iOS.
     */
    final public native class BannerAd
    {
        /**
         *  Creates the banner ad with the specified ad unit ID and size. Before creating the BannerAd
         *  Publisher.initialize() must be called.
         *
         *  @param adUnitId The AdMob Ad Unit ID. Looks like "ca-app-pub-XXXXXXXXXXXXXXX/XXXXXXXXXX".
         *  @param size The requested size of the banner. Default is BannerSize.SMART_LANDSCAPE
         */
        public native function BannerAd(adUnitId:String, size:BannerSize=0);

        public native function load();

        /**
         *  Shows the banner Ad. The ad will be displayed on top of Looms GLView.
         */
        public native function show();

        /**
         *  Hides the banner ad.
         */
        public native function hide();

        /**
         *  Gets the x position of the banner ad.
         */
        public native function get x():Number;
        
        /**
         *  Sets the x position of the banner ad.
         */
        public native function set x( value:Number );
        
        /**
         *  Gets the y position of the banner ad.
         */
        public native function get y():Number;
        
        /**
         *  Sets the y position of the banner ad.
         */
        public native function set y( value:Number );
        
        /**
         *  Gets the width of the banner ad.
         */
        public native function get width():Number;
        
        /**
         *  Sets the width of the banner ad.
         */
        public native function set width( value:Number );
        
        /**
         *  Gets the height of the banner ad.
         */
        public native function get height():Number;
        
        /**
         *  Sets the height of the banner ad.
         */
        public native function set height( value:Number );

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

    /**
     *  Represents options for sizes to request from admob.
     */
    public enum BannerSize 
    {
        SMART_LANDSCAPE = 0,
        SMART_PORTRAIT = 1,
        STANDARD = 2,
        TABLET_MEDIUM = 3,
        TABLET_FULL = 4,
        TABLET_LEADERBOARD = 5
    }
}