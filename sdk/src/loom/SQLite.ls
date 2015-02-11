/*
===========================================================================
Loom SDK
Copyright 2011, 2012, 2013 , 2014, 2015
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



///TODO:
//  -emulate the 'Example usage' functionality -> slowly bring all functions over to native bindings!
//  -remainder synchronous functionality
//  -asynchronous functionality
//  -full function/var/const header commenting



package loom.sqlite
{
    //SQLite Delegate definitions
    public delegate ImportComplete():void;
    public delegate StatementProgress():void;
    public delegate StatementComplete(results:Statement):void;




    /** 
     * An open session to a database file.
     *
     * Example usage:
     *      var c = Connection.open("my.db");
     *      var stmt = c.prepare("SELECT * FROM hotel_rates WHERE cityId=? AND rateDate >= ? AND rateDate <= ?");
     *      stmt.bindInt(1, 1); stmt.bindInt(2, 2304); stmt.bindInt(3, 2311);
     *      while(stmt.step() == Statement.ROW) trace("Saw rate of " + stmt.columnNumber(1));
     *      stmt.finalize();
     *      c.close();
     */
    public native class Connection
    {
        //Error Codes
        public static const ERROR_NONE:int   = 0;

        //Connection Flags
        public static const FLAG_READONLY:int   = 1;
        public static const FLAG_READWRITE:int  = 2;
        public static const FLAG_CREATE:int     = 4;
 

       /**
         * Background import interface. Load passed bytes in a background thread,
         * and fire onImportComplete when done.
         */
//TODO: Async support
        // public static native function backgroundImport(database:String, data:ByteArray):void;
        // public static native var onImportComplete:ImportComplete;

        /**
         * What version of SQLite are we accessing?
         */
        public static native function get version():String;

        /**
         * Most recent error code from SQLite (not threadsafe).
         */
        public native function get errorCode():int;
 
        /**
         * Most recent error message from SQLite (not threadsafe).
         */
        public native function get errorMessage():String;

        /**
         * Open a SQLite database.
         */
        public static native function open(database:String, flags:int = FLAG_READWRITE):Connection;
 
        /**
         * Prepare an SQL statement(s) for processing.
         */
        public native function prepare(query:String):Statement;
  
        /**
         * Close this database connection.
         */
        public native function close():void;
    }



    /**
     * A compiled SQL statement. Parameters can be manipulated
     * and result columns retrieved. step() advances the query
     * to the next row of results. Synchronous and asynchronous
     * query execution are supported.
     */
    public native class Statement
    {
        //SQLite Statement Constants
//TODO: These don't match 1:1 with sqlite ones...         
        public static const BUSY:int    = 0;
        public static const DONE:int    = 1;
        public static const ROW:int     = 2;
        public static const ERROR:int   = 3;
        public static const MISUSE:int  = 4;
 
 
        // Query parameters by name, index, etc.
//TODO
        public native function getParameterIndex(name:String):int;
        public native function getParameterName(index:int):String;
        public native function getParameterCount():int;
 
        // Interface to set query parameters.
//TODO
         public native function bindDouble(index:int, value:Number):void;
         public native function bindInt(index:int, value:int):void;
   //      public native function bindBytes(index:int, value:ByteArray):void;
         public native function bindString(index:int, value:String):void;
 
        // Advance to next result.
//TODO
         public native function step():int;

        // Asynchronously advance to next result.
//TODO: Async support
//         public native function stepAsync():void;
//         public native var onStatementProgress:StatementProgress;
//         public native var onStatementComplete:StatementComplete;
 
        // Retrieve result column from current row.
//TODO
         public native function columnDouble(index:int):Number;
         public native function columnInt(index:int):int;
 //        public native function columnBytes(index:int):ByteArray;
         public native function columnString(index:int):String;
 
        // Get row id from last insert.
//TODO
  //       public native function get lastInsertRowId():int;
 
        // Reset the statement.
//TODO
         public native function reset();
 
        // Clean up this statement.
//TODO
         public native function finalize();
    }    
}