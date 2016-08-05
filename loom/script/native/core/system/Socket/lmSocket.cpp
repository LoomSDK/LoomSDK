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

#include "loom/script/loomscript.h"
#include "loom/script/runtime/lsRuntime.h"

class LoomSocket {
public:

    static int send(lua_State *L)
    {
        // get our socket object
        lua_getfield(L, 1, "__socket");
        lua_getfield(L, -1, "send");
        lua_pushvalue(L, -2);
        lua_pushvalue(L, 2);
        lua_call(L, 2, 1);

        // Pop debug results if any
        #ifdef LUASOCKET_DEBUG
        lua_pop(L, 1);
        #endif

        // Results of an OK send are: nil, nil, index of last byte sent
        // Results of a failed send are: index of last byte sent, error message, nil

        // Handle errors
        if (lua_isnil(L, -3))
        {
            lua_pushvalue(L, -2);
            lua_setfield(L, 1, "__socket_error");
            lua_pop(L, 1);
        }

        // Clean up the results of "send"
        lua_pop(L, 3);

        return 0;
    }

    /*
     * Closes the socket instance
     */
    static int close(lua_State *L)
    {
        // get our socket object
        lua_getfield(L, 1, "__socket");
        lua_getfield(L, -1, "close");
        lua_pushvalue(L, -2);
        lua_call(L, 1, 1);

        return 0;
    }

    static int clearError(lua_State *L)
    {
        lua_pushstring(L, "");
        lua_setfield(L, 1, "__socket_error");
        return 0;
    }

    static int getError(lua_State *L)
    {
        lua_getfield(L, 1, "__socket_error");
        if (lua_isnil(L, -1))
        {
            lua_pushstring(L, "");
        }

        // clear the error if requested
        if (lua_isboolean(L, 2) && lua_toboolean(L, 2))
        {
            lua_pushstring(L, "");
            lua_setfield(L, 1, "__socket_error");
        }

        return 1;
    }

    static int receive(lua_State *L)
    {
        // get our socket object
        lua_getfield(L, 1, "__socket");
        lua_getfield(L, -1, "receive");
        lua_pushvalue(L, -2);
        lua_call(L, 1, 2);

        if (lua_isnil(L, -2))
        {
            lua_pushvalue(L, -1);
            lua_setfield(L, 1, "__socket_error");
            lua_pop(L, 1); // pop string error and return nil
        }
        else
        {
            lua_pushvalue(L, -2);
        }

        return 1;
    }

    static int setTimeout(lua_State *L)
    {
        // get our socket object
        lua_getfield(L, 1, "__socket");
        lua_getfield(L, -1, "settimeout");
        lua_pushvalue(L, -2);
        if (lua_isnil(L, 2))
        {
            lua_pushnil(L);
        }
        else
        {
            lua_pushnumber(L, lua_tonumber(L, 2) / 1000.0);
        }
        lua_call(L, 2, 1);
        return 1;
    }

    static int accept(lua_State *L)
    {
        // get our socket object
        lua_getfield(L, 1, "__socket");
        lua_getfield(L, -1, "accept");
        lua_insert(L, -2);
        lua_call(L, 1, 1);

        int sockIdx = lua_gettop(L);

        if (lua_isnil(L, sockIdx))
        {
            lua_pushvalue(L, -2);
            lua_setfield(L, 1, "__socket_error");
            lua_pop(L, 1);
        }

        Type *socketType = LSLuaState::getLuaState(L)->getType("system.socket.Socket");
        lsr_createinstance(L, socketType);

        lua_pushstring(L, "__socket");
        lua_pushvalue(L, sockIdx);
        lua_rawset(L, -3);

        return 1;
    }

