package Loom
{
    /**
     *  Facebook is currently supported on Android and iOS.
     */
    public native class Facebook
    {
        /**
         *  Called when the Facebook Session state changes.
         */
        public static native var onSessionStatus:NativeDelegate;

        /**
         * Open a Facebook session with read permissions.
         *  @param permissions String defining the Facebook permissions you wish to read (ie. "email")
         *  @return false if there is no Facebook Application Id defined, true otherwise.
         */
        public static native function openSessionWithReadPermissions(permissions:String):Boolean;

        /**
         * Open a Facebook session with read permissions.
         *  @param permissions String defining the Facebook permissions you wish to publish via (ie. "email")
         *  @return false if the there is no Facebook Application Id defined, or session has not been opened yet, true otherwise.
         */
        public static native function requestNewPublishPermissions(permissions:String):Boolean;

        /**
         * Get the access token for the current Facebook user, or null.
         */
         public static native function getAccessToken():String;

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
        public static native function showFrictionlessRequestDialog(recipients:String, title:String, message:String):Boolean;
    }
}
