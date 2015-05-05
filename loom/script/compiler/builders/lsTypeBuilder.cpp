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

#include "loom/common/core/assert.h"
#include "loom/script/compiler/builders/lsAssemblyBuilder.h"
#include "loom/script/compiler/builders/lsTypeBuilder.h"


namespace LS {
void MemberInfoBuilder::build(MemberInfoWriter *writer, ASTNode *node)
{
    writer->setName(name);

    writer->setSourceInfo(source.c_str(), lineNumber);

    writer->setDocString(node->docString);

    if (node)
    {
        for (UTsize i = 0; i < node->metaTags.size(); i++)
        {
            MetaTag *tag = node->metaTags.at(i);

            MetaInfo *minfo = writer->addUniqueMetaInfo(tag->name);

            for (UTsize j = 0; j < tag->keys.size(); j++)
            {
                utString key    = tag->keys.keyAt(j).str();
                utString *value = tag->keys.get(key);

                if (value)
                {
                    minfo->keys.insert(key, *value);
                }
                else
                {
                    minfo->keys.insert(key, "");
                }
            }
        }
    }
}


void MemberInfoBuilder::injectTypes(Assembly *assembly)
{
}


void FieldInfoBuilder::build()
{
    MemberInfoBuilder::build(&writer, varDecl);

    writer.setFieldAttributes(attr);
}


void FieldInfoBuilder::injectType(Type *type)
{
    lmAssert(varDecl->type, "Untyped field on injection");
    writer.setFullTypeName(varDecl->type->getFullName());
    writer.setTemplateTypeInfo(varDecl->templateInfo);
    writer.setOrdinal(varDecl->memberInfo->getOrdinal());

    if (varDecl->originalType)
    {
        writer.addUniqueMetaInfo("OriginalType", "Type", varDecl->originalType->getFullName().c_str());
    }
}


void FieldInfoBuilder::initialize(VariableDeclaration *vd)
{
    varDecl = vd;

    name = vd->identifier->string;

    source     = vd->classDecl->pkgDecl->compilationUnit->filename;
    lineNumber = vd->lineNumber;

    if (vd->isStatic)
    {
        attr.isStatic = true;
    }

    if (vd->isNative)
    {
        attr.isNative = true;
    }

    if (vd->isConst)
    {
        attr.isConst = true;
    }

    if (vd->classDecl->isInterface)
    {
        // implicit public on interfaces
        attr.isPublic = true;
    }
    else
    {
        if (vd->isPublic)
        {
            attr.isPublic = true;
        }
        else if (vd->isProtected)
        {
            attr.isProtected = true;
        }
        else
        {
            attr.isPrivate = true;
        }
    }
}


void PropertyInfoBuilder::build()
{
    MemberInfoBuilder::build(&writer, propertyLiteral);

    if (propertyLiteral->classDecl->isInterface)
    {
        // implicit public on interfaces
        attr.isPublic = true;
    }
    else
    {
        attr.isPrivate = true;

        if (propertyLiteral->getter)
        {
            if (propertyLiteral->getter->isPublic)
            {
                attr.isPrivate = false;
                attr.isPublic  = true;
            }
            else if (propertyLiteral->getter->isProtected)
            {
                attr.isPrivate   = false;
                attr.isProtected = true;
            }
        }
        else if (propertyLiteral->setter)
        {
            if (propertyLiteral->setter->isPublic)
            {
                attr.isPrivate = false;
                attr.isPublic  = true;
            }
            else if (propertyLiteral->setter->isProtected)
            {
                attr.isPrivate   = false;
                attr.isProtected = true;
            }
        }
    }


    writer.setPropertyAttributes(attr);

    if (getterBuilder)
    {
        getterBuilder->build();
        writer.setGetterMethodInfoWriter(&getterBuilder->writer);
    }

    if (setterBuilder)
    {
        setterBuilder->build();
        writer.setSetterMethodInfoWriter(&setterBuilder->writer);
    }
}


void PropertyInfoBuilder::injectTypes(Assembly *assembly)
{
    lmAssert(propertyLiteral->type, "Untyped PropertyInfo at injection");

    writer.setFullTypeName(propertyLiteral->type->getFullName());

    writer.setOrdinal(propertyLiteral->memberInfo->getOrdinal());

    if (getterBuilder)
    {
        getterBuilder->injectTypes(assembly);
    }

    if (setterBuilder)
    {
        setterBuilder->injectTypes(assembly);
    }

    TemplateInfo *templateInfo = propertyLiteral->memberInfo->getTemplateInfo();

    if (templateInfo)
    {
        writer.setTemplateTypeInfo(templateInfo);
    }
}


void PropertyInfoBuilder::injectByteCode(Type *type)
{
    PropertyInfo *pinfo = (PropertyInfo *)type->findMember(
        propertyLiteral->name.c_str());

    lmAssert(pinfo, "Unable to get PropertyInfo for bytecode injection");

    if (getterBuilder)
    {
        getterBuilder->injectByteCode(pinfo, pinfo->getGetMethod());
    }

    if (setterBuilder)
    {
        setterBuilder->injectByteCode(pinfo, pinfo->getSetMethod());
    }
}


void PropertyInfoBuilder::initialize(PropertyLiteral *literal)
{
    propertyLiteral = literal;

    name = propertyLiteral->name;

    source     = literal->classDecl->pkgDecl->compilationUnit->filename;
    lineNumber = literal->lineNumber;


    if (propertyLiteral->getter)
    {
        getterBuilder = lmNew(NULL) MethodInfoBuilder();
        getterBuilder->initialize(propertyLiteral->getter);
    }

    if (propertyLiteral->setter)
    {
        setterBuilder = lmNew(NULL) MethodInfoBuilder();
        setterBuilder->initialize(propertyLiteral->setter);
    }

    if (literal->isStatic)
    {
        attr.isStatic = true;
    }
}


void MethodBaseBuilder::injectTypes(Assembly *assembly)
{
    // this isn't valid until we have done type traversal
    attr.hasSuperCall = function->hasSuperCall;

    writer->setMethodAttributes(attr);

    writer->setTemplateTypeInfo(function->templateInfo);

    writer->setOrdinal(function->methodBase->getOrdinal());

    // parameters
    for (UTsize i = 0; i < parameters.size(); i++)
    {
        ParameterInfoBuilder *pib = parameters.at(i);

        lmAssert(pib->varDecl->type, "untyped parameter");
        pib->writer.setFullTypeName(pib->varDecl->type->getFullName());
        pib->writer.setTemplateTypeInfo(pib->varDecl->templateInfo);
    }
}


void MethodBaseBuilder::build(MethodBaseWriter *writer)
{
    MemberInfoBuilder::build(writer, function);

    this->writer = writer;

    writer->setMethodAttributes(attr);

    // parameters
    for (UTsize i = 0; i < parameters.size(); i++)
    {
        ParameterInfoBuilder *pib = parameters.at(i);
        pib->writer.name       = pib->name;
        pib->writer.attr       = pib->attr;
        pib->writer.defaultArg = pib->defaultArg;
    }
}


void MethodBaseBuilder::initialize(MethodBaseWriter *writer,
                                   FunctionLiteral  *function)
{
    this->function = function;

    name       = function->name->string;
    source     = function->classDecl->pkgDecl->compilationUnit->filename;
    lineNumber = function->lineNumber;

    if (function->isStatic)
    {
        attr.isStatic = true;
    }
    if (function->isNative)
    {
        attr.isNative = true;
    }

    if (function->classDecl->isInterface)
    {
        attr.isPublic = true;
    }
    else
    {
        if (function->isPublic)
        {
            attr.isPublic = true;
        }
        else if (function->isProtected)
        {
            attr.isProtected = true;
        }
        else
        {
            attr.isPrivate = true;
        }
    }

    if (function->isOperator)
    {
        attr.isOperator = true;
    }

    // parameters
    if (function->parameters)
    {
        for (UTsize i = 0; i < function->parameters->size(); i++)
        {
            VariableDeclaration *vd = function->parameters->at(i);

            ParameterInfoBuilder *pib = lmNew(NULL) ParameterInfoBuilder();

            if (function->defaultArguments[i])
            {
                pib->attr.hasDefault = true;

                utString value;

                Expression *e = function->defaultArguments[i];

                if (e->astType == AST_STRINGLITERAL)
                {
                    value = ((StringLiteral *)e)->string;
                }
                else if (e->astType == AST_NULLLITERAL)
                {
                    value = "null";
                }
                else if (e->astType == AST_BOOLEANLITERAL)
                {
                    value = ((BooleanLiteral *)e)->value ? "true" : "false";
                }
                else if (e->astType == AST_NUMBERLITERAL)
                {
                    value = ((NumberLiteral *)e)->svalue;
                }

                pib->defaultArg = value;
            }

            if (vd->isVarArg)
            {
                pib->attr.isVarArgs = true;
            }

            pib->varDecl = vd;

            pib->name = vd->identifier->string;

            parameters.push_back(pib);

            writer->addParameterInfoWriter(&pib->writer);
        }
    }
}


void ConstructorInfoBuilder::build()
{
    MethodBaseBuilder::build(&writer);
}


void ConstructorInfoBuilder::initialize(FunctionLiteral *function)
{
    MethodBaseBuilder::initialize(&writer, function);
}


void ConstructorInfoBuilder::injectByteCode(Type *type)
{
    // TODO: verify that this is actually a method
    ConstructorInfo *constructor = (ConstructorInfo *)type->findMember(name.c_str());

    lmAssert(constructor, "unable to get constructor");

    writer.setDefaultConstructor(constructor->defaultConstructor);

    writer.setByteCode(constructor->getByteCode()->getBase64());
}


void MethodInfoBuilder::build()
{
    MethodBaseBuilder::build(&writer);
}


void MethodInfoBuilder::initialize(FunctionLiteral *function)
{
    MethodBaseBuilder::initialize(&writer, function);
}


void MethodInfoBuilder::injectTypes(Assembly *assembly)
{
    MethodBaseBuilder::injectTypes(assembly);

    MethodInfo *methodInfo = (MethodInfo *)function->methodBase;

    lmAssert(methodInfo, "null methodInfo");
    Type *returnType = methodInfo->getReturnType();
    lmAssert(returnType, "untyped return type");
    writer.setReturnType(returnType->getFullName());
}


void MethodInfoBuilder::injectByteCode(Type *type)
{
    // TODO: verify that this is actually a method
    MethodInfo *method = (MethodInfo *)type->findMember(name.c_str());

    lmAssert(method, "unable to get methodinfo");

    lmAssert(method->getByteCode(), "ByteCode Injection Error: %s:%s", type->getName(), method->getName());

    writer.setByteCode(method->getByteCode()->getBase64());
}


void MethodInfoBuilder::injectByteCode(PropertyInfo *property, MethodInfo *method)
{
    if (!method)
    {
        return;
    }

    lmAssert(method->getByteCode(), "ByteCode Injection Error: %s:%s:%s",
             property->getDeclaringType()->getName(), property->getName(), method->getName());

    writer.setByteCode(method->getByteCode()->getBase64());
}


void TypeBuilder::injectTypes(Assembly *assembly)
{
    Type *type = assembly->getType(fullPath);

    lmAssert(type, "unable to get type for injection %s", fullPath.c_str());

    Type *baseType = type->getBaseType();

    if (baseType)
    {
        baseTypeFullPath = baseType->getFullName();
        writer.setBaseTypeFullPath(baseTypeFullPath);
    }

    for (UTsize i = 0; i < type->getNumInterfaces(); i++)
    {
        writer.addInteraceFullPath(type->getInterface(i)->getFullName());
    }

    if (type->isDelegate())
    {
        for (UTsize i = 0; i < type->getNumDelegateTypes(); i++)
        {
            writer.addDelegateTypeFullPath(
                type->getDelegateType(i)->getFullName());
        }

        writer.setDelegateReturnTypeFullPath(
            type->getDelegateReturnType()->getFullName());
    }

    if (constructorBuilder)
    {
        constructorBuilder->injectTypes(assembly);
    }

    for (UTsize i = 0; i < fieldBuilders.size(); i++)
    {
        fieldBuilders.at(i)->injectType(type);
    }

    for (UTsize i = 0; i < propertyBuilders.size(); i++)
    {
        propertyBuilders.at(i)->injectTypes(assembly);
    }

    for (UTsize i = 0; i < methodBuilders.size(); i++)
    {
        methodBuilders.at(i)->injectTypes(assembly);
    }

    // now that we have full type info ensure
    // that we have all type imports represented
    // including wildcard imports (.*)
    utArray<utString> imports;
    utArray<Type *>   typeImports;

    type->getImports(typeImports);
    for (UTsize i = 0; i < typeImports.size(); i++)
    {
        imports.push_back(typeImports.at(i)->getFullName());
    }

    writer.setImports(imports);
}


void TypeBuilder::injectByteCode(Assembly *assembly)
{
    Type *type = assembly->getType(fullPath);

    lmAssert(type, "unable to get type for bytecode injection %s", fullPath.c_str());

    utString bc = type->getBCStaticInitializer()->getBase64();
    writer.setBCStaticInitializer(bc);

    bc = type->getBCInstanceInitializer()->getBase64();
    writer.setBCInstanceInitializer(bc);

    if (constructorBuilder)
    {
        constructorBuilder->injectByteCode(type);
    }

    for (UTsize i = 0; i < methodBuilders.size(); i++)
    {
        methodBuilders.at(i)->injectByteCode(type);
    }

    for (UTsize i = 0; i < propertyBuilders.size(); i++)
    {
        propertyBuilders.at(i)->injectByteCode(type);
    }
}


void TypeBuilder::build()
{
    writer.setPackageName(packageName);
    writer.setTypeName(typeName);
    writer.setImports(imports);

    writer.setSourceInfo(source.c_str(), lineNumber);

    writer.setBaseTypeFullPath(baseTypeFullPath);

    if (constructorBuilder)
    {
        constructorBuilder->build();
    }

    // build methods

    for (UTsize i = 0; i < methodBuilders.size(); i++)
    {
        MethodInfoBuilder *mib = methodBuilders.at(i);
        mib->build();
    }

    // build fields

    for (UTsize i = 0; i < fieldBuilders.size(); i++)
    {
        FieldInfoBuilder *fib = fieldBuilders.at(i);
        fib->build();
    }

    // build properties
    for (UTsize i = 0; i < propertyBuilders.size(); i++)
    {
        PropertyInfoBuilder *pib = propertyBuilders.at(i);
        pib->build();
    }
}


void TypeBuilder::initialize(ClassDeclaration *cls)
{
    packageName = cls->pkgDecl->spath;
    typeName    = cls->name->string;
    fullPath    = cls->fullPath;

    source     = cls->pkgDecl->compilationUnit->filename;
    lineNumber = cls->lineNumber;

    writer.setDocString(cls->docString);

    typeID = assemblyBuilder->allocateTypeID();

    writer.setTypeID(typeID);

    if (cls->isInterface)
    {
        writer.setInterface();
    }
    else if (cls->isStruct)
    {
        writer.setStruct();
    }
    else if (cls->isDelegate)
    {
        writer.setDelegate();
    }
    else if (cls->isEnum)
    {
        writer.setEnum();
    }
    else
    {
        writer.setClass();
    }

    if (cls->isStatic)
    {
        writer.setStatic();
    }

    if (cls->isPublic)
    {
        writer.setPublic();
    }

    if (cls->isFinal)
    {
        writer.setFinal();
    }

    // meta

    for (UTsize i = 0; i < cls->metaTags.size(); i++)
    {
        MetaTag *tag = cls->metaTags.at(i);

        MetaInfo *minfo = writer.addUniqueMetaInfo(tag->name);

        for (UTsize j = 0; j < tag->keys.size(); j++)
        {
            utString key    = tag->keys.keyAt(j).str();
            utString *value = tag->keys.get(key);

            if (value)
            {
                minfo->keys.insert(key, *value);
            }
            else
            {
                minfo->keys.insert(key, "");
            }
        }
    }

    // imports
    for (UTsize i = 0; i < cls->pkgDecl->imports.size(); i++)
    {
        ImportStatement *import = cls->pkgDecl->imports.at(i);
        if (import->classname == "*")
        {
            continue;
        }
        imports.push_back(import->fullPath);
    }

    if (cls->constructor)
    {
        constructorBuilder = lmNew(NULL) ConstructorInfoBuilder();
        constructorBuilder->initialize(cls->constructor);

        // hook writer
        writer.setConstructorInfoWriter(&constructorBuilder->writer);
    }

    for (UTsize i = 0; i < cls->functionDecls.size(); i++)
    {
        FunctionLiteral *function = cls->functionDecls.at(i);

        MethodInfoBuilder *mib = lmNew(NULL)  MethodInfoBuilder();
        mib->initialize(function);
        methodBuilders.push_back(mib);

        // hook writer
        writer.addMethodInfoWriter(&mib->writer);
    }

    for (UTsize i = 0; i < cls->varDecls.size(); i++)
    {
        VariableDeclaration *vd  = cls->varDecls.at(i);
        FieldInfoBuilder    *fib = lmNew(NULL)  FieldInfoBuilder();
        fib->initialize(vd);
        fieldBuilders.push_back(fib);

        // hook writer
        writer.addFieldInfoWriter(&fib->writer);
    }

    // properties
    for (UTsize i = 0; i < cls->properties.size(); i++)
    {
        PropertyLiteral     *plit = cls->properties.at(i);
        PropertyInfoBuilder *pib = lmNew(NULL)  PropertyInfoBuilder();
        pib->initialize(plit);
        propertyBuilders.push_back(pib);
        writer.addPropertyInfoWriter(&pib->writer);
    }
}
}
