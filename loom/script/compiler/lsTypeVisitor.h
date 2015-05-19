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

#ifndef _lstypevisitor_h
#define _lstypevisitor_h

#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"

#include "loom/script/compiler/lsToken.h"
#include "loom/script/compiler/lsTraversalVisitor.h"
#include "loom/script/compiler/lsScope.h"

#include "loom/script/runtime/lsLuaState.h"
#include "loom/script/reflection/lsMemberInfo.h"
#include "loom/script/reflection/lsFieldInfo.h"

#include "loom/script/common/lsLog.h"

namespace LS {
class TypeVisitor : public TraversalVisitor {
private:

    PackageDeclaration *curPackage;
    ClassDeclaration   *curClass;
    FunctionLiteral    *curFunction;
    LSLuaState         *vm;
    int                nestedCall;
    int                curVarArgCalls;

    utStack<FunctionLiteral *> functionStack;

    // checks for a function with the given name in the current function stack
    // returns true if found
    bool checkFunctionStack(const char *name)
    {
        for (UTsize i = 0; i < functionStack.size(); i++)
        {
            FunctionLiteral *function = functionStack.peek(i);
            Identifier      *fname    = function->name;

            if (!fname)
            {
                continue;
            }

            if (fname->string == name)
            {
                return true;
            }
        }

        return false;
    }

public:

    TypeVisitor(LSLuaState *ls) :
        TraversalVisitor(), curPackage(NULL), curClass(NULL), curFunction(
            NULL), vm(ls), nestedCall(0), curVarArgCalls(0)
    {
        visitor = this;
    }

    bool checkStructCoerceToBooleanError(Type* type)
    {
        // this can happen if typing fails elsewhere, which we'll already have an error for
        if (!type)
            return false;

        if (type->isStruct())
        {
            error("Boolean operation on Struct type: %s", type->getFullName().c_str());
            return true;
        }

        return false;

    }

    // checks for access violation on member for current class
    // public, private, protected
    bool checkAccessError(MemberInfo *memberInfo)
    {
        lmAssert(curClass, "Must have a current class");

        if (!memberInfo)
        {
            return false;
        }

        bool accessError = false;

        Type *dtype = memberInfo->getDeclaringType();

        // check if deprecated
        if (dtype != curClass->type)
        {
            // check whether member if deprecated
            MetaInfo   *deprecated = memberInfo->getMetaInfo("Deprecated");
            const char *msg;

            if (deprecated)
            {
                msg = deprecated->getAttribute("msg");

                if (msg)
                {
                    warning("Accessing deprecated member \"%s\" of type: %s (%s)", memberInfo->getName(), dtype->getFullName().c_str(), msg);
                }
                else
                {
                    warning("Accessing deprecated member \"%s\" of type: %s", memberInfo->getName(), dtype->getFullName().c_str());
                }
            }
            else
            {
                // check whether type itself is deprecated
                deprecated = dtype->getMetaInfo("Deprecated");

                if (deprecated)
                {
                    msg = deprecated->getAttribute("msg");

                    if (msg)
                    {
                        warning("Accessing member \"%s\" of deprecated type: %s (%s)", memberInfo->getName(), dtype->getFullName().c_str(), msg);
                    }
                    else
                    {
                        warning("Accessing member \"%s\" of deprecated type: %s", memberInfo->getName(), dtype->getFullName().c_str());
                    }
                }
            }
        }


        if (memberInfo->isPrivate() || memberInfo->isProtected())
        {
            // TODO: Better handing of transformed private calls for
            // primitives and object
            if (dtype->isPrimitive() || (dtype->getFullName() == "system.Object"))
            {
                return false;
            }

            if (memberInfo->isPrivate())
            {
                if (dtype != curClass->type)
                {
                    accessError = true;
                }
            }
            else
            {
                if ((dtype != curClass->type) && !curClass->type->isDerivedFrom(dtype))
                {
                    accessError = true;
                }
            }

            if (accessError)
            {
                error("Accessing %s member %s:%s",
                      memberInfo->isPrivate() ? "private" : "protected",
                      dtype->getFullName().c_str(),
                      memberInfo->getName());
            }
        }

        return accessError;
    }

    CompilationUnit *visit(CompilationUnit *cunit)
    {
        Scope::setVM(vm);

        this->cunit = cunit;


        TraversalVisitor::visit(cunit);

        Scope::setVM(NULL);

        return cunit;
    }

    bool isTemplateType(Type *type)
    {
        if ((type == Scope::resolveType("Vector")) || (type == Scope::resolveType("Dictionary")))
        {
            return true;
        }

        return false;
    }

    Statement *visitStatement(Statement *statement)
    {
        if (statement != NULL)
        {
            lineNumber = statement->lineNumber;
            statement  = TraversalVisitor::visitStatement(statement);
        }

        return statement;
    }

    PackageDeclaration *visit(PackageDeclaration *pkg)
    {
        PackageDeclaration *oldPackage = curPackage;

        curPackage = pkg;

        Scope::push(pkg);

        pkg = (PackageDeclaration *)TraversalVisitor::visit(pkg);

        Scope::pop();

        curPackage = oldPackage;

        return pkg;
    }

    ClassDeclaration *visit(ClassDeclaration *cls)
    {
        ClassDeclaration *oldClass = curClass;

        curClass = cls;

        if (curClass->type->isStruct())
        {
            if (!curClass->type->findOperatorMethod("__op_assignment"))
            {
                error("struct types must define assignment operator");
            }
        }

        cls->type->assignOrdinals();

        bool scriptClass = !cls->isNative();

        int             baseCount = 0;
        utStack<Type *> bases;
        Type            *base = cls->baseType;
        while (base)
        {
            if (scriptClass && !cls->isStatic && (base->isNativePure()))
            {
                error("Script class %s derived from pure native class %s.  Script classes may only be derived from managed and static native classes",
                      cls->name->string.c_str(), base->getFullName().c_str());
            }

            if ((cls->isStatic && !base->isStatic()) && (base->getFullName() != "system.Object"))
            {
                error("Static class %s derived from non-static class %s.",
                      cls->name->string.c_str(), base->getFullName().c_str());
            }

            bases.push(base);
            base = base->getBaseType();
        }

        if (!bases.empty())
        {
            Type *t = bases.pop();
            while (t)
            {
                Scope::push(t);
                baseCount++;

                t = NULL;
                if (!bases.empty())
                {
                    t = bases.pop();
                }
            }
        }

        Scope::push(cls);

        cls->name->type = cls->type;

        utArray<Statement *> *statements = cls->statements;

        if (statements != NULL)
        {
            errorFlag = false;

            // first pass do variables so we have valid implicit types
            // regardless where the definition appears in the class
            for (unsigned int i = 0; i < statements->size(); i++)
            {
                if ((*statements)[i]->astType == AST_VARSTATEMENT)
                    (*statements)[i] = visitStatement(statements->at(i));

                if (errorFlag)
                {
                    break;
                }
            }

            // now do the rest
            for (unsigned int i = 0; i < statements->size(); i++)
            {
                if ((*statements)[i]->astType != AST_VARSTATEMENT)
                    (*statements)[i] = visitStatement(statements->at(i));

                if (errorFlag)
                {
                    break;
                }

            }
        }

        lastVisited = cls;

        Scope::pop();

        // pop base classes
        while (baseCount--)
        {
            Scope::pop();
        }

        curClass = oldClass;

        // reset error status
        errorFlag = false;

        return cls;
    }

