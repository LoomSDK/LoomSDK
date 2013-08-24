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

#ifndef _lsmembervisitor_h
#define _lsmembervisitor_h

#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"

#include "loom/script/compiler/lsToken.h"
#include "loom/script/compiler/lsTraversalVisitor.h"
#include "loom/script/compiler/lsScope.h"
#include "loom/script/compiler/lsCompilerLog.h"
#include "loom/script/compiler/lsCompiler.h"

#include "loom/script/runtime/lsLuaState.h"
#include "loom/script/common/lsLog.h"
#include "loom/script/reflection/lsMemberInfo.h"
#include "loom/script/reflection/lsPropertyInfo.h"

namespace LS {
//
class MemberTypeVisitor : public TraversalVisitor {
    LSLuaState *vm;

    utArray<utString> memberNames;

    bool fatalError;

public:

    MemberTypeVisitor(LSLuaState *ls, CompilationUnit *cunit) :
        vm(ls), fatalError(false)
    {
        this->cunit = cunit;
    }

    bool checkAddMemberName(const utString& memberName)
    {
        if (memberNames.find(memberName) != UT_NPOS)
        {
            error("Duplicate member \"%s\" found", memberName.c_str());
            return false;
        }

        memberNames.push_back(memberName);
        return true;
    }

    void processFunctionParameters(FunctionLiteral *function, MethodBase *method)
    {
        if (function->parameters)
        {
            for (UTsize j = 0; j < function->parameters->size(); j++)
            {
                VariableDeclaration *vd    = function->parameters->at(j);
                ParameterInfo       *param = method->getParameter(j);

                Type *type = Scope::resolveType(vd->typeString);

                const char *name = "anonymous";
                if (function->name)
                {
                    name = function->name->string.c_str();
                }

                if (!type)
                {
                    error("Unable to resolve function parameters for function \"%s\" at index %i, type: %s", name, j, vd->typeString.c_str(), j);
                }

                vd->type             = type;
                param->parameterType = type;

                if (type && (j < function->defaultArguments.size()) && function->defaultArguments.at(j))
                {
                    Type       *initType    = NULL;
                    Expression *initializer = function->defaultArguments.at(j);

                    if (initializer->astType == AST_NUMBERLITERAL)
                    {
                        initType = Scope::resolveType("system.Number");
                    }
                    else if (initializer->astType == AST_BOOLEANLITERAL)
                    {
                        initType = Scope::resolveType("system.Boolean");
                    }
                    else if (initializer->astType == AST_STRINGLITERAL)
                    {
                        initType = Scope::resolveType("system.String");
                    }
                    else if (initializer->astType == AST_NULLLITERAL)
                    {
                        initType = Scope::resolveType("system.Null");
                    }

                    if (initType)
                    {
                        initializer->type = initType;
                        if (!initType->castToType(type))
                        {
                            error("Cannot cast %s to %s for default argument assignment for member function \"%s\" at index %i, type: %s", \
                                  initType->getFullName().c_str(), type->getFullName().c_str(), name, j, vd->typeString.c_str(), j);
                        }
                    }
                }
            }
        }
    }

    Statement *visitStatement(Statement *statement)
    {
        if (statement != NULL)
        {
            if (statement->lineNumber)
            {
                lineNumber = statement->lineNumber;
            }
            statement = TraversalVisitor::visitStatement(statement);
        }

        return statement;
    }

