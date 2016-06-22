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

#ifndef _lsscope2_h
#define _lsscope2_h

#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"

#include "loom/script/compiler/lsAST.h"

#include "loom/script/reflection/lsReflection.h"

#include "loom/script/runtime/lsLuaState.h"
#include "loom/script/common/lsError.h"
#include "loom/script/compiler/lsCompilerLog.h"

namespace LS {
class Scope {
    // all types currently in this scope
    utHashTable<utHashedString, Type *> types;

    // ambiguous types (share name with another class in scope)
    utHashTable<utHashedString, Type *> ambiguousTypes;

    // members of current class scope (including base classes)
    utHashTable<utHashedString, MemberInfo *> members;

    // locals to function including parameters
    utHashTable<utHashedString, Type *> locals;

    // locals to function including parameters
    utHashTable<utHashedString, VariableDeclaration *> localVars;

    static utStack<Scope *> scopeStack;
    static Scope            *curScope;

    static LSLuaState *vm;

    static void push(Scope *scope)
    {
        assert(scope);
        scopeStack.push(scope);
        curScope = scope;
    }

public:

    static utString scopeErrorString;

    static void setVM(LSLuaState *vm)
    {
        Scope::vm = vm;

        assert(!curScope);
        assert(scopeStack.size() == 0);
    }

    static void push(PackageDeclaration *pkg)
    {
        Scope *scope = new Scope();

        // get the system types
        Assembly *system = vm->getAssembly("System");

        assert(system);

        utArray<Type *> systemTypes;
        system->getTypes(systemTypes);

        for (UTsize i = 0; i < systemTypes.size(); i++)
        {
            Type *type = systemTypes[i];

            scope->types.insert(type->getFullName(), type);
            scope->types.insert(type->getName(), type);
        }

        // insert all imports
        for (UTsize i = 0; i < pkg->imports.size(); i++)
        {
            ImportStatement *import = pkg->imports.at(i);

            if (!import->type)
            {
                continue;
            }

            scope->types.insert(import->fullPath, import->type);

            // mark ambiguous types
            UTsize pos = scope->types.find(import->classname);

            if ((pos != UT_NPOS) && (scope->types.at(pos) != import->type))
            {
                scope->ambiguousTypes.insert(import->classname, import->type);
            }

            scope->types.insert(import->classname, import->type);
        }

        // add package types, note that we always add the System types above
        if (pkg->spath != "System")
        {
            utArray<Type *> packageTypes;
            vm->getPackageTypes(pkg->spath, packageTypes);
            // insert all package types
            for (UTsize i = 0; i < packageTypes.size(); i++)
            {
                Type *ptype = packageTypes[i];
                scope->types.insert(ptype->getFullName(), ptype);

                // mark ambiguous types
                UTsize pos = scope->types.find(ptype->getName());
                if ((pos != UT_NPOS) && (scope->types.at(pos) != ptype))
                {
                    scope->ambiguousTypes.insert(ptype->getName(), ptype);
                }

                scope->types.insert(ptype->getName(), ptype);
            }
        }

        push(scope);
    }

    static void push(Type *type)
    {
        Scope *scope = new Scope();

        MemberTypes mtypes;

        mtypes.method   = true;
        mtypes.field    = true;
        mtypes.property = true;
        utArray<MemberInfo *> members;

        type->findMembers(mtypes, members);

        for (UTsize i = 0; i < members.size(); i++)
        {
            MemberInfo *info = members.at(i);
            scope->members.insert(info->getName(), info);
        }

        push(scope);
    }

    static void push(ClassDeclaration *cls)
    {
        assert(cls->type);
        push(cls->type);
    }

