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

#include "zlib.h"

#include "loom/common/core/allocator.h"
#include "loom/common/core/assert.h"
#include "loom/common/core/log.h"
#include "loom/common/utils/utByteArray.h"
#include "loom/common/platform/platformIO.h"
#include "loom/script/runtime/lsRuntime.h"
#include "loom/script/runtime/lsLuaState.h"
#include "loom/script/runtime/lsTypeValidatorRT.h"
#include "loom/script/runtime/lsProfiler.h"
#include "loom/script/native/lsLuaBridge.h"
#include "loom/script/reflection/lsType.h"
#include "loom/script/reflection/lsFieldInfo.h"
#include "loom/script/reflection/lsPropertyInfo.h"
#include "loom/script/common/lsError.h"
#include "loom/script/common/lsFile.h"
#include "loom/script/serialize/lsBinReader.h"

extern "C" int luaopen_socket_core(lua_State *L);

namespace LS {
void lsr_classinitializestatic(lua_State *L, Type *type);

utHashTable<utPointerHashKey, LSLuaState *> LSLuaState::toLuaState;

utArray<utString> LSLuaState::commandLine;

double            LSLuaState::uniqueKey      = 1;
lua_State         *LSLuaState::lastState     = NULL;
LSLuaState        *LSLuaState::lastLSState   = NULL;
double            LSLuaState::constructorKey = 0;
utArray<utString> LSLuaState::buildCache;

lmDefineLogGroup(gLuaStateLogGroup, "LuaState", true, LoomLogInfo);

// traceback stack queries
struct stackinfo
{
    const char *source;
    int        linenumber;
    MethodBase *methodBase;
};

static utStack<stackinfo> _tracestack;
static char               _tracemessage[2048];

size_t LSLuaState::allocatedBytes = 0;

static void *lsLuaAlloc(void *ud, void *ptr, size_t osize, size_t nsize)
{
    (void)ud;  /* not used */
    
    LSLuaState::allocatedBytes += nsize - osize;

    if (nsize == 0) 
    {
        lmFree(NULL, ptr);
        return NULL;
    }
    else if (ptr == NULL)
    {
        return lmAlloc(NULL, nsize);
    }
    else
    {
        return lmRealloc(NULL, ptr, nsize);
    }
}

void LSLuaState::open()
{
    assert(!L);

    L = lua_newstate(lsLuaAlloc, this);
    //L = luaL_newstate();
    toLuaState.insert(L, this);

    luaopen_base(L);
    luaopen_table(L);
    luaopen_string(L);
    luaopen_math(L);
    luaL_openlibs(L);

#ifdef LUAJIT_MODE_MASK
    // TODO: turn this back on when it doesn't fail on the testWhile unit test
    // update luajit and test again
    luaJIT_setmode(L, 0, LUAJIT_MODE_ENGINE | LUAJIT_MODE_OFF);
#endif

    // Stop the GC initially
    lua_gc(L, LUA_GCSTOP, 0);

    // open the lua debug library
    luaopen_debug(L);

    // open socket library
    luaopen_socket_core(L);

    lua_newtable(L);
    lua_rawseti(L, LUA_GLOBALSINDEX, LSINDEXCLASSES);

    lua_newtable(L);
    lua_setglobal(L, "__ls_nativeclasses");

    lua_pushcfunction(L, traceback);
    lua_setglobal(L, "__ls_traceback");
    _tracemessage[0] = 0;

    // entry -> version
    lua_newtable(L);
    lua_rawseti(L, LUA_GLOBALSINDEX, LSINDEXMANAGEDVERSION);

    // entry -> native user data
    lua_newtable(L);
    lua_rawseti(L, LUA_GLOBALSINDEX, LSINDEXMANAGEDUSERDATA);

    // native user data -> script instance
    lua_newtable(L);
    lua_rawseti(L, LUA_GLOBALSINDEX, LSINDEXMANAGEDNATIVESCRIPT);

    // native delegate table
    lua_newtable(L);
    lua_rawseti(L, LUA_GLOBALSINDEX, LSINDEXNATIVEDELEGATES);

    // interned field name lookup
    lua_newtable(L);
    lua_rawseti(L, LUA_GLOBALSINDEX, LSINDEXMEMBERINFONAME);

    // typeid -> type*
    lua_newtable(L);
    lua_rawseti(L, LUA_GLOBALSINDEX, LSASSEMBLYLOOKUP);

    // lua/luacfunction -> MethodBase* lookups
    lua_newtable(L);

    // weak key metatable
    lua_newtable(L);
    lua_pushstring(L, "k");
    lua_setfield(L, -2, "__mode");
    lua_setmetatable(L, -2);

    lua_rawseti(L, LUA_GLOBALSINDEX, LSINDEXMETHODLOOKUP);

    lsr_instanceregister(L);

    NativeInterface::registerNativeTypes(L);
}


void LSLuaState::close()
{
    assert(L);

    if (lastState == L)
    {
        lastState   = NULL;
        lastLSState = NULL;
    }

    // ensure profiler is down
    LSProfiler::disable(L);

    for (UTsize i = 0; i < assemblies.size(); i++)
    {
        lmDelete(NULL, assemblies.at(i));
    }

    NativeInterface::shutdownLuaState(L);

    lua_close(L);

    toLuaState.remove(L);

    L = NULL;
}


Assembly *LSLuaState::loadTypeAssembly(const utString& assemblyString)
{
    beginAssemblyLoad();

    Assembly *assembly = Assembly::loadFromString(this, assemblyString);

    utArray<Type *> types;
    assembly->getTypes(types);
    cacheAssemblyTypes(assembly, types);

    endAssemblyLoad();

    return assembly;
}


void LSLuaState::declareLuaTypes(const utArray<Type *>& types)
{
    for (UTsize i = 0; i < types.size(); i++)
    {
        declareClass(types[i]);
    }

    // validate/initialize native types
    for (UTsize i = 0; i < types.size(); i++)
    {
        Type *type = types.at(i);

        if (type->isNative() || type->hasStaticNativeMember())
        {
            NativeTypeBase *ntb = NativeInterface::getNativeType(type);

            if (!ntb)
            {
                LSError("Unable to get NativeTypeBase for type %s", type->getFullName().c_str());
            }

            if (type->isNativeManaged() != ntb->isManaged())
            {
                if (type->isNativeManaged())
                {
                    LSError("Managed mismatch for type %s, script declaration specifies native while native bindings are unmanaged", type->getFullName().c_str());
                }
                else
                {
                    LSError("Managed mismatch for type %s, script declaration specifies unmanaged while native bindings are managed", type->getFullName().c_str());
                }
            }

            ntb->validate(type);
            type->setCTypeName(ntb->getCTypeName());
        }
    }
}


void LSLuaState::initializeLuaTypes(const utArray<Type *>& types)
{
    for (UTsize i = 0; i < types.size(); i++)
    {
        types[i]->cache();
    }

    // initialize all classes
    for (UTsize i = 0; i < types.size(); i++)
    {
        initializeClass(types[i]);
    }

    // run static initializers now that all classes have been initialized
    for (UTsize i = 0; i < types.size(); i++)
    {
        lsr_classinitializestatic(VM(), types[i]);
    }
}


void LSLuaState::cacheAssemblyTypes(Assembly *assembly, utArray<Type *>& types)
{
    // setup assembly type lookup field
    lua_rawgeti(L, LUA_GLOBALSINDEX, LSASSEMBLYLOOKUP);
    lua_pushlightuserdata(L, assembly);
    lua_setfield(L, -2, assembly->getName().c_str());
    lua_pop(L, 1);

    lmAssert(assembly->ordinalTypes == NULL, "Assembly types cache error, ordinalTypes already exists");

    assembly->ordinalTypes = lmNew(NULL) utArray<Type*>();
    assembly->ordinalTypes->resize(types.size() + 1);

    for (UTsize j = 0; j < types.size(); j++)
    {
        Type *type = types.at(j);

        assembly->types.insert(type->getName(), type);

        lmAssert(type->getTypeID() > 0 && type->getTypeID() <= (LSTYPEID)types.size(), "LSLuaState::cacheAssemblyTypes TypeID out of range");

        assembly->ordinalTypes->ptr()[type->getTypeID()] = type;

        const char *typeName = type->getFullName().c_str();

        // fast access cache
        if (!strcmp(typeName, "system.Object"))
        {
            objectType = type;
        }
        else if (!strcmp(typeName, "system.Null"))
        {
            nullType = type;
        }
        else if (!strcmp(typeName, "system.Boolean"))
        {
            booleanType = type;
        }
        else if (!strcmp(typeName, "system.Number"))
        {
            numberType = type;
        }
        else if (!strcmp(typeName, "system.String"))
        {
            stringType = type;
        }
        else if (!strcmp(typeName, "system.Function"))
        {
            functionType = type;
        }
        else if (!strcmp(typeName, "system.Vector"))
        {
            vectorType = type;
        }
        else if (!strcmp(typeName, "system.reflection.Type"))
        {
            reflectionType = type;
        }

        lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMEMBERINFONAME);
        lua_pushlightuserdata(L, type);
        lua_gettable(L, -2);

        // cache all members for fast lookup of memberinfo -> pre-interned
        // lua string (interning strings is the devil's work)
        if (lua_isnil(L, -1))
        {
            lua_pop(L, 1);

            utArray<MemberInfo *> members;
            MemberTypes           types;
            types.method   = true;
            types.field    = true;
            types.property = true;
            type->findMembers(types, members, false);

            // cache the type to member info table
            lua_pushlightuserdata(L, type);
            lua_pushstring(L, type->getName());
            lua_settable(L, -3);

            for (UTsize i = 0; i < members.size(); i++)
            {
                MemberInfo *mi = members.at(i);

                lua_pushlightuserdata(L, mi);
                lua_pushstring(L, mi->getName());
                lua_settable(L, -3);
            }
        }
        else
        {
            lua_pop(L, 1);
        }

        lua_pop(L, 1);

        // if we weren't cached during assembly load, cache now
        if (!typeCache.get(type->getFullName()))
        {
            typeCache.insert(type->getFullName(), type);
        }
    }