    void processMemberVaribleDeclaration(VariableDeclaration *varDecl)
    {
        ClassDeclaration *cls = varDecl->classDecl;

        lineNumber = varDecl->lineNumber;

        MemberInfo *mi = cls->type->findMember(varDecl->identifier->string.c_str());
        assert(mi);
        varDecl->memberInfo = mi;

        mi->setDocString(varDecl->docString);

        checkAddMemberName(mi->getName());

        Type *type = Scope::resolveType(varDecl->typeString);

        if (!type)
        {
            error("Unable to resolve member %s:%s type: %s in %s at line %i",
                  cls->name->string.c_str(),
                  varDecl->identifier->string.c_str(),
                  varDecl->typeString.c_str(), cunit->filename.c_str(), lineNumber);


            fatalError = true;

            return;
        }

        if (varDecl->isNative && type->isDelegate())
        {
            varDecl->originalType = type;

            //TODO: LOOM-1197
            // we need to add this to loomlib and also use
            // for checking on function assignment to the native delegate
            varDecl->typeString = "NativeDelegate";
            type = Scope::resolveType("system.NativeDelegate");
            lmAssert(type, "unable to resolve system.NativeDelegate");
        }

        varDecl->type = type;
        mi->setType(type);

        // if we have astTemplateInfo on the variable declaration, for example: var myVector:Vector.<float>;
        if (varDecl->astTemplateInfo)
        {
            TemplateInfo *tinfo = processTemplateInfo(varDecl->astTemplateInfo);
            if (tinfo)
            {
                mi->setTemplateInfo(tinfo);
            }
            else
            {
                fatalError = true;
                return;
            }
        }
        else
        {
            if (varDecl->initializer && (varDecl->initializer->astType == AST_NEWEXPRESSION))
            {
                NewExpression *n = (NewExpression *)varDecl->initializer;
                if (n->function && (n->function->astType == AST_IDENTIFIER))
                {
                    Identifier *nident = (Identifier *)n->function;
                    if (nident->astTemplateInfo)
                    {
                        TemplateInfo *tinfo = processTemplateInfo(nident->astTemplateInfo);

                        if (tinfo)
                        {
                            mi->setTemplateInfo(tinfo);
                        }
                        else
                        {
                            fatalError = true;
                            return;
                        }

                        if (mi->getTemplateInfo()->isVector())
                        {
                            mi->setType(Scope::resolveType("Vector"));
                        }
                        else
                        {
                            mi->setType(Scope::resolveType("Dictionary"));
                        }
                    }
                }
            }
            else if (varDecl->initializer)
            {
                // handle common types, others will default to system.Object
                if (varDecl->initializer->astType == AST_STRINGLITERAL)
                {
                    mi->setType(Scope::resolveType("system.String"));
                }
                else if (varDecl->initializer->astType == AST_NUMBERLITERAL)
                {
                    mi->setType(Scope::resolveType("system.Number"));
                }
                else if (varDecl->initializer->astType == AST_BOOLEANLITERAL)
                {
                    mi->setType(Scope::resolveType("system.Boolean"));
                }
            }
        }
    }

    void processMemberPropertyLiteral(PropertyLiteral *property)
    {
        ClassDeclaration *cls = property->classDecl;

        lineNumber = property->lineNumber;

        MemberInfo *mi = cls->type->findMember(property->name.c_str());
        assert(mi);
        assert(mi->isProperty());

        mi->setDocString(property->docString);
        property->memberInfo = mi;

        lineNumber = property->lineNumber;
        checkAddMemberName(mi->getName());

        PropertyInfo *pinfo = (PropertyInfo *)mi;

        Type *type = Scope::resolveType(property->typeString);
        if (!type)
        {
            error("ERROR: unable to resolve %s in %s\n", property->typeString.c_str(), cunit->filename.c_str());
        }

        property->type = type;
        mi->setType(type);

        if (property->getter)
        {
            MethodInfo *m = pinfo->getGetMethod();

            assert(m);
            property->getter->methodBase = m;
            m->setReturnType(type);

            if (property->getter->retType && property->getter->retType->astTemplateInfo)
            {
                property->getter->templateInfo = processTemplateInfo(property->getter->retType->astTemplateInfo);
                if (!property->getter->templateInfo)
                {
                    fatalError = true;
                    return;
                }
                m->setTemplateInfo(property->getter->templateInfo);
                pinfo->setTemplateInfo(property->getter->templateInfo);
            }
        }

        if (property->setter)
        {
            MethodInfo *m = pinfo->getSetMethod();
            assert(m);
            property->setter->methodBase = m;
            m->setReturnType(Scope::resolveType("Void"));
        }
    }

    void processFunctionLiteral(FunctionLiteral *function)
    {
        assert(function);
        assert(function->classDecl);
        assert(function->name);

        ClassDeclaration *cls = function->classDecl;
        lineNumber = function->lineNumber;

        assert(cls->type);

        MemberInfo *mi = cls->type->findMember(function->name->string.c_str());
        lmAssert(mi, "Could not find member \"%s\"!", function->name->string.c_str());
        lmAssert(mi->isMethod(), "Expected method for member \"%s\", duplicate member named \"%s\"?",
                 function->name->string.c_str(), function->name->string.c_str());

        mi->setDocString(function->docString);

        lineNumber = function->lineNumber;
        if (!checkAddMemberName(mi->getName()))
        {
            return;
        }

        MethodInfo *methodInfo = (MethodInfo *)mi;

        assert(!function->methodBase);
        function->methodBase = (MethodBase *)mi;

        processFunctionParameters(function, methodInfo);

        utString sretType = "Void";
        if (function->retType)
        {
            //FIXME: this needs to handle Vector<> and other complex types
            sretType = function->retType->string;
        }

        Type *retType = Scope::resolveType(sretType);

        if (!retType)
        {
            error("Unable to resolve return type %s", sretType.c_str());
        }

        methodInfo->setReturnType(retType);

        if (function->retType && function->retType->astTemplateInfo)
        {
            function->templateInfo = processTemplateInfo(function->retType->astTemplateInfo);
            if (!function->templateInfo)
            {
                fatalError = true;
                return;
            }
            methodInfo->setTemplateInfo(function->templateInfo);
        }
    }

