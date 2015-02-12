/*
 * ===========================================================================
 * Loom SDK
 * Copyright 2011, 2012, 2013
 * The Game Engine Company, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ===========================================================================
 */

#include "platform/CCFileUtils.h"
#include "loom/script/loomscript.h"
#include "loom/common/core/log.h"
#include "loom/script/native/lsNativeDelegate.h"
#include "loom/vendor/sqlite3/sqlite3.h"
#include "loom/common/utils/utByteArray.h"
#include "loom/common/utils/utString.h"

lmDefineLogGroup(gSQLiteGroup, "loom.sqlite", 1, LoomLogInfo);

using namespace LS;


//forward declaration of Statement
class Statement;


//SQLite Connection binding for Loomscript
class Connection
{
protected:
    utString databaseName;
    utString databaseFullPath;
    sqlite3 *dbHandle;

public:
    LOOM_STATICDELEGATE(OnImportComplete);

    static Connection *open(const char *database, const char *path, int flags);
    static void backgroundImport(const char *database, const char *path, utByteArray *data);
    static const char *getVersion();

    Statement *prepare(const char *query);
    const char* getDBName() { return databaseName.c_str(); }


    int getErrorCode()
    {
        return sqlite3_errcode(dbHandle);
    }
  
    const char* getErrorMessage()
    {
        return sqlite3_errmsg(dbHandle);
    }
      
    int getlastInsertRowId()
    {
        //"NOTE: In SQLite the row ID is a 64-bit integer but for all practical 
        //database sizes you can cast the 64 bit value to a 32-bit integer."
        //
        // - Some Guy on The Internet
        //
        sqlite3_int64 rowid64 = sqlite3_last_insert_rowid(dbHandle);

        //safety check on the value of the row as SQLite allows 64bit ints and Loomscript 
        //only supports 32bit (31 for signed)
        if(rowid64 > (2^31))
        {
            lmLogError(gSQLiteGroup, "RowID found in getlastInsertRowId the SQLite database %s is larger than a 32 bit integer! The return value will not be as expected!", getDBName());
        }
        return (int)rowid64;
    }

    int close()
    {
        //close the database
        int result = sqlite3_close_v2(dbHandle);
        if(result != SQLITE_OK)
        {
            lmLogError(gSQLiteGroup, "Error closing the SQLite database: %s with message: %s", getDBName(), getErrorMessage());
        }
        return result;
    }
};



//SQLite Statement binding for Loomscript
class Statement
{
private:
    Connection *parentDB;

public:
    LOOM_DELEGATE(OnStatementProgress);
    LOOM_DELEGATE(OnStatementComplete);

    sqlite3_stmt *statementHandle;


    Statement(Connection *c)
    {
        parentDB = c;
    }

    int getParameterCount()
    {
        return sqlite3_bind_parameter_count(statementHandle);
    }

    const char *getParameterName(int index)
    {
        const char *name = sqlite3_bind_parameter_name(statementHandle, index);
        if(name == NULL)
        {
            lmLogError(gSQLiteGroup, "Invalid index for getParameterName in database: %s", parentDB->getDBName());
        }
        return name;
    }

    int getParameterIndex(const char* name)
    {
        int index = sqlite3_bind_parameter_index(statementHandle, name);
        if(name == NULL)
        {
            lmLogError(gSQLiteGroup, "Invalid name for getParameterIndex in database: %s", parentDB->getDBName());
        }
        return index;
    }

    int bindInt(int index, int value)
    {
        int result = sqlite3_bind_int(statementHandle, index, value);
        if(result != SQLITE_OK)
        {
            lmLogError(gSQLiteGroup, "Error calling bindInt for database: %s with Result Code: %i", parentDB->getDBName(), result);
        }
        return result;        
    }

    int bindDouble(int index, double value)
    {
        int result = sqlite3_bind_double(statementHandle, index, value);
        if(result != SQLITE_OK)
        {
            lmLogError(gSQLiteGroup, "Error calling bindDouble for database: %s with Result Code: %i", parentDB->getDBName(), result);
        }
        return result;        
    }

