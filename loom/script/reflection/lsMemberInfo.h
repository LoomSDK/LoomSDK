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

#ifndef _lsmemberinfo_h
#define _lsmemberinfo_h

#include "jansson.h"

#include "loom/common/core/assert.h"
#include "loom/common/core/log.h"
#include "loom/common/utils/utString.h"
#include "loom/common/utils/utTypes.h"
#include "loom/common/core/allocator.h"

namespace LS {

void lualoom_managedpointerreleased(void *p);

class Object;
class Type;
class Assembly;
class Module;
class MethodInfo;
class LSLuaState;

struct MemberTypes
{
    bool constructor;
    bool field;
    bool method;
    bool property;

    void clear()
    {
        constructor = false;
        field       = false;
        method      = false;
        property    = false;
    }

    MemberTypes()
    {
        clear();
    }
};

struct BaseAttributes
{
    // field is accessible throughout the assembly
    bool isAssembly;
    // available only to subtypes in the assembly
    bool isFamilyAndAssembly;
    // available only to type and subtypes
    bool isFamily;
    // available only to subtypes (anywhere) and in the assembly
    bool isFamilyOrAssembly;

    // compile time constant
    bool isLiteral;

    bool isPublic;
    bool isProtected;
    bool isPrivate;
    bool isNative;
    bool isStatic;
    bool isConst;

    BaseAttributes()
    {
        isAssembly          = false;
        isFamilyAndAssembly = false;
        isFamily            = false;
        isFamilyOrAssembly  = false;

        isLiteral   = false;
        isPublic    = false;
        isProtected = false;
        isPrivate   = false;
        isNative    = false;
        isStatic    = false;
        isConst     = false;
    }
};

class MetaInfo
{
public:

    utString name;
    utHashTable<utHashedString, utString> keys;

    const bool matchKeyValue(const char *key, const char *value)
    {
        UTsize idx = keys.find(key);

        if (idx == UT_NPOS)
        {
            return false;
        }

        if (keys[idx] == value)
        {
            return true;
        }

        return false;
    }

    const char *getAttribute(const char *key)
    {
        UTsize idx = keys.find(key);

        if (idx == UT_NPOS)
        {
            return NULL;
        }

        return keys[idx].c_str();
    }

    ~MetaInfo()
    {
        lualoom_managedpointerreleased(this);
    }
};

/*
 * MemberInfo template info which is serialized and
 * stores the template type info for Vector and Dictionary
 */
class TemplateInfo {
public:
    TemplateInfo() : type(NULL)
    {
        refs = 0;
    }

    ~TemplateInfo()
    {
        lmAssert(refs == 0, "Destructing a template info with %d remaining references", refs);
    }

    void addReference()
    {
        refs++;
        for (UTsize i = 0; i < types.size(); i++)
        {
            types.at(i)->addReference();
        }
    }
    
    void removeReference()
    {
        refs--;
        for (UTsize i = 0; i < types.size(); i++)
        {
            types.at(i)->removeReference();
        }
        lmAssert(refs >= 0, "Template info was removed more times than it should've been, refs < 0");
        if (refs == 0) lmDelete(NULL, this);
    }

    Type                    *type;
    utString                fullTypeName;
    utArray<TemplateInfo *> types;

    // Reference counter for TemplateInfo
    int refs;

    // if we have types, we're a templated type
    bool isTemplate()
    {
        return types.size() > 0;
    }

    // retrieve the full type name of the
    // value type
    const utString& getIndexedTypeString()
    {
        assert(types.size() > 0);
        assert(types[types.size() - 1]->fullTypeName.size() > 0);
        return types[types.size() - 1]->fullTypeName;
    }

    // tests for a Vector template type
    bool isVector()
    {
        assert(types.size() > 0);
        return types.size() == 1;
    }

    bool hasIndexerType()
    {
        if ((types.size() > 0) && types[0]->type)
        {
            return true;
        }

        return false;
    }

    // for a Dictionary this retrieves the key type
    // for Vectors this will always be system.Number
    Type *getIndexerType()
    {
        assert(types.size() > 1);
        assert(types[0]->type);
        return types[0]->type;
    }

    bool hasIndexedType()
    {
        if ((types.size() > 0) && types[types.size() - 1]->type)
        {
            return true;
        }

        return false;
    }

    // for Dictionaries and Vectors this retrieves the value type
    Type *getIndexedType()
    {
        lmAssert(types.size() > 0, "Failed trying to get the value type on parametric type."); //, type->getFullName().c_str());
        assert(types[types.size() - 1]->type);
        return types[types.size() - 1]->type;
    }

    // if we have nested template types (a dictionary of vector values for instance)
    // this will retrieve the nexted TemplateInfo
    TemplateInfo *getIndexedTemplateInfo()
    {
        assert(types.size() > 0);
        return types[types.size() - 1];
    }

    // at load time this resolves the TemplateInfo types to valid
    // RTTI
    void resolveTypes(LSLuaState *lstate);
};

class MemberInfo {
    friend class Type;
    friend class MemberInfoReader;
    friend class MemberInfoWriter;
    friend class BinReader;

protected:

    utString name;
    utString fullMemberName;

    MemberTypes memberType;

    // the class object that declares this member info
    Type *declaringType;

    // the class object used to obtain this member info
    Type *reflectedType;

    Type *type;

