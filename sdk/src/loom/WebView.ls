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

package loom
{
    /**
     * The Loom WebView API provides cross-platform support for displaying 
     * a WebKit container in your Loom application.
     *
     * WebViews always live on top of Loom's rendering. This allows cheaper
     * compositing and better performance.
     */
    public native class WebView
    {
        /**
         *  Instantiates and creates our WebView through platform-specific means. 
         *  When a WebView is initialized it’s initial dimensions are positioned at 
         *  (0,0) and sized at the devices screen dimensions. The created WebView, it 
         *  is not added to the screen. 
         *
         *  If the WebView is created on an unsupported platform, it will not crash or 
         *  throw in error. Instead it will continue to run the game and any calls to 
         *  functions on the WebView instance will have no side effects. 
         *
         *  Technical Note: We would love to throw an PLATFORM_NOT_SUPPORTED 
         *  exception. As of the time of this writing LoomScript does not have support 
         *  for exceptions (LOOM–248).
         */
        public native function WebView();

        /**
         *  Adds the WebView to the screen. The WebView will be placed on top of the GLView 
         *  that most Loom display nodes are rendered on and on top of any WebViews that are 
         *  currently showing.
         */
        public native function show();

        /**
         *  Removes the WebView from the screen. Although the WebView is removed from the 
         *  screen, it does not stop functioning. Performance of a functioning WebView that 
         *  is not on screen can vary by platform.
         */
        public native function hide();

        /**
         *  Navigates the WebView to the specified URL, calling this will trigger an 
         *  onRequestSent and possibly an onRequestFailed delegate call (if the request 
         *  was unsuccessful).
         *
         *  Currently there is no official support for requesting local URLs that are pointing 
         *  to html files in the assets folder. Doing so is possible, but may not be cross platform.
         */
        public native function request( url:String );

        /**
         *  Attempts to navigate the WebView backward in it’s history queue. If there is nothing to 
         *  go back to, this function returns false.
         */
        public native function goBack():Boolean;
        
        /**
         *  Attempts to navigate the WebView forward in it’s history queue. If there is nothing to go 
         *  forward to, this function returns false.
         */
        public native function goForward():Boolean;
        
        /**
         *  Returns true if the WebView can navigate backward in it’s history queue, false otherwise.
         */
        public native function canGoBack():Boolean;
        
        /**
         *  Returns true if the WebView can navigate forward in it’s history queue, false otherwise.
         */
        public native function canGoForward():Boolean;
        
        /**
         *  Sets the position and size of the WebView on the screen. It is highly recommended that 
         *  this function be used in favor of the individual getters/setters for performance reasons 
         *  as it reduces function calls and marshaling time between certain languages (*cough* Java *cough*).
         */
        public native function setDimensions( x:Number, y:Number, width:Number, height:Number );

        /**
         *  Gets/Sets the x position of the WebView. Positioning is platform-specific and the 
         *  coordinate system may in fact be different than the Cocos2D coordinate system (or any other rendering subsystem you are using for that matter).
         */
        public native function get x():Number;
        public native function set x( value:Number );
        
        /**
         *  Gets/Sets the y position of the WebView.
         */
        public native function get y():Number;
        public native function set y( value:Number );
        
        /**
         *  Gets/Sets the width of the WebView.
         */
        public native function get width():Number;
        public native function set width( value:Number );
        
        /**
         *  Gets/Sets the height of the WebView.
         */
        public native function get height():Number;
        public native function set height( value:Number );

        /**
         *  Called when a request has been sent for the WebView to process. This can be triggered by a call 
         *  to request() or by the WebView internally. It is common for HTML interaction to happen here by 
         *  calling an address for the application to respond to, for instance:
         *  
         *  ~~~as3
         *  webView.onRequestSent += function(url:String) {
         *      // if the html is telling us to go back I guess we will do so
         *      if(url == “loom://backToMenu”)
         *          goBackToMenu();
         *  }
         *  ~~~
         *
         *  This processes any requests by the HTML and allows great interaction between Loom and the WebView.  
         */
        public native var onRequestSent:NativeDelegate;

        /**
         *  Called when a request has failed. There can be numerous reasons why a request has failed, these 
         *  reasons can be platform specific and for that reason all you get is a pretty little error 
         *  message (that is platform specific to muahahahaha). A failed request can be handled like so:
         *  
         *  ~~~as3
         *  webView.onRequestFailed += function(msg:String) {
         *      Alert.show(“Oh Noes”, msg);
         *  }
         *  ~~~
         */
        public native var onRequestFailed:NativeDelegate;
    }
}