    FunctionLiteral *visit(FunctionLiteral *function)
    {
        FunctionLiteral *oldFunction = curFunction;

        functionStack.push(function);

        // hook into function hierarchy tracking
        if (oldFunction)
        {
            function->parentFunction = oldFunction;
            function->childIndex     = (int)oldFunction->childFunctions.size();
            oldFunction->childFunctions.push_back(function);
        }

        curFunction = function;

        if (function->classDecl)
        {
            if (function->classDecl->isStatic)
            {
                if (!function->isStatic)
                {
                    error("Static class %s defines non-static function %s",
                          function->classDecl->name->string.c_str(), function->name->string.c_str());
                }
            }
        }

        if (!function->classDecl)
        {
            // local function
            function->type = Scope::resolveType("system.Function");

            utString sretType = "Void";
            if (function->retType)
            {
                //FIXME: this needs to handle Vector<> and other complex types
                sretType = function->retType->string;
            }

            Type *retType = Scope::resolveType(sretType);

            if (!retType)
            {
                error("Unable to resolve function return type");
                return function;
            }

            function->templateTypes.push_back(retType);
        }

        for (UTsize i = 0; i < function->defaultArguments.size(); i++)
        {
            if (function->defaultArguments[i])
            {
                function->defaultArguments[i]->visitExpression(this);
            }
        }

        Scope::push(function, cunit);

        clearLastVisited();

        function = (FunctionLiteral *)TraversalVisitor::visit(function);

        // for methods/functions with return types ensure that we return a value
        // for final code path, all other code paths will use return statement
        // which we check in that AST node type
        if (!function->isNative)
        {
            if (!function->classDecl || (function->classDecl && !function->classDecl->isInterface))
            {
                if (function->retType && function->retType->type)
                {
                    if (function->retType->type->getFullName() != "system.Void")
                    {
                        if (!function->statements || !getLastVisited() || (getLastVisited()->astType != AST_RETURNSTATEMENT))
                        {
                            error("Return value of type %s required", function->retType->type->getFullName().c_str());
                        }
                    }
                }
            }
        }

        curFunction = oldFunction;

        functionStack.pop();

        Scope::pop();

        if (!function->classDecl && function->parameters)
        {
            for (UTsize i = 0; i < function->parameters->size(); i++)
            {
                VariableDeclaration *vd = function->parameters->at(i);
                if (!vd->type)
                {
                    error("Unable to resolve parameter %s",
                          vd->identifier->string.c_str());
                    return function;
                }

                function->templateTypes.push_back(vd->type);
            }
        }

        return function;
    }

    Expression *visit(Identifier *identifier)
    {
        utString istring = identifier->string;

        if (identifier->astTemplateInfo)
        {
            identifier->templateInfo = processTemplateInfo(identifier->astTemplateInfo);

            if (!identifier->templateInfo)
            {
                return identifier;
            }
        }

        if (!strncmp("__pset_", istring.c_str(), 7) || !strncmp("__pget_", istring.c_str(), 7))
        {
            istring = istring.substr(7, istring.size() - 7);
        }

        // first look in locals
        VariableDeclaration *vd = Scope::resolveLocalVar(istring);
        if (vd)
        {
            identifier->localVarDecl = vd;
            if (!identifier->templateInfo)
            {
                identifier->templateInfo = vd->templateInfo;
            }

            if (!vd->type)
            {
                // report error if not conflicting (which will already be reported)
                if (!checkFunctionStack(istring.c_str()))
                {
                    error("unable to resolve local variable decl type: %s", istring.c_str());
                }

                return identifier;
            }

            identifier->type = vd->type;
        }
        else
        {
            // next look in members
            MemberInfo *minfo = Scope::resolveMemberInfo(istring);

            if (minfo)
            {
                checkAccessError(minfo);

                //TODO: Walk up the function stack as we may be in a local function here
                if (curFunction)
                {
                    if ((curFunction->methodBase && curFunction->methodBase->isStatic()) && !minfo->isStatic())
                    {
                        error("Non-static member %s accessed from static method %s::%s", minfo->getName(), curFunction->methodBase->getDeclaringType()->getName(), curFunction->methodBase->getName());
                    }
                }

                identifier->memberInfo = minfo;
                TemplateInfo *tinfo = minfo->getTemplateInfo();

                // if we're a property, we need the template info off the return type
                // of the getter method
                if (minfo->isProperty())
                {
                    if (((PropertyInfo *)minfo)->getGetMethod())
                    {
                        tinfo = ((PropertyInfo *)minfo)->getGetMethod()->getTemplateInfo();
                    }
                }

                identifier->templateInfo = tinfo;
                identifier->type         = minfo->getType();

                if (!identifier->type)
                {
                    error("unable to resolve identifier type: %s",
                          istring.c_str());
                    return identifier;
                }
            }
            else
            {
                // next look in visible types
                if (!identifier->type)
                {
                    identifier->type = Scope::resolveType(istring);
                }
                if (identifier->primaryExpression && identifier->type && (identifier->string == identifier->type->getName()))
                {
                    identifier->typeExpression = true;
                    identifier->string         = identifier->type->getFullName();
                    identifier->type           = vm->getType("system.reflection.Type");
                }
            }
        }

        if (!(identifier->type || identifier->localVarDecl ||
              identifier->memberInfo))
        {
            if (Scope::scopeErrorString.length())
            {
                error(Scope::scopeErrorString.c_str());
                return identifier;
            }
            else
            {
                error("unable to resolve type for identifier %s", istring.c_str());
                return identifier;
            }
        }

        // process super property accessor
        if (identifier->superAccess)
        {
            if (!identifier->memberInfo)
            {
                error("No member for super access %s", istring.c_str());
                return identifier;
            }

            if (!identifier->memberInfo->isProperty())
            {
                error("Non property for super access %s", istring.c_str());
                return identifier;
            }


            Type *base = identifier->memberInfo->getDeclaringType()->getBaseType();

            if (!base)
            {
                error("No base type for member super access %s", istring.c_str());
                return identifier;
            }

            identifier->memberInfo = base->findMember(identifier->memberInfo->getName());


            if (!identifier->memberInfo)
            {
                error("No base member for super access %s:%s", base->getFullName().c_str(), istring.c_str());
                return identifier;
            }
        }

        return TraversalVisitor::visit(identifier);
    }

    Expression *visit(VariableDeclaration *vd)
    {
        if (vd->classDecl && vd->classDecl->isStatic)
        {
            if (!vd->isStatic)
            {
                error("Static class %s defines non-static var %s",
                      vd->classDecl->name->string.c_str(), vd->identifier->string.c_str());
            }
        }

        // check that variable is not the same name as any function in the function stack

        if (checkFunctionStack(vd->identifier->string.c_str()))
        {
            error("variable declaration %s conflicts with enclosing function of the same name", vd->identifier->string.c_str());
            return vd;
        }

        // check whether we already have type info (member variables)
        if (!vd->type)
        {
            vd->type = Scope::resolveType(vd->typeString);

            if (!vd->type)
            {
                error("unable to resolve variable declaration type");
                return vd;
            }
        }

        // if we have AST template info, process it
        if (vd->astTemplateInfo)
        {
            vd->templateInfo = processTemplateInfo(vd->astTemplateInfo);
            if (!vd->templateInfo)
            {
                return vd;
            }
        }

        // call the traversal visitor, which will traverse the initializer, etc
        vd = (VariableDeclaration *)TraversalVisitor::visit(vd);

        // implicit typing, note that if we're implicitly assigning type
        // from within a for..in or for..each loop, this is delayed
        // and handled in the ForInExpression visitor
        if (vd->assignType && !vd->assignForIn)
        {
            vd->assignType = false;

            if (!vd->initializer || !vd->initializer->type)
            {
                error("Unable to resolve initializer type: %s", vd->identifier->string.c_str());
                return vd;
            }

            vd->type = vd->initializer->type;

            Type *verifyImport = Scope::resolveType(vd->type->getFullName());
            if (!verifyImport)
            {
                error("Implicit usage of type %s, please import %s", vd->type->getName(), vd->type->getFullName().c_str());
            }

            // implicitly set member info
            if (vd->classDecl)
            {
                MemberInfo *mi = vd->classDecl->type->findMember(vd->identifier->string.c_str());
                if (mi)
                {
                    mi->setType(vd->type);
                }
            }

            if (isTemplateType(vd->type))
            {
                if (!vd->initializer->templateInfo)
                {
                    // process template info if it is available
                    if (vd->initializer->astTemplateInfo)
                    {
                        vd->initializer->templateInfo = processTemplateInfo(vd->initializer->astTemplateInfo);
                        if (!vd->initializer->templateInfo)
                        {
                            return vd;
                        }
                    }

                    // if we still don't have it, error
                    if (!vd->initializer->templateInfo)
                    {
                        error("Type cannot be inferred from right hand template type.  Please specify full type information for left hand expression.");
                        return vd;
                    }
                }


                if (!vd->templateInfo)
                {
                    vd->templateInfo = vd->initializer->templateInfo;
                }
            }

            Scope::setLocalType(vd->identifier->string, vd->type);
        }

        if (vd->initializer)
        {
            if (!vd->initializer->type)
            {
                error("Unable to resolve initializer type: %s", vd->identifier->string.c_str());
                return vd;
            }

            if (vd->type->isDelegate())
            {
                if (vd->initializer->memberInfo)
                {
                    if (!vd->initializer->memberInfo->isMethod())
                    {
                        error("right assign on delegate vardecl isn't a method");
                        return vd;
                    }


                    checkDelegateAssign(vd->type,
                                        (MethodInfo *)vd->initializer->memberInfo);
                }
                else if (vd->initializer->astType == AST_FUNCTIONLITERAL)
                {
                    checkDelegateAssign(vd->type,
                                        (FunctionLiteral *)vd->initializer);
                }
                else
                {
                    if ((vd->initializer->type->getFullName() != "system.Null") && (vd->initializer->type->getFullName() != "system.Function") &&
                        (vd->type != vd->initializer->type))
                    {
                        error("mismatched type on delegate assign");
                        return vd;
                    }
                }

                return vd;
            }

            // error checking
            if (!vd->defaultInitializer && vd->type->isStruct() &&
                (vd->initializer->type->getFullName() == "system.Null"))
            {
                error("Cannot assign null to struct type");
                return vd;
            }

            if (!vd->defaultInitializer && !vd->initializer->type->castToType(vd->type))
            {
                error("Unable to cast %s to %s",
                      vd->initializer->type->getFullName().c_str(),
                      vd->type->getFullName().c_str());
                return vd;
            }
        }

        return vd;
    }