    lmAssert(nullType, "LSLuaState::cacheAssemblyTypes - system.Null not found");
    lmAssert(booleanType, "LSLuaState::cacheAssemblyTypes - system.Boolean not found");
    lmAssert(numberType, "LSLuaState::cacheAssemblyTypes - system.Number not found");
    lmAssert(stringType, "LSLuaState::cacheAssemblyTypes - system.String not found");
    lmAssert(functionType, "LSLuaState::cacheAssemblyTypes - system.Function not found");
    lmAssert(reflectionType, "LSLuaState::cacheAssemblyTypes - system.reflection.Type not found");
    lmAssert(vectorType, "LSLuaState::cacheAssemblyTypes - system.Vector not found");
}


void LSLuaState::finalizeAssemblyLoad(Assembly *assembly, utArray<Type *>& types)
{
    for (UTsize j = 0; j < types.size(); j++)
    {
        Type *type = types.at(j);

        if (type->isNative() || type->hasStaticNativeMember())
        {
            // we're native
            NativeInterface::resolveScriptType(type);
        }
    }

    declareLuaTypes(types);
    initializeLuaTypes(types);

    // we avoid runtime validation on mobile, this works but should be unnecessary
    // as issues with be caught on OSX/WINDOWS development platforms
#if LOOM_PLATFORM == LOOM_PLATFORM_OSX || LOOM_PLATFORM == LOOM_PLATFORM_WIN32
    for (UTsize j = 0; j < types.size(); j++)
    {
        Type            *type = types.at(j);
        TypeValidatorRT tv(this, type);
        tv.validate();
    }
#endif

    assembly->bootstrap();
}