    int bindString(int index, const char *value)
    {
        int result = sqlite3_bind_text(statementHandle, index, value, -1, SQLITE_TRANSIENT); 
        if(result != SQLITE_OK)
        {
            lmLogError(gSQLiteGroup, "Error calling bindString for database: %s with Result Code: %i", parentDB->getDBName(), result);
        }
        return result;        
    }

    int bindBytes(int index, utByteArray *value)
    {
        void *bytes;
        int size;

        if(!value || !value->getSize())
        {
            bytes = NULL;
            size = 0;
        }
        else
        {
            bytes = value->getDataPtr();      
            size = (int)value->getSize();
        }

        //bind the blob to the statement
        int result = sqlite3_bind_blob(statementHandle, index, (const void *)bytes, size, SQLITE_TRANSIENT); 
        if(result != SQLITE_OK)
        {
            lmLogError(gSQLiteGroup, "Error calling bindBytes for database: %s with Result Code: %i", parentDB->getDBName(), result);
        }
        return result;
    }

    int step()
    {
        int result = sqlite3_step(statementHandle); 
        if(result == SQLITE_ERROR)
        {
            lmLogError(gSQLiteGroup, "Error calling step for database: %s", parentDB->getDBName());
        }
        return result;
    }

    void stepAsync(lua_State *L)
    {
//TODO: create threaded step functionality
//TEMP: call normal blocking step() for now
        int result = step();

//TEMP: call the progress or complete delegates immmediately for testing
        if(result == SQLITE_ROW)
        {
            _OnStatementProgressDelegate.invoke();
        }
        else if(result == SQLITE_DONE)
        {
            lualoom_pushnative<Statement>(L, this);
            _OnStatementCompleteDelegate.incArgCount();
            _OnStatementCompleteDelegate.invoke();
            lua_pop(L, 1);
        }
        else
        {
//TODO: Should we have an additiona _OnStatementErrorDelegate to call here?
        }
    }

    const char *columnName(int col)
    {
        return sqlite3_column_name(statementHandle, col);
    }

    int columnType(int col)
    {
        return sqlite3_column_type(statementHandle, col);
    }

    int columnInt(int col)
    {
        return sqlite3_column_int(statementHandle, col);
    }

    double columnDouble(int col)
    {
        return sqlite3_column_double(statementHandle, col);
    }

    const char* columnString(int col)
    {
        return (const char *)sqlite3_column_text(statementHandle, col);
    }

    utByteArray *columnBytes(int col)
    {
        //get the blob from the column
        void *blob = (void *)sqlite3_column_blob(statementHandle, col);
        if(blob == NULL)
        {
            return NULL;
        }
        int size = sqlite3_column_bytes(statementHandle, col);

        //valid blob so allocate byte array for it
        utByteArray *bytes = new utByteArray();
        bytes->allocateAndCopy(blob, size);     

        return bytes;   
    }

    int reset()
    {
        int result = sqlite3_reset(statementHandle); 
        if(result != SQLITE_OK)
        {
            lmLogError(gSQLiteGroup, "Error calling reset for database: %s with Result Code: %i", parentDB->getDBName(), result);
        }
        return result;        
    }

    int finalize()
    {
        int result = sqlite3_finalize(statementHandle); 
        if(result != SQLITE_OK)
        {
            lmLogError(gSQLiteGroup, "Error calling finalize for database: %s with Result Code: %i", parentDB->getDBName(), result);
        }
        return result;        
    }
};



//**Connection** external function / variable initialisation
NativeDelegate Connection::_OnImportCompleteDelegate;

Statement *Connection::prepare(const char *query)
{
    Statement *s = new Statement(this);

    //prepare the database with the query provided
    int res = sqlite3_prepare_v2(dbHandle, query, -1, &s->statementHandle, NULL);
    if(res != SQLITE_OK)
    {
        lmLogError(gSQLiteGroup, "Error preparing the SQLite database: %s with message: %s", getDBName(), getErrorMessage());
    }
    return s;
}