    Expression *visit(PropertyExpression *p)
    {
        p = (PropertyExpression *)TraversalVisitor::visit(p);

        Expression *left  = p->leftExpression;
        Expression *right = p->rightExpression;

        utString leftString;
        utString rightString;

        if (left->astType == AST_IDENTIFIER)
        {
            Identifier *ident = (Identifier *)left;
            leftString = ident->string;
        }
        else if (left->astType == AST_STRINGLITERAL)
        {
            StringLiteral *literal = (StringLiteral *)left;
            leftString = literal->string;
        }
        else if (left->astType == AST_THISLITERAL)
        {
            leftString = "this";
        }

        if (right->astType == AST_IDENTIFIER)
        {
            Identifier *ident = (Identifier *)right;
            rightString = ident->string;
        }

        else if (right->astType == AST_STRINGLITERAL)
        {
            StringLiteral *literal = (StringLiteral *)right;
            rightString = literal->string;
        }

        Type *leftType = NULL;

        if (p->arrayAccess && ((left->astType == AST_PROPERTYEXPRESSION) || (left->astType == AST_CALLEXPRESSION)))
        {
            VariableDeclaration *varDecl = NULL;
            if (left->astType == AST_PROPERTYEXPRESSION)
            {
                PropertyExpression *pleft = (PropertyExpression *)left;
                varDecl = pleft->varDecl;
            }

            if (varDecl)
            {
                if (varDecl->templateInfo)
                {
                    TemplateInfo *tinfo = varDecl->templateInfo->getIndexedTemplateInfo();

                    p->templateInfo = tinfo;
                    p->type         = tinfo->getIndexedType();
                }
                else
                {
                    p->type = varDecl->type;
                }
            }
            else if (left->memberInfo)
            {
                TemplateInfo *tinfo = left->memberInfo->getTemplateInfo();

                // in the case of a property, we want the getter
                if (left->memberInfo->isProperty())
                {
                    PropertyInfo *pinfo = (PropertyInfo *)left->memberInfo;
                    if (pinfo->getGetMethod())
                    {
                        tinfo = pinfo->getGetMethod()->getTemplateInfo();
                    }
                }

                if (tinfo && tinfo->isTemplate())
                {
                    // we have a template type, so get the info

                    // get the (recursive) type of the template, that is the type of the [] indexer
                    tinfo = tinfo->getIndexedTemplateInfo();

                    p->templateInfo = tinfo;

                    if (tinfo->isTemplate())
                    {
                        // if we're a template, we need to use the next indexer type
                        p->type = tinfo->getIndexedType();
                    }
                    else
                    {
                        // otherwise, use the type itself
                        p->type = tinfo->type;
                    }
                }
                else
                {
                    p->type = left->memberInfo->getType();
                }
            }
            else
            {
                if (!left->templateInfo)
                {
                    error("Bad indexer");
                    return p;
                }
                else
                {
                    if (left->templateInfo->isTemplate())
                    {
                        TemplateInfo *tinfo = left->templateInfo->getIndexedTemplateInfo();

                        p->templateInfo = tinfo;

                        if (tinfo->isTemplate())
                        {
                            tinfo = tinfo->getIndexedTemplateInfo();
                        }

                        p->type = tinfo->type;
                    }
                    else
                    {
                        if (!left->templateInfo->types.size())
                        {
                            error("incomplete template info");
                            return p;
                        }


                        p->templateInfo = left->templateInfo->getIndexedTemplateInfo();
                        p->type         = left->templateInfo->getIndexedType();
                    }
                }
            }

            return p;
        }


        if (leftString.size() > 0)
        {
            // first check local variables
            if (p->arrayAccess)
            {
                if (leftString == "this")
                {
                    p->type = Scope::resolveLocal(leftString);
                    if (!p->type || ((p->type != Scope::resolveType("Vector")) && (p->type != Scope::resolveType("Dictionary"))))
                    {
                        error("this[] array access on non-template type");
                        return p;
                    }

                    if (right->type != Scope::resolveType("system.Number"))
                    {
                        error("Vector indexed with non-number");
                        return p;
                    }

                    // this[] vector access only happens in Vector/Dictionary which are final classes
                    // resolve this[] to Object (we don't have template type info)
                    p->type = Scope::resolveType("Object");
                    return p;
                }

                VariableDeclaration *vd = Scope::resolveLocalVar(leftString);

                if (vd)
                {
                    p->varDecl = vd;

                    if (vd->type == Scope::resolveType("Vector"))
                    {
                        if (!vd->templateInfo)
                        {
                            error("Untyped vector access");
                            return p;
                        }

                        p->type = vd->templateInfo->types[0]->type;

                        if (right->type != Scope::resolveType("system.Number"))
                        {
                            error("Vector indexed with non-number");
                            return p;
                        }
                    }
                    else if (vd->type == Scope::resolveType("Dictionary"))
                    {
                        if (!vd->templateInfo)
                        {
                            error("Untyped vector access");
                            return p;
                        }

                        p->type = vd->templateInfo->types[1]->type;

                        if (right->type->isNativePure())
                        {
                            error("Dictionary indexed with pure native class %s", right->type->getFullName().c_str());
                            return p;
                        }

                       if (!right->type->castToType(vd->templateInfo->types[0]->type))
                        {
                            error("unable to cast %s to %s for Dictionary index", right->type->getFullName().c_str(), vd->templateInfo->types[0]->type->getFullName().c_str());
                            return p;
                        }
 
                    }
                    else
                    {
                        if (p->arrayAccess)
                        {
                            if (vd->type)
                            {
                                error("Type %s indexed at symbol: %s.  Indexing supported on Vector and Dictionary types",
                                      vd->type->getFullName().c_str(), leftString.c_str());
                                return p;
                            }
                            else
                            {
                                error("Unknown type indexed at symbol: %s", leftString.c_str());
                                return p;
                            }
                        }
                        else
                        {
                            error("unknown type for symbol: %s", leftString.c_str());
                            return p;
                        }

                        return p;
                    }

                    if (!p->type)
                    {
                        error("unknown type for symbol: %s", leftString.c_str());
                    }



                    return p;
                }

                MemberInfo *memberInfo = Scope::resolveMemberInfo(leftString);
                if (!memberInfo)
                {
                    error("Unable to resolved Member Info %s", leftString.c_str());
                    return p;
                }

                p->memberInfo = memberInfo;

                if (p->memberInfo->getType()->isVector())
                {
                    if (right->type != Scope::resolveType("system.Number"))
                    {
                        error("Vector indexed with non-number");
                        return p;
                    }
                }

                if (memberInfo->getTemplateType())
                {
                    p->type = memberInfo->getTemplateInfo()->types[memberInfo->getTemplateInfo()->types.size() - 1]->type;
                }
                else
                {
                    error("unknown type for member %s", memberInfo->getFullMemberName());
                    return p;
                }

                return p;
            }

            // we're furthest left of any nested property expression
            if (left->type)
            {
                leftType = left->type; // the type has already been resolved
            }
            else
            {
                leftType = Scope::resolveType(leftString); // otherwise, search the scope hierarchy for the symbol
            }
            if (!leftType)
            {
                error("Unable to resolve type for %s", leftString.c_str());
                return p;
            }

            if (rightString.size() == 0)
            {
                error("Empty string for right property string");
                return p;
            }

            MemberInfo *memberInfo = leftType->findMember(rightString.c_str());

            if (!memberInfo)
            {
                error("Unable to resolve memberInfo %s:%s",
                      leftType->getFullName().c_str(), rightString.c_str());
                return p;
            }

            p->memberInfo     = memberInfo;
            right->memberInfo = memberInfo;

            if (p->arrayAccess)
            {
                if (memberInfo->getTemplateType())
                {
                    p->type = memberInfo->getTemplateInfo()->types[memberInfo->getTemplateInfo()->types.size() - 1]->type;
                }
                else
                {
                    error("array access on non template type");
                    return p;
                }
            }
            else
            {
                p->type = memberInfo->getType();
            }

            if (!p->type)
            {
                error("Unable to resolve property type");
                return p;
            }

            // check for static access of an instance member
            if (left->type && !strcmp(left->type->getName(), leftString.c_str()) && right->memberInfo)
            {
                // we are accessing a member staticly
                p->staticAccess = true;

                if (!right->memberInfo->isStatic())
                {
                    // some static access of instance methods is allowed
                    // we catch cases where it isn't in other methods
                    // of the type visitor
                    if (!right->memberInfo->isMethod())
                    {
                        error("static access of instance member %s:%s", left->type->getFullName().c_str(), right->memberInfo->getName());
                        return p;
                    }
                }
            }
        }
        else
        {
            leftType = left->type;

            if (!leftType)
            {
                error("Unable to resolve property type");
                return p;
            }

            if (p->arrayAccess)
            {
            }
            else
            {
                MemberInfo *memberInfo = leftType->findMember(rightString.c_str());
                if (!memberInfo)
                {
                    error("Unable to resolve member '%s'", rightString.c_str());
                    return p;
                }

                right->memberInfo = memberInfo;
                p->memberInfo     = memberInfo;
                p->type           = memberInfo->getType();

                if (!p->type)
                {
                    error("Unable to resolve property type");
                    return p;
                }
            }
        }

        // if we have a member, on a primitive type and it is an instance method
        // we need to transform to the matching static primitive method
        if (right->memberInfo && right->memberInfo->getDeclaringType()->isPrimitive() &&
            !right->memberInfo->isStatic() && right->memberInfo->isMethod())
        {
            // transform to static method on primitive type
            Type *ptype = right->memberInfo->getDeclaringType();

            // the idiom is to match the instance call to a private static method preceded with an underscore
            utString staticMethodName = "_";
            staticMethodName += right->memberInfo->getName();
            MemberInfo *staticMethod = ptype->findMember(staticMethodName.c_str());

            // do a bunch of checking
            lmAssert(staticMethod, "Primitive type %s missing static method %s", ptype->getName(), staticMethodName.c_str());
            lmAssert(staticMethod->isMethod(), "Primitive type %s static is not a method %s", ptype->getName(), staticMethodName.c_str());
            lmAssert(staticMethod->isStatic(), "Primitive type %s method %s is not static", ptype->getName(), staticMethodName.c_str());

            // transform the AST
            p->memberInfo     = staticMethod;
            p->type           = ((MethodInfo *)staticMethod)->getReturnType();
            right->memberInfo = staticMethod;
            right->type       = p->type;

            // we need to patch up the AST here as well, to index with the replaced method
            lmAssert(right->astType == AST_STRINGLITERAL, "transforming primitive method call on non-string literal");
            ((StringLiteral *)right)->string = staticMethod->getName();
        }

        if (right->memberInfo && right->memberInfo->getTemplateInfo())
        {
            p->templateInfo = right->memberInfo->getTemplateInfo();
        }

        if (right->memberInfo && (right->memberInfo->isField() || right->memberInfo->isProperty()))
        {
            checkAccessError(right->memberInfo);
        }

        return p;
    }

