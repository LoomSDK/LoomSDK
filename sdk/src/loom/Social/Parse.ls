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
     *
     */

    import loom.HTTPRequest;

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

        static var parseAppID:String;
        static var parseRESTKey:String;
        static var parseSessionToken:String;

        static var requestQueue:Vector.<HTTPRequest>;
        static var activeQueryQueue:Vector.<HTTPRequest>;
        static var timeoutDuration = 10000;                                //Time in ms before a request is considered to have timed out. 0 = no timeout.
        static var requestDelay = 50;                                      //Delay in ms between queued HTTPrequests being sent.

        static const PARSE_API_BASE:String = "https://api.parse.com/1/";   //Base REST URL for Parse.
        static const REQUEST_BUFFER_LENGTH = 20;                           //We keep a buffer of sent HTTPRequests to prevent them from being GC'd before they can complete.

        static public var REST_onTimeout:Function;

        static var dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";            //Parse date format string

        static var nextTick:Number;
        static var nextTimeout:Number=0;

        public static function REST_setCredentials(appID:String = "", restKey:String = "")
        {
            parseAppID = appID;
            parseRESTKey = restKey;
            requestQueue = new Vector.<HTTPRequest>;
            activeQueryQueue = new Vector.<HTTPRequest>;          

            nextTick = Platform.getTime()+requestDelay;
        }
        
        public static function REST_setAppID(newID:String)
        {
            parseAppID = newID;
        }

        public static function REST_getAppID():String
        {
            return parseAppID;
        }

        public static function REST_setDateFormat(newFormat:String)
        {
            dateFormat = newFormat;
        }

        public static function REST_getDateFormat():String
        {
            return dateFormat;
        }
        
        public static function REST_setRESTKey(newKey:String)
        {
            parseRESTKey = newKey;
        }

        public static function REST_getRESTKey():String
        {
            return parseRESTKey;
        }
        
        public static function REST_setSessionToken(newToken:String)
        {
            parseSessionToken = newToken;
        }

        
        public static function REST_getSessionToken():String
        {
            return parseSessionToken;
        }

        //REST functionality calls

        public static function REST_OauthLogin(oauthJSON:JSON = null, success:Function=null, failure:Function=null)
        {
            POST("users",oauthJSON,success,failure);
        }

        public static function REST_loginWithUsername(userName:String, password:String, success:Function=null, failure:Function=null)
        {                       
            var arguments = "username="+userName+"&password="+password;
            
            GET("login",null,arguments,success,failure);
        }

        
        public static function REST_signupWithUsername(signupParameters:JSON = null, success:Function=null, failure:Function=null)
        {            
            POST("users",signupParameters,success,failure);
        }

        
        public static function REST_requestPasswordReset(resetParams:JSON,success:Function = null,failure:Function = null)
        {            
            POST("requestPasswordReset",resetParams,success,failure);
        }

                
        public static function REST_callCloudFunction(functionName:String, functionParameters:JSON = null, success:Function=null, failure:Function=null)
        {                       
            POST("functions/"+functionName,functionParameters,success,failure);
        }       
        
        public static function REST_getCurrentUser(success:Function=null,failure:Function=null)
        {
            GET("users/me",null,"",success,failure);
        }

        public static function REST_createObject(objectName:String,additionalData:JSON = null,success:Function = null, failure:Function=null)
        {           
            POST("classes/"+objectName,additionalData,success,failure);
        }

        public static function REST_retrieveObject(objectName:String,objectID:String,success:Function = null, failure:Function=null)
        {           
            GET("classes/"+objectName+"/"+objectID,null,"",success,failure);
        }

        public static function REST_updateObject(objectName:String,objectID:String,updateData:JSON = null,success:Function = null, failure:Function=null)
        {           
            PUT("classes/"+objectName+"/"+objectID,updateData,success,failure);
        }

        public static function REST_makeQuery(objectName:String,queryString:String,success:Function = null, failure:Function = null)
        {            
            GET("classes/"+objectName,null,queryString,success,failure);
        }
        
        //HTTP Request functions

        public static function POST(URL:String="", data:JSON=null, success:Function=null, failure:Function=null)
        {            
            var req = new HTTPRequest(PARSE_API_BASE+URL,"application/json");            
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

            if(failure != null)
                req.onFailure += failure;
            
            if(success != null)
                req.onSuccess += success;

            requestQueue.push(req);
            
        }

        public static function PUT(URL:String="", data:JSON=null, success:Function=null, failure:Function=null)
        {         
            var req = new HTTPRequest(PARSE_API_BASE+URL,"application/json");            
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

            if(failure != null)
                req.onFailure += failure;
            
            if(success != null)
                req.onSuccess += success;

            requestQueue.push(req);
            
        }
        
        public static function GET(URL:String, jsonData:JSON = null, urlData:String = "", success:Function=null, failure:Function=null)
        {           
            var url = PARSE_API_BASE+URL;       

            if(!String.isNullOrEmpty(urlData))
            {
                url+="?"+urlData;           
            }            
            
            var req = new HTTPRequest(url,"application/json");            
            req.method = "GET";
            
            req.setHeaderField("X-Parse-Application-Id", parseAppID);
            req.setHeaderField("X-Parse-REST-API-Key", parseRESTKey);  
            
            if(!String.isNullOrEmpty(parseSessionToken))          
                req.setHeaderField("X-Parse-Session-Token", parseSessionToken); 
            
            if(jsonData != null)
                req.body = jsonData.serialize();          
            
            if(success != null)
                req.onSuccess += success;
            if(failure != null)
                req.onFailure += failure;
                        
            requestQueue.push(req);
        }


        //Request control variables and timeout functions
                
        public static function REST_pushToRequestQueue(newReq:HTTPRequest)
        {            
            requestQueue.push(newReq);
        }
        
        public static function REST_setTimeoutDuration(newTimeout:Number)
        {
            timeoutDuration = newTimeout;
        }

        public static function REST_getTimeoutDuration():Number
        {
            return timeoutDuration;
        }

        public static function REST_setRequestDelay(newDelay:Number)
        {
            requestDelay = newDelay;
        }

        public static function REST_getRequestDelay():Number
        {
            return requestDelay;
        }

        public static function REST_resetTimeout()
        {
            //We reset the timeout count to 0, so as to ignore it.
            nextTimeout = 0;
        }

        public static function tick() 
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

                    //We add the timeout cancellation function to success and failure delegates.

                    nextReq.onSuccess += REST_resetTimeout;
                    nextReq.onFailure += REST_resetTimeout;

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