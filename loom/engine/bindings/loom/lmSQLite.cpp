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


//SQLite Statement binding for Loomscript
class Statement
{
public:
    sqlite3_stmt *statementHandle = NULL;
};



//SQLite Connection binding for Loomscript
class Connection
{
protected:
    char szDBFullPath[1024];
    sqlite3 *dbHandle = NULL;

public:
    static Connection *open(const char *database, int flags);
    static const char *getVersion();

    int getErrorCode()
    {
        return sqlite3_errcode(dbHandle);
    }
  
    const char* getErrorMessage()
    {
        return sqlite3_errmsg(dbHandle);
    }

    Statement *prepare(const char *query)
    {
        Statement *s = new Statement();

        //prepare the database with the query provided
        int res = sqlite3_prepare_v2(dbHandle, query, -1, &s->statementHandle, NULL);
        if(res != SQLITE_OK)
        {
            lmLogError(gSQLiteGroup, "Error preparing the SQLite database: %s with message: %s", szDBFullPath, getErrorMessage());
        }
        return s;
    }
      
    void close()
    {
        //close the database
        int res = sqlite3_close_v2(dbHandle);
        if(res != SQLITE_OK)
        {
            lmLogError(gSQLiteGroup, "Error closing the SQLite database: %s with message: %s", szDBFullPath, getErrorMessage());
        }
    }
};


//static initializers for Connection
Connection *Connection::open(const char *database, int flags)
{
    Connection *c = new Connection();

    //prefix the system writable path in front of the database name
    sprintf(c->szDBFullPath, "%s%s", cocos2d::CCFileUtils::sharedFileUtils()->getWriteablePath().c_str(), database);
    
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
