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

#ifndef _lsmethodinfo_h
#define _lsmethodinfo_h

#include "jansson.h"

#include "loom/script/reflection/lsReflection.h"
#include "loom/script/reflection/lsType.h"

struct LoomProfilerRoot;

namespace LS {
struct MethodAttributes : BaseAttributes
{
    bool isVirtual;
    bool isOperator;
    bool hasSuperCall;

    MethodAttributes()
    {
        isVirtual    = false;
        isOperator   = false;
        hasSuperCall = false;
    }
};

struct ParameterAttributes
{
    bool hasDefault;
    bool isVarArgs;

    ParameterAttributes()
    {
        hasDefault = false;
        isVarArgs  = false;
    }
};

class ParameterInfo
{
public:


    Type *getParameterType()
    {
        return parameterType;
    }

    const char *getName()
    {
        return name.c_str();
    }

    ParameterInfo() : parameterType(NULL), member(NULL)
    {
    }

    ~ParameterInfo()
    {
        lualoom_managedpointerreleased(this);
    }

    utString name;
    utString defaultArg;

    Type *parameterType;

    ParameterAttributes attributes;

    // member the parameter is implemented on
    MemberInfo *member;

    // signature index for this parameter
    int position;

    utArray<Type *> templateTypes;

    void addTemplateType(Type *type)
    {
        templateTypes.push_back(type);
    }
};

class PropertyInfo;

class MethodBase : public MemberInfo
{
    friend class MethodReader;
    friend class MethodWriter;
    friend class BinReader;

private:

    MethodAttributes attr;

    ByteCode *byteCode;

    // native methods
    lua_CFunction cfunction;

    utArray<ParameterInfo *> parameters;

    PropertyInfo *propertyInfo;

    /*
     * Index of the first parameter which provides a default argument
     */
    int firstDefaultArg;

    /*
     * Index of the variable argument parameter, if any (...args)
     */
    int varArgIndex;

protected:

    MethodBase() : byteCode(NULL), cfunction(NULL), propertyInfo(NULL), firstDefaultArg(-1), varArgIndex(-2), profilerRoot(NULL)
    {
    }

public:

    LoomProfilerRoot *profilerRoot;

    ~MethodBase()
    {
        freeByteCode();
    }

    bool isAbstract();

    // can be called by other classes in the same assembly
    bool isAssembly();
    virtual bool isConstructor() = 0;

    // access is limited to method limited to members of class and derived classes
    bool isFamily();

    // can be called by derived classes in the same assembly
    bool isFamilyAndAssembly();

    // can be called by derived classes (wherever they are) and all classes in same
    // assembly
    bool isFamilyOrAssembly();

    inline bool isPublic() { return attr.isPublic; }
    inline bool isProtected() { return attr.isProtected; }
    inline bool isPrivate() { return attr.isPrivate; }

    inline bool isOperator()
    {
        return attr.isOperator;
    }

    inline bool isNative()
    {
        return attr.isNative;
    }

    inline bool isStatic()
    {
        return attr.isStatic;
    }

    inline bool hasSuperCall()
    {
        return attr.hasSuperCall;
    }

    bool isVirtual();

    inline PropertyInfo *getPropertyInfo()
    {
        return propertyInfo;
    }

    inline void setPropertyInfo(PropertyInfo *propertyInfo)
    {
        this->propertyInfo = propertyInfo;
    }

    inline int getNumParameters()
    {
        return (int)parameters.size();
    }

    inline ParameterInfo *getParameter(int idx)
    {
        return parameters.at(idx);
    }

    ParameterInfo *getVarArgParameter()
    {
        for (UTsize i = 0; i < parameters.size(); i++)
        {
            if (parameters.at(i)->attributes.isVarArgs)
            {
                return parameters.at(i);
            }
        }

        return NULL;
    }