Assembly *LSLuaState::loadAssemblyJSON(const utString& json)
{
    beginAssemblyLoad();

    Assembly *assembly = Assembly::loadFromString(this, json);

    utArray<Type *> types;
    assembly->getTypes(types);

    cacheAssemblyTypes(assembly, types);

    if (!isCompiling())
    {
        finalizeAssemblyLoad(assembly, types);
    }

    endAssemblyLoad();

    return assembly;
}


Assembly *LSLuaState::loadAssemblyBinary(utByteArray *bytes)
{
    Assembly *assembly = Assembly::loadBinary(this, bytes);

    return assembly;
}


Assembly *LSLuaState::loadExecutableAssembly(const utString& assemblyName, bool absPath)
{
    // executables always in bin
    utString filePath;

    if (!absPath)
    {
        filePath = "./bin/";
    }

    filePath += assemblyName;

    if (!strstr(filePath.c_str(), ".loom"))
    {
        filePath += ".loom";
    }

    const char *buffer   = NULL;
    long       bufferSize;
    LSMapFile(filePath.c_str(), (void **)&buffer, &bufferSize);

    lmAssert(buffer && bufferSize, "Error loading executable: %s, unable to map file", assemblyName.c_str());

    Assembly* assembly = loadExecutableAssemblyBinary(buffer, bufferSize);

	LSUnmapFile(filePath.c_str());

    lmAssert(assembly, "Error loading executable: %s", assemblyName.c_str());

	assembly->freeByteCode();
	
	return assembly;
}

