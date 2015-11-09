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

#include "loom/script/compiler/lsCompiler.h"
#include "loom/script/compiler/lsTypeCompilerBase.h"

#include "loom/script/reflection/lsFieldInfo.h"
#include "loom/script/reflection/lsPropertyInfo.h"

#include "loom/script/runtime/lsProfiler.h"

#if LOOM_ENABLE_JIT

extern "C" {
#include "lj_obj.h"
#include "lj_bcdump.h"
}

#else 

// Some shims to let us write code with LuaJIT conventions but work against classic.
#define VKNIL VNIL
#define VKTRUE VTRUE
#define VKFALSE VFALSE
#define setnumV(var, val) *(var) = val;

#endif

namespace LS  {

int TypeCompilerBase::luaByteCodewriter(lua_State *L, const void *p, size_t size,
                             void *u)
{
    UNUSED(L);

    utArray<unsigned char> *bytecode = (utArray<unsigned char> *)u;

    unsigned char *data = (unsigned char *)p;
    for (size_t i = 0; i < size; i++, data++)
    {
        bytecode->push_back(*data);
    }
    
    return 0;
}

void TypeCompilerBase::_compile()
{
    vm    = cls->type->getModule()->getAssembly()->getLuaState();
    L     = vm->VM();
    cunit = cls->pkgDecl->compilationUnit;

    BC::L = L;
    BC::currentFilename = cunit->filename.c_str();

    generateStaticInitializer();
    generateInstanceInitializer();


    MemberTypes types;
    types.method = true;
    utArray<MemberInfo *> methods;
    cls->type->findMembers(types, methods);

    if (cls->constructor)
    {
        MethodBase *mb = (MethodBase *)cls->type->getConstructor();

        lmAssert(mb, "Missing constructor method base");
        lmAssert(mb->isConstructor(), "constructor method base is not a constructor");

        generateConstructor(cls->constructor, (ConstructorInfo *)mb);
    }

    // methods
    for (UTsize i = 0; i < methods.size(); i++)
    {
        MethodBase *mb = (MethodBase *)methods.at(i);

        MethodInfo *method = (MethodInfo *)mb;

        FunctionLiteral *function = NULL;

        // find the corresponding function literal
        for (UTsize j = 0; j < cls->functionDecls.size(); j++)
        {
            FunctionLiteral *f = cls->functionDecls.at(j);
            if (f->name->string == method->getName())
            {
                function = f;
                break;
            }
        }

        lmAssert(function, "missing function");

        generateMethod(function, method);
    }

    // properties
    types.clear();
    types.property = true;
    utArray<MemberInfo *> properties;
    cls->type->findMembers(types, properties);
    for (UTsize i = 0; i < properties.size(); i++)
    {
        PropertyInfo *pinfo = (PropertyInfo *)properties[i];

        // find the corresponding property literal
        PropertyLiteral *plit = NULL;
        for (UTsize j = 0; j < cls->properties.size(); j++)
        {
            PropertyLiteral *p = cls->properties.at(j);
            if (p->name == pinfo->getName())
            {
                plit = p;
                break;
            }
        }

        if (plit->getter)
        {
            MethodInfo *getter = pinfo->getGetMethod();
            lmAssert(getter, "missing getter");
            generateMethod(plit->getter, getter);
        }

        if (plit->setter)
        {
            MethodInfo *setter = pinfo->getSetMethod();
            lmAssert(setter, "missing setter");
            generateMethod(plit->setter, setter);
        }

        lmAssert(plit, "missing property literal");
    }
}


void TypeCompilerBase::generateIdentifierTypeConversion(Identifier *identifier)
{
    // We're a Type, so we need to query reflection

    FuncState *fs = cs->fs;

    utArray<Expression *> args;
    StringLiteral         *fullTypeName = new StringLiteral(identifier->string.c_str());
    args.push_back(fullTypeName);

    ExpDesc opcall;
    ExpDesc emethod;

    BC::singleVar(cs, &opcall, "Type");
    BC::expString(cs, &emethod, "getTypeByName");

    BC::expToNextReg(fs, &opcall);
    BC::expToNextReg(fs, &emethod);
    BC::expToVal(fs, &emethod);
    BC::indexed(fs, &opcall, &emethod);

    identifier->e = opcall;

    generateCall(&identifier->e, &args,
                 (MethodBase *)vm->getType("system.reflection.Type")->findMember("getTypeByName"));

    // we're done with our expression, so delete it
    delete (StringLiteral *)args[0];
}

utArray<Statement *> *TypeCompilerBase::visitStatementArray(utArray<Statement *> *_statements)
{
    if (_statements != NULL)
    {
        utArray<Statement *>& statements = *_statements;

        for (unsigned int i = 0; i < statements.size(); i++)
        {
            statements[i] = visitStatement(statements[i]);
        }
    }
    
    return _statements;
}

utArray<Expression *> *TypeCompilerBase::visitExpressionArray(utArray<Expression *> *_expressions)
{
    if (_expressions != NULL)
    {
        utArray<Expression *>& expressions = *_expressions;

        for (unsigned int i = 0; i < expressions.size(); i++)
        {
            expressions[i] = visitExpression(expressions[i]);
        }
    }

    return _expressions;
}


Expression *TypeCompilerBase::visitExpression(Expression *expression)
{
    if (expression != NULL)
    {
        expression = expression->visitExpression(this);
    }
    
    return expression;
}

CompilationUnit *TypeCompilerBase::visit(CompilationUnit *cunit)
{
    return cunit;
}

Statement *TypeCompilerBase::visit(FunctionDeclaration *declaration)
{
    lmAssert(0, "FunctionDeclaration");

    return declaration;
}


Statement *TypeCompilerBase::visit(PropertyDeclaration *declaration)
{
    lmAssert(0, "PropertyDeclaration");
    
    return declaration;
}

Statement *TypeCompilerBase::visit(BlockStatement *statement)
{
    chunk(statement->statements);

    return statement;
}

Statement *TypeCompilerBase::visit(EmptyStatement *statement)
{
    return statement;
}


Statement *TypeCompilerBase::visit(ExpressionStatement *statement)
{
    statement->expression->visitExpression(this);
    
    return statement;
}

Statement *TypeCompilerBase::visit(LabelledStatement *statement)
{
    lmAssert(0, "LabelledStatement");

    return statement;
}

Statement *TypeCompilerBase::visit(VariableStatement *statement)
{
    for (unsigned int i = 0; i < statement->declarations->size(); i++)
    {
        VariableDeclaration *d = statement->declarations->at(i);
        d->visitExpression(this);
    }

    return statement;
}

Statement *TypeCompilerBase::visit(WithStatement *statement)
{
    lmAssert(0, "WithStatement");
    return statement;
}


Statement *TypeCompilerBase::visit(ClassDeclaration *statement)
{
    lmAssert(0, "ClassDeclaration");
    return statement;
}


Statement *TypeCompilerBase::visit(InterfaceDeclaration *statement)
{
    lmAssert(0, "InterfaceDeclaration");
    return statement;
}


Statement *TypeCompilerBase::visit(PackageDeclaration *statement)
{
    lmAssert(0, "PackageDeclaration");
    return statement;
}


Statement *TypeCompilerBase::visit(ImportStatement *statement)
{
    lmAssert(0, "ImportStatement");
    return statement;
}

Expression *TypeCompilerBase::visit(MultipleAssignmentExpression *expression)
{
    lmAssert(0, "MultipleAssignmentExpression");
    return expression;
}

Expression *TypeCompilerBase::visit(DeleteExpression *expression)
{
    lmAssert(0, "DeleteExpression");
    return expression;
}

Expression *TypeCompilerBase::visit(LogicalAndExpression *expression)
{
    return visit((BinaryOperatorExpression *)expression);
}

Expression *TypeCompilerBase::visit(LogicalOrExpression *expression)
{
    return visit((BinaryOperatorExpression *)expression);
}

Expression *TypeCompilerBase::visit(CallExpression *call)
{
    MethodBase *methodBase = call->methodBase;

    call->function->visitExpression(this);

    // check whether we're calling a methodbase
    if (methodBase)
    {
        lmAssert(methodBase->isMethod(), "Non-method called");

        MethodInfo *method = (MethodInfo *)methodBase;
        generateCall(&call->function->e, call->arguments, method);

        call->e = call->function->e;
    }
    else
    {
        lmAssert(call->function->type, "Untyped call");

        // if we're calling a delegate we need to load up the call method
        if (call->function->type->isDelegate())
        {
            MethodInfo *method = (MethodInfo *)call->function->type->findMember("call");

            lmAssert(method, "delegate with no call method");

            ExpDesc right;

            BC::initExpDesc(&right, VKNUM, 0);
            setnumV(&right.u.nval, method->getOrdinal());


            BC::expToNextReg(cs->fs, &call->function->e);
            BC::expToNextReg(cs->fs, &right);
            BC::expToVal(cs->fs, &right);
            BC::indexed(cs->fs, &call->function->e, &right);

            generateCall(&call->function->e, call->arguments, NULL);
            call->e = call->function->e;
        }
        else
        {
            // we're directly calling a local, instance (bound), or static method of type Function
            generateCall(&call->function->e, call->arguments, NULL);
            call->e = call->function->e;
        }
    }
    
    return call;
}


void TypeCompilerBase::createVarArg(ExpDesc *varg, utArray<Expression *> *arguments,
                                   int startIdx)
{
    char varargname[1024];

    sprintf(varargname, "__ls_vararg%i", currentFunctionLiteral->curVarArgCalls++);
    lmAssert(currentFunctionLiteral->numVarArgCalls > 0, "0 numVarArgs");
    currentFunctionLiteral->curVarArgCalls %= currentFunctionLiteral->numVarArgCalls;

    FuncState *fs = cs->fs;

    int reg = fs->freereg;

    ExpDesc nvector;
    createInstance(&nvector, "system.Vector", NULL);

    ExpDesc evector;
    BC::singleVar(cs, &evector, varargname);
    BC::storeVar(fs, &evector, &nvector);

    if (!arguments || !arguments->size())
    {
        *varg = evector;
        return;
    }

    // load the vector value table
    ExpDesc vtable;
    BC::singleVar(cs, &vtable, varargname);
    BC::expToNextReg(fs, &vtable);

    ExpDesc v;
    BC::initExpDesc(&v, VKNUM, 0);
    setnumV(&v.u.nval, LSINDEXVECTOR);

    BC::expToNextReg(fs, &v);
    BC::expToVal(fs, &v);
    BC::indexed(fs, &vtable, &v);
    BC::expToNextReg(fs, &vtable);

    // set the length of the varargs vector
    ExpDesc elength;
    BC::initExpDesc(&elength, VKNUM, 0);
    setnumV(&elength.u.nval, LSINDEXVECTORLENGTH);

    BC::expToNextReg(fs, &elength);
    BC::expToVal(fs, &elength);
    BC::indexed(fs, &vtable, &elength);

    BC::initExpDesc(&elength, VKNUM, 0);

    setnumV(&elength.u.nval, arguments->size() - startIdx);

    // and store
    BC::storeVar(fs, &vtable, &elength);

    utArray<Expression *> args;
    int length = 0;
    for (UTsize i = startIdx; i < arguments->size(); i++)
    {
        Expression *arg = arguments->at(i);

        int restore = fs->freereg;

        BC::initExpDesc(&v, VKNUM, 0);
        setnumV(&v.u.nval, length);

        BC::expToNextReg(fs, &v);
        BC::expToVal(fs, &v);

        BC::indexed(fs, &vtable, &v);

        arg->visitExpression(this);

        BC::storeVar(fs, &vtable, &arg->e);
        length++;

        fs->freereg = restore;
    }

    BC::singleVar(cs, &evector, varargname);
    BC::expToNextReg(fs, &evector);

    fs->freereg = reg;

    BC::singleVar(cs, varg, varargname);
}

int TypeCompilerBase::expList(ExpDesc *e, utArray<Expression *> *expressions,
                             MethodBase *methodBase)
{
    ParameterInfo *vararg = NULL;

    if (methodBase)
    {
        vararg = methodBase->getVarArgParameter();
    }

    if (!expressions && !vararg)
    {
        return 0;
    }

    if (!expressions && vararg)
    {
        lmAssert(vararg->position == 0, "Bad position on variable args");
        createVarArg(e, NULL, vararg->position);
        return 1;
    }

    int count = 0;

    if (expressions)
    {
        for (unsigned int i = 0; i < expressions->size(); i++)
        {
            Expression *ex = expressions->at(i);

            if (vararg && (vararg->position == i))
            {
                if (i)
                {
                    BC::expToNextReg(cs->fs, e);
                }
                
                createVarArg(e, expressions, vararg->position);
                count++;
                return count;
            }
            
            ex->visitExpression(this);
            
            if (i != expressions->size() - 1)
            {
                BC::expToNextReg(cs->fs, &ex->e);
            }
            
            *e = ex->e;
            count++;
        }
    }
    
    if (vararg)
    {
        if (expressions && expressions->size())
        {
            BC::expToNextReg(cs->fs, e);
        }
        
        createVarArg(e, expressions, vararg->position);
        count++;
    }
    
    return count;
}

Expression *TypeCompilerBase::visit(NewExpression *expression)
{
    FuncState *fs = cs->fs;

    Type *type = expression->function->type;

    lmAssert(type, "Untyped new expression");

    ExpDesc e;
    createInstance(&e, type->getFullName(), expression->arguments);

    if ((expression->function->astType == AST_VECTORLITERAL) || (expression->function->astType == AST_DICTIONARYLITERAL))
    {
        // assign new instance
        expression->function->e = e;

        BC::expToNextReg(fs, &e);

        int restore = fs->freereg;

        // visit literal
        expression->function->visitExpression(this);
        
        fs->freereg = restore;
    }
    
    expression->e = e;
    
    return expression;
}


Expression *TypeCompilerBase::visit(VariableExpression *expression)
{
    for (UTsize i = 0; i < expression->declarations->size(); i++)
    {
        VariableDeclaration *v = expression->declarations->at(i);
        v->visitExpression(this);
        expression->e = v->identifier->e;
    }

    return expression;
}

Expression *TypeCompilerBase::visit(SuperExpression *expression)
{
    lmAssert(currentMethod, "Super call outside of method");

    Type *type     = currentMethod->getDeclaringType();
    Type *baseType = type->getBaseType();

    //FIXME:  issue a warning
    if (!baseType)
    {
        return expression;
    }

    FuncState *fs = cs->fs;

    if (currentMethod->isConstructor())
    {
        ConstructorInfo *base = baseType->getConstructor();

        //FIXME: warn if no base constructor
        if (!base)
        {
            return expression;
        }

        // load up base class
        ExpDesc eclass;
        BC::singleVar(cs, &eclass, baseType->getFullName().c_str());

        // index with the __ls_constructor
        BC::expToNextReg(fs, &eclass);

        ExpDesc fname;
        BC::expString(cs, &fname, "__ls_constructor");

        BC::expToNextReg(fs, &fname);
        BC::expToVal(fs, &fname);
        BC::indexed(fs, &eclass, &fname);

        // call the LSMethod
        generateCall(&eclass, &expression->arguments);
    }
    else
    {
        utString name = currentMethod->getName();

        if (expression->method)
        {
            name = expression->method->string;
        }

        MemberInfo *mi = baseType->findMember(name.c_str());
        //FIXME: warn
        if (!mi)
        {
            return expression;
        }

        lmAssert(mi->isMethod(), "super call on non-method");

        MethodInfo *methodInfo = (MethodInfo *)mi;

        // load up declaring class
        ExpDesc eclass;
        BC::singleVar(cs, &eclass,
                      methodInfo->getDeclaringType()->getFullName().c_str());

        BC::expToNextReg(fs, &eclass);

        ExpDesc fname;
        BC::expString(cs, &fname, name.c_str());

        BC::expToNextReg(fs, &fname);
        BC::expToVal(fs, &fname);
        BC::indexed(fs, &eclass, &fname);

        // call the LSMethod
        generateCall(&eclass, &expression->arguments);

        expression->e = eclass;
    }

    return expression;
}

Expression *TypeCompilerBase::visit(ThisLiteral *literal)
{
    BC::singleVar(cs, &literal->e, "this");

    return literal;
}


Expression *TypeCompilerBase::visit(NullLiteral *literal)
{
    BC::initExpDesc(&literal->e, VKNIL, 0);

    return literal;
}


Expression *TypeCompilerBase::visit(BooleanLiteral *literal)
{
    if (literal->value)
    {
        BC::initExpDesc(&literal->e, VKTRUE, 0);
    }
    else
    {
        BC::initExpDesc(&literal->e, VKFALSE, 0);
    }

    return literal;
}


Expression *TypeCompilerBase::visit(NumberLiteral *literal)
{
    ExpDesc e;
    BC::initExpDesc(&e, VKNUM, 0);

    setnumV(&e.u.nval, literal->value);

    literal->e = e;
    
    return literal;
}

Expression *TypeCompilerBase::visit(ArrayLiteral *literal)
{
    lmAssert(0, "ArrayLiteral");
    return literal;
}

Expression *TypeCompilerBase::visit(ObjectLiteral *literal)
{
    lmAssert(0, "ObjectLiteral");
    return literal;
}


Expression *TypeCompilerBase::visit(ObjectLiteralProperty *property)
{
    lmAssert(0, "ObjectLiteralProperty");
    return property;
}


Expression *TypeCompilerBase::visit(PropertyLiteral *property)
{
    lmAssert(0, "PropertyLiteral");
    return property;
}


Expression *TypeCompilerBase::visit(DictionaryLiteralPair *pair)
{
    return pair;
}

Expression *TypeCompilerBase::visit(DictionaryLiteral *literal)
{
    FuncState *fs = cs->fs;

    for (UTsize i = 0; i < literal->pairs.size(); i++)
    {
        int restore = fs->freereg;

        DictionaryLiteralPair *pair = literal->pairs[i];

        // comes in from NewExpression visitor
        ExpDesc ethis = literal->e;

        BC::expToNextReg(fs, &ethis);

        pair->key->visitExpression(this);

        BC::expToNextReg(fs, &pair->key->e);
        BC::expToVal(fs, &pair->key->e);
        BC::indexed(fs, &ethis, &pair->key->e);
        
        pair->value->visitExpression(this);
        BC::storeVar(fs, &ethis, &pair->value->e);
        
        fs->freereg = restore;
    }
    
    return literal;
}

Expression *TypeCompilerBase::visit(VariableDeclaration *declaration)
{
    FuncState *fs = cs->fs;

    // local variable declaration
    lmAssert(!declaration->classDecl, "local variable declaration belongs to a class");

    ExpDesc v;
    BC::singleVar(cs, &v, declaration->identifier->string.c_str());

    Type       *dt     = declaration->type;
    MethodInfo *method = NULL;
    method = (MethodInfo *)dt->findMember("__op_assignment");

    //TODO: assignment overload in default args?
    if (declaration->isParameter)
    {
        method = NULL;
    }

    if (method)
    {
        if (dt->isStruct())
        {
            generateVarDeclStruct(declaration);
        }
        else if (dt->isDelegate())
        {
            generateVarDeclDelegate(declaration);
        }
        else
        {
            lmAssert(0, "unexpected __op_assignment on non delegate or struct");
        }
        
        return declaration;
    }
    
    else
    {
        lmAssert(!dt->isDelegate() && !dt->isStruct(),
                 "unexpected delegate/struct");
        
        fs->freereg = fs->nactvar; /* free registers */
        declaration->identifier->visitExpression(this);
        declaration->initializer->visitExpression(this);
        BC::storeVar(fs, &declaration->identifier->e,
                     &declaration->initializer->e);
    }
    
    return declaration;
}


Statement *TypeCompilerBase::visit(ThrowStatement *statement)
{
    // Emit a call to Debug.assertException.
    FuncState *fs = cs->fs;
    ExpDesc   object, method;
    BC::singleVar(cs, &object, "Debug");
    BC::expString(cs, &method, "assertException");

    BC::expToNextReg(fs, &object);
    BC::expToVal(fs, &method);
    BC::indexed(fs, &object, &method);

    utArray<Expression *> args;
    args.push_back(statement->expression);

    generateCall(&object, &args);

    return statement;
}


Statement *TypeCompilerBase::visit(TryStatement *statement)
{
    // Just process the try and finally blocks.
    statement->tryBlock->visitStatement(this);
    statement->finallyBlock->visitStatement(this);

    return statement;
}


Expression *TypeCompilerBase::visit(PropertyExpression *expression)
{
    FuncState *fs = cs->fs;

    Expression *eleft  = expression->leftExpression;
    Expression *eright = expression->rightExpression;

    ExpDesc left;
    ExpDesc right;

    // handle property access

    if (!expression->arrayAccess && eright->memberInfo &&
        eright->memberInfo->isProperty())
    {
        // property access in the form of foo.bar

        bool primitive = eright->memberInfo->getDeclaringType()->isPrimitive() && expression->staticAccess == false;

        if (!primitive)
        {
            // non-primitive property path

            eleft->visitExpression(this);
            left = eleft->e;

            BC::expToNextReg(cs->fs, &left);

            bool    getter = false;
            ExpDesc right;

            lmAssert(eright->memberInfo->isProperty(), "right member is not a PropertyInfo");

            PropertyInfo *prop = (PropertyInfo *)eright->memberInfo;

            bool isInterface = prop->getDeclaringType()->isInterface();

            if (isInterface)
            {
                utString pstring;

                // getter
                if (!expression->assignment)
                {
                    // getter
                    pstring = "__pget_";
                    getter  = true;
                }
                else
                {
                    // setter
                    pstring = "__pset_";
                }

                pstring += eright->memberInfo->getName();
                BC::expString(cs, &right, pstring.c_str());
            }
            else
            {
                memset(&right, 0, sizeof(ExpDesc));
                BC::initExpDesc(&right, VKNUM, 0);

                // getter
                if (!expression->assignment)
                {
                    // getter
                    getter = true;

                    MethodBase *mb = prop->getGetMethod();

                    lmAssert(mb, "missing getter for %s on %s:%d", prop->getFullMemberName(), cunit->filename.c_str(), expression->lineNumber);

#ifdef LOOM_ENABLE_JIT
                    setnumV(&right.u.nval, mb->getOrdinal());
#else
                    right.u.nval = mb->getOrdinal();
#endif
                }
                else
                {
                    // setter
                    MethodBase *mb = prop->getSetMethod();

                    lmAssert(mb, "missing setter for %s on %s:%d", prop->getFullMemberName(), cunit->filename.c_str(), expression->lineNumber);

#ifdef LOOM_ENABLE_JIT
                    setnumV(&right.u.nval, mb->getOrdinal());
#else
                    right.u.nval = mb->getOrdinal();
#endif
                }
            }

            BC::expToNextReg(cs->fs, &right);
            BC::expToVal(cs->fs, &right);
            BC::indexed(cs->fs, &left, &right);

            // generate property getter call for getters
            if (getter)
            {
                generateCall(&left, NULL, NULL);
            }

            // we're out of here, so store off our expressions
            expression->e = left;
            eleft->e      = left;
            eright->e     = right;

            return expression;
        }
        else
        {
            // primitive property (this is caught in TypeValidator, but make double sure)
            lmAssert(!expression->assignment,
                     "primitive property used in assignment");

            Type *ptype = eright->memberInfo->getDeclaringType();

            // access the type
            BC::singleVar(cs, &left, ptype->getName());

            // get the transformed static method
            utString staticMember = "_";
            staticMember += eright->memberInfo->getName();
            BC::expString(cs, &right, staticMember.c_str());

            // index the type with the static method
            BC::expToNextReg(cs->fs, &left);
            BC::expToNextReg(cs->fs, &right);
            BC::expToVal(cs->fs, &right);
            BC::indexed(cs->fs, &left, &right);

            // whatever is on the left hand side of the property expression becomes an argument
            utArray<Expression *> args;
            args.push_back(eleft);

            // call the transformed method
            generateCall(&left, &args, NULL /*((PropertyInfo*)eright->memberInfo)->getGetMethod()*/);

            // store out the expressions/registers
            expression->e = left;
            eleft->e      = left;
            eright->e     = right;

            return expression;
        }
    }
    else
    {
        // non-property (or array) access
        // either a simple foo.bar or foo["bar"]

        // visit the left hand expression
        eleft->visitExpression(this);

        ExpDesc left = eleft->e;

        if (expression->arrayAccess)
        {
            // this needs to handle dictionary as well
            ExpDesc eidxVectorIndex;
            BC::initExpDesc(&eidxVectorIndex, VKNUM, 0);

            int v = LSINDEXVECTOR;

            if (eleft->type->isDictionary())
            {
                v = LSINDEXDICTPAIRS;
            }

#ifdef LOOM_ENABLE_JIT
            setnumV(&eidxVectorIndex.u.nval, v);
#else
            eidxVectorIndex.u.nval = (int)v;
#endif

            BC::expToNextReg(fs, &left);
            BC::expToNextReg(fs, &eidxVectorIndex);
            BC::expToVal(fs, &eidxVectorIndex);
            BC::indexed(fs, &left, &eidxVectorIndex);
        }

        BC::expToNextReg(cs->fs, &left);

        // and the right
        eright->visitExpression(this);
        right = eright->e;

        // do the index
        BC::expToNextReg(cs->fs, &right);
        BC::expToVal(cs->fs, &right);
        BC::indexed(cs->fs, &left, &right);

        // store out expressions
        expression->e = left;
        eleft->e      = left;
        eright->e     = right;

        return expression;
    }

    lmAssert(0, "should never get here");
    return NULL;
}


void TypeCompilerBase::insertYield(ExpDesc *yield, utArray<Expression *> *arguments)
{
    BC::singleVar(cs, yield, "yield");

    generateCall(yield, arguments, NULL);
}


Expression *TypeCompilerBase::visit(YieldExpression *expression)
{
    ExpDesc yield;

    insertYield(&yield, expression->arguments);
    expression->e = yield;

    return expression;
}


Expression *TypeCompilerBase::visit(VectorLiteral *vector)
{
    FuncState *fs = cs->fs;

    int restore = fs->freereg;

    // vtable will go into this reg
    fs->freereg = fs->freereg + 1;

    // comes in from NewExpression visitor
    ExpDesc ethis = vector->e;

    // initialize the internal vector table
    ethis = vector->e;
    ExpDesc eidxVectorIndex;
    BC::initExpDesc(&eidxVectorIndex, VKNUM, 0);

#ifdef LOOM_ENABLE_JIT
    setnumV(&eidxVectorIndex.u.nval, LSINDEXVECTOR);
#else
    eidxVectorIndex.u.nval = (int)LSINDEXVECTOR;
#endif

    BC::expToNextReg(fs, &ethis);    

    BC::expToNextReg(fs, &eidxVectorIndex);
    BC::expToVal(fs, &eidxVectorIndex);
    BC::indexed(fs, &ethis, &eidxVectorIndex);

    // moves vtables into ethis
    BC::expToNextReg(fs, &ethis);

    // store vector length to LSINDEXVECTORLENGTH

    ExpDesc eidxVectorLength;

    BC::initExpDesc(&eidxVectorLength, VKNUM, 0);

    // LSINDEXVECTORLENGTH access will get forwarded to internal vector table
#ifdef LOOM_ENABLE_JIT
    setnumV(&eidxVectorLength.u.nval, LSINDEXVECTORLENGTH);
#else
    eidxVectorLength.u.nval = (int)LSINDEXVECTORLENGTH;
#endif

    ExpDesc nelements;
    BC::initExpDesc(&nelements, VKNUM, 0);

#ifdef LOOM_ENABLE_JIT
    setnumV(&nelements.u.nval, vector->elements.size());
#else
    nelements.u.nval = (int)vector->elements.size();
#endif

    // set length    
    BC::expToNextReg(fs, &eidxVectorLength);
    BC::expToVal(fs, &eidxVectorLength);
    BC::indexed(fs, &ethis, &eidxVectorLength);
    BC::storeVar(fs, &ethis, &nelements);


    // add any elements to vector
    for (UTsize i = 0; i < vector->elements.size(); i++)
    {
        ExpDesc idx;
        BC::initExpDesc(&idx, VKNUM, 0);
#ifdef LOOM_ENABLE_JIT
        setnumV(&idx.u.nval, i);
#else
        idx.u.nval = i;
#endif

        BC::expToNextReg(fs, &idx);
        BC::expToVal(fs, &idx);
        BC::indexed(fs, &ethis, &idx);

        Expression *expr = vector->elements[i];
        expr->visitExpression(this);
        BC::storeVar(fs, &ethis, &expr->e);
    }

    fs->freereg = restore;

    return vector;
}


Expression *TypeCompilerBase::visit(IncrementExpression *expression)
{
    FuncState *fs = cs->fs;

    bool post = expression->post;

    int regback = fs->freereg;

    expression->subExpression->visitExpression(this);

    ExpDesc postInc;
    BC::singleVar(cs, &postInc, "__ls_postinc");
    BC::storeVar(fs, &postInc, &expression->subExpression->e);

    double value = expression->value;

    ExpDesc v2;

    ExpDesc e = expression->subExpression->e;

#ifdef LOOM_ENABLE_JIT
    BC::emitBinOpLeft(fs, OPR_ADD, &e);

    BC::initExpDesc(&v2, VKNUM, 0);

    setnumV(&v2.u.nval, value);

    BC::expToNextReg(fs, &v2);

    BC::emitBinOp(fs, OPR_ADD, &e, &v2);

#else
    BC::initExpDesc(&v2, VKNUM, 0);

    v2.u.nval = value;

    BC::codeArith(fs, OP_ADD, &e, &v2);
#endif

    BC::expToNextReg(fs, &e);

    // revisit
    Expression *sub = expression->subExpression;

    // if we're a property, need to do some fancy footwork
    if (sub->memberInfo && sub->memberInfo->isProperty())
    {
        // promote to a register and mark restore reg
        BC::expToNextReg(fs, &e);
        ExpDesc erestore = e;
        int     restore  = fs->freereg;

        // switch the subexpression to assignment mode
        sub->assignment = true;
        // visit it
        sub->visitExpression(this);

        // setup the property setter call
        ExpDesc set = sub->e;
        sub->e = e;
        generatePropertySet(&set, sub, false);

        // back to the original expression (with associated register)
        e = erestore;

        // back to our watermark
        fs->freereg = restore;

        // if we're a post increment we need to store the
        // pre-increment value
        if (!post)
        {
            BC::singleVar(cs, &postInc, "__ls_postinc");
            BC::storeVar(fs, &postInc, &e);
        }
    }
    else
    {
        sub->visitExpression(this);

        ExpDesc se = sub->e;

        BC::storeVar(fs, &se, &e);

        if (!post)
        {
            BC::singleVar(cs, &postInc, "__ls_postinc");
            BC::storeVar(fs, &postInc, &e);
        }
    }

    fs->freereg = regback;

    BC::singleVar(cs, &expression->e, "__ls_postinc");

    return expression;
}


void TypeCompilerBase::setupVarDecl(ExpDesc             *out,
                                    VariableDeclaration *declaration)
{
    FuncState *fs = cs->fs;

    if (declaration->classDecl)
    {
        // if we're either a static or instance member variable we
        // need to store to the class or "this" table

        ExpDesc vname;

        BC::initExpDesc(&vname, VKNUM, 0);

#ifdef LOOM_ENABLE_JIT
        setnumV(&vname.u.nval, declaration->memberInfo->getOrdinal());

#else
        vname.u.nval = declaration->memberInfo->getOrdinal();
#endif

        if (declaration->isStatic)
        {
            BC::singleVar(cs, out,
                          declaration->classDecl->name->string.c_str());
        }
        else
        {
            BC::singleVar(cs, out, "this");
        }

        BC::expToNextReg(fs, out);
        BC::expToNextReg(fs, &vname);
        BC::expToVal(fs, &vname);
        BC::indexed(fs, out, &vname);
    }
    else
    {
        // store out to local variable
        BC::singleVar(cs, out, declaration->identifier->string.c_str());
    }
}


void TypeCompilerBase::createInstance(ExpDesc *expr, const utString& className,
                                      utArray<Expression *> *arguments)
{
    // get the class table from method's fenv
    ExpDesc ecls;
    BC::singleVar(cs, &ecls, className.c_str());
    BC::expToNextReg(cs->fs, &ecls);

    generateCall(&ecls, arguments);

    *expr = ecls;
}


void TypeCompilerBase::generateAssignmentOperatorCall(MethodInfo *method,
                                                      Expression *eleft, Expression *eright)
{
    lmAssert(method, "Internal Error: TypeCompilerBase::generateAssignmentOperatorCall method is NULL");

    FuncState *fs = cs->fs;

    utArray<Expression *> args;
    args.push_back(eleft);
    args.push_back(eright);

    ExpDesc opcall;
    ExpDesc emethod;

    BC::singleVar(cs, &opcall, method->getDeclaringType()->getName());

    BC::initExpDesc(&emethod, VKNUM, 0);

#ifdef LOOM_ENABLE_JIT
    setnumV(&emethod.u.nval, method->getOrdinal());

#else
    emethod.u.nval = method->getOrdinal();
#endif


    BC::expToNextReg(fs, &opcall);
    BC::expToNextReg(fs, &emethod);
    BC::expToVal(fs, &emethod);
    BC::indexed(fs, &opcall, &emethod);

    generateCall(&opcall, &args, method);
}


void TypeCompilerBase::generateVarDeclStruct(VariableDeclaration *declaration)
{
    FuncState *fs = cs->fs;

    ExpDesc v;

    MethodInfo *method = (MethodInfo *)declaration->type->findMember("__op_assignment");

    lmAssert(method, "Internal Error: TypeCompilerBase::generateVarDeclStruct method is NULL");

    // if we have a default initialzer or are assigning
    // a right hand expression, we need to implicitly create
    // the struct and then in the case of a right hand expression
    // assign via the assignment operator
    if (declaration->defaultInitializer ||
        (declaration->initializer &&
         (declaration->initializer->astType != AST_NEWEXPRESSION)))
    {
        ExpDesc instance;

        createInstance(&instance, method->getDeclaringType()->getFullName().c_str(), NULL);

        setupVarDecl(&v, declaration);

        BC::storeVar(cs->fs, &v, &instance);

        if (!declaration->defaultInitializer)
        {
            generateAssignmentOperatorCall(method, declaration->identifier,
                                           declaration->initializer);
        }

        return;
    }
    else if (declaration->initializer &&
             (declaration->initializer->astType == AST_NEWEXPRESSION))
    {
        fs->freereg = fs->nactvar; /* free registers */

        setupVarDecl(&v, declaration);

        declaration->initializer->visitExpression(this);
        BC::storeVar(fs, &v, &declaration->initializer->e);

        return;
    }

    if (!declaration->initializer && declaration->isNative)
    {
        return;
    }

    lmAssert(0, "Invalid variable decl with assign overload");
}


Expression *TypeCompilerBase::visit(AssignmentExpression *expression)
{
    Expression *eleft  = expression->leftExpression;
    Expression *eright = expression->rightExpression;

    bool arrayAccess = false;

    if ((eleft->astType == AST_PROPERTYEXPRESSION) && ((PropertyExpression *)eleft)->arrayAccess)
    {
        arrayAccess = true;
    }

    if (!arrayAccess)
    {
        if (eleft->memberInfo && eleft->memberInfo->isProperty())
        {
            // the value of the assignment expression itself
            // is the value being set to support patterns like:
            // setter = setter = value;

            FuncState *fs = cs->fs;

            // first visit the expression of the assignment value
            eright->visitExpression(this);

            BC::expToNextReg(fs, &eright->e);
            ExpDesc e = eright->e;
            // mark where we will be restoring to
            int restore = fs->freereg;

            // visit the setter property expression
            eleft->visitExpression(this);

            ExpDesc left = eleft->e;

            // check for super.property access
            bool set = false;
            if (eleft->astType == AST_IDENTIFIER)
            {
                Identifier *identifier = (Identifier *)eleft;

                if (identifier->superAccess)
                {
                    // if we're not static, we need to pass
                    // this as first argument
                    utArray<Expression *> args;
                    if (!identifier->memberInfo->isStatic())
                    {
                        args.push_back(new ThisLiteral());
                        BC::singleVar(cs, &args[0]->e, "this");
                    }

                    args.push_back(eright);
                    generateCall(&identifier->e, &args, NULL);
                    set = true;
                }
            }

            // generate the set call, if we haven't already
            // generated a super.property call for it
            if (!set)
            {
                generatePropertySet(&left, eright, false);
            }

            expression->e = e;

            // back to our watermark
            fs->freereg = restore;

            return expression;
        }
        else if ((eleft->astType != AST_PROPERTYEXPRESSION) ||
                 ((eleft->astType == AST_PROPERTYEXPRESSION) &&
                  !((PropertyExpression *)eleft)->arrayAccess))
        {
            // if we're an array access need to store

            // assignment operator overload
            MemberInfo *mi = eleft->type->findMember("__op_assignment");
            if (mi && (eright->astType != AST_NEWEXPRESSION))
            {
                if (!mi->isMethod())
                {
                    error("non-method");
                }
                MethodInfo *method = (MethodInfo *)mi;
                if (!method->isOperator())
                {
                    error("non-operator");
                }

                generateAssignmentOperatorCall(method, eleft, eright);
                return expression;
            }
        }
    }

    eright->visitExpression(this);
    BC::expToNextReg(cs->fs, &eright->e);

    eleft->visitExpression(this);

    ExpDesc left = eleft->e;

    BC::storeVar(cs->fs, &left, &eright->e);

    expression->e = left;

    return expression;
}


Expression *TypeCompilerBase::visitSuperProperty(Identifier *identifier)
{
    FuncState *fs = cs->fs;

    // visitor for super.property setter/getter

    // the member has already been resolved to the parent member
    // by the type visitor
    MemberInfo *memberInfo = identifier->memberInfo;

    lmAssert(memberInfo && memberInfo->isProperty(), "non-property on super property access");

    PropertyInfo *pinfo = (PropertyInfo *)memberInfo;

    bool isStatic = false;
    if (pinfo->isStatic())
    {
        isStatic = true;
    }

    bool       getter = false;
    MethodBase *mb    = NULL;

    if (!identifier->assignment)
    {
        mb = pinfo->getGetMethod();
        lmAssert(mb, "Missing property getter %s", pinfo->getFullMemberName());
        getter = true;
    }
    else
    {
        mb = pinfo->getSetMethod();
        lmAssert(mb, "Missing property setter %s", pinfo->getFullMemberName());
    }

    ExpDesc eclass;
    BC::singleVar(cs, &eclass, memberInfo->getDeclaringType()->getFullName().c_str());

    // index with the function name
    BC::expToNextReg(fs, &eclass);

    ExpDesc fname;
    BC::expString(cs, &fname, mb->getName());

    BC::expToNextReg(fs, &fname);
    BC::expToVal(fs, &fname);
    BC::indexed(fs, &eclass, &fname);

    identifier->e = eclass;

    if (getter)
    {
        utArray<Expression *> args;
        if (!isStatic)
        {
            // if we're not static we need to pass this in arg 1
            args.push_back(new ThisLiteral());
            BC::singleVar(cs, &args[0]->e, "this");
            generateCall(&identifier->e, &args, NULL);
        }
        else
        {
            generateCall(&identifier->e, NULL, NULL);
        }
    }

    return identifier;
}


Expression *TypeCompilerBase::visit(Identifier *identifier)
{
    if (identifier->superAccess)
    {
        return visitSuperProperty(identifier);
    }

    FuncState *fs = cs->fs;

    utString istring         = identifier->string;
    bool     propertyGetCall = false;

    int ordinal = 0;

    if (identifier->typeExpression)
    {
        generateIdentifierTypeConversion(identifier);

        return identifier;
    }
    else if (!identifier->memberInfo)
    {
        BC::singleVar(cs, &identifier->e, istring.c_str());
    }
    else
    {
        MemberInfo *memberInfo = identifier->memberInfo;

        bool isStatic = false;

        ordinal = memberInfo->getOrdinal();

        if (memberInfo->isMethod())
        {
            MethodInfo *methodInfo = (MethodInfo *)memberInfo;
            if (methodInfo->isStatic())
            {
                isStatic = true;
            }
        }
        else if (memberInfo->isField())
        {
            FieldInfo *fieldInfo = (FieldInfo *)memberInfo;
            if (fieldInfo->isStatic())
            {
                isStatic = true;
            }
        }
        else if (memberInfo->isProperty())
        {
            PropertyInfo *pinfo = (PropertyInfo *)memberInfo;

            if (pinfo->isStatic())
            {
                isStatic = true;
            }

            if (!identifier->assignment)
            {
                MethodBase *mb = pinfo->getGetMethod();
                lmAssert(mb, "Missing property getter %s", pinfo->getFullMemberName());
                ordinal         = mb->getOrdinal();
                propertyGetCall = true;
            }
            else
            {
                MethodBase *mb = pinfo->getSetMethod();
                lmAssert(mb, "Missing property setter %s", pinfo->getFullMemberName());
                ordinal = mb->getOrdinal();
            }
        }

        ExpDesc ethis;
        if (isStatic)
        {
            BC::singleVar(cs, &ethis, memberInfo->getDeclaringType()->getFullName().c_str());
        }
        else
        {
            BC::singleVar(cs, &ethis, "this");
        }

        ExpDesc vname;

        lmAssert(ordinal, "Out of range ordinal");

        BC::initExpDesc(&vname, VKNUM, 0);

#ifdef LOOM_ENABLE_JIT
        setnumV(&vname.u.nval, ordinal);
#else
        vname.u.nval = ordinal;
#endif
        BC::expToNextReg(fs, &ethis);
        BC::expToNextReg(fs, &vname);
        BC::expToVal(fs, &vname);
        BC::indexed(fs, &ethis, &vname);
        identifier->e = ethis;

        if (propertyGetCall)
        {
            generateCall(&identifier->e, NULL, NULL);
        }
    }

    return identifier;
}


Expression *TypeCompilerBase::visit(StringLiteral *literal)
{
    if (literal->memberInfo)
    {
        if (!literal->memberInfo->getDeclaringType()->isInterface())
        {
            int ordinal = literal->memberInfo->getOrdinal();
            BC::initExpDesc(&literal->e, VKNUM, 0);
#ifdef LOOM_ENABLE_JIT
            setnumV(&literal->e.u.nval, ordinal);
#else
            literal->e.u.nval = ordinal;
#endif
        }
        else
        {
            BC::expString(cs, &literal->e, literal->memberInfo->getName());
        }

        return literal;
    }

    BC::expString(cs, &literal->e, literal->string.c_str());

    return literal;
}


void TypeCompilerBase::generateStaticInitializer()
{
    CompilationUnit *cunit = cls->pkgDecl->compilationUnit;

    CodeState codeState;
    FuncState funcState;

    initCodeState(&codeState, &funcState, cunit->filename);

    cs = &codeState;

    FuncState *fs = cs->fs;

    ExpDesc eclass;
    ExpDesc vname;

    // We're solely interested in initializer expressions of static class variables
    for (UTsize i = 0; i < cls->varDecls.size(); i++)
    {
        VariableDeclaration *v = cls->varDecls.at(i);

        if (!v->isStatic)
        {
            continue;
        }

        if (v->type->isStruct())
        {
            generateVarDeclStruct(v);
        }
        else if (v->type->isDelegate())
        {
            generateVarDeclDelegate(v);
        }
        else
        {
            if (v->initializer)
            {
                lmAssert(v->memberInfo, "untyped initializer");
                memset(&vname, 0, sizeof(ExpDesc));

                BC::initExpDesc(&vname, VKNUM, 0);

#if LOOM_ENABLE_JIT
                setnumV(&vname.u.nval, v->memberInfo->getOrdinal());
#else
                vname.u.nval = v->memberInfo->getOrdinal();
#endif



                BC::singleVar(cs, &eclass, cls->name->string.c_str());

                BC::expToNextReg(fs, &eclass);
                BC::expToNextReg(fs, &vname);
                BC::expToVal(fs, &vname);
                BC::indexed(fs, &eclass, &vname);

                v->initializer->visitExpression(this);
                BC::storeVar(fs, &eclass, &v->initializer->e);
            }
        }

        fs->freereg = fs->nactvar; /* free registers */
    }

    // Generate default values for methods, this is done in static initializer
    // so that we can have non-trivial default values compiled into class bytecode
    // which is necessary for cross assembly access
    // Default values must be valid at static scope

    utArray<FunctionLiteral *> functionDecls = cls->functionDecls;

    if (cls->constructor)
    {
        functionDecls.push_back(cls->constructor);
    }

    for (UTsize i = 0; i < functionDecls.size(); i++)
    {
        FunctionLiteral *function = functionDecls[i];

        if (!function->parameters || (function->getFirstDefaultArg() == UT_NPOS))
        {
            continue;
        }

        bool gotone = false;
        for (UTsize j = 0; j < function->parameters->size(); j++)
        {
            Expression *expr = function->defaultArguments[j];
            if (!expr)
            {
                // if we hit a varargs decl, we're out of here
                if (function->methodBase && function->methodBase->getVarArgParameter() && (function->methodBase->getVarArgParameter()->position == j))
                {
                    break;
                }

                lmAssert(!gotone, "default args after var args");
                continue;
            }

            gotone = true;

            memset(&vname, 0, sizeof(ExpDesc));
            memset(&eclass, 0, sizeof(ExpDesc));

            utString name;

            // get the method
            if (function->isConstructor)
            {
                name = "__ls_constructor";
            }
            else
            {
                name = function->name->string;
            }

            name += "__default_args";

            BC::expString(cs, &vname, name.c_str());

            // get the default args table
            BC::singleVar(cs, &eclass, cls->name->string.c_str());
            BC::expToNextReg(fs, &eclass);
            BC::expToNextReg(fs, &vname);
            BC::expToVal(fs, &vname);
            BC::indexed(fs, &eclass, &vname);


            ExpDesc idx;
            BC::initExpDesc(&idx, VKNUM, 0);

#if LOOM_ENABLE_JIT
            setnumV(&idx.u.nval, j);
#else
            idx.u.nval = j;
#endif

            BC::expToNextReg(fs, &eclass);
            BC::expToNextReg(fs, &idx);
            BC::expToVal(fs, &idx);
            BC::indexed(fs, &eclass, &idx);

            expr->visitExpression(this);
            BC::storeVar(fs, &eclass, &expr->e);

            fs->freereg = fs->nactvar; /* free registers */
        }
    }

    closeCodeState(&codeState);

	bool debug = cunit->buildInfo->isDebugBuild();

#if LOOM_ENABLE_JIT
	cls->type->setBCStaticInitializer(generateByteCode(codeState.proto, debug));
#else
    cls->type->setBCStaticInitializer(generateByteCode(funcState.f, debug));
#endif
}


void TypeCompilerBase::generateInstanceInitializer()
{
    CompilationUnit *cunit = cls->pkgDecl->compilationUnit;

    CodeState codeState;
    FuncState funcState;

    initCodeState(&codeState, &funcState, cunit->filename);

    cs = &codeState;

    FuncState *fs = cs->fs;

    // this "parameter"

#if LOOM_ENABLE_JIT
    BC::newLocalVar(cs, "this", 0);
    fs->numparams = 1;
    BC::adjustLocalVars(cs, 1);
    BC::regReserve(fs, fs->nactvar); /* reserve register for parameters */
#else
    BC::newLocalVar(cs, "this", 0);
    BC::adjustLocalVars(cs, 1);
    fs->f->numparams = cast_byte(fs->nactvar);
    BC::reserveRegs(fs, fs->nactvar); /* reserve register for parameters */
#endif

    ExpDesc ethis;

    // Skip initialization code when it does nothing.
    bool doesNothing = true;

    // We're solely interested in initializer expressions non static variables
    for (UTsize i = 0; i < cls->varDecls.size(); i++)
    {
        VariableDeclaration *v = cls->varDecls.at(i);

        if (v->isStatic)
        {
            continue;
        }

        if (v->type->isStruct())
        {
            doesNothing = false;
            generateVarDeclStruct(v);
        }
        else if (v->type->isDelegate())
        {
            doesNothing = false;
            generateVarDeclDelegate(v);
        }
        else if (v->initializer)
        {
            doesNothing = false;

            ExpDesc vname;

            BC::initExpDesc(&vname, VKNUM, 0);
#if LOOM_ENABLE_JIT
            setnumV(&vname.u.nval, v->memberInfo->getOrdinal());
#else
            vname.u.nval = v->memberInfo->getOrdinal();
#endif

            BC::singleVar(cs, &ethis, "this");

            BC::expToNextReg(fs, &ethis);
            BC::expToNextReg(fs, &vname);
            BC::expToVal(fs, &vname);
            BC::indexed(fs, &ethis, &vname);

            v->initializer->visitExpression(this);
            BC::storeVar(fs, &ethis, &v->initializer->e);
        }

        fs->freereg = fs->nactvar; /* free registers */
    }

    closeCodeState(&codeState);

    if(doesNothing == false)
    {
        bool debug = cunit->buildInfo->isDebugBuild();

#if LOOM_ENABLE_JIT
        cls->type->setBCInstanceInitializer(generateByteCode(codeState.proto, debug));
#else
        cls->type->setBCInstanceInitializer(generateByteCode(funcState.f, debug));
#endif
    }
}


void TypeCompilerBase::generateVarDeclDelegate(VariableDeclaration *declaration)
{
    ExpDesc v;
    ExpDesc instance;

    if (!declaration->defaultInitializer && declaration->initializer &&
        declaration->initializer->type->isDelegate())
    {
        setupVarDecl(&v, declaration);

        declaration->initializer->visitExpression(this);
        BC::storeVar(cs->fs, &v, &declaration->initializer->e);
    }
    else
    {
        createInstance(&instance, declaration->type->getFullName().c_str(),
                       NULL);

        setupVarDecl(&v, declaration);

        BC::storeVar(cs->fs, &v, &instance);

        if (!declaration->defaultInitializer)
        {
            MethodInfo *method = (MethodInfo *)declaration->type->findMember(
                "__op_assignment");

            lmAssert(method, "delegate with no __op_assignment");

            generateAssignmentOperatorCall(method, declaration->identifier,
                                           declaration->initializer);
        }
    }
}


void TypeCompilerBase::declareLocalVariables(FunctionLiteral *literal)
{
    int nlocals = 0;

    // note that any var args must be created ahead of time
    // as they cannot be created in the call bytecode
    // generator
    for (int i = 0; i < literal->numVarArgCalls; i++)
    {
        char varargname[1024];
        sprintf(varargname, "__ls_vararg%i", i);
        BC::newLocalVar(cs, varargname, nlocals++);
    }

    BC::newLocalVar(cs, "__ls_swft", nlocals++);
    BC::newLocalVar(cs, "__ls_swexpr", nlocals++);
    BC::newLocalVar(cs, "__ls_key", nlocals++);
    BC::newLocalVar(cs, "__ls_ternary", nlocals++);
    BC::newLocalVar(cs, "__ls_postinc", nlocals++);

    // for functions that contain (direct) child functions, we need to use unqiue upvalues
    // to store function information, such as how many arguments the functions takes for the
    // Function.length property, note that Lua 5.2 has support for this internally'
    // and this can be removed upon upgrading to it (once LuaJIT supports 5.2 features)
    for (UTsize i = 0; i < literal->childFunctions.size(); i++)
    {
        char funcinfo[256];
        snprintf(funcinfo, 250, "__ls_funcinfo_arginfo_%i", i);
        BC::newLocalVar(cs, funcinfo, nlocals++);
    }

    utHashTable<utHashedString, Type *> localTypes;

    for (UTsize i = 0; i < literal->localVariables.size(); i++)
    {
        Identifier *ident = literal->localVariables.at(i)->identifier;

        Type *type = literal->localVariables.at(i)->type;

        // this should be caught in type visitor, this is only sanity check
        lmAssert(type, "untyped local variable decl");

        bool skip = false;

        if (literal->parameters)
        {
            for (UTsize j = 0; j < literal->parameters->size(); j++)
            {
                if (ident->string == literal->parameters->at(j)->identifier->string)
                {
                    skip = true;
                    break;
                }
            }
        }

        if (!skip)
        {
            BC::newLocalVar(cs, ident->string.c_str(), nlocals++);
            localTypes.insert(ident->string.c_str(), type);
        }
    }

    BC::adjustLocalVars(cs, nlocals);

#if LOOM_ENABLE_JIT
    BC::regReserve(cs->fs, nlocals);
#else
    BC::reserveRegs(cs->fs, nlocals);
#endif

    // initialize to default values
    for (UTsize i = 0; i < localTypes.size(); i++)
    {
        const char *vname = localTypes.keyAt(i).str().c_str();
        Type       *type  = localTypes.at(i);

        ExpDesc var;
        ExpDesc value;

        BC::singleVar(cs, &var, vname);

        if (type->isStruct())
        {
            // We currently are creating additional structs
            // this will be fixed once LOOM-1595 is addressed (which is to stop front loading vars altogether)
            createInstance(&value, type->getFullName().c_str(), NULL);
        }
        else if (!strcmp(type->getFullName().c_str(), "system.Boolean"))
        {
#if LOOM_ENABLE_JIT
            BC::initExpDesc(&value, VKFALSE, 0);
#else
            BC::initExpDesc(&value, VFALSE, 0);
#endif
        }
        else if (!strcmp(type->getFullName().c_str(), "system.Number"))
        {
            BC::initExpDesc(&value, VKNUM, 0);

#if LOOM_ENABLE_JIT
            setnumV(&value.u.nval, 0);
#else
            value.u.nval = 0;
#endif
        }
        else
        {
#if LOOM_ENABLE_JIT
            BC::initExpDesc(&value, VKNIL, 0);
#else
            BC::initExpDesc(&value, VNIL, 0);
#endif
        }

        BC::storeVar(cs->fs, &var, &value);
    }
}


void TypeCompilerBase::storeLocalToMember(MemberInfo *memberInfo, const char *localVar)
{
    FuncState *fs = cs->fs;

    ExpDesc ethis;

    if (memberInfo->isStatic())
    {
        BC::singleVar(cs, &ethis, memberInfo->getDeclaringType()->getFullName().c_str());
    }
    else
    {
        BC::singleVar(cs, &ethis, "this");
    }

    ExpDesc vname;

    int ordinal = memberInfo->getOrdinal();

    lmAssert(ordinal, "Out of range ordinal");

    BC::initExpDesc(&vname, VKNUM, 0);

#ifdef LOOM_ENABLE_JIT
    setnumV(&vname.u.nval, ordinal);
#else
    vname.u.nval = ordinal;
#endif

    BC::expToNextReg(fs, &ethis);
    BC::expToNextReg(fs, &vname);
    BC::expToVal(fs, &vname);
    BC::indexed(fs, &ethis, &vname);

    ExpDesc value;
    BC::singleVar(cs, &value, localVar);

    BC::storeVar(fs, &ethis, &value);
}


void TypeCompilerBase::coerceToString(Expression *expression)
{
    ExpDesc _object;
    ExpDesc _toString;
    BC::singleVar(cs, &_object, "Object");
    BC::expString(cs, &_toString, "_toString");

    BC::expToNextReg(cs->fs, &_object);
    BC::expToVal(cs->fs, &_toString);
    BC::indexed(cs->fs, &_object, &_toString);

    utArray<Expression *> args;
    args.push_back(expression);

    // generate the Object._toString call
    generateCall(&_object, &args, NULL);

    expression->e = _object;
}
}
