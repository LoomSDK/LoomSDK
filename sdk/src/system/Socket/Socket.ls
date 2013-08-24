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

package system.socket {
    
    /**
     * A Simple %Socket interface in loomscript.
     */
    public native class Socket {
    
        /**
         *  Creates a new Socket for a newly created connection.
         *
         *  @return A Socket for a newly created connection.
         */
        public native function accept():Socket;

        /**
         *  Creates a Socket instance connected to the specified host and port.
         *
         *  @param host The host for the connection.
         *  @param port The port for the connection.
         *
         *  @return The Socket instance.
         */
        public static native function connect(host:String, port:Number):Socket;

        /**
         *  Closes a Socket instance.
         *
         */
        public native function close():void;


        /**
         *  Creates a Socket instance bound to the specified host and port.
         *
         *  @param host The host for the connection.
         *  @param port The port for the connection.
         *
         *  @return The Socket instance.
         */
        public static native function bind(host:String, port:Number, backlog:Number = 32):Socket;
        
        /**
         *  Recieves a message from an accepted Socket.
         *
         *  @return The recieved message string.
         */
        public native function receive():String;
        
        /**
         * Sends a message to an accepted Socket.
         *
         *  @param msg The message to send.
         */
        public native function send(msg:String);
        
        /**
         *  Retrieves an error (if any) that the socket returns.
         *
         *  @param clear Specifies whether to clear the message upon reading. Defaults to true.
         *
         *  @return The error string.
         */
        public native function getError(clear:Boolean = true):String;

        /**
         *  Clears the last Socket error.
         *
         *  @see getError
         */
        public native function clearError();
        
        /**
         *  Sets a timeout (in ms) for the socket to connect/send/recieve messages.
         *  
         *  @param milliseconds The timeout value in ms.
         */
        public native function setTimeout(milliseconds:Number);
        
    }
    
}