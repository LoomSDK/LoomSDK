package testjournal 
{
    import loom.Application;
    import loom.HTTPRequest;
    import loom.platform.Timer;
    import loom2d.events.EventDispatcher;
    import system.platform.File;
    import system.platform.Platform;
    import system.platform.PlatformType;
    import system.utils.Base64;
    
    import loom.graphics.Graphics;
    
    /**
     * The TestJournal class links with the Test Journal Web app to give analytical support
     */
    public class TestJournal 
    {
        /*
         * ------------------
         *      STATIC
         * ------------------
         */
        // Constants: The name of the screenshot taken for the test journal and the endpoint
        private static const SCREENSHOT_NAME:String = "testJournalScreen.png";
        //private static const TJ_URI:String = "localhost:3000/api/1";
        private static const TJ_URI:String = "http://loomtestjournal.parseapp.com/api/1";
        
        // Constant: How long Test Journal will retry an initial object creation request
        private static const CREATE_OBJ_RETRY_TIME:Number = 60000; // 1 minute
        
        // The current state of the test journal
        private static var state:TestJournalState = TestJournalState.UNINITIALIZED;
        
        // The application ID that is used by the Test Journal to identify the application (Provided by The Engine Company)
        private static var appID:String;
        
        // A tag that may be optionally passed by the user to help identify the app
        private static var tag:String;
        
        // Timer for taking screenshots and log data
        private static var timer:Timer;
        
        // Timer for handing an initial HTTP Error
        private static var httpRetryTimer:Timer;
        
        // HTTPRequest object that will handle the initial creation of data
        private static var objectUploadReq:HTTPRequest;
        
        // The object ID used to identify the specific object test data is being added to
        private static var objectId:String = "";
        
        // Vector for keeping track of log data
        private static var logData:Vector.<Dictionary.<String, String>>;
        
        // Variables used for keeping track of framerate
        private static var frameCountStartTime:Number;
        private static var frameCount:Number = 0;
        
        // Object that holds data to be sent up to Test Journal. Looks like:
        // { "data": { "time": updateTime, "screen": url, "log": nextLogData, "fps":frameUploadData } }
        private static var updateData:UpdateData;
        
        // Vector stores active request handlers
        private static var activeRequests:Vector.<TestJournal> = new Vector.<TestJournal>();
        
        /**
         * This function enables the Loom Test Journal. On an interval defined by the `delay` parameter, Loom will
         * attempt to upload log data, time data, and a screenshot to the Loom Test Journal web service available at
         * http://loomtestjournal.parseapp.com.
         *
         * Note: If an upload is still pending while another upload is triggered, the new upload will be skipped. Uploads
         * will not be queued.
         * 
         * @param applicationID An application ID provided by The Engine Company that is used to upload and access your test data.
         * @param tag A tag that can be applied to the application that will be searchable on the Loom Test Journal web app.
         * @param delay (Optional) How often (in ms) the TestJournal will attempt to upload data. Default is 5000.
         */
        public static function init(applicationID:String, tagString:String = "", delay:Number = 5000):void
        {
            // If we are already initialized, don't initialize!
            if (state == TestJournalState.INITIALIZED)
            {
                trace("Test Journal Warning: Test Journal is already initialized! Ignoring initialization request");
                return;
            }
            
            // If the app ID is invalid, do nothing
            if (!applicationID || applicationID == "")
            {
                trace("Test Journal Error: Application ID must be provided in initialization");
                return;
            }
            
            appID = applicationID;
            
            // Create an object upload request
            objectUploadReq = createRequest("/newObject?appId=" + appID, "application/json", "POST");
            objectUploadReq.onSuccess += onObjectCreateSuccess;
            objectUploadReq.onFailure += onError;
            
            // Send the platform with the object creation request
            var sendObj:Dictionary.<String, Dictionary.<String, String>> = { "data": { "platform": getPlatformString() }};
            
            if (tagString != "")
                sendObj["data"]["tag"] = tagString;
            
            objectUploadReq.body = JSON.stringify(sendObj);
            
            // Send a request attempting to create the object
            objectUploadReq.send();
            
            // Add the onScreenshotData delegate
            Graphics.onScreenshotData += onScreenshotTaken;
            
            // Initialize log data
            logData = new Vector.<String>();
            
            // Set up the delay timer
            timer = new Timer(delay);
            timer.onComplete += onTimerComplete;
            timer.repeats = true;
            
            Application.ticks += onTick;
            frameCountStartTime = Platform.getTime();
            
            state = TestJournalState.INITIALIZED;
            trace("Test Journal Initialized");
        }
        
        /**
         * This function will trace the provided objects, as well as store the log data for upload to the Test Journal
         * 
         * Note: If this function is called before TestJournal.init, the provided objects will be traced, but they will not be stored.
         * 
         * @param ...args The data to be traced
         */
        public static function log(...args):void
        {
            if (!logData)
            {
                // If the TestJournal has not been initialized, just trace, don't store
                trace(args);
                return;
            }
            
            // Add the logs to the log data array
            var logStr:String = "";
            for (var i:int = 0; i < args.length; i++)
            {
                logStr += args[i].toString();
                
                if (i < args.length - 1)
                    logStr += " ";
            }
            
            logData.push({ "time": Platform.getTime().toString(), "log":logStr });
            
            // Trace the log
            trace(args);
        }
        
        /**
         * This function can be used to manually take a screenshot at key moments in your app. A screenshot will be taken
         * at the end of the current frame, and only one screenshot will be taken per frame.
         * 
         * Unlike screenshots taken automatically, screenshots taken with this function will stack, meaning mutliple requests can
         * be active at the same time.
         * 
         * This function will also restart the automatic screenshot delay.
         */
        public static function takeScreen():void
        {
            if (state == TestJournalState.UNINITIALIZED)
            {
                trace("Test Journal Warning: Ignoring screenshot request, TestJournal must be initialized first!");
                return;
            }
            else if (state == TestJournalState.ERRORED)
            {
                trace("Test Journal Warning: Ignoring screenshot request, TestJournal not active due to an error");
                return;
            }
            
            if (!objectId)
            {
                trace("Test Journal Warning: Ignoring screenshot request, TestJournal has been initialized, but initial object creation request has not yet completed");
                return;
            }
            
            // Queue a screenshot, stacking the request if need be
            takeScreenShot(true);
            
            // Reset the timer
            timer.start();
        }
        
        /**
         * If the TestJournal has been initialized and is active
         */
        public static function get initialized():Boolean
        {
            return (state == TestJournalState.INITIALIZED ? true : false);
        }
        
        private static function onTick():void
        {
            // Increment the frame count
            frameCount++;
        }
        
        private static function onObjectCreateSuccess(e:ByteArray):void
        {
            // If we got an error previously, stop the error timer!
            if (httpRetryTimer)
            {
                httpRetryTimer.stop;
                httpRetryTimer = null;
            }
            
            var json:JSON = JSON.parse(e.readUTFBytes(e.length));
            objectId = json.getString("id");
            
            objectUploadReq = null; // This request is no longer needed
            
            // Create an initial screenshot
            takeScreenShot();
            
            // Start the timer
            timer.start();
        }
        
        private static function onTimerComplete(e:Timer):void
        {
            // Take a new screenshot
            takeScreenShot();
        }
        
        private static function onScreenshotTaken(s:ByteArray):void
        {
            // Do nothing if there is no update data
            if (!updateData)
            {
                trace("Test Journal Warning: Skipping screenshot upload. Screenshot taken, but no update data available.");
                return;
            }
            
            // Instantiate a new request
            activeRequests.push(new TestJournal(s, updateData));
            
            // Null the update data
            updateData = null;
        }
        
        private static function onError(e:ByteArray):void
        {   
            // If there is no object ID, then we encountered an error trying to GET that id, this is a special case
            if (!httpRetryTimer)
            {
                httpRetryTimer = new Timer(CREATE_OBJ_RETRY_TIME);
                httpRetryTimer.repeats = true;
                httpRetryTimer.onComplete += onRetryTimerComplete;
                httpRetryTimer.start();
            }
            
            state = TestJournalState.ERRORED;
            
            timer.stop();
            
            trace("Test Journal Error: Error Creating new Object. Retrying in " + (CREATE_OBJ_RETRY_TIME / 1000) + " seconds", e.readUTFBytes(e.length));
        }
        
        private static function onRetryTimerComplete(e:Timer)
        {
            // Re-initialize
            init(appID, tag, timer.delay);
        }
        
        private static function takeScreenShot(stackRequests:Boolean = false):void
        {
            // If we are not stacking requests, and there are still request pending, don't do anything!
            if (!stackRequests && activeRequests.length != 0)
            {
                trace("Test Journal Warning: Skipping new screen request. " + activeRequests.length + " Request" + (activeRequests.length > 0 ? "s" : "") + " already pending, ");
            }
            
            // Trigger a screenshot
            Graphics.screenshotData();
            
            // Save the average framerate
            var frameUploadData:Number = Math.round(frameCount / ((Platform.getTime() - frameCountStartTime) / 1000));
            frameCountStartTime = Platform.getTime();
            frameCount = 0;
            
            updateData = new UpdateData(logData, Platform.getTime(), frameUploadData);
            
            // Clear the log data
            logData.clear();
        }
        
        private static function uploadFree():Boolean
        {
            // Don't send a request if the object hasn't been created yet
            if (objectId == "") return false;
            
            // Don't send more than one request at a time so we don't clog a user's network
            if (activeRequests.length != 0) return false;
            
            return true;
        }
        
        private static function createRequest(endpoint:String, type:String, method:String):HTTPRequest
        {
            var newRequest:HTTPRequest = new HTTPRequest(TJ_URI + endpoint, type);
            newRequest.method = method;
            
            return newRequest;
        }
        
        private static function getPlatformString():String
        {
            var plat:PlatformType = Platform.getPlatform();
            
            switch (plat)
            {
                case PlatformType.ANDROID:
                    return "ANDROID";
                case PlatformType.IOS:
                    return "IOS";
                case PlatformType.LINUX:
                    return "LINUX";
                case PlatformType.OSX:
                    return "OSX";
                case PlatformType.WINDOWS:
                    return "WINDOWS";
                default:
                    return "UNKNOWN";
            }
            
            return "UNKNOWN"; // This line will never be hit, but must exist to keep the compiler happy
        }
        
        /*
         * ------------------
         *      INSTANCE
         * ------------------
         */
        // HTTP Requests
        private var updateRequest:HTTPRequest;
        
        /**
         * @private
         * 
         * All of the outward facing functionality is static, but internally instances of TestJournal are created to
         * handle HTTP requests to the server. Instances of TestJournal should never be created externally
         * 
         * @param screenData The raw screenshot data to be uplaoded to the TestJournal
         * @param data The misc upload data that will be associated with the screenshot
         */
        private function TestJournal(screenData:ByteArray, data:UpdateData)
        {
            // Create the request
            updateRequest = TestJournal.createRequest("/update?sessionId=" + objectId, "application/octet-stream", "POST");
            updateRequest.onSuccess += onUpdateRequestSuccess;
            updateRequest.onFailure += onLocalFailure;
            
            // Add the data and send the screenshot request!
            updateRequest.bodyBytes = screenData;
            updateRequest.setHeaderField("log_data", JSON.stringify(data.log));
            updateRequest.setHeaderField("time_data", data.time.toString());
            updateRequest.setHeaderField("fps_data", data.fps.toString());
            updateRequest.send();
        }
        
        private function onUpdateRequestSuccess(e:ByteArray):void
        {
            // The update was successful! Clean ourselves up
            end();
        }
        
        private function onLocalFailure(e:ByteArray):void
        {
            trace("Test Journal Warning: Skipping next request. HTTP Error encountered", e.readUTFBytes(e.length));
            
            end();
        }
        
        private function end():void
        {
            // Clean ourself up
            TestJournal.activeRequests.remove(this);
        }
        
        /**
         * Will cancel any actively running requests and remove the object's reference in memory
         */
        public function cancel():void
        {
            // Cancel active requests and shuts down
            updateRequest.cancel();
            end();
        }
    }
    
    /**
     * Class holds data that will be sent to the TestJournal API
     */
    private class UpdateData
    {
        public var log:Vector.<String> = new Vector.<String>;
        public var time:Number;
        public var fps:Number;
        
        public function UpdateData(l:Vector.<String>, t:Number, f:Number)
        {
            log = l.slice();
            time = t;
            fps = f;
        }
    }
    
    /**
     * The possible Test Journal states. Used to ensure functions are not called out of order, and to
     * give user friendly error logs.
     */
    private enum TestJournalState
    {
        UNINITIALIZED,
        INITIALIZED,
        ERRORED
    }
}
