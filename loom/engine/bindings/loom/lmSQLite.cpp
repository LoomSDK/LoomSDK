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

lmDefineLogGroup(gSQLiteGroup, "loom.sqlite", 1, LoomLogInfo);

using namespace LS;


//forward declaration of Statement
class Statement;


//SQLite Connection binding for Loomscript
class Connection
{
protected:
    char szDBName[128];
    char szDBFullPath[1024];
    sqlite3 *dbHandle;

public:
    static Connection *open(const char *database, int flags);
    static const char *getVersion();

    Statement *prepare(const char *query);
    const char* getDBName() { return szDBName; }


    int getErrorCode()
    {
        return sqlite3_errcode(dbHandle);
    }
  
    const char* getErrorMessage()
    {
        return sqlite3_errmsg(dbHandle);
    }
      
    void close()
    {
        //close the database
        int res = sqlite3_close_v2(dbHandle);
        if(res != SQLITE_OK)
        {
            lmLogError(gSQLiteGroup, "Error closing the SQLite database: %s with message: %s", szDBName, getErrorMessage());
        }
    }
};



//SQLite Statement binding for Loomscript
class Statement
{
private:
    Connection *parentDB;

public:
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
            lmLogError(gSQLiteGroup, "Error calling bindInt for database: %s with message: %s", parentDB->getDBName(), parentDB->getErrorMessage());
        }
        return result;        
    }

    int bindDouble(int index, double value)
    {
        int result = sqlite3_bind_double(statementHandle, index, value);
        if(result != SQLITE_OK)
        {
            lmLogError(gSQLiteGroup, "Error calling bindDouble for database: %s with message: %s", parentDB->getDBName(), parentDB->getErrorMessage());
        }
        return result;        
    }

    int bindString(int index, const char *value)
    {
        int result = sqlite3_bind_text(statementHandle, index, value, sizeof(value), SQLITE_STATIC); 
        if(result != SQLITE_OK)
        {
            lmLogError(gSQLiteGroup, "Error calling bindString for database: %s with message: %s", parentDB->getDBName(), parentDB->getErrorMessage());
        }
        return result;        
    }

    // int bindBytes(int index, const sqlite3_value *value)
    // {
    //     int result = sqlite3_bind_value(statementHandle, index, value);
    //     if(result != SQLITE_OK)
    //     {
    //         lmLogError(gSQLiteGroup, "Error calling bindString for database: %s with message: %s", parentDB->getDBName(), parentDB->getErrorMessage());
    //     }
    //     return result;
    // }    

    int step()
    {
        int result = sqlite3_step(statementHandle); 
        if((result == SQLITE_ERROR) || (result == SQLITE_MISUSE))
        {
            lmLogError(gSQLiteGroup, "Error calling bindString for database: %s with message: %s", parentDB->getDBName(), parentDB->getErrorMessage());
        }
        return result;
    }

    double columnDouble(int col)
    {
        return sqlite3_column_double(statementHandle, col);
    }

    int columnInt(int col)
    {
        return sqlite3_column_int(statementHandle, col);
    }

    const char* columnString(int col)
    {
       // unsigned const char* string = (sqlite3_column_text(statementHandle, col)); //the weird memory error
        return "test";
    }

//    sqlite3_value* columnBytes(int col) //wasnt sure which SQLite method to use
//    {
//        return sqlite3_column_value(statementHandle, col);
//    }

    int reset()
    {
        int result = sqlite3_reset(statementHandle); 
        if(result != SQLITE_OK)
        {
            lmLogError(gSQLiteGroup, "Error calling reset for database: %s with message: %s", parentDB->getDBName(), parentDB->getErrorMessage());
        }
        return result;        
    }

    int finalize()
    {
        int result = sqlite3_finalize(statementHandle); 
        if(result != SQLITE_OK)
        {
            lmLogError(gSQLiteGroup, "Error calling finalize for database: %s with message: %s", parentDB->getDBName(), parentDB->getErrorMessage());
        }
        return result;        
    }

//   sqlite3_int64 getlastInsertRowId() //the weird memory error
//   {
//        sqlite3 *dbHandle;
//        return sqlite3_last_insert_rowid(dbHandle);
//    }

};




//**Connection** external function initialisation
Statement *Connection::prepare(const char *query)
{
    Statement *s = new Statement(this);

    //prepare the database with the query provided
    int res = sqlite3_prepare_v2(dbHandle, query, -1, &s->statementHandle, NULL);
    if(res != SQLITE_OK)
    {
        lmLogError(gSQLiteGroup, "Error preparing the SQLite database: %s with message: %s", szDBName, getErrorMessage());
    }
    return s;
}
Connection *Connection::open(const char *database, int flags)
{
    Connection *c = new Connection();

    //prefix the system writable path in front of the database name
    strcpy(c->szDBName, database);
    sprintf(c->szDBFullPath, "%s%s", cocos2d::CCFileUtils::sharedFileUtils()->getWriteablePath().c_str(), c->szDBName);
    
    //open the SQLite DB
    int res = sqlite3_open_v2(c->szDBFullPath, &c->dbHandle, flags, 0);
    if(res != SQLITE_OK)
    {
        lmLogError(gSQLiteGroup, "Error opening the SQLite database: %s with message: %s", c->szDBFullPath, c->getErrorMessage());
    }
    return c;
}
const char* Connection::getVersion()
{
    return sqlite3_libversion();
}






//Loomscript binding registations
static int registerLoomSQLiteStatement(lua_State *L)
{
    beginPackage(L, "loom.sqlite")
      .beginClass<Statement>("Statement")

//TODO: Add Statement methods
        .addMethod("getParameterCount", &Statement::getParameterCount)
        .addMethod("getParameterName", &Statement::getParameterName)
        .addMethod("getParameterIndex", &Statement::getParameterIndex)
        .addMethod("bindInt", &Statement::bindInt)
        .addMethod("bindDouble", &Statement::bindDouble)
        .addMethod("bindString", &Statement::bindString)
     //   .addMethod("bindBytes", &Statement::bindBytes)
        .addMethod("step", &Statement::step)
        .addMethod("columnInt", &Statement::columnInt)
        .addMethod("columnDouble", &Statement::columnDouble)
        .addMethod("columnString", &Statement::columnString)
    //    .addMethod("columnBytes", &Statement::columnBytes)
        .addMethod("reset", &Statement::reset)
        .addMethod("finalize", &Statement::finalize)
    //    .addMethod("getlastInsertRowId", &Statement::getlastInsertRowId)

//TODO: Add Async methods

      .endClass()
    .endPackage();
    return 0;
}

static int registerLoomSQLiteConnection(lua_State *L)
{
    beginPackage(L, "loom.sqlite")
      .beginClass<Connection>("Connection")

        .addStaticMethod("open", &Connection::open)
        .addStaticMethod("__pget_version", &Connection::getVersion)

        .addMethod("prepare", &Connection::prepare)
        .addMethod("close", &Connection::close)
        .addMethod("__pget_errorCode", &Connection::getErrorCode)
        .addMethod("__pget_errorMessage", &Connection::getErrorMessage)

//TODO: Add Async methods

      .endClass()
    .endPackage();
    return 0;
}

void installLoomSQLite()
{
    LOOM_DECLARE_NATIVETYPE(Statement, registerLoomSQLiteStatement);
    LOOM_DECLARE_NATIVETYPE(Connection, registerLoomSQLiteConnection);
}