Assembly *LSLuaState::loadExecutableAssemblyBinary(const char *buffer, long bufferSize) {
    Assembly   *assembly = NULL;

    utByteArray headerBytes;

    headerBytes.allocateAndCopy((void *)buffer, sizeof(unsigned int) * 4);

    // we need to decompress
    lmCheck(headerBytes.readUnsignedInt() == LOOM_BINARY_ID, "binary id mismatch");
    lmCheck(headerBytes.readUnsignedInt() == LOOM_BINARY_VERSION_MAJOR, "major version mismatch");
    lmCheck(headerBytes.readUnsignedInt() == LOOM_BINARY_VERSION_MINOR, "minor version mismatch");
    unsigned int sz = headerBytes.readUnsignedInt();

    utByteArray bytes;
    bytes.resize(sz);

    uLongf readSZ = sz;

    int ok = uncompress((Bytef *)bytes.getDataPtr(), (uLongf *)&readSZ, (const Bytef *)((unsigned char *)buffer + sizeof(unsigned int) * 4), (uLong)sz);

    lmCheck(ok == Z_OK, "problem uncompressing executable assembly");
    lmCheck(readSZ == sz, "Read size mismatch");

    assembly = loadAssemblyBinary(&bytes);

    return assembly;
}


// get all types loaded for a given package
void LSLuaState::getPackageTypes(const utString&  packageName,
                                 utArray<Type *>& types)
{
    for (UTsize i = 0; i < assemblies.size(); i++)
    {
        Assembly *assembly = assemblies.at(i);

        assembly->getPackageTypes(packageName, types);
    }
}


Assembly *LSLuaState::getAssembly(const utString& name)
{
    for (UTsize i = 0; i < assemblies.size(); i++)
    {
        Assembly *assembly = assemblies.at(i);

        if (assembly->getName() == name)
        {
            return assembly;
        }

        if (assembly->getName() + ".loom" == name)
        {
            return assembly;
        }
    }

    return NULL;
}


void LSLuaState::invokeStaticMethod(const utString& typePath,
                                    const char *methodName, int numParameters)
{
    Type *type = getType(typePath.c_str());

    lmAssert(type, "LSLuaState::invokeStaticMethod unknown type: %s", typePath.c_str());

    MemberInfo *member = type->findMember(methodName);
    lmAssert(member, "LSLuaState::invokeStaticMethod unknown member: %s:%s", typePath.c_str(), methodName);
    if (!member->isMethod())
    {
        lmAssert(0, "LSLuaState::invokeStaticMethod member: %s:%s is not a method", typePath.c_str(), methodName);
    }

    MethodInfo *method = (MethodInfo *)member;

    lmAssert(method->isStatic(), "LSLuaState::invokeStaticMethod member: %s:%s is not a static method", typePath.c_str(), methodName);

    method->invoke(NULL, numParameters);
}


void LSLuaState::getClassTable(Type *type)
{
    lsr_getclasstable(L, type);
}


void LSLuaState::declareClass(Type *type)
{
    lsr_declareclass(L, type);
}


void LSLuaState::initializeClass(Type *type)
{
    lsr_classinitialize(L, type);
}


void LSLuaState::tick()
{
    invokeStaticMethod("system.VM", "_tick");
}


void LSLuaState::initCommandLine(int argc, const char **argv)
{
    for (int i = 0; i < argc; i++)
    {
        commandLine.push_back(argv[i]);
    }
}


