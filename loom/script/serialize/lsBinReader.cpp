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

#include "loom/common/core/allocator.h"
#include "loom/script/serialize/lsBinReader.h"
#include "loom/script/reflection/lsFieldInfo.h"

namespace LS {
utByteArray           *BinReader::sBytes = NULL;
utArray<const char *> BinReader::stringPool;
const char            *BinReader::stringBuffer = NULL;
LSLuaState            *BinReader::vm           = NULL;

utHashTable<utHashedString, BinReader::Reference *> BinReader::references;
utHashTable<utHashedString, BinReader::TypeIndex *> BinReader::types;

void BinReader::readStringPool()
{
    // read to one allocated memory area for speed

    // number of strings in the string pool
    int stringPoolSize = sBytes->readInt();

    stringPool.resize(stringPoolSize);

    // the complete size of the string buffer
    int stringBufferSize = sBytes->readInt();

    stringBuffer = (const char*)lmAlloc(NULL, stringBufferSize);

    char *p = (char *)stringBuffer;

    for (UTsize i = 0; i < (UTsize)stringPoolSize; i++)
    {
        int length = sBytes->readInt();

        const char *pstring = p;

        while (length--)
        {
            *p = sBytes->readByte();
            p++;
        }

        *p = 0;
        p++;
        stringPool[i] = pstring;
    }
}


void BinReader::readMemberInfo(MemberInfo *memberInfo)
{
    const char *name = readPoolString();

    memberInfo->ordinal = bytes->readInt();
    const char *source    = readPoolString();
    int        linenumber = bytes->readInt();

    memberInfo->name       = name;
    memberInfo->source     = source;
    memberInfo->lineNumber = linenumber;

    int numMeta = bytes->readInt();

    for (int i = 0; i < numMeta; i++)
    {
        const char *metaname = readPoolString();

        int numMetaList = bytes->readInt();

        for (int j = 0; j < numMetaList; j++)
        {
            MetaInfo *minfo = memberInfo->addUniqueMetaInfo(metaname);

            int numKeys = bytes->readInt();

            for (int k = 0; k < numKeys; k += 2)
            {
                const char *key   = readPoolString();
                const char *value = readPoolString();

                minfo->keys.insert(key, value);

                // NOTE: On VS2010 this does not work and had to be replaced with the above
                // this code did however work fine under OSX< Android, and iOS
                // minfo->keys.insert(readPoolString(), readPoolString());
            }
        }
    }
}


TemplateInfo *BinReader::readTemplateTypes()
{
    if (!bytes->readBoolean())
    {
        return NULL;
    }

    TemplateInfo *templateInfo = lmNew(NULL) TemplateInfo;
    templateInfo->fullTypeName = readPoolString();
    templateInfo->type         = getType(templateInfo->fullTypeName.c_str());

    int numTypes = bytes->readInt();

    for (int i = 0; i < numTypes; i++)
    {
        if (!bytes->readBoolean())
        {
            TemplateInfo *t = lmNew(NULL) TemplateInfo;
            t->fullTypeName = readPoolString();
            t->type         = getType(t->fullTypeName.c_str());
            templateInfo->types.push_back(t);
        }
        else
        {
            templateInfo->types.push_back(readTemplateTypes());
        }
    }

    return templateInfo;
}


void BinReader::readMethodBase(MethodBase *mbase)
{
    readMemberInfo(mbase);

    int numMethodAttributes = bytes->readInt();

    for (int i = 0; i < numMethodAttributes; i++)
    {
        const char *methodAttr = readPoolString();

        if (!strcmp(methodAttr, "static"))
        {
            mbase->attr.isStatic = true;
        }
        else if (!strcmp(methodAttr, "public"))
        {
            mbase->attr.isPublic = true;
        }
        else if (!strcmp(methodAttr, "private"))
        {
            mbase->attr.isPrivate = true;
        }
        else if (!strcmp(methodAttr, "protected"))
        {
            mbase->attr.isProtected = true;
        }
        else if (!strcmp(methodAttr, "native"))
        {
            mbase->attr.isNative = true;
        }
        else if (!strcmp(methodAttr, "virtual"))
        {
            mbase->attr.isVirtual = true;
        }
        else if (!strcmp(methodAttr, "supercall"))
        {
            mbase->attr.hasSuperCall = true;
        }
        else if (!strcmp(methodAttr, "operator"))
        {
            mbase->attr.isOperator = true;
        }
    }

    if (bytes->readBoolean())
    {
        mbase->setTemplateInfo(readTemplateTypes());
    }

    // parameters
    int numParamaters = bytes->readInt();

    for (int i = 0; i < numParamaters; i++)
    {
        ParameterInfo *param = lmNew(NULL) ParameterInfo();
        mbase->parameters.push_back(param);

        const char *name = readPoolString();

        Type *ptype = NULL;
        if (bytes->readBoolean())
        {
            ptype = getType(readPoolString());
        }

        bool hasDefault = bytes->readBoolean();
        bool isVarArg   = bytes->readBoolean();

        int numTemplateTypes = bytes->readInt();
        for (int j = 0; j < numTemplateTypes; j++)
        {
            Type *ttype = getType(readPoolString());
            param->addTemplateType(ttype);
        }


        param->position              = (int)i;
        param->name                  = name;
        param->member                = mbase;
        param->parameterType         = ptype;
        param->attributes.hasDefault = hasDefault;
        param->attributes.isVarArgs  = isVarArg;
    }

    // find first default argument
    for (UTsize i = 0; i < mbase->parameters.size(); i++)
    {
        if (mbase->parameters.at(i)->attributes.hasDefault)
        {
            mbase->firstDefaultArg = i;
            break;
        }
    }


    if (mbase->isNative())
    {
        // empty bytecode
        bytes->readString();

        lua_CFunction function = NULL;
        lua_State     *L       = vm->VM();

        int top = lua_gettop(L);
        lua_settop(L, top);
        lsr_pushmethodbase(L, mbase);

        if (!lua_isnil(L, -1))
        {
            function = lua_tocfunction(L, -1);

            if (!function)
            {
                if (lua_isuserdata(L, -1))
                {
                    mbase->setFastCall((void *)lua_topointer(L, -1));
                }
            }
        }

        lua_pop(L, 1);

        if (!mbase->isFastCall())
        {
            if (!function)
            {
                if (mbase->declaringType->isPrimitive() && mbase->isStatic())
                {
                    LSError("Missing primitive native function %s:%s",
                            mbase->declaringType->getFullName().c_str(),
                            mbase->name.c_str());
                }
                else if (!mbase->declaringType->isPrimitive())
                {
                    LSError("Missing native function %s:%s",
                            mbase->declaringType->getFullName().c_str(),
                            mbase->name.c_str());
                }
            }
            else
            {
                if (mbase->declaringType->isPrimitive() && !mbase->isStatic())
                {
                    LSError("Unnecessary primitive native instance function %s:%s",
                            mbase->declaringType->getFullName().c_str(),
                            mbase->name.c_str());
                }
            }
        }
    }
    else
    {
        mbase->setByteCode(ByteCode::decode64(bytes->readString()));
    }
}


MethodInfo *BinReader::readMethodInfo(Type *type)
{
    MethodInfo *methodInfo = lmNew(NULL) MethodInfo();

    methodInfo->declaringType = type;

    readMethodBase(methodInfo);

    Type *retType = NULL;
    if (bytes->readBoolean())
    {
        retType = getType(readPoolString());
    }

    methodInfo->memberType.method = true;
    methodInfo->type = getType("system.Function");

    if (retType)
    {
        methodInfo->setReturnType(retType);
    }

    return methodInfo;
}


PropertyInfo *BinReader::readProperty(Type *type)
{
    PropertyInfo *prop = lmNew(NULL) PropertyInfo();

    readMemberInfo(prop);

    // read attributes

    int numAttr = bytes->readInt();
    for (int i = 0; i < numAttr; i++)
    {
        const char *attr = readPoolString();

        if (!strcmp(attr, "static"))
        {
            prop->attr.isStatic = true;
        }
        else if (!strcmp(attr, "public"))
        {
            prop->attr.isPublic = true;
        }
        else if (!strcmp(attr, "private"))
        {
            prop->attr.isPrivate = true;
        }
        else if (!strcmp(attr, "protected"))
        {
            prop->attr.isProtected = true;
        }
        else if (!strcmp(attr, "native"))
        {
            prop->attr.isNative = true;
        }
    }

    Type *ptype = NULL;
    if (bytes->readBoolean())
    {
        ptype = getType(readPoolString());
    }

    prop->type = ptype;

    // getter
    MethodInfo *getter = NULL;
    if (bytes->readBoolean())
    {
        getter       = readMethodInfo(type);
        prop->getter = getter;
        getter->setPropertyInfo(prop);
    }

    // setter
    MethodInfo *setter = NULL;
    if (bytes->readBoolean())
    {
        setter       = readMethodInfo(type);
        prop->setter = setter;
        setter->setPropertyInfo(prop);
    }

    return prop;
}


FieldInfo *BinReader::readField(Type *type)
{
    FieldInfo *field = lmNew(NULL) FieldInfo();

    readMemberInfo(field);

    field->memberType.field = true;
    field->declaringType    = type;

    // handle attr
    int numAttr = bytes->readInt();

    for (int i = 0; i < numAttr; i++)
    {
        const char *attr = readPoolString();

        if (!strcmp(attr, "static"))
        {
            field->attr.isStatic = true;
        }
        else if (!strcmp(attr, "public"))
        {
            field->attr.isPublic = true;
        }
        else if (!strcmp(attr, "private"))
        {
            field->attr.isPrivate = true;
        }
        else if (!strcmp(attr, "protected"))
        {
            field->attr.isProtected = true;
        }
        else if (!strcmp(attr, "native"))
        {
            field->attr.isNative = true;
        }
        else if (!strcmp(attr, "const"))
        {
            field->attr.isConst = true;
        }
    }

    Type *fieldType = NULL;

    if (bytes->readBoolean())
    {
        fieldType = getType(readPoolString());
    }

    field->type = fieldType;

    if (bytes->readBoolean())
    {
        field->setTemplateInfo(readTemplateTypes());
    }

    return field;
}


ConstructorInfo *BinReader::readConstructor(Type *type)
{
    ConstructorInfo *cinfo = lmNew(NULL) ConstructorInfo();

    cinfo->declaringType = type;

    readMethodBase(cinfo);

    cinfo->memberType.constructor = true;
    cinfo->type = getType("system.Function");
    cinfo->defaultConstructor = bytes->readBoolean();

    return cinfo;
}


void BinReader::readClass(Type *type)
{
    readMemberInfo(type);

    MetaInfo *meta = type->getMetaInfo("Native");
    if (meta)
    {
        type->attr.isNative = true;

        if (meta->keys.find("managed") != UT_NPOS)
        {
            type->attr.isNativeManaged = true;
        }
    }

    int numClassAttr = bytes->readInt();

    for (int i = 0; i < numClassAttr; i++)
    {
        const char *cattr = readPoolString();

        if (!strcmp(cattr, "public"))
        {
            type->attr.isPublic = true;
        }
        if (!strcmp(cattr, "static"))
        {
            type->attr.isStatic = true;
        }
        if (!strcmp(cattr, "final"))
        {
            type->attr.isFinal = true;
        }
    }

    // base type
    Type *baseType = getType(readPoolString());
    if (baseType)
    {
        type->setBaseType(baseType);
    }

    // interfaces
    int numInterfaces = bytes->readInt();

    for (int i = 0; i < numInterfaces; i++)
    {
        Type *interface = getType(readPoolString());
        type->addInterface(interface);
    }

    // delegate types
    int numDelegateTypes = bytes->readInt();

    for (int i = 0; i < numDelegateTypes; i++)
    {
        Type *delegateType = getType(readPoolString());
        type->addDelegateType(delegateType);
    }

    // delegateReturnType
    Type *delegateReturnType = getType(readPoolString());
    if (delegateReturnType)
    {
        type->setDelegateReturnType(delegateReturnType);
    }

    // imports
    int numImports = bytes->readInt();

    for (int i = 0; i < numImports; i++)
    {
        Type *import = getType(readPoolString());
        type->addImport(import);
    }

    // read constructor
    if (bytes->readBoolean())
    {
        ConstructorInfo *cinfo = readConstructor(type);
        type->addMember(cinfo);
    }

    // read fields

    int numFields = bytes->readInt();

    for (int i = 0; i < numFields; i++)
    {
        FieldInfo *fieldInfo = readField(type);
        type->addMember(fieldInfo);
    }

    // read properties

    int numProps = bytes->readInt();

    for (int i = 0; i < numProps; i++)
    {
        PropertyInfo *propertyInfo = readProperty(type);
        type->addMember(propertyInfo);
    }

    // read methods

    int numMethods = bytes->readInt();

    for (int i = 0; i < numMethods; i++)
    {
        MethodInfo *methodInfo = readMethodInfo(type);
        type->addMember(methodInfo);
    }

    type->setBCStaticInitializer(ByteCode::decode64(bytes->readString()));
    type->setBCInstanceInitializer(ByteCode::decode64(bytes->readString()));
}


Type *BinReader::readType()
{
    int startPosition = bytes->getPosition();

    const char *stype       = readPoolString();
    const char *packageName = readPoolString();
    const char *name        = readPoolString();
    int        typeID       = bytes->readInt();
    const char *source      = readPoolString();
    int        linenumber   = bytes->readInt();

    utString fullname = packageName;

    fullname += ".";
    fullname += name;

    TypeIndex *tindex = *(types.get(utHashedString(fullname)));

    Type *type = tindex->type;

    type->setTypeID((LSTYPEID)typeID);
    type->packageName = packageName;
    type->fullName    = fullname;

    if (!strcmp(stype, "CLASS"))
    {
        type->attr.isClass = true;
    }
    else if (!strcmp(stype, "INTERFACE"))
    {
        type->attr.isInterface = true;
    }
    else if (!strcmp(stype, "STRUCT"))
    {
        type->attr.isStruct = true;
    }
    else if (!strcmp(stype, "DELEGATE"))
    {
        type->attr.isDelegate = true;
    }
    else if (!strcmp(stype, "ENUM"))
    {
        type->attr.isEnum = true;
    }
    else
    {
        lmAssert(0, "Unknown type: %s", stype);
    }

    readClass(type);

    return type;
}


void BinReader::readModules()
{
    // modules

    int numModules = bytes->readInt();

    for (int i = 0; i < numModules; i++)
    {
        const char *type    = readPoolString();
        const char *name    = readPoolString();
        const char *version = readPoolString();

        Module *module = Module::create(assembly, name);

        int numTypes = bytes->readInt();

        for (int j = 0; j < numTypes; j++)
        {
            Type *type = readType();
            module->addType(type);
        }
    }
}


Assembly *BinReader::readAssembly(LSLuaState *_vm, utByteArray *_bytes)
{
    vm->beginAssemblyLoad();

    bytes = _bytes;

    const char *type       = readPoolString();
    const char *name       = readPoolString();
    const char *version    = readPoolString();
    const char *loomconfig = readPoolString();

    // write out flags
    bool executable = bytes->readBoolean();
    bool jit        = bytes->readBoolean();
    bool debugbuild = bytes->readBoolean();

#ifdef LOOM_ENABLE_JIT
    if (!jit)
    {
        LSError("Assembly %s.loom has interpreted bytecode, JIT required", name);
    }
#else
    if (jit)
    {
        LSError("Assembly %s.loom has JIT bytecode, interpreted required", name);
    }
#endif


    if (!executable)
    {
        Reference *aref = *(references.get(utHashedString(name)));
        aref->loaded = true;
    }

    // number of references
    utArray<Reference *> assrefs;

    int numrefs = bytes->readInt();
    for (int i = 0; i < numrefs; i++)
    {
        const char *refname = readPoolString();

        Reference *ref = *(references.get(utHashedString(refname)));

        assrefs.push_back(ref);

        if (ref->loaded)
        {
            continue;
        }

        int position = bytes->getPosition();
        bytes->setPosition(ref->position);
        BinReader refReader;
        refReader.readAssembly(_vm, bytes);
        bytes->setPosition(position);
    }

    assembly = Assembly::create(vm, name);

    for (UTsize i = 0; i < assrefs.size(); i++)
    {
        assembly->addReference(assrefs.at(i)->name);
    }

    if (loomconfig && loomconfig[0])
    {
        assembly->setLoomConfig(loomconfig);
    }

    assembly->setDebugBuild(debugbuild);

    readModules();

    utArray<Type *> asstypes;
    assembly->getTypes(asstypes);
    vm->cacheAssemblyTypes(assembly, asstypes);
    vm->finalizeAssemblyLoad(assembly, asstypes);

    vm->endAssemblyLoad();


    return assembly;
}


Assembly *BinReader::loadExecutable(LSLuaState *_vm, utByteArray *byteArray)
{
    sBytes = byteArray;
    vm     = _vm;

    // load up the string pool
    readStringPool();

    // read the type table

    int numTypes = sBytes->readInt();

    for (UTsize i = 0; i < (UTsize)numTypes; i++)
    {
        TypeIndex *tindex = lmNew(NULL) TypeIndex;
        tindex->type     = NULL;
        tindex->refIdx   = sBytes->readInt();
        tindex->fullName = readPoolString();

        // within the ref
        tindex->position = sBytes->readInt();
        tindex->length   = sBytes->readInt();
        types.insert(utHashedString(tindex->fullName), tindex);
    }

    // load up reference assemblies
    // write out the number of references
    int numRefs = sBytes->readInt();

    for (int i = 0; i < numRefs; i++)
    {
        Reference *ref = lmNew(NULL) Reference;
        ref->name     = readPoolString();
        ref->length   = sBytes->readInt();
        ref->position = sBytes->readInt();
        ref->loaded   = false;
        ref->assembly = NULL;
        
        references.insert(utHashedString(ref->name), ref);

        // offset the types to global position
        for (UTsize j = 0; j < types.size(); j++)
        {
            TypeIndex *tindex = types.at(j);

            if (tindex->refIdx == (int)i)
            {
                tindex->position += ref->position;
            }
        }
    }

    Assembly *assembly = NULL;

    // declare types
    for (UTsize i = 0; i < types.size(); i++)
    {
        TypeIndex *tindex = types.at(i);
        tindex->type = lmNew(NULL) Type();
    }

    for (UTsize i = 0; i < references.size(); i++)
    {
        Reference *ref = references.at(i);
        if (ref->loaded)
        {
            continue;
        }

        sBytes->setPosition(ref->position);
        BinReader reader;
        Assembly  *rassembly = reader.readAssembly(vm, sBytes);
        ref->assembly = rassembly;
        if (!assembly)
        {
            assembly = rassembly;
        }
    }

    // cleanup
    for (UTsize i = 0; i < references.size(); i++)
    {
        Reference *ref = references.at(i);
        if (!ref->assembly)
            continue;
        ref->assembly->freeByteCode();
    }
    
    sBytes = NULL;
    
	if (stringBuffer)
    {
        lmFree(NULL, (void*)stringBuffer);
		stringBuffer = NULL;
	}
    
	stringPool.clear();
    references.clear();
    types.clear();
    
	vm = NULL;

    return assembly;
}
}