Connection *Connection::open(const char *database, const char *path, int flags)
{
    Connection *c;

    //check for valid database name
    if((database == NULL) || (database[0] == '\0'))
    {
        lmLogError(gSQLiteGroup, "Invalid database name specified!");
        return NULL;
    }

    //create the connection
    c = new Connection();
    c->databaseName = utString(database);
    
    //prep the database path
    if((path == NULL) || (path[0] == '\0'))
    {
        //prefix the system writable path in front of the database name
        c->databaseFullPath = utString(cocos2d::CCFileUtils::sharedFileUtils()->getWriteablePath().c_str());
    }
    else
    {
        //assume that the user specified a valid system writeable path!!!
        c->databaseFullPath = utString(path);
    }
    c->databaseFullPath += c->databaseName;

    //open the SQLite DB
    int res = sqlite3_open_v2(c->databaseFullPath.c_str(), &c->dbHandle, flags, 0);
    if(res != SQLITE_OK)
    {
        lmLogError(gSQLiteGroup, "Error opening the SQLite database file: %s with message: %s", c->databaseFullPath.c_str(), c->getErrorMessage());
    }
    return c;
}

void Connection::backgroundImport(const char *database, const char *path, utByteArray *data)
{
//TODO: create threaded open and update of the given database

//TEMP: call the completion delegate immmediately for testing
    _OnImportCompleteDelegate.invoke();
}

const char* Connection::getVersion()
{
    return sqlite3_libversion();
}



//Loomscript binding registations for Connection and Statement
static int registerLoomSQLiteConnection(lua_State *L)
{
    beginPackage(L, "loom.sqlite")
      .beginClass<Connection>("Connection")

        .addStaticProperty("onImportComplete", &Connection::getOnImportCompleteDelegate)

        .addStaticMethod("open", &Connection::open)
        .addStaticMethod("backgroundImport", &Connection::backgroundImport)
        .addStaticMethod("__pget_version", &Connection::getVersion)

        .addMethod("__pget_errorCode", &Connection::getErrorCode)
        .addMethod("__pget_errorMessage", &Connection::getErrorMessage)
        .addMethod("__pget_lastInsertRowId", &Connection::getlastInsertRowId)
        .addMethod("prepare", &Connection::prepare)
        .addMethod("close", &Connection::close)

      .endClass()
    .endPackage();
    return 0;
}


static int registerLoomSQLiteStatement(lua_State *L)
{
    beginPackage(L, "loom.sqlite")
      .beginClass<Statement>("Statement")

        .addVarAccessor("onStatementProgress", &Statement::getOnStatementProgressDelegate)
        .addVarAccessor("onStatementComplete", &Statement::getOnStatementCompleteDelegate)

        .addMethod("getParameterCount", &Statement::getParameterCount)
        .addMethod("getParameterName", &Statement::getParameterName)
        .addMethod("getParameterIndex", &Statement::getParameterIndex)
        .addMethod("bindInt", &Statement::bindInt)
        .addMethod("bindDouble", &Statement::bindDouble)
        .addMethod("bindString", &Statement::bindString)
        .addMethod("bindBytes", &Statement::bindBytes)
        .addMethod("step", &Statement::step)
        .addMethod("stepAsync", &Statement::stepAsync)
        .addMethod("columnName", &Statement::columnName)
        .addMethod("columnType", &Statement::columnType)
        .addMethod("columnInt", &Statement::columnInt)
        .addMethod("columnDouble", &Statement::columnDouble)
        .addMethod("columnString", &Statement::columnString)
        .addMethod("columnBytes", &Statement::columnBytes)
        .addMethod("reset", &Statement::reset)
        .addMethod("finalize", &Statement::finalize)

      .endClass()
    .endPackage();
    return 0;
}


void installLoomSQLite()
{
    LOOM_DECLARE_NATIVETYPE(Connection, registerLoomSQLiteConnection);
    LOOM_DECLARE_NATIVETYPE(Statement, registerLoomSQLiteStatement);
}