    static void push(FunctionLiteral *function, CompilationUnit *cunit = NULL)
    {
        Scope *scope = new Scope();

        utString source = "(Unknown Source File)";

        if (cunit)
        {
            source = cunit->filename;
        }

        if (function->methodBase)
        {
            if (!function->methodBase->isStatic())
            {
                scope->locals.insert("this", function->classDecl->type);
            }
        }

        for (UTsize i = 0; i < function->localVariables.size(); i++)
        {
            VariableDeclaration *vd   = function->localVariables.at(i);
            Type                *type = resolveType(vd->typeString);

            if (!type)
            {
                char errormsg[1024];
                sprintf(errormsg,
                        "unable to resolve type %s for local var %s:%s in function %s:%s",
                        vd->typeString.c_str(), vd->identifier->string.c_str(),
                        vd->typeString.c_str(),
                        function->classDecl ? function->classDecl->fullPath.c_str() : "[UNKNOWN CLASS]",
                        function->name ? function->name->string.c_str() : "(anonymous function)");

                LSCompilerLog::logError(source.c_str(), vd->lineNumber, errormsg, "Scope");
            }

            utHashedString hs = vd->identifier->string;

            if ((scope->locals.get(hs) != NULL) || (scope->localVars.get(hs) != NULL))
            {
                int conflict = -1;
                VariableDeclaration **cvd = scope->localVars.get(hs);
                if (cvd)
                {
                    conflict = (*cvd)->lineNumber;
                }

                // print line information if we have it
                if (conflict != -1)
                {
                    char errormsg[1024];
                    sprintf(errormsg,
                            "duplicate local variable definition \"%s\" in function %s:%s conflicts with declaration at line %i",
                            vd->identifier->string.c_str(),
                            function->classDecl ? function->classDecl->fullPath.c_str() : "",
                            function->name ? function->name->string.c_str() : "anonymous", conflict);

                    LSCompilerLog::logError(source.c_str(), vd->lineNumber, errormsg, "Scope");
                }
                else
                {
                    char errormsg[1024];
                    sprintf(errormsg,
                            "duplicate local variable definition \"%s\" in function %s:%s",
                            vd->identifier->string.c_str(),
                            function->classDecl ? function->classDecl->fullPath.c_str() : "",
                            function->name ? function->name->string.c_str() : "anonymous");

                    LSCompilerLog::logError(source.c_str(), vd->lineNumber, errormsg, "Scope");
                }
            }

            scope->locals.insert(vd->identifier->string, type);
            scope->localVars.insert(vd->identifier->string, vd);
        }

        push(scope);
    }

    static void setLocalType(const utString& identifier, Type *type)
    {
        Scope *s = scopeStack.peek(0);

        s->locals.erase(identifier);
        s->locals.insert(identifier, type);
    }

    static VariableDeclaration *resolveLocalVar(const utString& identifier)
    {
        utHashedString hs = identifier;

        for (unsigned int i = 0; i < scopeStack.size(); i++)
        {
            Scope *s = scopeStack.peek(i);

            VariableDeclaration **vd = s->localVars.get(hs);

            if (vd && *vd)
            {
                return *vd;
            }
        }

        return NULL;
    }

    static Type *resolveLocal(const utString& identifier)
    {
        utHashedString hs = identifier;

        for (unsigned int i = 0; i < scopeStack.size(); i++)
        {
            Scope *s = scopeStack.peek(i);

            Type **type = s->locals.get(hs);

            if (type && *type)
            {
                return *type;
            }
        }

        return NULL;
    }

    static MemberInfo *resolveMemberInfo(const utString& identifier)
    {
        utHashedString hs = identifier;

        for (unsigned int i = 0; i < scopeStack.size(); i++)
        {
            Scope *s = scopeStack.peek(i);

            MemberInfo **m = s->members.get(hs);

            if (m && *m)
            {
                return(*m);
            }
        }

        return NULL;
    }

    static Type *resolveMemberType(const utString& identifier)
    {
        utHashedString hs = identifier;

        for (unsigned int i = 0; i < scopeStack.size(); i++)
        {
            Scope *s = scopeStack.peek(i);

            MemberInfo **m = s->members.get(hs);

            if (m && *m)
            {
                return (*m)->getType();
            }
        }

        return NULL;
    }

    static Type *resolveType(const utString& identifier)
    {
        utHashedString hs = identifier;

        for (unsigned int i = 0; i < scopeStack.size(); i++)
        {
            Scope *s = scopeStack.peek(i);

            // first look in locals
            Type *t = resolveLocal(identifier);
            if (t)
            {
                return t;
            }

            // look in members
            t = resolveMemberType(identifier);
            if (t)
            {
                return t;
            }

            // check to see whether this identifier is ambiguous
            Type **type = s->ambiguousTypes.get(identifier);

            if (type && *type)
            {
                scopeErrorString  = "Ambiguous reference to type ";
                scopeErrorString += identifier;
                return NULL;
            }

            // look in visible types
            type = s->types.get(hs);

            if (type && *type)
            {
                return *type;
            }
        }

        return NULL;
    }

    static void pop()
    {
        if (!scopeStack.size())
        {
            curScope = NULL;
            return;
        }

        scopeStack.pop();

        curScope = scopeStack.size() ? scopeStack.top() : NULL;
    }
};
}
#endif
