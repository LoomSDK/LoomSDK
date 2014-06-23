package loom.social
{
    /**
     * Delegate used to register when the Facebook Session Status changes
     *
     *  @param state State of the session
     *  @param permissions String detailing the current permissions of this session
     *  @param errorCode Error, if any
     */
    public delegate FacebookSessionStatusDelegate(state:FacebookSessionState, permissions:String, errorCode:FacebookErrorCode):void;

    /**
     * Delegate called when the Frictionless Request Dialog ends 
     *
     *  @param success true if the user completed the request, false if it was cancelled
     */
    public delegate FacebookFrictionlessRequstDelegate(success:Boolean):void;

    /**
     * Possible Facebook Session States
     */
    public enum FacebookSessionState
    {
        /**
         * Session has been created
         */
        Created = 0,

        /**
         * Session has been opened
         */
        Openen = 1,

        /**
         * Session has been closed
         */
        Closed = 2,
    };


    /**
     * Possible Facebook Error Codes
     */
    public enum FacebookErrorCode
    {
        /**
         * No error detected
         */
        NoError = 0,
        
        /**
         * User must Retry the Login Process
         */
        RetryLogin = 1,

        /**
         * User cancelled the Login Process
         */
        UserCancelled = 2,

        /**
         * Application does not have permission to access Facebook
         */
        ApplicationNotPermitted = 3,

        /**
         * Unknown error
         */
        Unknown = 4
    };


    /**
     *  Facebook is currently supported on Android and iOS.
     */
    public native class Facebook
    {
        /**
         *  Called when the Facebook Session state changes.
         */
        public static native var onSessionStatus:FacebookSessionStatusDelegate;

        /**
         *  Called when the Facebook Frictionless Request dialog completes.
         */
        public static native var onFrictionlessRequest:FacebookFrictionlessRequstDelegate;

        /**
         * Checks if Facebook is active and ready for use
         *
         *  @return Whether or not the Facebook API is currently active
         */
        public static native function isActive():Boolean;

        /**
         * Open a Facebook session with read permissions.
         *  @param permissions String defining the Facebook permissions (comma separated) you wish to read (ie. "email,user_friends")
         *  @return false if there is no Facebook Application Id defined, true otherwise.
         */
        public static native function openSessionWithReadPermissions(permissions:String):Boolean;

        /**
         * Open a Facebook session with read permissions.
         *  @param permissions String defining the Facebook permissions (comma separated) you wish to publish via (ie. "email,user_friends")
         *  @return false if the there is no Facebook Application Id defined, or session has not been opened yet, true otherwise.
         */
        public static native function requestNewPublishPermissions(permissions:String):Boolean;

        /**
         * Get the access token for the current Facebook user, or null.
         */
        public static native function getAccessToken():String;

        /**
        * Close our session and purge cached tokens and user data
        */
        public static native function closeAndClearTokenInformation():void;

        /**
         * Get the expiry time for our session with the provided date format
         *  @param dateFormat Formatting string used to format the expiration date with, or null to return it raw
         */
        public static native function getExpirationDate(dateFormat:String = null):String;
		
		/**
         * Show a frictionless app request dialog.
         *  @param recipients Recepients of the dialog
         *  @param title Title of the dialog
         *  @param message Message to display in the dialog
         */
        public static native function showFrictionlessRequestDialog(recipients:String, title:String, message:String):void;
		
		/**
         * Request whether the active session has a given permission.
         *  @param permission Permission name to check
         */
        public static native function isPermissionGranted(permission:String):Boolean;
    }
}