    Expression *visit(CallExpression *expression)
    {
        // reset nested varargs
        if (!nestedCall)
        {
            curVarArgCalls = 0;
        }

        nestedCall++;
        Expression *expr = _visit(expression);
        nestedCall--;
        return expr;
    }

    Expression *_visit(CallExpression *expression)
    {
        // this will visit all arguments
        expression = (CallExpression *)TraversalVisitor::visit(expression);

        MemberInfo *memberInfo = NULL;
        Type       *castType   = NULL;
        Type       *retType    = NULL;

        if (expression->function->astType == AST_IDENTIFIER)
        {
            if (!expression->function->type)
            {
                error("untyped call expression");
                return expression;
            }

            Identifier *function = (Identifier *)expression->function;
            memberInfo = function->memberInfo;

            // check if we're casting var a = Apple(o);
            if (expression->function->type->getFullName() == "system.reflection.Type")
            {
                castType = Scope::resolveType(function->string);
                if (!castType)
                {
                    error("Unable to retrieve type %s", function->string.c_str());
                    return expression;
                }

                // get the Object._as method.
                MemberInfo *_as = Scope::resolveType("system.Object")->findMember("_as");
                if (!_as || !_as->isMethod())
                {
                    error("unable to retrieve Object._as for cast");
                    return expression;
                }

                // fix up AST with the Object._as call
                expression->function       = new Identifier("_as");
                expression->function->type = Scope::resolveType("system.Function");
                function->memberInfo       = memberInfo = _as;

                if (!expression->arguments || (expression->arguments->size() > 1))
                {
                    error("Type cast requires exactly one argument");
                    return expression;
                }

                // add the parameters to the call
                Identifier* arg0 = new Identifier(castType->getName());
                arg0->type = Scope::resolveType("system.reflection.Type");
                expression->arguments->push_back(arg0);
            }
        }
        else if (expression->function->astType == AST_PROPERTYEXPRESSION)
        {
            PropertyExpression *p = (PropertyExpression *)expression->function;

            memberInfo = p->memberInfo;

            // if memberInfo is null, we're recovering from a previous error
            if (!memberInfo)
            {
                return p;
            }

            // catch static call of an instance method
            if (p->staticAccess && !memberInfo->isStatic())
            {
                error("static access of instance method %s:%s", memberInfo->getDeclaringType()->getName(), memberInfo->getName());
                return expression;
            }

            if (memberInfo)
            {
                // Vector.pop():T and Vector.shift():T
                if (memberInfo->getDeclaringType()->isVector())
                {
                    // rewrite vector.push(arg) to vector.pushSingle(arg)
                    // to avoid a vararg vector instantiation
                    if (!strcmp(memberInfo->getName(), "push"))
                    {
                        if (expression->arguments && (expression->arguments->size() == 1))
                        {
                            if (p->rightExpression->astType == AST_STRINGLITERAL)
                            {
                                StringLiteral *rewrite = (StringLiteral *)p->rightExpression;
                                rewrite->string     = "pushSingle";
                                rewrite->memberInfo = p->memberInfo = memberInfo = memberInfo->getDeclaringType()->findMember("pushSingle");
                                lmAssert(memberInfo, "Unable to retrieve pushSingle method from Vector");
                            }
                        }
                    }

                    if (!strcmp(memberInfo->getName(), "pop") ||
                        !strcmp(memberInfo->getName(), "shift"))
                    {
                        retType = p->rightExpression->type;

                        if (p->leftExpression->templateInfo)
                        {
                            retType = p->leftExpression->templateInfo->types[0]->type;
                        }
                    }
                }
            }

            // if we're a method on a primitive and private, we need to transform
            // the call arguments to take the primitive data type in arg0
            if (memberInfo->getDeclaringType()->isPrimitive() && memberInfo->isPrivate())
            {
                lmAssert(memberInfo->isMethod(), "non-method on transformed static call expression");

                expression->methodBase = (MethodBase *)memberInfo;
                expression->type       = ((MethodInfo *)memberInfo)->getReturnType();

                // we need to insert the primitive instance into the transformed
                // primitive static call at argument 0
                if (!expression->arguments || (expression->arguments->size() == 0))
                {
                    expression->arguments = new utArray<Expression *>();
                    expression->arguments->push_back(p->leftExpression);

                    // if it is missing, fill in a Function.call's null argument
                    if (!strcmp(memberInfo->getDeclaringType()->getName(), "Function") && !strcmp(memberInfo->getName(), "_call"))
                    {
                        NullLiteral *enull = new NullLiteral();
                        enull->type = Scope::resolveType("system.Null");
                        expression->arguments->push_back(enull);
                    }
                }
                else
                {
                    utArray<Expression *> arguments;
                    arguments.push_back(p->leftExpression);

                    for (UTsize i = 0; i < expression->arguments->size(); i++)
                    {
                        arguments.push_back(expression->arguments->at(i));
                    }

                    expression->arguments->clear();

                    *(expression->arguments) = arguments;
                }

                // alright, now we need to replace the left expression
                // with an identifier which represents the primitive class
                p->leftExpression       = new Identifier(memberInfo->getDeclaringType()->getName());
                p->leftExpression->type = memberInfo->getDeclaringType();
            }
        }
        else
        {
            error("CallExpression function is of unknown AST type");
            return expression;
        }


        utArray<Type *> parameters;

        // valid if method has variable arguments
        int varArgIdx  = -1;
        int defaultIdx = -1;

        if (memberInfo)
        {
            checkAccessError(memberInfo);

            Type *delegateType = NULL;
            bool doDelegate    = false;

            if (memberInfo->isMethod())
            {
                MethodInfo *methodInfo = (MethodInfo *)memberInfo;

                ParameterInfo *p;

                defaultIdx = methodInfo->getFirstDefaultParm();

                p = methodInfo->getVarArgParameter();
                if (p)
                {
                    varArgIdx = p->position;
                }

                if (!retType)
                {
                    retType = methodInfo->getReturnType();
                }

                expression->templateInfo = memberInfo->getTemplateInfo();

                for (int i = 0; i < methodInfo->getNumParameters(); i++)
                {
                    p = methodInfo->getParameter(i);

                    parameters.push_back(p->parameterType);
                }

                expression->methodBase = (MethodBase *)memberInfo;
            }
            else if (memberInfo->getTemplateType())
            {
                doDelegate = true;
                TemplateInfo *tinfo = memberInfo->getTemplateInfo();
                delegateType = tinfo->types[tinfo->types.size() - 1]->type;
            }
            else if (memberInfo->getType() == Scope::resolveType("system.Function"))
            {
                // Emit a call
                Type *otype = Scope::resolveType("system.Object");

                if (expression->arguments)
                {
                    for (UTsize i = 0; i < expression->arguments->size(); i++)
                    {
                        parameters.push_back(otype);
                    }
                }

                retType = otype;
            }
            else
            {
                doDelegate   = true;
                delegateType = memberInfo->getType();
            }

            if (doDelegate && delegateType && delegateType->isDelegate())
            {
                for (UTsize i = 0; i < delegateType->getNumDelegateTypes(); i++)
                {
                    parameters.push_back(delegateType->getDelegateType(i));
                }

                retType = delegateType->getDelegateReturnType();
            }
            else if (doDelegate)
            {
                if (memberInfo->isProperty())
                {
                    error("Attempting to call property member %s", memberInfo->getName());
                    return expression;
                }

                error("Unknown member %s", memberInfo->getName());
                return expression;
            }
        }
        else
        {
            //local/anonymous function
            Type *ftype = expression->function->type;

            if (!ftype)
            {
                error("Untyped call expression");
                return expression;
            }

            // for functions we just fill in the type info with system.Object for every arg given
            // and system.Object as return type, this is unsafe typewise, though flexible
            if (!strcmp(ftype->getFullName().c_str(), "system.Function"))
            {
                Type *otype = Scope::resolveType("system.Object");

                if (expression->arguments)
                {
                    for (UTsize i = 0; i < expression->arguments->size(); i++)
                    {
                        parameters.push_back(otype);
                    }
                }

                retType = otype;
            }
            else
            {
                // otherwise we must be a delegate (which is strongly typed for arguments and return values)
                if (!ftype->isDelegate())
                {
                    error("non-member call isn't a delegate: %s", ftype->getFullName().c_str());
                    return expression;
                }

                for (UTsize i = 0; i < ftype->getNumDelegateTypes(); i++)
                {
                    parameters.push_back(ftype->getDelegateType(i));
                }

                retType = ftype->getDelegateReturnType();
            }
        }

        if (castType)
        {
            retType = castType;
        }

        expression->type = retType;

        UTsize ncallargs = 0;
        if (expression->arguments)
        {
            ncallargs = expression->arguments->size();
        }
        UTsize nmethodargs = parameters.size();

        UTsize minArgs = nmethodargs;

        if (defaultIdx != -1)
        {
            minArgs = defaultIdx;
        }

        if ((varArgIdx != -1) && (defaultIdx == -1))
        {
            minArgs = varArgIdx;
        }

        if (varArgIdx != -1)
        {
            curVarArgCalls++;
            if (curVarArgCalls > curFunction->numVarArgCalls)
            {
                curFunction->numVarArgCalls = curVarArgCalls;
            }
        }

        if (ncallargs < minArgs)
        {
            if (memberInfo && memberInfo->isMethod())
            {
                error("call argument number mismatch: call %i method %i: %s:%s", ncallargs,
                      nmethodargs, memberInfo->getDeclaringType()->getFullName().c_str(), ((MethodInfo *)memberInfo)->getStringSignature().c_str());

                return expression;
            }
            else
            {
                error("call argument number mismatch: call %i method %i", ncallargs,
                      nmethodargs);

                return expression;
            }
        }

        if (((ncallargs > nmethodargs) && (varArgIdx == -1)))
        {
            if (!memberInfo)
            {
                error("call argument number mismatch: call %i method %i", ncallargs, nmethodargs);
            }
            else
            {
                error("call argument to %s::%s number mismatch: call %i method %i",
                      memberInfo->getDeclaringType()->getName(),
                      memberInfo->getName(), ncallargs, nmethodargs);
            }

            return expression;
        }
        else
        {
            if (expression->arguments)
            {
                for (UTsize i = 0; i < expression->arguments->size(); i++)
                {
                    // we don't type check varargs
                    if (i == varArgIdx)
                    {
                        break;
                    }

                    Expression *expr = expression->arguments->at(i);

                    if (!expr->type)
                    {
                        warning("Unable to resolve argument %i", i);
                        continue;
                    }

                    Type *parmType = parameters[i];

                    if (!parmType)
                    {
                        error("Unable to resolve parameter type for %i", i);
                        return expression;
                    }

                    if (parmType->isDelegate())
                    {
                        if (expr->memberInfo && expr->memberInfo->isMethod())
                        {
                            checkDelegateAssign(parmType,
                                                (MethodInfo *)expr->memberInfo);
                        }
                    }

                    else if (!expr->type->castToType(parmType))
                    {
                        utString fname = "Anonymous Function";

                        // If we're a method, display full function signature
                        if (memberInfo && memberInfo->isMethod())
                        {
                            fname = ((MethodInfo *)memberInfo)->getStringSignature().c_str();
                        }

                        error("type mismatch at argument %i, %s -> %s on %s",
                              i, expr->type->getFullName().c_str(),
                              parmType->getFullName().c_str(), fname.c_str());

                        return expression;
                    }
                }
            }
        }

        return expression;
    }

