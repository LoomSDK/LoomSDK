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

#ifndef _lstypevalidator_h
#define _lstypevalidator_h

#include "loom/script/runtime/lsLuaState.h"
#include "loom/script/runtime/lsRuntime.h"
#include "loom/script/native/lsNativeInterface.h"

namespace LS {
/************************************************************************
* TypeValidatorRT validates the runtime aspects of a type
* (native signatures, etc which may not be available at compile time or
* may change based on binaries
************************************************************************/

class TypeValidatorRT {
    LSLuaState *vm;
    Type       *type;

    static bool conversionsInitialized;
    static utHashTable<utHashedString, bool> stringConversion;
    static utHashTable<utHashedString, bool> booleanConversion;
    static utHashTable<utHashedString, bool> numberConversion;
    static utHashTable<utHashedString, bool> voidConversion;

    // TODO: LOOM-687 Allow external converstions to be added
    static void initializeConversions();

    /*
     * In the case of an error, we use this method to dump a nicely formated native representation of the MethodBase
     */
    static const char *_getnativesig(MethodBase             *base,
                                     utArray<const char *>& array)
    {
        static utString sig;

        sig.clear();

        sig += base->getDeclaringType()->getFullName();
        sig += ":";
        sig += base->getName();
        sig += "(";

        for (UTsize i = 1; i < array.size(); i++)
        {
            sig += array.at(i);

            if (i < array.size() - 1)
            {
                sig += ", ";
            }
        }

        sig += ")";
        if (array.size())
        {
            sig += ":";
            sig += array.at(0);
        }

        sig += ";";

        return sig.c_str();
    }

    /************************************************************************
     * Compare a script and native type signature
     ***********************************************************************
     */
    static bool _compareScriptAndNativeType(Type *stype, const char *native)
    {
        if (!conversionsInitialized)
        {
            initializeConversions();
        }

        char       snative[512];
        const char *script = stype->getName();
        if (stype->isNative())
        {
            script = stype->getCTypeName().c_str();
        }

        if (stype->isPrimitive())
        {
            // String
            if (!strcmp(script, "String"))
            {
                if (stringConversion.find(native) != UT_NPOS)
                {
                    return true;
                }

                return false;
            }

            if (!strcmp(script, "Number"))
            {
                if (numberConversion.find(native) != UT_NPOS)
                {
                    return true;
                }

                return false;
            }

            if (!strcmp(script, "Boolean"))
            {
                if (booleanConversion.find(native) != UT_NPOS)
                {
                    return true;
                }

                return false;
            }

            // end primitive
            return false;
        }

        if (!strcmp(script, "Void"))
        {
            if (voidConversion.find(native) != UT_NPOS)
            {
                return true;
            }

            return false;
        }

        if (stype->isEnum())
        {
            // we allow a cast from a number to LS enum
            if (numberConversion.find(native) != UT_NPOS)
            {
                return true;
            }

            // this is a little sketchy
            if (strstr(native, script))
            {
                return true;
            }
        }

        snprintf(snative, 512, "%s", native);
        for (size_t i = 0; i < strlen(snative); i++)
        {
            if ((snative[i] == ' ') || (snative[i] == '*'))
            {
                snative[i] = 0;
                break;
            }
        }

        // do we have a match?
        if (!strcmp(script, snative))
        {
            return true;
        }

        // if we can cast, allow it, should this be a warning?
        // What Could Possibly Go Wrong? (tm)

        NativeTypeBase *ntb = NativeInterface::getNativeType(snative);
        if (!ntb)
        {
            return false;
        }

        Type *ntype = NativeInterface::getScriptType(ntb);
        if (!ntype)
        {
            return false;
        }

        if (!ntype->castToType(stype))
        {
            return false;
        }

        return true;
    }

public:

    TypeValidatorRT(LSLuaState *vm, Type *type)
    {
        this->vm   = vm;
        this->type = type;
    }

