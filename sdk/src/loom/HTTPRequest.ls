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
     *  The Loom HTTPRequest API provides the ability to call asynchronous HTTP methods at a 
     *  specified URL across all platforms that Loom supports.
     */
    final public native class HTTPRequest
    {
        /**
         * True if the network is available.
         */
        public static native function isConnected():Boolean;


        /**
         *  Constructs and initializes the HTTP request with the (optionally) specified URL 
         *  and Content-Type. If 'contentType' is null or empty, then the default of 
         *  'application/x-www-form-urlencoded' will be used.
         *  Keep in mind that the URL can be changed later with the URL property if you wish. 
         *  Headers will be initialized to empty when the HTTPRequest is instantiated.
         */
        public native function HTTPRequest(url:String=null, contentType:String=null);

        /**
         *  Sets the specified value-key pair in the request that is to be sent. This function 
         *  does not checking or validation so it is completely appropriate to overwrite values 
         *  of the specified key.
         */
        public native function setHeaderField(key:String, value:String);

        /**
         *  Returns the header value for the specified key, this is `null` if the value for the 
         *  key does not exist.
         */
        public native function getHeaderField(key:String):String;

        /**
         *  Sends the HTTPRequest along. Will immediately call `onFailure` if the url field is null.
         *  @return Whether or not the call was successful.
         */
        public native function send():Boolean;

        /**
         *  Cancels an in progress HTTPRequest.
         */
        public native function cancel();

        /**
         *  Called when the HTTPRequest is successful. Passes the response from the HTTP server.
         */
        public native var onSuccess:NativeDelegate;
        
        /**
         *  Called when the HTTPRequest is unsuccessful or cancelled. 
         *  Passes the an Error message (this can differ between plaforms).
         */
        public native var onFailure:NativeDelegate;

        /**
         *  Sets the HTTP method that the request will sent to the HTTP server.
         */
        public native var method:String;
        
        /**
         *  Sets the body to send with the request in the case of the method being POST.
         */
        public native var body:String;

        /**
         * Set this to send a binary body; it will be transmitted unmodified.
         */
        public native var bodyBytes:ByteArray;
        
        /**
         *  Another way to set the URL to send the HTTP request to.
         */
        public native var url:String;

        /**
         * When true, we return binary values encoded as base64.
         */
        public native var encodeResponse:Boolean;

        /**
         * When true, follow any redirects.
         */
        public native var followRedirects:Boolean;

        /**
         * When not null, the downloaded data is written to this file. This is
         * useful for caching purposes.
         */
        public native var cacheFileName:String;

    }
}