    inline int getVarArgIndex()
    {
        if (varArgIndex != -2)
        {
            return varArgIndex;
        }

        varArgIndex = -1;

        ParameterInfo *pinfo = getVarArgParameter();
        if (pinfo)
        {
            varArgIndex = pinfo->position;
        }

        return varArgIndex;
    }

    inline int getFirstDefaultParm()
    {
        return firstDefaultArg;
    }

    void setCFunction(lua_CFunction cfunction)
    {
        this->cfunction = cfunction;
    }

    lua_CFunction getCFunction()
    {
        return cfunction;
    }

    void setByteCode(ByteCode *bc)
    {
        freeByteCode();
        this->byteCode = bc;
    }

    ByteCode *getByteCode()
    {
        return byteCode;
    }

    void freeByteCode()
    {
        lmSafeDelete(NULL, this->byteCode);
    }

    // module the method is defined in
    const Module *getModule()
    {
        assert(declaringType);
        return declaringType->getModule();
    }

    // get the current executing method
    static MethodBase *getCurrentMethod();

    // TODO: multiple return values
    Object *invoke(void *othis, int numParams);

    void push();

    bool isDefined(Type *attributeType, bool inherit)
    {
        return false;
    }

    virtual const utString& getStringSignature()
    {
        static utString sig;

        if (sig.length())
        {
            return sig;
        }

        sig  = getName();
        sig += "(";
        for (int i = 0; i < getNumParameters(); i++)
        {
            ParameterInfo *p = getParameter(i);
            sig += p->getName();
            sig += ":";

            if (p->getParameterType())
            {
                sig += p->getParameterType()->getFullName();
            }
            else
            {
                sig += "[UNKNOWN TYPE]";
            }

            if (i != getNumParameters() - 1)
            {
                sig += ", ";
            }
        }
        sig += ")";
        return sig;
    }

    /*
     * Whether or not this method supports the fastcall C closure path
     */
    inline virtual bool isFastCall()
    {
        return false;
    }

    /*
     * Sets the fastcall C closure data (generally a data structure with a call member)
     */
    virtual void setFastCall(void *fastcall)
    {
    }

    /*
     * Gets the fastcall C closure data (generally a data structure with a call member)
     */
    inline virtual void *getFastCall()
    {
        return NULL;
    }
};

class MethodInfo : public MethodBase
{
    Type *returnType;

    void *fastCall;

public:

    MethodInfo() : returnType(NULL), fastCall(NULL)
    {
        memberType.method = true;
    }

    ~MethodInfo()
    {
        lualoom_managedpointerreleased(this);
    }

    /*
     * Whether or not this method supports the fastcall C closure path
     */
    inline virtual bool isFastCall()
    {
        return fastCall ? true : false;
    }

    /*
     * Gets the fastcall C closure data (generally a data structure with a call member)
     */
    inline void *getFastCall()
    {
        return fastCall;
    }

    /*
     * Sets the fastcall C closure data (generally a data structure with a call member)
     */
    inline void setFastCall(void *_fastCall)
    {
        fastCall = _fastCall;
    }

    bool isConstructor()
    {
        return false;
    }

    Type *getReturnType()
    {
        return returnType;
    }

    void setReturnType(Type *returnType)
    {
        this->returnType = returnType;
    }

    int _invoke(lua_State *L);
    int _invokeSingle(lua_State *L);

    const utString& getStringSignature()
    {
        static utString sig;

        if (sig.length())
        {
            return sig;
        }

        sig = MethodBase::getStringSignature();

        if (returnType)
        {
            sig += ":";
            sig += returnType->getFullName();
        }

        return sig;
    }
};

class ConstructorInfo : public MethodBase {
public:

    bool isConstructor()
    {
        return true;
    }

    ConstructorInfo() : defaultConstructor(false)
    {
        memberType.constructor = true;
    }

    ~ConstructorInfo()
    {
        lualoom_managedpointerreleased(this);
    }

    int _invoke(lua_State *L);

    // compiler generated constructor
    bool defaultConstructor;
};
}
#endif