    void validateMethodBase(MethodBase *base)
    {
        if (!base->isNative())
        {
            return;
        }

        // C++ void is valid on return, on LS we specify
        // return type
        if (!strcmp(base->getName(), "__op_assignment"))
        {
            return;
        }

        lua_State *L = vm->VM();

        int top = lua_gettop(L);

        lua_CFunction function = NULL;

        lsr_pushmethodbase(vm->VM(), base);

        if (!lua_iscfunction(L, -1))
        {
            lua_settop(L, top);
            return;
        }

        const char *haveStringSig = lua_getupvalue(L, -1, 2);

        // Check whether we have a string signature for this native method
        // these are generated at bind time for instance/static member methods
        // which aren't lua_CFunction's (in that case we are driving the lua stack
        // directly and don't have any way of verifying parameters, return values, etc

        if (haveStringSig)
        {
            utArray<utString> *array =
                (utArray<utString> *)lua_touserdata(L, -1);
            lua_pop(L, 1);

            utArray<const char *> narray;
            for (UTsize i = 0; i < array->size(); i++)
            {
                narray.push_back(array->at(i).c_str());
            }

            if (narray.size())
            {
                // if we have a lua_State* in first position, we're manipulating stack and
                // cannot check (account for return type at index 0)
                if ((narray.size() > 1) &&
                    !strcmp(narray.at(1), "lua_State*"))
                {
                    lua_settop(L, top);
                    return;
                }

                // you can add a lua_State* as a silent arg if it is last
                // if this is the only argument, all bets are off as we can be
                // manipulating the stack directly
                if ((narray.size() > 1) &&
                    !strcmp(narray.at(narray.size() - 1),
                            "lua_State*"))
                {
                    narray.pop_back();
                }

                // if the num parameters (minus the return type) don't match, error
                if ((narray.size() > 1) &&
                    (narray.size() - 1
                     != (UTsize)base->getNumParameters()))
                {
                    LSError(
                        "Native function and script signature mismatch\nScript: %s:%s\nNative: %s",
                        base->getDeclaringType()->getFullName().c_str(),
                        base->getStringSignature().c_str(),
                        _getnativesig(base, narray));
                }

                if (base->isMethod())
                {
                    MethodInfo *minfo   = (MethodInfo *)base;
                    Type       *retType = minfo->getReturnType();
                    if (retType)
                    {
                        const char *ctype = narray.at(0);

                        if (!_compareScriptAndNativeType(retType, ctype))
                        {
                            LSError(
                                "Native function and script signature mismatch\nScript: %s:%s\nNative: %s\n at return type, %s -> %s",
                                base->getDeclaringType()->getFullName().c_str(),
                                base->getStringSignature().c_str(),
                                _getnativesig(base, narray), retType->isNative() ? retType->getCTypeName().c_str() : retType->getName(),
                                ctype);
                        }
                    }
                }

                if (base->getNumParameters())
                {
                    for (int i = 0; i < base->getNumParameters(); i++)
                    {
                        ParameterInfo *pinfo = base->getParameter(i);

                        // check that we aren't out of bounds

                        if (i + 1 > (int)narray.size() - 1)
                        {
                            LSError(
                                "Native function and script signature mismatch\nScript: %s:%s\nNative: %s\n at parameter %i, %s -> native out of bounds",
                                base->getDeclaringType()->getFullName().c_str(),
                                base->getStringSignature().c_str(),
                                _getnativesig(base, narray), i, pinfo->getParameterType()->isNative() ? pinfo->getParameterType()->getCTypeName().c_str() : pinfo->getParameterType()->getName());
                        }

                        // account for return type at index 0

                        const char *ctype = narray.at(i + 1);

                        if (!_compareScriptAndNativeType(
                                pinfo->getParameterType(), ctype))
                        {
                            LSError(
                                "Native function and script signature mismatch\nScript: %s:%s\nNative: %s\n at parameter %i, %s -> %s",
                                base->getDeclaringType()->getFullName().c_str(),
                                base->getStringSignature().c_str(),
                                _getnativesig(base, narray), i, pinfo->getParameterType()->isNative() ? pinfo->getParameterType()->getCTypeName().c_str() : pinfo->getParameterType()->getName(),
                                ctype);
                        }
                    }
                }
            }
        }

        lua_settop(L, top);
    }

    /*
     * Validate a native type (at runtime)
     */
    void validate()
    {
        utArray<MemberInfo *> members;
        MemberTypes           types;
        types.method = true;
        type->findMembers(types, members, false);

        for (UTsize i = 0; i < members.size(); i++)
        {
            validateMethodBase((MethodBase *)members.at(i));
        }
    }
};
}
#endif
