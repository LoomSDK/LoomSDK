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


package loom.sqlite
{
    /**
     * Loom SQLite API.
     *
     * Loom provides animplementation of SQLite that can be
     * used for database management across all supported platforms.
     *
     */

    /**
     * Delegate used to handle when a Connection.backgroundImport has completed.
     *  @param result Result of the import process.
     */
    public delegate ImportComplete(result:ResultCode):void;

    /**
     * Delegate used to handle when a Statement.stepAsync has progressed.
     */
    public delegate StatementProgress():void;

    /**
     * Delegate used to handle when a Statement.stepAsync has completed.
     *  @param result Result of the step. Common values of this are:
                           ResultCode.SQLITE_ROW indicates that there is valid data.
                           ResultCode.SQLITE_DONE indicates that the end of the statement has been reached.
                           ResultCode.SQLITE_MISUSE indicates invalid data in the query.
     */
    public delegate StatementComplete(result:ResultCode):void;



    /** 
     * The various relavent SQLITE return codes for Connection and Statement usage.
     */
    public enum ResultCode
    {
        /** 
         * Everything is OK.
         */
        SQLITE_OK           = 0,

        /** 
         * There is an ERROR that should be handled.  More information may be 
         * available with a call to Connection.errorMessage.
         */
        SQLITE_ERROR        = 1,

        /** 
         * The database is currently BUSY handling another process, 
         * due to a conflict with a different connection.
         */
        SQLITE_BUSY         = 5,

        /** 
         * The database is currently LOCKED handling another process, 
         * due to a conflict with the current connection.
         */
        SQLITE_LOCKED       = 6,

        /** 
         * The previous database operation was aborted through an INTERRUPT request. 
         */
        SQLITE_INTERRUPT    = 9,

        /** 
         * The current action is a MISUSE of of the SQLite interface.
         */
        SQLITE_MISUSE       = 21,

        /** 
         * A supplied parameter is out of RANGE.
         */
        SQLITE_RANGE        = 25,

        /** 
         * Returned by Statement.step() to indicate that another ROW of output.
         * is available.
         */
        SQLITE_ROW          = 100,

        /** 
         * The operation is now DONE. Mostly commonly seen returned by Statement.step().
         */
        SQLITE_DONE         = 101
    }

    /** 
     * The possible column data types returned by Statement.columnType() function.
     */
    public enum DataType
    {
        /** 
         * 32 bit integer value.
         */
        SQLITE_INTEGER  = 1,

        /** 
         * 32 bit floating point value.
         */
        SQLITE_FLOAT    = 2,

        /** 
         * NULL terminated string value.
         */
        SQLITE_TEXT     = 3,

        /** 
         * Arbitraty byte array value.
         */
        SQLITE_BLOB     = 4,

        /** 
         * Single NULL value.
         */
        SQLITE_NULL     = 5
    }



    /** 
     * An open session to an SQLite database file.
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
        /** 
         * Connection.open() flag to indicate that the databse should be accessed as READONLY.
         */
        public static const FLAG_READONLY:int   = 1;

        /** 
         * Connection.open() flag to indicate that the databse should be accessed as as READ AND WRITE.
         */
        public static const FLAG_READWRITE:int  = 2;

        /** 
         * Connection.open() flag to indicate that the databse should be CREATED as a new one.
         */
        public static const FLAG_CREATE:int     = 4;
 

        /**
         * Called when the backgroundImport() completes.
         */
        public static native var onImportComplete:ImportComplete;


        /**
         * Background import interface for an SQLite database. This loads the passed bytes into 
         * the given database in a background thread, and fires onImportComplete when done.
         *
         *  NOTE: The database name must either be located at a to be a valid system 
         *  writeable path that begins with Path.getWritablePath(), or merely a plain 
         *  filename in which case it will internally be saved to the system writeable 
         *  path location.
         *
         *  The expected format of the JSON data String is:
         *      { "tableA": [ {"columnA": value, "columnB": value, ...}, 
                                 {"columnA": value, "columnB": value, ...}], 
                  "tableB": [ {"columnA": value, "columnB": value, ...}, 
                                 {"columnA": value, "columnB": value, ...}], 
                  ...}
         *  Where "table*", etc. is the name of the table to insert into, 
         *  "column*" is the column to insert "value" into
         *
         *  @param database Name of the databse to import the data into.
         *  @param data JSON formatted data String to import into the database.
         *  @return Boolean Whether or not the background import process was successfully kicked off.
         */
//TODO: Change over to ByteArray or similar eventually
        public static native function backgroundImport(database:String, data:String):Boolean;

        /**
         * Checks the version of SQLite
         * 
         *  @return String The current version of SQLite running.
         */
        public static native function get version():String;

        /**
         * Return the most recent error code from SQLite (not threadsafe).  Value will most likely
         * be one of those defined in ResultCode (ie. can be checked against ResultCode.SQLITE_OK), 
         * but potentially could differ and be any internal SQLITE code.
         * 
         *  @return int Value of the error code.
         */
        public native function get errorCode():int;
 
        /**
         * Returns the most recent error message from SQLite (not threadsafe).
         * 
         *  @return String Text message associated with the last error code.
         */
        public native function get errorMessage():String;

        /**
         * Returns the returns the rowid of the most recent successful INSERT into a table 
         * of this database connection.
         *
         * NOTE: As Loomscript only supports 32 bit integers, this function will not return
         * the expected value if there are more than 2^31 rows in the database.
         * 
         *  @return int ID of the last row successfully inserted into.
         */
        public native function get lastInsertRowId():int;
         
        /**
         * Opens the indicated SQLite database for operations.
         *
         *  NOTE: The database name must either be located at a to be a valid system 
         *  writeable path that begins with Path.getWritablePath(), or merely a plain 
         *  filename in which case it will internally be saved to the system writeable 
         *  path location.
         *
         *  @param database Name of the databse to import the data into.
         *  @param flags Flags describing how to open the database.
         *  @return Connection A newly opened Connection to the provide database.
         */
        public static native function open(database:String, flags:int = FLAG_READWRITE):Connection;
 
        /**
         * Prepares an SQL statement for processing.
         *
         *  @param query Query string to create the compiled Statement with.
         *  @return Statement The compiled Statement for processing.
         */
        public native function prepare(query:String):Statement;
  
        /**
         * Closes this database connection.
         *  @return ResultCode Result of the function call.
         */
        public native function close():ResultCode;
    }


    /**
     * A compiled SQL statement. Parameters can be manipulated and result columns retrieved. 
     * step() advances the query to the next row of results. Synchronous and asynchronous
     * query execution are supported.
     */
    public native class Statement
    {
        /**
         * Number of Virtual Machine Instructions to wait for between 
         * between each call to onStatementProgress. Setting this to < 1 
         * will disable the progress handler. The default value is 1.
         */
        public static native var statementProgressVMIWait:int;

        /**
         * Called at intervals during the stepAsync() query processing.
         */
        public native var onStatementProgress:StatementProgress;

        /**
         * Called when stepAsync() completes the query processing.
         */
        public native var onStatementComplete:StatementComplete;


        /**
         * Returns the number of parameters in the current query.
         *  @return int Parameter count.
         */
        public native function getParameterCount():int;

        /**
         * Returns the name of the specified parameter in the current query.
         *  @param index Index of the parameter to search for. 
         *               The left-most (first) paramater is index 1.
         *  @return String Parameter name.
         */
        public native function getParameterName(index:int):String;

        /**
         * Returns the index of the specified parameter in the current query.
         *  @param name Name of the parameter to search for.
         *  @return int Parameter index.
         */
        public native function getParameterIndex(name:String):int;
 
        /**
         * Sets an integeter query parameter for the given index.
         *  @param index Index of the parameter to bind the value to. 
         *               The left-most (first) paramater is index 1.
         *  @param value Integer value to set
         *  @return ResultCode Result of the bind.
         */
        public native function bindInt(index:int, value:int):ResultCode;

        /**
         * Sets a floating point query parameter for the given index.
         *  @param index Index of the parameter to bind the value to. 
         *               The left-most (first) paramater is index 1.
         *  @param value Floating point value to set
         *  @return ResultCode Result of the bind.
         */
        public native function bindDouble(index:int, value:Number):ResultCode;

        /**
         * Sets a string query parameter for the given index.
         *  @param index Index of the parameter to bind the value to. 
         *               The left-most (first) paramater is index 1.
         *  @param value String value to set
         *  @return ResultCode Result of the bind.
         */
        public native function bindString(index:int, value:String):ResultCode;

        /**
         * Sets a ByteArray query parameter for the given index.
         *  @param index Index of the parameter to bind the value to. 
         *               The left-most (first) paramater is index 1.
         *  @param value ByteArray value to set
         *  @return ResultCode Result of the bind.
         */
        public native function bindBytes(index:int, value:ByteArray):ResultCode;
 
        /**
         * Blocking function that advances the statement to the next result in the query.
         *  @return ResultCode Result of the step. Common values of this are:
                               ResultCode.SQLITE_ROW indicates that there is valid data.
                               ResultCode.SQLITE_DONE indicates that the end of the statement has been reached.
                               ResultCode.SQLITE_MISUSE indicates invalid data in the query.
         */
        public native function step():ResultCode;

        /**
         * Asynchronous function that advances the statement to the next result in the query.
         *  @return Boolean Whether or not the step process was successfully kicked off.
         */
        public native function stepAsync():Boolean;
 
        /**
         * Retrieves the name of the specified column in the current row of the query.
         *  @param index Index of the column to retrieve the name from.
         *               The left-most (first) paramater is index 0.
         *  @return String Name of the column.
         */
        public native function columnName(index:int):String;

        /**
         * Retrieves the type of data that specified column is used to storein the 
         * current row of the query.
         *  @param index Index of the column to retrieve the type from.
         *               The left-most (first) paramater is index 0.
         *  @return DataType Enumation value defining the type of data for the column.
         */
        public native function columnType(index:int):DataType;

        /**
         * Retrieves an integer value from the specified column in the current row of the query.
         *  @param index Index of the column to retrieve the data from.
         *               The left-most (first) paramater is index 0.
         *  @return int Integer value stored in this column.
         */
        public native function columnInt(index:int):int;

        /**
         * Retrieves a floating point value from the specified column in the current row of the query.
         *  @param index Index of the column to retrieve the data from.
         *               The left-most (first) paramater is index 0.
         *  @return float Floating point value stored in this column.
         */
        public native function columnDouble(index:int):Number;

        /**
         * Retrieves a string from the specified column in the current row of the query.
         *  @param index Index of the column to retrieve the data from.
         *               The left-most (first) paramater is index 0.
         *  @return String String stored in this column.
         */
        public native function columnString(index:int):String;

        /**
         * Retrieves a byte array from the specified column in the current row of the query.
         *  @param index Index of the column to retrieve the data from.
         *               The left-most (first) paramater is index 0.
         *  @return ByteArray Byte array stored in this column.
         */
        public native function columnBytes(index:int):ByteArray;
 
        /**
         * Resets this statement back to its initial state so that it can be re-executed.
         *  @return ResultCode Result of the function call.
         */
        public native function reset():ResultCode;
 
        /**
         * Deletes and cleans up this statement.
         *  @return ResultCode Result of the function call.
         */
        public native function finalize():ResultCode;
    }    
}