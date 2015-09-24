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

#ifndef _lstypequalifyvisitor_h
#define _lstypequalifyvisitor_h

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
/*
 * Visits AST to identify fully qualified type specifications and
 * transforms these to Identifiers ahead of other AST visitors
 */
class TypeQualifyVisitor : public TraversalVisitor {
private:

    utArray<Type *> systemTypes;
    utArray<Type *> importTypes;
    utArray<Type *> packageTypes;
    utArray<Type *> allTypes;

    PackageDeclaration *curPackage;
    LSLuaState         *vm;

public:

    TypeQualifyVisitor(LSLuaState *ls) :
        TraversalVisitor(), curPackage(NULL), vm(ls)
    {
        visitor = this;
    }

    CompilationUnit *visit(CompilationUnit *cunit)
    {
        this->cunit = cunit;

        cunit = TraversalVisitor::visit(cunit);

        return cunit;
    }

    void errorMissingImport(ImportStatement *import)
    {
        utArray<Type *> types;
        vm->getAllTypes(types);
        for (UTsize i = 0; i < types.size(); i++)
        {
            if (!strcasecmp(import->fullPath.c_str(), types[i]->getFullName().c_str()))
            {
                error("Failed to import type \"%s\". However, found \"%s\", improper case on import?", import->fullPath.c_str(), types[i]->getFullName().c_str());
                return;
            }
        }

        error("Failed to import type %s on line %d", import->fullPath.c_str(), import->lineNumber);
    }

    PackageDeclaration *visit(PackageDeclaration *pkg)
    {
        utArray<ImportStatement *> remove;
        utArray<utString>          wildcardPackages;
        ImportStatement            *import;

        // squash wildcard imports
        for (UTsize i = 0; i < pkg->imports.size(); i++)
        {
            import = pkg->imports.at(i);

            if (import->classname == "*")
            {
                if (wildcardPackages.find(import->spath) == UT_NPOS)
                {
                    wildcardPackages.push_back(import->spath);
                }
            }
        }

        // mark all imports (including .* for removal
        // as these will be redundant when wildcard imports
        // are brought in
        for (UTsize i = 0; i < pkg->imports.size(); i++)
        {
            import = pkg->imports.at(i);

            if (wildcardPackages.find(import->spath) != UT_NPOS)
            {
                remove.push_back(import);
            }
        }

        // remove
        for (UTsize i = 0; i < remove.size(); i++)
        {
            import = remove.at(i);
            pkg->imports.erase(import);
        }

        // add all visible wildcard types

        for (UTsize i = 0; i < wildcardPackages.size(); i++)
        {
            utArray<Type *> wildTypes;
            utString        wpackage = wildcardPackages.at(i);
            vm->getPackageTypes(wpackage, wildTypes);

            // for each wildcard import, creating a new
            // import statment and fill it in
            for (UTsize j = 0; j < wildTypes.size(); j++)
            {
                Type *wtype = wildTypes.at(j);

                import            = new ImportStatement();
                import->spath     = wpackage;
                import->classname = wtype->getName();
                import->fullPath  = wtype->getFullName();
                import->type      = wtype;

                // calculate path array
                char _path[1024];
                char *path = _path;

                snprintf(path, 1023, "%s", import->fullPath.c_str());

                int len = (int)strlen(path);

                for (int k = 0; k <= (int)strlen(path); k++)
                {
                    if ((path[k] == '.') || (path[k] == 0))
                    {
                        path[k] = 0;
                        import->path.push_back(path);
                        path = path + k + 1;
                        k    = -1;

                        if (path >= _path + len)
                        {
                            break;
                        }
                    }
                }

                // and add
                pkg->imports.push_back(import);
            }
        }

        // get the system types
        Assembly *system = vm->getAssembly("System");
        assert(system);
        system->getTypes(systemTypes);

        vm->getPackageTypes(pkg->spath, packageTypes);

        // insert all imports
        for (UTsize i = 0; i < pkg->imports.size(); i++)
        {
            import = pkg->imports.at(i);

            if (!import->type)
            {
                import->type = vm->getType(import->fullPath.c_str());
            }

            if (!import->type)
            {
                lineNumber = import->lineNumber;
                errorMissingImport(import);
            }
            else
            {
                importTypes.push_back(import->type);
            }
        }

        for (UTsize i = 0; i < packageTypes.size(); i++)
        {
            allTypes.push_back(packageTypes.at(i));
        }

        for (UTsize i = 0; i < importTypes.size(); i++)
        {
            allTypes.push_back(importTypes.at(i));
        }

        for (UTsize i = 0; i < systemTypes.size(); i++)
        {
            allTypes.push_back(systemTypes.at(i));
        }

        return (PackageDeclaration *)TraversalVisitor::visit(pkg);
    }

    /*
     * Flattens out a property expression to a path array
     */
    void getPropertyExpressionPath(PropertyExpression *expression, utArray<utString>& path)
    {
        PropertyExpression *p = expression;

        while (p)
        {
            if (p->rightExpression->astType == AST_STRINGLITERAL)
            {
                path.push_back(((StringLiteral *)p->rightExpression)->string);
            }

            if (p->rightExpression->astType == AST_IDENTIFIER)
            {
                path.push_back(((Identifier *)p->rightExpression)->string);
            }

            if (p->leftExpression->astType == AST_STRINGLITERAL)
            {
                path.push_back(((StringLiteral *)p->leftExpression)->string);
            }

            if (p->leftExpression->astType == AST_IDENTIFIER)
            {
                path.push_back(((Identifier *)p->leftExpression)->string);
            }

            if (p->leftExpression->astType == AST_PROPERTYEXPRESSION)
            {
                p = (PropertyExpression *)p->leftExpression;
            }
            else if (p->rightExpression->astType == AST_PROPERTYEXPRESSION)
            {
                p = (PropertyExpression *)p->rightExpression;
            }
            else
            {
                break;
            }
        }
    }

    /*
     * A PropertyExpression may actually be a fully qualified type name (FQT)
     * and not an accessor, this visitor will recursively
     * test a propery expression for this case and rewrite
     * the AST with an identifier if a matching type
     * is found
     */
    Expression *visit(PropertyExpression *expression)
    {
        // array access is never a FQT
        if (expression->arrayAccess)
        {
            return expression;
        }

        utString classpath;

        utArray<utString> path;

        // flatten out the property expression to a path
        getPropertyExpressionPath(expression, path);

        Type *match = NULL;
        // if the expression fully matched without any
        // leftovers, this will be true
        // If true, we replace the entire ProperyExpression with
        // an Identifier node
        // If false, we only replace the left expression
        bool exprMatched = false;

        // go through the path, in reverse order and
        // find the matching type if any
        if (path.size() > 1)
        {
            utString classpath;

            for (int i = ((int)path.size()) - 1; i >= 0; i--)
            {
                classpath += path.at((UTsize)i);

                for (UTsize j = 0; j < allTypes.size(); j++)
                {
                    Type *type = allTypes.at(j);
                    if (type->getFullName() == classpath)
                    {
                        if (!i)
                        {
                            exprMatched = true; // we fully matched
                        }
                        match = type;
                    }
                }

                if (i)
                {
                    classpath += ".";
                }
            }
        }

        if (match)
        {
            if (!exprMatched)
            {
                // we matched the left side, so replace it leaving
                // the right side intact
                expression->leftExpression = new Identifier(match->getFullName());
                return expression;
            }
            else
            {
                // rewrite AST with Identifier
                return new Identifier(match->getFullName());
            }
        }

        // and recurse
        return TraversalVisitor::visit(expression);
    }
};
}
#endif
