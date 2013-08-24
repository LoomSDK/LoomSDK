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

#ifndef _lstypebuilder_h
#define _lstypebuilder_h

#include "loom/script/compiler/lsAST.h"
#include "loom/script/serialize/lsFieldInfoWriter.h"
#include "loom/script/serialize/lsPropertyInfoWriter.h"
#include "loom/script/serialize/lsMethodWriter.h"
#include "loom/script/serialize/lsTypeWriter.h"
#include "loom/script/reflection/lsMethodInfo.h"

namespace LS {
class AssemblyBuilder;

class MemberInfoBuilder {
protected:
    utString name;

    utArray<utString> templateTypes;

    utString source;

    int lineNumber;

    void build(MemberInfoWriter *writer, ASTNode *node = NULL);

    void injectTypes(Assembly *assembly);

    MemberInfoBuilder() : lineNumber(0)
    {
    }
};

class MethodBaseBuilder : public MemberInfoBuilder {
    friend class TypeBuilder;

    class ParameterInfoBuilder {
public:

        VariableDeclaration *varDecl;

        ParameterInfoWriter writer;

        ParameterAttributes attr;

        utString name;

        // fully qualified
        utString typeName;

        // value of default arg, if any
        utString defaultArg;

        ParameterInfoBuilder() :
            varDecl(NULL)
        {
        }
    };

    utArray<ParameterInfoBuilder *> parameters;

    MethodBaseWriter *writer;

protected:

    MethodAttributes attr;
    FunctionLiteral  *function;

    MethodBaseBuilder() :
        function(NULL), writer(NULL)
    {
    }

    void build(MethodBaseWriter *writer);

    void initialize(MethodBaseWriter *writer, FunctionLiteral *function);

    virtual void injectTypes(Assembly *assembly);

    virtual void injectByteCode(Type *type) = 0;
};

class ConstructorInfoBuilder : public MethodBaseBuilder {
    friend class TypeBuilder;

    ConstructorInfoWriter writer;

public:

    void build();

    void initialize(FunctionLiteral *function);

    void injectByteCode(Type *type);
};

class MethodInfoBuilder : public MethodBaseBuilder {
    friend class TypeBuilder;
    friend class PropertyInfoBuilder;

    utString returnType;

    MethodInfoWriter writer;

public:

    void build();

    void initialize(FunctionLiteral *function);

    void injectByteCode(PropertyInfo *property, MethodInfo *method);

    void injectByteCode(Type *type);

    void injectTypes(Assembly *assembly);
};

class FieldInfoBuilder : public MemberInfoBuilder {
    friend class TypeBuilder;

    FieldAttributes attr;

    FieldInfoWriter writer;

    VariableDeclaration *varDecl;

public:

    FieldInfoBuilder() :
        varDecl(NULL)
    {
    }

    void build();

    void initialize(VariableDeclaration *variable);

    void injectType(Type *type);
};

class PropertyInfoBuilder : public MemberInfoBuilder {
    friend class TypeBuilder;

    PropertyInfoWriter writer;

    PropertyAttributes attr;

    PropertyLiteral *propertyLiteral;

    MethodInfoBuilder *getterBuilder;
    MethodInfoBuilder *setterBuilder;

public:

    PropertyInfoBuilder() :
        propertyLiteral(NULL), setterBuilder(NULL), getterBuilder(NULL)
    {
    }

    void build();

    void initialize(PropertyLiteral *literal);

    void injectTypes(Assembly *assembly);

    void injectByteCode(Type *type);
};

class TypeBuilder {
    friend class ModuleBuilder;

    utString baseTypeFullPath;

    utString packageName;
    utString typeName;
    utString fullPath;

    utString source;
    int      lineNumber;

    LSTYPEID typeID;

    TypeWriter      writer;
    AssemblyBuilder *assemblyBuilder;

    utArray<utString>            imports;
    utArray<MethodInfoBuilder *> methodBuilders;

    ConstructorInfoBuilder *constructorBuilder;

    utArray<FieldInfoBuilder *> fieldBuilders;

    utArray<PropertyInfoBuilder *> propertyBuilders;

    void initialize(ClassDeclaration *cls);

    void injectByteCode(Assembly *assembly);

    void injectTypes(Assembly *assembly);

public:

    TypeBuilder(AssemblyBuilder *assemblyBuilder) :
        constructorBuilder(NULL)
    {
        this->assemblyBuilder = assemblyBuilder;
    }

    void build();
};
}
#endif
