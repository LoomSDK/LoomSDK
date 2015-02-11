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


/////////////////////
// THINGS TO DO:
/////////////////////
//
//  -asynchronous functionality
//  -full function/var/const header commenting
//
/////////////////////



package loom.sqlite
{
    //SQLite Delegate definitions
//TODO: Async support
    // public delegate ImportComplete():void;
    // public delegate StatementProgress():void;
    // public delegate StatementComplete(results:Statement):void;



    /** 
     * An enumeration that defines the various relavent SQLITE return codes for Connection and Statement usage.
     */
    public enum ResultCode
    {
        SQLITE_OK       = 0,
        SQLITE_ERROR    = 1,
        SQLITE_BUSY     = 5,
        SQLITE_MISUSE   = 21,
        SQLITE_RANGE    = 25,
        SQLITE_ROW      = 100,
        SQLITE_DONE     = 101
    }



    /** 
     * An enumeration that defines the possible column data types
     */
    public enum DataType
    {
        SQLITE_INTEGER  = 1,
        SQLITE_FLOAT    = 2,
        SQLITE_TEXT     = 3,
        SQLITE_BLOB     = 4,
        SQLITE_NULL     = 5
    }



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
         * Return the most recent error code from SQLite (not threadsafe).  
         * Value will most likely be one of those defined in ResultCode (ie. can be checked 
         * against ResultCode.SQLITE_OK), but potentially could differ and be any 
         */
        public native function get errorCode():int;
 
        /**
         * Returns the most recent error message from SQLite (not threadsafe).
         */
        public native function get errorMessage():String;

        /**
         * Returns the returns the rowid of the most recent successful INSERT into a table 
         * of this database connection
         */
        public native function get lastInsertRowId():int;
         
        /**
         * Opens a SQLite database.
         */
        public static native function open(database:String, flags:int = FLAG_READWRITE):Connection;
 
        /**
         * Prepares an SQL statement(s) for processing.
         */
        public native function prepare(query:String):Statement;
  
        /**
         * Closes this database connection.
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
        // Query parameters by name, index, etc.
        public native function getParameterCount():int;
        public native function getParameterName(index:int):String;
        public native function getParameterIndex(name:String):int;
 
        // Interface to set query parameters.
        public native function bindInt(index:int, value:int):ResultCode;
        public native function bindDouble(index:int, value:Number):ResultCode;
        public native function bindString(index:int, value:String):ResultCode;
        public native function bindBytes(index:int, value:ByteArray):ResultCode;
 
        // Advance to next result.
        public native function step():ResultCode;

        // Asynchronously advance to next result.
//TODO: Async support
//         public native function stepAsync():void;
//         public native var onStatementProgress:StatementProgress;
//         public native var onStatementComplete:StatementComplete;
 
        // Retrieve result column from current row.
        public native function columnType(index:int):DataType;
        public native function columnInt(index:int):int;
        public native function columnDouble(index:int):Number;
        public native function columnString(index:int):String;
        public native function columnBytes(index:int):ByteArray;
 
        // Reset the statement.
        public native function reset():ResultCode;
 
        // Clean up this statement.
        public native function finalize():ResultCode;
    }    
}