    Expression *visit(VectorLiteral *expression)
    {
        expression = (VectorLiteral *)TraversalVisitor::visit(expression);

        expression->type = Scope::resolveType("Vector");

        return expression;
    }

    Expression *visit(DictionaryLiteral *expression)
    {
        expression = (DictionaryLiteral *)TraversalVisitor::visit(expression);

        expression->type = Scope::resolveType("Dictionary");

        for (size_t i = 0; i  < expression->pairs.size(); i++)
        {
            Expression* key = expression->pairs[i]->key;
            if (key->type && key->type->isNativePure())
            {
                error("Pure native type %s used as Dictionary key", key->type->getFullName().c_str());
            }
        }

        return expression;
    }

    Expression *visit(NewExpression *expression)
    {
        expression = (NewExpression *)TraversalVisitor::visit(expression);

        if (expression->function->astType == AST_IDENTIFIER)
        {
            Identifier *identifier = (Identifier *)expression->function;
            if (identifier->astTemplateInfo)
            {
                expression->templateInfo = processTemplateInfo(identifier->astTemplateInfo);
                if (!expression->templateInfo)
                {
                    return expression;
                }
            }
        }

        Type *t = expression->type = expression->function->type;

        if (!t)
        {
            error("Unable to resolve type for new expression");
            return expression;
        }

        if (t != curClass->type)
        {
            MetaInfo *deprecated = t->getMetaInfo("Deprecated");
            if (deprecated)
            {
                const char *msg = deprecated->getAttribute("msg");
                if (msg)
                {
                    warning("Instantiating deprecated type: %s (%s)", t->getFullName().c_str(), msg);
                }
                else
                {
                    warning("Instantiating deprecated type: %s", t->getFullName().c_str());
                }
            }
        }

        if (t->isInterface())
        {
            error("Unable to instantiate interface: %s", t->getFullName().c_str());
            return expression;
        }

        // constructor parameter checking

        ConstructorInfo *ci = t->getConstructor();

        // if we don't have a constructor defined, the default
        // constructor takes zero args
        if (!ci && expression->arguments && expression->arguments->size())
        {
            error("Constructor for type %s takes no arguments", t->getFullName().c_str());
            return expression;
        }
        else if (ci)
        {
            validateMethodBaseCall((MethodBase *)ci, expression->arguments);
        }

        return expression;
    }