void LSLuaState::dumpManagedNatives()
{
    NativeInterface::dumpManagedNatives(L);
}

void LSLuaState::dumpLuaStack()
{
    int i;
    int top = lua_gettop(L);

    lmLog(gLuaStateLogGroup, "Total in stack: %d", top);

    for (i = 1; i <= top; i++)
    {
        int t = lua_type(L, i);
        switch (t) {
        case LUA_TSTRING:
            lmLog(gLuaStateLogGroup, "string: '%s'", lua_tostring(L, i));
            break;
        case LUA_TBOOLEAN:
            lmLog(gLuaStateLogGroup, "boolean %s", lua_toboolean(L, i) ? "true" : "false");
            break;
        case LUA_TNUMBER:
            lmLog(gLuaStateLogGroup, "number: %g", lua_tonumber(L, i));
            break;
        default:  /* other values */
            lmLog(gLuaStateLogGroup, "%s", lua_typename(L, t));
            break;
        }
    }
    lmLog(gLuaStateLogGroup, "");
}

int LSLuaState::getStackSize()
{
    return L->stacksize;
}


static void _getCurrentStack(lua_State *L, utStack<stackinfo>& stack)
{
    int       top = lua_gettop(L);
    lua_Debug lstack;
    int       stackFrame = 0;

    MethodBase *lastMethod = NULL;

    while (true)
    {
        // if we get a null result here, we are out of stack
        if (!lua_getstack(L, stackFrame++, &lstack))
        {
            lua_settop(L, top);
            return;
        }

        // something bad in denmark
        if (!lua_getinfo(L, "fSl", &lstack))
        {
            lua_settop(L, top);
            return;
        }

        bool cfunc = false;
        if (lua_iscfunction(L, -1))
        {
            cfunc = true;
        }

        lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMETHODLOOKUP);
        lua_pushvalue(L, -2);
        lua_rawget(L, -2);

        if (lua_isnil(L, -1))
        {
            lua_settop(L, top);
            continue;
        }

        MethodBase *methodBase = (MethodBase *)lua_topointer(L, -1);

        lua_settop(L, top);

        // we only want the root call, not the pcall wrapper
        if (cfunc && (lastMethod == methodBase))
        {
            continue;
        }

        lastMethod = methodBase;

        stackinfo si;
        si.methodBase = methodBase;
        si.source     = methodBase->isNative() ? "[NATIVE]" : lstack.source;
        si.linenumber = lstack.currentline == -1 ? 0 : lstack.currentline;

        stack.push(si);
    }
}


int LSLuaState::traceback(lua_State *L)
{
    _tracestack.clear();

    if (lua_isstring(L, 1))
    {
        snprintf(_tracemessage, 2040, "%s", lua_tostring(L, 1));
    }
    else
    {
        _tracemessage[0] = 0;
    }

    _getCurrentStack(L, _tracestack);

    return 0;
}


void LSLuaState::triggerRuntimeError(const char *format, ...)
{
    LSLog(LSLogError, "=====================");
    LSLog(LSLogError, "=   RUNTIME ERROR   =");
    LSLog(LSLogError, "=====================\n");

    lmAllocVerifyAll();

    char    buff[2048];
    va_list args;
    va_start(args, format);
#ifdef _MSC_VER
    vsprintf_s(buff, 2046, format, args);
#else
    vsnprintf(buff, 2046, format, args);
#endif
    va_end(args);

    if (buff)
    {
        LSLog(LSLogError, "%s", buff);
    }

    if (_tracemessage[0])
    {
        LSLog(LSLogError, "%s\n", _tracemessage);
    }

    _tracemessage[0] = 0;

    // coming from a native assert?
    if (!_tracestack.size())
    {
        _getCurrentStack(L, _tracestack);
    }

    LSLog(LSLogError, "Stacktrace:", buff);

    for (UTsize i = 0; i < _tracestack.size(); i++)
    {
        const stackinfo& s = _tracestack.peek(_tracestack.size() - i - 1);

        LSLog(LSLogError, "%s : %s : %i", s.methodBase->getFullMemberName(),
              s.source ? s.source : NULL, s.linenumber);
    }


    LSError("\nFatal Runtime Error\n\n");
}
}