    // client
    static int connect(lua_State *L)
    {
        //local sock, err = socket.tcp()
        lua_getglobal(L, "socket");
        lua_getfield(L, -1, "tcp");

        int top = lua_gettop(L);
        lua_call(L, 0, 1);
        int sockIdx = lua_gettop(L);

        int nret = sockIdx - top;

        if (nret == 2)
        {
            lua_pushvalue(L, -1);
            lua_setfield(L, 1, "__socket_error");
            lua_pop(L, 1);

            lua_pushnil(L);
            return 1;
        }

        //local res, err = sock:connect(host, port)
        lua_getfield(L, sockIdx, "connect");
        lua_pushvalue(L, sockIdx);
        lua_pushvalue(L, 1); // host
        lua_pushvalue(L, 2); // port
        top = lua_gettop(L);
        lua_call(L, 3, 1);
        int resIdx = lua_gettop(L);

        nret = resIdx - top;

        if (nret == 2)
        {
            lua_pushvalue(L, -1);
            lua_setfield(L, 1, "__socket_error");
            lua_pop(L, 1);

            lua_pushnil(L);
            return 1;
        }

        Type *socketType = LSLuaState::getLuaState(L)->getType("system.socket.Socket");
        lsr_createinstance(L, socketType);

        // stash our luasocket
        lua_pushstring(L, "__socket");
        lua_pushvalue(L, sockIdx);
        lua_rawset(L, -3);

        return 1;
    }

    // server
    static int bind(lua_State *L)
    {
        //local sock, err = socket.tcp()
        lua_getglobal(L, "socket");
        lua_getfield(L, -1, "tcp");

        int top = lua_gettop(L);
        lua_call(L, 0, 1);
        int sockIdx = lua_gettop(L);

        int nret = sockIdx - top;

        if (nret == 2)
        {
            lua_pushvalue(L, -1);
            lua_setfield(L, 1, "__socket_error");
            lua_pop(L, 1); // pop string error and return nil

            lua_pushnil(L);
            return 1;
        }

        //sock:setoption("reuseaddr", true)
        lua_getfield(L, sockIdx, "setoption");
        lua_pushvalue(L, sockIdx);
        lua_pushstring(L, "reuseaddr");
        lua_pushboolean(L, 1);
        lua_call(L, 3, 1);

        //local res, err = sock:bind(host, port)
        lua_getfield(L, sockIdx, "bind");
        lua_pushvalue(L, sockIdx);
        lua_pushvalue(L, 1); // host
        lua_pushvalue(L, 2); // port
        top = lua_gettop(L);
        lua_call(L, 3, 1);

        int resIdx = lua_gettop(L);
        nret = resIdx - top;

        if (nret == 2)
        {
            lua_pushvalue(L, -1);
            lua_setfield(L, 1, "__socket_error");
            lua_pop(L, 1); // pop string error and return nil

            lua_pushnil(L);
            return 1;
        }

        //res, err = sock:listen(backlog)
        lua_getfield(L, sockIdx, "listen");
        lua_pushvalue(L, sockIdx);
        lua_pushvalue(L, 3); // backlog
        top = lua_gettop(L);
        lua_call(L, 2, 1);

        resIdx = lua_gettop(L);
        nret = resIdx - top;

        if (nret == 2)
        {
            lua_pushvalue(L, -1);
            lua_setfield(L, 1, "__socket_error");
            lua_pop(L, 1); // pop string error and return nil

            lua_pushnil(L);
            return 1;
        }

        Type *socketType = LSLuaState::getLuaState(L)->getType("system.socket.Socket");
        lsr_createinstance(L, socketType);

        // stash our luasocket
        lua_pushstring(L, "__socket");
        lua_pushvalue(L, sockIdx);
        lua_rawset(L, -3);

        return 1;
    }
};

static int registerSystemSocket(lua_State *L)
{
    beginPackage(L, "system.socket")

       .beginClass<LoomSocket> ("Socket")

       .addConstructor<void (*)(void)>()
       .addStaticLuaFunction("bind", &LoomSocket::bind)
       .addStaticLuaFunction("accept", &LoomSocket::accept)
       .addStaticLuaFunction("connect", &LoomSocket::connect)
       .addStaticLuaFunction("send", &LoomSocket::send)
       .addStaticLuaFunction("receive", &LoomSocket::receive)
       .addStaticLuaFunction("setTimeout", &LoomSocket::setTimeout)
       .addStaticLuaFunction("getError", &LoomSocket::getError)
       .addStaticLuaFunction("clearError", &LoomSocket::clearError)
       .addStaticLuaFunction("close", &LoomSocket::close)
       .endClass()

       .endPackage();

    return 0;
}


void installSystemSocket()
{
    NativeInterface::registerNativeType<LoomSocket>(registerSystemSocket);
}