    Expression *visit(PropertyLiteral *literal)
    {
        Type *type = Scope::resolveType(literal->typeString);

        if (!type)
        {
            error("Unable to resolve type for Property Literal: %s", literal->typeString.c_str());
            return literal;
        }

        literal->type = type;

        literal = (PropertyLiteral *)TraversalVisitor::visit(literal);

        return literal;
    }

    Expression *visit(BooleanLiteral *literal)
    {
        literal = (BooleanLiteral *)TraversalVisitor::visit(literal);

        Type *type = Scope::resolveType("Boolean");

        if (!type)
        {
            error("Unable to resolve type for Boolean");
            return literal;
        }

        literal->type = type;

        return literal;
    }

    Expression *visit(ThisLiteral *literal)
    {
        if (!curClass || !curFunction)
        {
            error("this literal outside of class or function");
            return literal;
        }

        if (curFunction->isStatic)
        {
            error("this used in static function");
            return literal;
        }

        literal->type = curClass->type;

        if (!literal->type)
        {
            error("Unable to resolve type for this literal");
            return literal;
        }

        return TraversalVisitor::visit(literal);
    }

    Expression *visit(StringLiteral *literal)
    {
        literal = (StringLiteral *)TraversalVisitor::visit(literal);

        Type *type = Scope::resolveType("system.String");

        if (!type)
        {
            error("Unable to resolve type for String");
            return literal;
        }

        literal->type = type;

        return literal;
    }

    Expression *visit(NullLiteral *literal)
    {
        literal = (NullLiteral *)TraversalVisitor::visit(literal);

        Type *type = Scope::resolveType("system.Null");

        if (!type)
        {
            error("Unable to resolve type for system.Null");
            return literal;
        }

        literal->type = type;

        return literal;
    }

    Expression *visit(NumberLiteral *literal)
    {
        literal = (NumberLiteral *)TraversalVisitor::visit(literal);

        Type *type = Scope::resolveType("Number");

        if (!type)
        {
            error("Unable to resolve type for Number");
            return literal;
        }

        literal->type = type;

        return literal;
    }

    Type *getBinOpType(BinaryOperatorExpression *expression)
    {
        const Token *t          = expression->op;
        Tokens      *tok        = Tokens::getSingletonPtr();
        Type        *boolType   = Scope::resolveType("Boolean");
        Type        *numberType = Scope::resolveType("Number");

        if (t == &tok->OPERATOR_PLUS)
        {
            return numberType;
        }

        if (t == &tok->OPERATOR_MINUS)
        {
            return numberType;
        }

        if (t == &tok->OPERATOR_MULTIPLY)
        {
            return numberType;
        }

        if (t == &tok->OPERATOR_DIVIDE)
        {
            return numberType;
        }

        if (t == &tok->OPERATOR_MODULO)
        {
            return numberType;
        }

        if (t == &tok->OPERATOR_NOTEQUAL)
        {
            return boolType;
        }

        if (t == &tok->OPERATOR_EQUALEQUAL)
        {
            return boolType;
        }

        if (t == &tok->OPERATOR_LESSTHAN)
        {
            return boolType;
        }

        if (t == &tok->OPERATOR_LESSTHANOREQUAL)
        {
            return boolType;
        }

        if (t == &tok->OPERATOR_GREATERTHAN)
        {
            return boolType;
        }

        if (t == &tok->OPERATOR_GREATERTHANOREQUAL)
        {
            return boolType;
        }

        if (t == &tok->OPERATOR_LOGICALAND)
        {
            return boolType;
        }

        if (t == &tok->OPERATOR_LOGICALOR)
        {
            return boolType;
        }

        if (t == &tok->OPERATOR_SHIFTLEFT)
        {
            return numberType;
        }

        if (t == &tok->OPERATOR_SHIFTRIGHT)
        {
            return numberType;
        }

        if (t == &tok->OPERATOR_BITWISEAND)
        {
            return numberType;
        }

        if (t == &tok->OPERATOR_BITWISEOR)
        {
            return numberType;
        }

        if (t == &tok->OPERATOR_BITWISEXOR)
        {
            return numberType;
        }

        if (t == &tok->KEYWORD_AS)
        {
            return expression->rightExpression->type;
        }

        if (t == &tok->KEYWORD_IS)
        {
            return boolType;
        }

        if (t == &tok->KEYWORD_INSTANCEOF)
        {
            return boolType;
        }

        error("Unknown binary operator");
        return NULL;
    }

    Expression *visit(BinaryOperatorExpression *expression)
    {
        Tokens *tok = Tokens::getSingletonPtr();

        expression = (BinaryOperatorExpression *)TraversalVisitor::visit(
            expression);

        expression->type = NULL;

        Expression *left  = expression->leftExpression;
        Expression *right = expression->rightExpression;

        Type *stype = Scope::resolveType("system.String");

        if (!left->type || !right->type)
        {
            error("Untyped Binary Operator");
            return expression;
        }

        // check that types are related, unless we are using as/is to do so at runtime
        if ((expression->op != &tok->KEYWORD_AS) && (expression->op != &tok->KEYWORD_IS))
        {
            if (!right->type->castToType(left->type, true))
            {
                bool skip = false;

                // we can perform binary operations on enums
                if (left->type->isEnum() && right->type->isEnum())
                {
                    skip             = true;
                    expression->type = Scope::resolveType("system.Number");
                }

                // we skip for string concat
                if ((expression->op == &tok->OPERATOR_PLUS) && ((left->type->getFullName() == "system.String") || (right->type->getFullName() == "system.String")))
                {
                    skip = true;
                }

                if (!skip)
                {
                    error("unrelated types %s and %s in binary operator",
                          right->type->getFullName().c_str(),
                          left->type->getFullName().c_str());

                    return expression;
                }
            }
        }

        if (expression->op == &tok->KEYWORD_AS)
        {
            expression->type = right->type;
        }


        const char *opmethod = tok->getOperatorMethodName(expression->op);
        if (opmethod)
        {
            MemberInfo *mi = left->type->findMember(opmethod);
            if (mi)
            {
                if (!mi->isMethod())
                {
                    error("Non-method operator");
                    return expression;
                }

                MethodInfo *method = (MethodInfo *)mi;

                if (!method->isOperator())
                {
                    error("Non-operator method");
                    return expression;
                }

                if (method->getNumParameters() != 2)
                {
                    error("Binary operator requires method that takes 2 arguments");
                    return expression;
                }

                expression->type = method->getReturnType();
            }
        }

        if (!expression->type)
        {
            if ((expression->op == &tok->OPERATOR_PLUS) && ((left->type == stype) ||
                                                            (right->type == stype)))
            {
                expression->type = stype;
            }
            else
            {
                expression->type = getBinOpType(expression); //leftExpression->type;
            }
        }

        if (!expression->type)
        {
            error("Untyped Binary Operator");
            return expression;
        }

        return expression;
    }

