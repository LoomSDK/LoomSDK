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

package loom.social 
{
    /**
     * Loom Parse API.
     *
     * Loom provides access to the Parse API on mobile devices for social networking services.
     * Visit https://parse.com/ for more information
     *
     *  In order to use Parse support in Loom, you must set your 
     *  'parse_app_id' (unique App ID) and optionally the 'parse_client_key' 
     *  (unique Client Key) in your project's loom.config file.
     *
     *  For custom servers you must also set `parse_server` to the
     *  base Parse URL, e.g. "https://example.com/parse/".
     *
     */

    import loom.HTTPRequest;
    import loom.Application;
    import loom.gameframework.LoomGroup;
    import loom.gameframework.TimeManager;
    import loom.gameframework.ITicked;

    /**
     * Small class which implements ITicked to handle
     * running Parse ticks.
     */
    private class ParseTicker implements ITicked
    {
        function onTick():void
        {
            Parse.internalTick();
        }
    }

    /**
     * Static control class for accessing the Parse API functionality
     */
    public native class Parse 
    {
        /*******NATIVE LINKS******/

        /**
         * Checks if Native Parse is active and ready for use
         *
         *  @return Whether or not the Native Parse API is currently active
         */
        public static native function isActive():Boolean;

        /**
         * Obtains the Parse Installation ID
         *
         *  @return the current installation ID, or and empty string if there was an error or Parse has not been initialized
         */
        public static native function getInstallationID():String;

        /**
         * Obtains the Parse Installation ObjectID
         *
         *  @return the current installation objectID, or an empty string if there was an error or Parse has not been initialized
         */
        public static native function getInstallationObjectID():String;

        /**
         * Sets the Parse Installation userId property
         *
         *  @param userId The new installation userID to set
         *  @return Whether or not the the userID was able to be updated
         */
        public static native function updateInstallationUserID(userId:String):Boolean;
    
        
        /******REST COMMANDS******/

        private static var parseAppID:String;
        private static var parseRESTKey:String;
        private static var parseSessionToken:String;

        private static var requestQueue:Vector.<HTTPRequest>;
        private static var activeQueryQueue:Vector.<HTTPRequest>;
        private static var timeoutDuration = 10000;                                //Time in ms before a request is considered to have timed out. 0 = no timeout.
        private static var requestDelay = 50;                                      //Delay in ms between queued HTTPrequests being sent.

        private static var apiBase:String;                                         //Base REST URL for Parse.
        private static const REQUEST_BUFFER_LENGTH = 20;                           //We keep a buffer of sent HTTPRequests to prevent them from being GC'd before they can complete.

        private static var dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";            //Parse date format string
        private static var nextTick:Number;
        private static var nextTimeout:Number=0;

        private static var ticker:ParseTicker;
        private static var deprecatedTickWarned:Boolean = false;

        private static var initialized:Boolean = false;

        /**
         *  Called when the any REST operation times out.
         */
        public static var REST_onTimeout:Function;

        /**
         * Initializes Parse for further use.
         * You can call this once on application startup to initialize Parse
         * in advance, otherwise it is initialized on first use.
         */
        public static function initialize()
        {
            if (initialized) return;
            initialized = true;

            var config = JSON.parse(Application.loomConfigJSON);
            parseAppID = config.getString("parse_app_id");
            parseRESTKey = config.getString("parse_client_key");
            apiBase = config.getString("parse_server");
            requestQueue = new Vector.<HTTPRequest>;
            activeQueryQueue = new Vector.<HTTPRequest>;
            nextTick = Platform.getTime()+requestDelay;

            if (!ticker) {
                ticker = new ParseTicker();
                var timeManager = LoomGroup.rootGroup.getManager(TimeManager) as TimeManager;
                timeManager.addTickedObject(ticker);
            }
        }


        /**
         * Sets the REST credentials to append to our http requests. Also initializes request queues.
         *
         *  @param appId The Parse application ID
         *  @param restKey The Parse REST API key.
         */
        public static function REST_setCredentials(appID:String = "", restKey:String = "")
        {
            parseAppID = appID;
            parseRESTKey = restKey;
            requestQueue = new Vector.<HTTPRequest>;
            activeQueryQueue = new Vector.<HTTPRequest>;
            nextTick = Platform.getTime()+requestDelay;
        }
        
        /**
         * Individually sets the Parse App ID
         */
        public static function set REST_AppID(newID:String):void  {parseAppID = newID;}
        /**
         * Individually gets the Parse App ID
         */
        public static function get REST_AppID():String {return parseAppID;}

        /**
         * Individually sets the date format string for Parse. (This is a convenience variable to store the date format string for Oauth tokens)
         */
        public static function set REST_DateFormat(newFormat:String):void {dateFormat = newFormat;}
        /**
         * Individually gets the date format string for Parse. (This is a convenience variable to store the date format string for Oauth tokens)
         */
        public static function get REST_DateFormat():String {return dateFormat;}
        
        /**
         * Individually sets the REST API key
         */
        public static function set REST_RESTKey(newKey:String):void {parseRESTKey = newKey;}
        /**
         * Individually gets the REST API key
         */
        public static function get REST_RESTKey():String {return parseRESTKey;}
        
        /**
         * Individually sets the Parse session token.
         */
        public static function set REST_SessionToken(newToken:String):void {parseSessionToken = newToken;}      
        /**
         * Individually gets the Parse session token.
         */
        public static function get REST_SessionToken():String {return parseSessionToken;}



        //REST functionality calls

        /**
         * Logs the user in using an Oauth json object formatted as per Parse REST specs for the third-party service (Facebook, Twitter, etc.)
         *
         *  @param oathJSON - JSON object containing the necessary Oauth data for the service, as per Parse documentation
         *  @param success - delegate function to run on request success
         *  @param failure - delegate function to run on request failure
         */
        public static function REST_OauthLogin(oauthJSON:JSON = null, success:Function=null, failure:Function=null):HTTPRequest
        {
            return POST("users",oauthJSON,success,failure);
        }

        /**
         * Logs an existing user in using their username and password
         *
         *  @param userName - The user's username
         *  @param password - The user's password
         *  @param success - delegate function to run on request success
         *  @param failure - delegate function to run on request failure
         */
        public static function REST_loginWithUsername(userName:String, password:String, success:Function=null, failure:Function=null):HTTPRequest
        {                       
            var arguments = "username="+userName+"&password="+password;
            return GET("login",null,arguments,success,failure);
        }

        /**
         * Signs a user up for a new account using the data passed via json object (formatted as per Parse REST signup specs)
         *         
         *  @param signupParameters - JSON containing the required signup data
         *  @param success - delegate function to run on request success
         *  @param failure - delegate function to run on request failure
         */
        public static function REST_signupWithUsername(signupParameters:JSON = null, success:Function=null, failure:Function=null):HTTPRequest
        {            
            return POST("users",signupParameters,success,failure);
        }

        /**
         * Requests a password reset mail from Parse for the given account data
         *         
         *  @param resetParams - JSON containing the required account data for reset
         *  @param success - delegate function to run on request success
         *  @param failure - delegate function to run on request failure
         */
        public static function REST_requestPasswordReset(resetParams:JSON,success:Function = null,failure:Function = null):HTTPRequest
        {            
            return POST("requestPasswordReset",resetParams,success,failure);
        }

        /**
         * Calls a Cloud Function on the Parse servers
         *         
         *  @param functionName - String containing the name of the cloud function to call
         *  @param functionParameters - JSON containing any parameters being passed to the cloud function
         *  @param success - delegate function to run on request success
         *  @param failure - delegate function to run on request failure
         */     
        public static function REST_callCloudFunction(functionName:String, functionParameters:JSON = null, success:Function=null, failure:Function=null):HTTPRequest
        {                       
            return POST("functions/"+functionName,functionParameters,success,failure);
        }       
        
        /**
         * Gets the current user's data (assuming a valid session token has been provided)
         *                  
         *  @param success - delegate function to run on request success
         *  @param failure - delegate function to run on request failure
         */   
        public static function REST_getCurrentUser(success:Function=null,failure:Function=null):HTTPRequest
        {
            return GET("users/me",null,"",success,failure);
        }

        /**
         * Creates a new Parse object
         *         
         *  @param objectName - string containing the name of the object
         *  @param additionalData - JSON object containing additional fields and data to be assigned to the object
         *  @param success - delegate function to run on request success
         *  @param failure - delegate function to run on request failure
         */
        public static function REST_createObject(objectName:String,additionalData:JSON = null,success:Function = null, failure:Function=null):HTTPRequest
        {           
            return POST("classes/"+objectName,additionalData,success,failure);
        }

        /**
         * Retrieves data from an existing Parse object
         *         
         *  @param objectName - string containing the type of the object
         *  @param objectID - string containing the unique objectId of the object to retrieve
         *  @param success - delegate function to run on request success
         *  @param failure - delegate function to run on request failure
         */
        public static function REST_retrieveObject(objectName:String,objectID:String,success:Function = null, failure:Function=null):HTTPRequest
        {           
            return GET("classes/"+objectName+"/"+objectID,null,"",success,failure);
        }

        /**
         * Updates an existing Parse object with new data
         *         
         *  @param objectName - string containing the type of the object
         *  @param objectID - string containing the unique objectId of the object to retrieve
         *  @param updateData - JSON object containing update data
         *  @param success - delegate function to run on request success
         *  @param failure - delegate function to run on request failure
         */
        public static function REST_updateObject(objectName:String,objectID:String,updateData:JSON = null,success:Function = null, failure:Function=null):HTTPRequest
        {           
            return PUT("classes/"+objectName+"/"+objectID,updateData,success,failure);
        }

        /**
         * Passes a query to the Parse servers
         *         
         *  @param objectName - string containing the type of the object to query
         *  @param queryString - URI-formatted string containing query, as per Parse REST query format
         *  @param success - delegate function to run on request success
         *  @param failure - delegate function to run on request failure
         */
        public static function REST_makeQuery(objectName:String,queryString:String,success:Function = null, failure:Function = null):HTTPRequest
        {            
            return GET("classes/"+objectName,null,queryString,success,failure);
        }
        



        //HTTP Request functions

        /**
         * Sends a POST httprequest
         *         
         *  @param URL - string to be appended to the base REST API URL for specific functions
         *  @param data - JSON object containing any data to pass to the server in this query
         *  @param success - delegate function to run on request success
         *  @param failure - delegate function to run on request failure
         */
        public static function POST(URL:String="", data:JSON=null, success:Function=null, failure:Function=null):HTTPRequest
        {            
            if (!initialized) initialize();

            var req = new HTTPRequest(apiBase+URL,"application/json");            
            req.method = "POST";
            
            req.setHeaderField("X-Parse-Application-Id", parseAppID);
            req.setHeaderField("X-Parse-REST-API-Key", parseRESTKey);            
            if(!String.isNullOrEmpty(parseSessionToken))
                req.setHeaderField("X-Parse-Session-Token", parseSessionToken); 

            if(data != null)
            {
                req.body = data.serialize();
            }
            else
            {
                req.body = "{}";
            }                                  

            //We add the timeout cancellation function to success and failure delegates.
            req.onSuccess += REST_resetTimeout;
            req.onFailure += REST_resetTimeout;

            if(failure != null)
                req.onFailure += failure;
            
            if(success != null)
                req.onSuccess += success;

            requestQueue.push(req);

            return req;
        }

        /**
         * Sends a PUT httprequest
         *         
         *  @param URL - string to be appended to the base REST API URL for specific functions
         *  @param data - JSON object containing any data to pass to the server in this query
         *  @param success - delegate function to run on request success
         *  @param failure - delegate function to run on request failure
         */
        public static function PUT(URL:String="", data:JSON=null, success:Function=null, failure:Function=null):HTTPRequest
        {         
            var req = new HTTPRequest(apiBase+URL,"application/json");            
            req.method = "PUT";
            
            req.setHeaderField("X-Parse-Application-Id", parseAppID);
            req.setHeaderField("X-Parse-REST-API-Key", parseRESTKey);            
            if(!String.isNullOrEmpty(parseSessionToken))
                req.setHeaderField("X-Parse-Session-Token", parseSessionToken); 

            if(data != null)
            {
                req.body = data.serialize();
            }
            else
            {
                req.body = "{}";
            }                                  

            //We add the timeout cancellation function to success and failure delegates.
            req.onSuccess += REST_resetTimeout;
            req.onFailure += REST_resetTimeout;

            if(failure != null)
                req.onFailure += failure;
            
            if(success != null)
                req.onSuccess += success;

            requestQueue.push(req);

            return req;
        }
        
        /**
         * Sends a GET httprequest
         *         
         *  @param URL - string to be appended to the base REST API URL for specific functions
         *  @param jsonData - JSON object containing any data to pass to the server in this query
         *  @param urlData - string containing any URI-formatted data to pass to the server in this query
         *  @param success - delegate function to run on request success
         *  @param failure - delegate function to run on request failure
         */
        public static function GET(URL:String, jsonData:JSON = null, urlData:String = "", success:Function=null, failure:Function=null):HTTPRequest
        {
            if (!initialized) initialize();

            var url = apiBase+URL;       

            if(!String.isNullOrEmpty(urlData))
            {
                url+="?"+urlData;           
            }            
            
            var req = new HTTPRequest(url,"application/json");            
            req.method = "GET";
            
            req.setHeaderField("X-Parse-Application-Id", parseAppID);
            req.setHeaderField("X-Parse-REST-API-Key", parseRESTKey);
            if (URL == "login") {
                req.setHeaderField("X-Parse-Installation-Id", getInstallationID());
            }
            
            if(!String.isNullOrEmpty(parseSessionToken))          
                req.setHeaderField("X-Parse-Session-Token", parseSessionToken); 
            
            if(jsonData != null)
                req.body = jsonData.serialize();          
            
            //We add the timeout cancellation function to success and failure delegates.
            req.onSuccess += REST_resetTimeout;
            req.onFailure += REST_resetTimeout;
            
            if(success != null)
                req.onSuccess += success;
            if(failure != null)
                req.onFailure += failure;
            
            requestQueue.push(req);

            return req;
        }



        //Request control variables and timeout functions
                
        /**
         * Pushes an outside HTTPRequest to the internal request queue
         *         
         *  @param newReq - request to be pushed into the queue
         */
        public static function REST_pushToRequestQueue(newReq:HTTPRequest)
        {            
            newReq.onSuccess+=REST_resetTimeout;
            newReq.onFailure+=REST_resetTimeout;
            requestQueue.push(newReq);
        }
        
        /**
         * Sets the request timeout duration
         */
        public static function set REST_TimeoutDuration(newTimeout:Number):void {timeoutDuration = newTimeout;}
        /**
         * Gets the request timeout duration
         */
        public static function get REST_TimeoutDuration():Number {return timeoutDuration;}

        /**
         * Sets the period between requests being sent from the request queue
         */
        public static function set REST_RequestDelay(newDelay:Number):void {requestDelay = newDelay;}
        /**
         * Gets the period between requests being sent from the request queue
         */
        public static function get REST_RequestDelay():Number {return requestDelay;}

        /**
         * Resets the request timeout time to 0, preventing timeout from firing.
         */
        public static function REST_resetTimeout()
        {
            //We reset the timeout count to 0, so as to ignore it.
            nextTimeout = 0;
        }

        /**
         * Deprecated: this is now handled internally.
         *
         * Check current time, fire off requests and trigger timeouts where necessary
         * @deprecated
         */
        public static function tick()
        {
            if (!deprecatedTickWarned) {
                trace("Deprecation Warning: You can remove all calls to Parse.tick() as it is now handled internally.");
                deprecatedTickWarned = true;
            }
        }

        /**
         * Internal function that gets called to run requests and timeouts.
         *
         * @private 
         */
        public static function internalTick() 
        {
            var currentTick = Platform.getTime();
            
            //Check for timeout on the last request.
            if((nextTimeout > 0) && (currentTick>=nextTimeout))
            {
                nextTimeout = 0;
                
                if(REST_onTimeout)
                    REST_onTimeout.call();

                return;
            }

            //Send the next request in the queue
            if(currentTick>=nextTick)
            {
                if(requestQueue.length>0)
                {                   
                    //We send the next queued request and add it to the active request buffer.
                    var nextReq = requestQueue[0];                              

                    nextReq.send();

                    activeQueryQueue.push(nextReq);
                    requestQueue.remove(nextReq);

                    nextTick = currentTick + requestDelay;
                    nextTimeout = currentTick + timeoutDuration;
                }

                //Clean up the buffer if it gets oversized.
                if(requestQueue.length>REQUEST_BUFFER_LENGTH) 
                {
                    requestQueue.remove(requestQueue[0]);
                }
            }
        }
    }
}