    TemplateInfo *templateInfo;

    utHashTable<utHashedString, utList<MetaInfo *> *> metaInfo;

    int ordinal;

    // docstring for the member
    utString docString;

    // which source file this member is defined in
    utString source;
    // the line number in the source
    int lineNumber;

    bool missing;

public:

    MemberInfo() :
        declaringType(NULL), reflectedType(NULL), type(NULL), ordinal(0), templateInfo(NULL), lineNumber(0), missing(false)
    {
    }

    virtual ~MemberInfo()
    {
        if (templateInfo) templateInfo->removeReference();
        for (UTsize i = 0; i < metaInfo.size(); i++)
        {
            utList<MetaInfo *> *metaInfoList = metaInfo.at(i);

            for (UTsize j = 0; j < metaInfoList->size(); j++)
            {
                lmDelete(NULL, metaInfoList->at(j));
            }

            lmDelete(NULL, metaInfoList);
        }
    }

    void getCustomAttributes(bool inherit, utList<Object *> );

    inline bool isConstructor()
    {
        return memberType.constructor;
    }

    inline bool isField()
    {
        return memberType.field;
    }

    inline bool isMethod()
    {
        return memberType.method;
    }

    inline bool isProperty()
    {
        return memberType.property;
    }

    inline const char *getName()
    {
        return name.c_str();
    }

    inline virtual bool isStatic()
    {
        return false;
    }

    inline virtual bool isPrivate()
    {
        return false;
    }

    inline virtual bool isPublic()
    {
        return false;
    }

    inline virtual bool isProtected()
    {
        return false;
    }

    inline virtual bool isNative()
    {
        return false;
    }

    inline virtual bool isConst()
    {
        return false;
    }

    inline int getOrdinal() { return ordinal; }

    inline void setOrdinal(int _ordinal) { ordinal = _ordinal; }

    inline Type *getType()
    {
        return type;
    }

    inline void setType(Type *type)
    {
        this->type = type;
    }

    inline bool getMissing()
    {
        return missing;
    }

    // Sets the missing state to true.
    // Subclasses are able to override
    // with error reporting and logging
    inline void setMissing()
    {
        missing = true;
    }

    inline Type *getDeclaringType()
    {
        return declaringType;
    }

    Type *getReflectedType();

    virtual bool isDefined(Type *attributeType, bool inherit) = 0;

    Type *getTemplateType()
    {
        return templateInfo ? templateInfo->type : NULL;
    }

    TemplateInfo *getTemplateInfo()
    {
        return templateInfo;
    }

    void setTemplateInfo(TemplateInfo *_templateInfo)
    {
        if (templateInfo) templateInfo->removeReference();
        templateInfo = _templateInfo;
        if (templateInfo) templateInfo->addReference();
    }

    // get the first meta info with this name
    MetaInfo *getMetaInfo(const utString& name)
    {
        UTsize idx = metaInfo.find(name);

        if (idx != UT_NPOS)
        {
            return metaInfo.at(idx)->at(0);
        }

        return NULL;
    }

    // gets a list of all the MetaInfo with this name (duplicates are allowed)
    utList<MetaInfo *> *getAllMetaInfo(const utString& name)
    {
        UTsize idx = metaInfo.find(name);

        if (idx != UT_NPOS)
        {
            return metaInfo.at(idx);
        }

        return NULL;
    }

    // set the first meta info with the given name, otherwise create a new tag list and add it
    void setMetaInfo(const utString& name, const utString& key = "", const utString& value = "")
    {
        MetaInfo *mi = NULL;
        UTsize   idx = metaInfo.find(name);

        if (idx != UT_NPOS)
        {
            mi = metaInfo.at(idx)->at(0);
        }
        else
        {
            utList<MetaInfo *> *metaList = lmNew(NULL) utList<MetaInfo *>;
            mi       = lmNew(NULL) MetaInfo;
            mi->name = name;
            metaList->push_back(mi);
            metaInfo.insert(name, metaList);
        }

        if (key != "")
        {
            mi->keys.insert(key, value);
        }
    }

    // Adds a unique MetaInfo to thie MemberInfo, possibly in addtion to an existing MetaInfo with the same name
    MetaInfo *addUniqueMetaInfo(const utString& name, const utString& key = "", const utString& value = "")
    {
        UTsize idx = metaInfo.find(name);

        utList<MetaInfo *> *metaList;

        if (idx == UT_NPOS)
        {
            metaList = lmNew(NULL) utList<MetaInfo *>;
            metaInfo.insert(name, metaList);
        }
        else
        {
            metaList = metaInfo.at(idx);
        }

        MetaInfo *mi = lmNew(NULL) MetaInfo;

        mi->name = name;

        if (key != "")
        {
            mi->keys.insert(key, value);
        }

        metaList->push_back(mi);

        return mi;
    }

    const utString& getDocString()
    {
        return docString;
    }

    void setDocString(const utString& _docString)
    {
        docString = _docString;
    }

    const utString& getSource()
    {
        return source;
    }

    inline int getLineNumber()
    {
        return lineNumber;
    }

    /*
     * Retrieves the fully qualified name of the MemberInfo
     * for example "system.Vector.length"
     */
    inline const char *getFullMemberName()
    {
        lmAssert(fullMemberName != "", "fullMemberName not set");
        return fullMemberName.c_str();
    }
};

}
#endif