    Statement *visit(ReturnStatement *returnStatement)
    {
        returnStatement = (ReturnStatement *)TraversalVisitor::visit(
            returnStatement);

        // method's return type
        Type *ftype = NULL;

        // return type of return value
        Type *rtype = NULL;


        // make sure we're returning the right kind of value for non-void methods/functions

        if (curFunction && curFunction->retType)
        {
            ftype = curFunction->retType->type;
        }

        if (returnStatement->result && (returnStatement->result->size() > 0))
        {
            rtype = returnStatement->result->at(0)->type;
        }

        if (ftype && !rtype)
        {
            if (ftype->getFullName() != "system.Void")
            {
                error("Empty return statement, %s required", ftype->getFullName().c_str());
                return returnStatement;
            }
        }

        if (rtype && ftype)
        {
            if (!rtype->castToType(ftype))
            {
                error("unable to cast %s to %s for return statement", rtype->getFullName().c_str(), ftype->getFullName().c_str());
                return returnStatement;
            }
        }

        return returnStatement;
    }

    void checkDelegateAssign(Type *delegate, MethodInfo *method)
    {
        if (method->getNumParameters() != delegate->getNumDelegateTypes())
        {
            error("mismatch on number of delegate vs method parameters");
            return;
        }

        for (int i = 0; i < method->getNumParameters(); i++)
        {
            if (method->getParameter(i)->parameterType
                != delegate->getDelegateType(i))
            {
                error("incorrect delegate parameter type at %i", i);
                return;
            }
        }

        if (method->getReturnType() != delegate->getDelegateReturnType())
        {
            error("method/delegate return types don't match");
            return;
        }
    }

    void checkDelegateAssign(Type *delegate, FunctionLiteral *literal)
    {
        if (!literal->parameters && delegate->getNumDelegateTypes())
        {
            error("mismatch on number of delegate vs method parameters %s",
                  delegate->getFullName().c_str());

            return;
        }

        if (literal->parameters &&
            (literal->parameters->size()
             != delegate->getNumDelegateTypes()))
        {
            error("mismatch on number of delegate vs method parameters %s",
                  delegate->getFullName().c_str());
            return;
        }

        for (UTsize i = 0; i < delegate->getNumDelegateTypes(); i++)
        {
            if (literal->parameters->at(i)->type
                != delegate->getDelegateType(i))
            {
                error("incorrect parameter type at %i", i);
                return;
            }
        }

        Type *rtype = Scope::resolveType("system.Void");
        if (literal->retType)
        {
            rtype = literal->retType->type;
        }

        if (rtype != delegate->getDelegateReturnType())
        {
            error("method/delegate return types don't match");
            return;
        }
    }

    AssignmentOperatorExpression *visit(AssignmentOperatorExpression *expr)
    {
        expr = (AssignmentOperatorExpression *)TraversalVisitor::visit(expr);

        Expression *left  = expr->leftExpression;
        Expression *right = expr->rightExpression;

        if (!left->type)
        {
            error("Untyped left expression on assignment operator");
            return expr;
        }

        if (!right->type)
        {
            error("Untyped right expression on assignment operator");
            return expr;
        }

        if ((left->type && left->type->isDelegate()) && right->type)
        {
            if (right->memberInfo)
            {
                if (!right->memberInfo->isMethod())
                {
                    error("right assign on delegate isn't a method");
                    return expr;
                }

                checkDelegateAssign(left->type,
                                    (MethodInfo *)right->memberInfo);
            }
            else
            {
                if ((right->type->getFullName() != "system.Null") && (right->type->getFullName() != "system.Function") &&
                    (right->type != left->type))
                {
                    error("mismatch delegate assign");
                    return expr;
                }
            }
        }

        return expr;
    }

    AssignmentExpression *visit(AssignmentExpression *expression)
    {
        expression = (AssignmentExpression *)TraversalVisitor::visit(
            expression);

        Expression *left  = expression->leftExpression;
        Expression *right = expression->rightExpression;

        if (!left->type)
        {
            error("Untyped left expression on assignment");
            return expression;
        }

        expression->type = left->type;

        if (!right->type)
        {
            error("Untyped right expression on assignment");
            return expression;
        }

        if (left->type->isStruct())
        {
            if (right->type->getFullName() == "system.Null")
            {
                error("Cannot assign null to a struct type");
                return expression;
            }
        }

        if ((left->type && left->type->isDelegate()) && right->type)
        {
            if (right->memberInfo)
            {
                if (!right->memberInfo->isMethod())
                {
                    error("right assign on delegate isn't a method");
                    return expression;
                }

                checkDelegateAssign(left->type,
                                    (MethodInfo *)right->memberInfo);
            }
            else
            {
                if ((right->type->getFullName() != "system.Null") && (right->type->getFullName() != "system.Function") &&
                    (right->type != left->type))
                {
                    error("mismatch delegate assign");
                    return expression;
                }
            }
        }
        else if (left->type && right->type)
        {
            if (!right->type->castToType(left->type))
            {
                if (right->type->getFullName() == "system.Void")
                {
                    error("Assigning Void to %s",
                          left->type->getFullName().c_str());
                    return expression;
                }

                bool skip = false;

                if ((left->type->getFullName() == "system.NativeDelegate") && (right->type->getFullName() == "system.Function"))
                {
                    skip = true;
                }

                if (!skip)
                {
                    error("type mismatch on assignment %s = %s", left->type->getFullName().c_str(), right->type->getFullName().c_str());
                    return expression;
                }
            }
        }

        return expression;
    }

    Expression *visit(YieldExpression *expression)
    {
        if (!curFunction)
        {
            error("yield outside of function");
            return expression;
        }

        TraversalVisitor::visit(expression);

        expression->type = Scope::resolveType("system.Object");

        curFunction->isCoroutine = true;
        return expression;
    }

    void validateMethodBaseCall(MethodBase *methodBase, utArray<Expression *> *arguments)
    {
        // methodBase parameter checking

        if (!methodBase)
        {
            return;
        }

        // calculate the number of provided arguments
        int nargs = 0;
        if (arguments)
        {
            nargs = (int)arguments->size();
        }

        // check on any default arguments or variable arguments
        int defaultIdx = methodBase->getFirstDefaultParm();
        int varArgIdx  = -1;

        if (methodBase->getVarArgParameter())
        {
            varArgIdx = methodBase->getVarArgParameter()->position;
        }

        // too many?

        int nparms = methodBase->getNumParameters();

        if ((nargs > nparms) && (varArgIdx == -1))
        {
            error("Too many arguments for method: %s", methodBase->getStringSignature().c_str());
            return;
        }

        // too few?
        if ((nargs < nparms) && (defaultIdx != -1))
        {
            if (nargs < defaultIdx)
            {
                error("Too few arguments (%i) for method: %s", nargs, methodBase->getStringSignature().c_str());
                return;
            }
        }
        else if (nargs < nparms)
        {
            error("Too few arguments (%i) for method: %s", nargs, methodBase->getStringSignature().c_str());
            return;
        }

        // now check that that arguments are a valid cast
        for (int i = 0; i < nargs && i < nparms; i++)
        {
            Type *argType = arguments->at(i)->type;
            if (!argType)
            {
                warning("Unable to resolve type for argument %i", i);
                continue;
            }

            if (!argType->castToType(methodBase->getParameter(i)->getParameterType()))
            {
                error("Unable to cast argument %i from %s to %s for method %s", i,
                      argType->getFullName().c_str(),
                      methodBase->getParameter(i)->getParameterType() ?
                      methodBase->getParameter(i)->getParameterType()->getFullName().c_str()
                      : "[UNKNOWN TYPE]",
                      methodBase->getStringSignature().c_str());
                return;
            }
        }
    }

