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

#ifndef _lsdeclarationvisitor_h
#define _lsdeclarationvisitor_h

#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"

#include "loom/script/compiler/lsToken.h"
#include "loom/script/compiler/lsTraversalVisitor.h"
#include "loom/script/common/lsError.h"


namespace LS {
class DeclarationVisitor : public TraversalVisitor {
private:

    PackageDeclaration *curPackage;
    ClassDeclaration   *curClass;
    FunctionLiteral    *curFunction;
    CompilationUnit    *cunit;

public:

    DeclarationVisitor() :
        TraversalVisitor(), curPackage(NULL), curClass(NULL), curFunction(NULL), cunit(NULL)
    {
        visitor = this;
    }

    CompilationUnit *visit(CompilationUnit *cunit)
    {
        this->cunit = cunit;

        cunit = TraversalVisitor::visit(cunit);

        return cunit;
    }

    PackageDeclaration *visit(PackageDeclaration *pkg)
    {
        assert(!cunit->pkgDecl);

        cunit->pkgDecl       = pkg;
        pkg->compilationUnit = cunit;

        PackageDeclaration *oldPackage = curPackage;
        curPackage = pkg;

        pkg = (PackageDeclaration *)TraversalVisitor::visit(pkg);

        curPackage = oldPackage;

        return pkg;
    }

    ClassDeclaration *visit(ClassDeclaration *cls)
    {
        if (!curPackage)
        {
            LSError("Class %s outside of package declatation in %s", cls->name->string.c_str(), cunit->filename.c_str());
        }

        ClassDeclaration *oldClass = curClass;

        curClass = cls;

        curPackage->clsDecls.push_back(curClass);

        curClass->pkgDecl = curPackage;

        cls->fullPath  = curPackage->spath;
        cls->fullPath += ".";
        cls->fullPath += curClass->name->string;

        cunit->classDecls.push_back(cls);

        cls = (ClassDeclaration *)TraversalVisitor::visit(cls);

        // create default constructor if it doesn't exist
        if (!cls->constructor)
        {
            FunctionLiteral *defaultConstructor = new FunctionLiteral();
            defaultConstructor->isConstructor        = true;
            defaultConstructor->isDefaultConstructor = true;
            defaultConstructor->name = new Identifier(cls->name->string);
            visit(defaultConstructor);
        }

        curClass = oldClass;

        return cls;
    }

    FunctionLiteral *visit(FunctionLiteral *function)
    {
        FunctionLiteral *oldFunction = curFunction;

        curFunction = function;

        // if we're not a local function
        if (!oldFunction)
        {
            function->classDecl = curClass;

            if (curClass)
            {
                if (function->name)
                {
                    if (curClass->name->string == function->name->string)
                    {
                        if (function->isStatic)
                        {
                            // static constructor
                            function->name->string = function->name->string
                                                     + "__ls_staticconstructor";
                        }
                        else
                        {
                            function->isConstructor = true;
                        }
                    }
                }

                if (function->isConstructor)
                {
                    curClass->constructor = function;
                }
                else if (!function->property)
                {
                    curClass->functionDecls.push_back(function);
                }
            }
        }

        function = (FunctionLiteral *)TraversalVisitor::visit(function);

        curFunction = oldFunction;

        return function;
    }

    VariableDeclaration *visit(VariableDeclaration *v)
    {
        v->function = curFunction;
        if (!curFunction)
        {
            v->classDecl = curClass;
            if (curClass)
            {
                curClass->varDecls.push_back(v);
            }
        }
        else
        {
            curFunction->localVariables.push_back(v);
        }

        v = (VariableDeclaration *)TraversalVisitor::visit(v);

        return v;
    }

    ImportStatement *visit(ImportStatement *import)
    {
        utString dep = import->spath + ".";

        dep += import->classname;

        if (!curPackage)
        {
            LSError("Importing %s outside of package declaration in %s", dep.c_str(), cunit->filename.c_str());
        }


        if (cunit->dependencies.find(dep) == UT_NPOS)
        {
            cunit->dependencies.push_back(dep);
        }

        import = (ImportStatement *)TraversalVisitor::visit(import);

        curPackage->imports.push_back(import);

        return import;
    }
};
}
#endif