    void processMemberTypes()
    {
        PackageDeclaration *pkg = cunit->pkgDecl;

        if (!pkg)
        {
            LSWarning("Compilation Unit %s contains no package declaration", cunit->filename.c_str());
            return;
        }

        Scope::setVM(vm);

        // process imports assigning type to them
        for (UTsize i = 0; i < pkg->imports.size(); i++)
        {
            ImportStatement *import = pkg->imports.at(i);

            //find type
            Type *type = vm->getType(import->fullPath.c_str());

            import->type = type;

            if (!type)
            {
                lineNumber = import->lineNumber;
                error("Unable to process type for import %s\n in %s\n",
                      import->fullPath.c_str(), cunit->filename.c_str());
            }
            else
            {
                // mark the type as being imported
                LSCompiler::markImportType(type);
            }
        }

        Scope::push(pkg);

        // process the package class types
        for (UTsize i = 0; i < pkg->clsDecls.size(); i++)
        {
            ClassDeclaration *cls = pkg->clsDecls.at(i);
            cls->type = vm->getType(cls->fullPath.c_str());
            assert(cls->type);

            if (cls->extends)
            {
                cls->baseType = Scope::resolveType(cls->extends->string);

                if (!cls->baseType)
                {
                    error("Unable to resolve base class for %s:%s\n in %s",
                          cls->type->getFullName().c_str(),
                          cls->extends->string.c_str(),
                          cunit->filename.c_str());
                }

                cls->type->setBaseType(cls->baseType);
            }

            for (UTsize j = 0; j < cls->implements.size(); j++)
            {
                Type *itype = Scope::resolveType(cls->implements[j]->string);
                if (!itype)
                {
                    error("Unable to resolve interface for %s:%s",
                          cls->type->getFullName().c_str(),
                          cls->implements[j]->string.c_str());
                }

                cls->type->addInterface(itype);
            }

            // delegate types
            if (cls->isDelegate)
            {
                for (UTsize j = 0; j < cls->delegateParameters.size(); j++)
                {
                    Type *ptype = Scope::resolveType(cls->delegateParameters[j]->typeString);
                    if (!ptype)
                    {
                        error("Unable to resolve type %s for delegate parameter %i", cls->delegateParameters[j]->typeString.c_str(), j);
                    }
                    cls->type->addDelegateType(ptype);
                }
                Type *rtype = Scope::resolveType(cls->delegateReturnType->string);
                assert(rtype);
                cls->type->setDelegateReturnType(rtype);
            }
        }

        for (UTsize i = 0; i < pkg->clsDecls.size(); i++)
        {
            ClassDeclaration *cls = pkg->clsDecls[i];

            cls->type->setDocString(cls->docString);

            // clear type imports and readd from package
            // as we may have gained some wildcard's
            cls->type->clearImports();

            for (UTsize j = 0; j < pkg->imports.size(); j++)
            {
                cls->type->addImport(pkg->imports.at(j)->type);
            }

            memberNames.clear();

            for (UTsize j = 0; j < cls->varDecls.size(); j++)
            {
                processMemberVaribleDeclaration(cls->varDecls[j]);
            }

            for (UTsize j = 0; j < cls->properties.size(); j++)
            {
                processMemberPropertyLiteral(cls->properties[j]);
            }

            // constructor
            if (cls->constructor)
            {
                MemberInfo *mi = cls->type->findMember(
                    cls->constructor->name->string.c_str());
                assert(mi);
                assert(mi->isConstructor());

                ConstructorInfo *constructorInfo = (ConstructorInfo *)mi;

                if (constructorInfo->isNative() && !cls->type->isFinal())
                {
                    if (cls->constructor->parameters && cls->constructor->parameters->size())
                    {
                        error("non final type %s defines a native constructor with parameters", cls->fullPath.c_str());
                    }
                }

                MetaInfo *deprecated = constructorInfo->getMetaInfo("Deprecated");

                if (deprecated)
                {
                    error("Deprecated metatag on %s constructor.  Please place Deprecated metatag on class declaration instead.", cls->fullPath.c_str());
                }

                assert(!cls->constructor->methodBase);
                cls->constructor->methodBase = (MethodBase *)mi;

                processFunctionParameters(cls->constructor, constructorInfo);

                if (cls->constructor->isDefaultConstructor)
                {
                    constructorInfo->defaultConstructor = true;
                }

                if (cls->isStruct && cls->constructor->parameters)
                {
                    int dcount = 0;
                    for (UTsize j = 0; j < cls->constructor->defaultArguments.size(); j++)
                    {
                        if (cls->constructor->defaultArguments[j])
                        {
                            dcount++;
                        }
                    }

                    if (cls->constructor->parameters->size() != dcount)
                    {
                        error("struct type constructors must supply default arguments for all parameters: %s", cls->fullPath.c_str());
                    }
                }
            }

            for (UTsize j = 0; j < cls->functionDecls.size(); j++)
            {
                processFunctionLiteral(cls->functionDecls[j]);
            }
        }

        Scope::pop();

        Scope::setVM(NULL);
    }
};
}
#endif