    Expression *visit(SuperExpression *expression)
    {
        // start with the current method
        MethodBase *method = curFunction->methodBase;

        if (!method)
        {
            error("super called outside of method");
            return expression;
        }

        // traverse the super expression
        expression = (SuperExpression *)TraversalVisitor::visit(expression);

        // initial to the name of the current method
        utString baseMethodName = method->getName();

        // if we're a super.foo call, use the foo method instead
        if (expression->method)
        {
            baseMethodName = expression->method->string;
        }
        else
        {
            // mark the function as having a super() call
            curFunction->hasSuperCall = true;
        }

        if (!method->isConstructor())
        {
            // we're not in a constructor

            Type *type = method->getDeclaringType();

            if (!type)
            {
                error("Unable to resolve declaring type for super");
                return expression;
            }

            Type *baseType = type->getBaseType();

            if (!baseType)
            {
                error("super called with no base type");
                return expression;
            }

            // find the super method in the base class
            MemberInfo *mi = baseType->findMember(baseMethodName.c_str());

            if (mi)
            {
                if (!mi->isMethod())
                {
                    error("super called on non-method");
                    return expression;
                }

                MethodBase *methodBase = (MethodBase *)mi;
                Type       *declType   = methodBase->getDeclaringType();

                if (!declType)
                {
                    error("super call can't resolve super declaring type");
                    return expression;
                }

                expression->resolvedTypeName = declType->getFullName();

                // use return type of base method if we have it
                if (methodBase->isMethod())
                {
                    expression->type = ((MethodInfo *)methodBase)->getReturnType();
                }

                // validate before adding implicit this
                validateMethodBaseCall((MethodBase *)mi, &expression->arguments);

                // set the method to the base method
                method = (MethodBase *)mi;
            }
            else
            {
                error("invalid super call in method %s, unable to find a super method in parent classes", method->getStringSignature().c_str());
                return expression;
            }
        }
        else
        {
            // we're in a constructor super chain
            expression->type = method->getDeclaringType();

            Type *baseType = expression->type->getBaseType();

            bool checked = false;

            if (baseType)
            {
                utArray<MemberInfo *> cmembers;
                MemberTypes           mtypes;
                mtypes.constructor = true;

                baseType->findMembers(mtypes, cmembers);

                if (cmembers.size())
                {
                    ConstructorInfo *ci = (ConstructorInfo *)cmembers.at(0);

                    if (ci->isNative())
                    {
                        error("cannot super a native constructor");
                        return expression;
                    }


                    checked = true;
                    validateMethodBaseCall(ci, &expression->arguments);
                }
            }

            if (!checked && expression->arguments.size())
            {
                error("super call specifies too many arguments %s", method->getStringSignature().c_str());
                return expression;
            }
        }


        // for non static methods (and constructors) add an implicit this to
        // arguments
        if (!method->isStatic())
        {
            ThisLiteral *literal = new ThisLiteral();
            literal->type = method->getDeclaringType();

            utArray<Expression *> nargs;
            nargs.push_back(literal);

            for (UTsize i = 0; i < expression->arguments.size(); i++)
            {
                nargs.push_back(expression->arguments[i]);
            }

            expression->arguments = nargs;
        }

        return expression;
    }

    Expression *visit(UnaryOperatorExpression *expression)
    {
        Expression* subExpr = expression->subExpression;
        subExpr->visitExpression(this);

        int c = expression->op->value.str()[0];

        if (c == '!')
        {
            expression->type = Scope::resolveType("system.Boolean");

            if (checkStructCoerceToBooleanError(subExpr->type))
                return expression;

        }
        else if (c == '-')
        {
            expression->type = Scope::resolveType("system.Number");
        }
        else if (c == '~')
        {
            expression->type = Scope::resolveType("system.Number");
        }
        else
        {
            error("Unknown Unary Operator");
            return expression;
        }

        return expression;
    }

    Expression *visit(IncrementExpression *expression)
    {
        TraversalVisitor::visit(expression);

        expression->type = Scope::resolveType("system.Number");
        return expression;
    }

    Expression *visit(LogicalAndExpression *expression)
    {
        Type *boolType = Scope::resolveType("Boolean");

        expression->type = boolType;

        return TraversalVisitor::visit(expression);
    }

    Expression *visit(LogicalOrExpression *expression)
    {
        Type *boolType = Scope::resolveType("Boolean");

        expression->type = boolType;

        return TraversalVisitor::visit(expression);
    }

    Statement *visit(ForInStatement *forInStatement)
    {
        // mark thie node as the last visited
        lastVisited = forInStatement;


        // if we have a variable declaration and we are implicitly typing
        // this variable declaration, mark it as such this will delay
        // the type assignment which will be handled below
        VariableDeclaration *vd = NULL;
        if (forInStatement->variable && (forInStatement->variable->astType == AST_VARDECL))
        {
            vd = (VariableDeclaration *)forInStatement->variable;

            if (vd->assignType)
            {
                vd->assignForIn = true;
            }
        }

        forInStatement->variable = TraversalVisitor::visitExpression(forInStatement->variable);

        if (forInStatement->variable->memberInfo)
        {
            error("Member variables cannot be used as for..in iterators: %s", forInStatement->variable->memberInfo->getFullMemberName());
        }

        forInStatement->expression = TraversalVisitor::visitExpression(forInStatement->expression);

        if (!forInStatement->expression->type)
        {
            // the expression lacking type will have already raised an error
            return forInStatement;
        }

        TemplateInfo *tinfo = forInStatement->expression->templateInfo;

        if (!tinfo)
        {
            error("for .. in must iterate over a Vector or Dictionary");
            return forInStatement;
        }

        if (!tinfo->hasIndexedType() && !tinfo->hasIndexerType())
        {
            error("for..in iterating over a template type without indexed or indexer types");
            return forInStatement;
        }

        // implicit typing to key or value type
        if (vd && vd->assignType)
        {
            vd->assignType  = false;
            vd->assignForIn = false;

            if (forInStatement->foreach)
            {
                vd->type = forInStatement->expression->templateInfo->getIndexedType();
            }
            else
            {
                if (forInStatement->expression->templateInfo->isVector())
                {
                    vd->type = Scope::resolveType("system.Number");
                }
                else
                {
                    vd->type = forInStatement->expression->templateInfo->getIndexerType();
                }
            }

            Type *verifyImport = Scope::resolveType(vd->type->getFullName());
            if (!verifyImport)
            {
                error("Implicit usage of type %s, please import %s", vd->type->getName(), vd->type->getFullName().c_str());
            }

            // make sure we mark the type for local scope
            Scope::setLocalType(vd->identifier->string, vd->type);
        }

        forInStatement->statement = TraversalVisitor::visitStatement(forInStatement->statement);

        // make sure the iterator variable can be cast to the key or value type
        if (forInStatement->expression->templateInfo)
        {
            if (!forInStatement->variable->type)
            {
                // the expression lacking type will have already raised an error
                return forInStatement;
            }

            // depending on type of iteration we'll either be casting to key or value
            Type *castType = NULL;
            if (forInStatement->foreach)
            {
                castType = forInStatement->expression->templateInfo->getIndexedType();
            }
            else
            {
                if (forInStatement->expression->templateInfo->isVector())
                {
                    castType = Scope::resolveType("system.Number");
                }
                else
                {
                    castType = forInStatement->expression->templateInfo->getIndexerType();
                }
            }

            // make sure cast is valid
            if (!castType->castToType(forInStatement->variable->type))
            {
                // back up the line number to the forInStatement as
                // we have already traversed the loop statements
                lineNumber = forInStatement->lineNumber;
                error("Unable to cast %s to %s in for .. in initializer",
                      castType->getFullName().c_str(),
                      forInStatement->variable->type->getFullName().c_str());
                return forInStatement;
            }
        }

        return forInStatement;
    }

    Expression *visit(DeleteExpression *expression)
    {
        TraversalVisitor::visit(expression);

        error("delete expression is not implemented");

        return expression;
    }

    Expression *visit(MultipleAssignmentExpression *expression)
    {
        error("multiple assignment expression is not implemented");
        return expression;
    }

    Statement *visit(IfStatement *ifStatement)
    {
        TraversalVisitor::visit(ifStatement);

        if (ifStatement->expression)
            checkStructCoerceToBooleanError(ifStatement->expression->type);

        return ifStatement;
    }

    Statement *visit(WhileStatement *whileStatement)
    {
        TraversalVisitor::visit(whileStatement);

        if (whileStatement->expression)
            checkStructCoerceToBooleanError(whileStatement->expression->type);

        return whileStatement;
    }

    Statement *visit(ForStatement *forStatement)
    {
        TraversalVisitor::visit(forStatement);

        if (forStatement->condition)
            checkStructCoerceToBooleanError(forStatement->condition->type);

        return forStatement;
    }

    Expression *visit(ConditionalExpression *expression)
    {
        expression = (ConditionalExpression *)TraversalVisitor::visit(expression);
            
        //LOOM-1837: verify false expression type
        expression->type = expression->trueExpression->type;

        if (expression->expression)
            checkStructCoerceToBooleanError(expression->expression->type);

        return expression;
    }




};
}
#endif
