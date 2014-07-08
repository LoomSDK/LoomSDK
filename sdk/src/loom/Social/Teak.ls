package loom.social
{
    /**
     * Delegate used to register when the Teach Authorization Status changes
     *
     *  @param status Current authorization status of Teak
     */
    public delegate TeakAuthStatusDelegate(status:int):void;



    /**
     *  Teak is a Facebook Integration API and is currently supported on Android and iOS.  
     *  See https://teak.io/ for more information
     *
     *  In order to use Facebook support in Loom, you must set 
     *  'teak_app_secret' (unique Teak Secret) in your project's 
     *  loom.config file.  This value is availble to you as a Teak 
     *  Developer once you have created your App on 
     *  https://teak.io/
     */
    public native class Teak
    {

        /**
         * Possible Teak Authentication Status Values
         */

        /**
         * Teak has not been authorized yet
         */
        static public const StatusNotAuthorized:int = -1;
        
        /**
         * Authorization has not been determined yet
         */
        static public const StatusUndetermined:int = 0;

        /**
         * Authorization is for Read Only permissions
         */
        static public const StatusReadOnly:int = 1;

        /**
         * Teak has full authorization access and is ready
         */
        static public const StatusReady:int = 2;



        /**
         *  Called when the Teak Auth Status changes.
         */
        public static native var onAuthStatus:TeakAuthStatusDelegate;

        /**
         * Checks if Teak is active and ready for use
         *
         *  @return Whether or not the Teak API is currently active
         */
        public static native function isActive():Boolean;

        /**
         * Called in order to give the Facebook Access Token through to Teak to use.  
         * NOTE: This must be done before any other calls to Teak are made!!!
         *  @param String Facebook Access Token obtained via loom.social.Facebook.getAccessToken()
         */
        public static native function setAccessToken(fbAccessToken:String):void;

        /**
         * Get the current Teak Authorization Status string
         *  @return Current Authorization Status for Teak
         */
        public static native function getStatus():int;

        /**
         * Posts a new Achivement via Teak
         *  @param String representation of the Achievement to post
         *  @return True if successful, false if not
         */
        public static native function postAchievement(achievementId:String):Boolean;

        /**
         * Posts a new High Score via Teak
         *  @param High score value to post
         *  @return True if successful, false if not
         */
        public static native function postHighScore(score:Number):Boolean;

        /**
         * Posts a new Open Graph Action via Teak
         *  @param String representation of the Action to post
         *  @param String instance Id of the Teak object
         *  @return True if successful, false if not
         */
        public static native function postAction(actionId:String, objectInstanceId:String):Boolean;
    }
}
