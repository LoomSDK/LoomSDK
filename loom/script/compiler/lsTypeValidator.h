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

#ifndef _lstypevalidator_h
#define _lstypevalidator_h

#include "loom/script/common/lsLog.h"
#include "loom/script/loomscript.h"

namespace LS {
/************************************************************************
* TypeValidator validates a type (class, struct, enum, and interfaces
* are validated), including inheritance validation.
* It will error for conflicting fields, overloads with mismatch signature
* mixing static/instance method on overrides, etc.  This class
* is meant to keep the AST visitors clean of these types of checks
************************************************************************/

class TypeValidator {
    LSLuaState       *vm;
    CompilationUnit  *cunit;
    ClassDeclaration *cls;

public:


    TypeValidator(LSLuaState *vm, CompilationUnit *cunit, ClassDeclaration *cls)
    {
        this->vm    = vm;
        this->cls   = cls;
        this->cunit = cunit;
    }

    void validateStructType(Type *type)
    {
        if (!type->isStruct())
        {
            return;
        }

        Type *baseType = type->getBaseType();

        // Check that we're inheriting from system.Object
        if (type->isStruct() && baseType && (baseType->getFullName() != "system.Object"))
        {
            error(NULL, "Inheriting struct type from base other than system.Object %s : %s", type->getFullName().c_str(), baseType->getFullName().c_str());
        }

        // Check that all constructor parameters have default arguments
        MemberTypes ctype;
        ctype.constructor = true;
        utArray<MemberInfo *> members;
        type->findMembers(ctype, members, false);

        ConstructorInfo *cinfo = NULL;

        if (members.size())
        {
            cinfo = (ConstructorInfo *)members.at(0);
        }

        if (cinfo && !cinfo->defaultConstructor)
        {
            for (int i = 0; i < cinfo->getNumParameters(); i++)
            {
                ParameterInfo *p = cinfo->getParameter(i);
                if (!p->attributes.hasDefault)
                {
                    error(cinfo,
                          "Struct type %s has a constructor which defines parameters without default values.  Struct type constructors must provide default parameters for all parameters.",
                          type->getFullName().c_str());
                }
            }
        }

        if (!type->findMember("__op_assignment") || !type->findMember("__op_assignment")->isMethod())
        {
            error(NULL,
                  "Struct type %s must define an assignment operator overload in the form of \"public static operator function =(a:MyStruct, b:MyStruct):MyStruct\".",
                  type->getFullName().c_str());
        }
    }

    /************************************************************************
    * For efficiency, primitive types are represented in the VM by number, string, boolean datatypes
    * and not instances (which are tables).  This means that they needs to be handled
    * specially.  The compiler transforms instance methods on primitive types to
    * static methods which take the primitive data in arg0.  The matching is done by
    * method name with a _ prepended to the static method
    ************************************************************************/
    void validatePrimitive(Type *type)
    {
        if (!type->isPrimitive())
        {
            return;
        }

        if (type->getBaseType() != NULL)
        {
            if (type->getBaseType()->getFullName() != "system.Object")
            {
                error(NULL, "Primitive type %s not inherited from system.Object", type->getFullName().c_str());
            }
        }

        //  run through and ensure that all methods with _
        // (ie. transformed primitive methods are private, static, and have a matching instance method which is public)

        MemberTypes mtypes;
        mtypes.clear();
        mtypes.method = true;
        utArray<MemberInfo *> minfos;
        type->findMembers(mtypes, minfos, false);

        utArray<MemberInfo *> checked;

        for (UTsize i = 0; i < minfos.size(); i++)
        {
            lmAssert(minfos.at(i)->isMethod(), "Non-method in type method query");
            MethodInfo *m1 = (MethodInfo *)minfos.at(i);

            if (m1->getName()[0] == '_')
            {
                if (!m1->isStatic() || !m1->isPrivate())
                {
                    error(m1, "Primitive Type Error: transform method %s must be private and static", m1->getStringSignature().c_str());
                }

                // make sure we have a matching public call
                MethodInfo *found = NULL;
                for (UTsize j = 0; j < minfos.size(); j++)
                {
                    // don't attempt to match against self
                    if (i == j)
                    {
                        continue;
                    }

                    lmAssert(minfos.at(j)->isMethod(), "Non-method in type method query");
                    MethodInfo *m2 = (MethodInfo *)minfos.at(j);

                    // match name of method with static transform method minus the _
                    if (!strcasecmp(m2->getName(), &(m1->getName()[1])))
                    {
                        found = m2;
                        break;
                    }
                }

                if (!found)
                {
                    // We haven't found a matching instance method
                    // check for a property instead
                    utString   pname  = &m1->getName()[1];
                    MemberInfo *pinfo = type->findMember(pname.c_str(), false);
                    if (pinfo && pinfo->isProperty())
                    {
                        // ensure we do not have a property setter on primitive type
                        // as they are not (currently) supported
                        if (((PropertyInfo *)pinfo)->getSetMethod())
                        {
                            error(m1, "Primitive Type Error: Property set defined for %s", m1->getStringSignature().c_str());
                        }

                        continue; // we found one, so continue checks
                    }
                }

                if (!found)
                {
                    error(m1, "Primitive Type Error: No matching instance method for static transform method %s", m1->getStringSignature().c_str());
                }

                if (!found->isPublic())
                {
                    error(m1, "Primitive Type Error: instance method for static transform method %s is not public", m1->getStringSignature().c_str());
                }

                if (!found->isNative())
                {
                    error(m1, "Primitive Type Error: instance method for static transform method %s is not marked native", m1->getStringSignature().c_str());
                }

                // now check the method signatures
                validateRelatedMethods(m1, found, true);

                // add to checked to avoid redundancy
                checked.push_back(m1);
                checked.push_back(found);
            }
            else
            {
                if (m1->isStatic() && !m1->isPublic())
                {
                    error(m1, "Primitive Type Error: static methods on primitive type, which aren't transformed primitive methods (pre-pended with '_') must be public", m1->getStringSignature().c_str());
                }
            }
        }

        // now check that instance methods have a transformed static backing
        for (UTsize i = 0; i < minfos.size(); i++)
        {
            lmAssert(minfos.at(i)->isMethod(), "Non-method in type method query");
            MethodInfo *m1 = (MethodInfo *)minfos.at(i);

            // already checked?
            if (checked.find(m1) != UT_NPOS)
            {
                continue;
            }

            // we don't care about statics as these are not transformed
            if (m1->isStatic())
            {
                continue;
            }

            if (!m1->isNative())
            {
                error(m1, "Primitive Type Error: instance method not marked native", m1->getStringSignature().c_str());
            }

            if (!m1->isPublic())
            {
                error(m1, "Primitive Type Error: instance method not marked public", m1->getStringSignature().c_str());
            }

            // make sure we have a matching transformed private static call
            MethodInfo *found = NULL;
            for (UTsize j = 0; j < minfos.size(); j++)
            {
                // don't attempt to match against self
                if (i == j)
                {
                    continue;
                }

                lmAssert(minfos.at(j)->isMethod(), "Non-method in type method query");
                MethodInfo *m2 = (MethodInfo *)minfos.at(j);

                if (checked.find(m2) != UT_NPOS)
                {
                    continue;
                }

                // match name of method with static transform method minus the _
                if (!strcasecmp(m1->getName(), &(m2->getName()[1])))
                {
                    found = m2;
                    break;
                }
            }

            if (!found)
            {
                error(m1, "Primitive Type Error: No matching static transform method for instance method %s", m1->getStringSignature().c_str());
            }
        }
    }

    /************************************************************************
    * Validate related methods, this is called when overriding methods to verify
    * that return types and arguments match.  It is also called to verify that
    * a transformed static primitive method and the instance methods are
    * properly constructed.  See validatePrimitive for more information on
    * primitive type transformations
    ************************************************************************/
    void validateRelatedMethods(MethodInfo *m1, MethodInfo *m2, bool primitiveTransform = false)
    {
        Type *type = m1->getDeclaringType();

        // check return type

        if (m1->getReturnType() != m2->getReturnType())
        {
            const char *r1 = "system.Void";
            const char *r2 = "system.Void";

            if (m1->getReturnType())
            {
                r1 = m1->getReturnType()->getFullName().c_str();
            }

            if (m2->getReturnType())
            {
                r2 = m2->getReturnType()->getFullName().c_str();
            }

            error(m1, "Method Override Error: return type mismatch on %s.%s():%s and base type %s.%s():%s",
                  type->getFullName().c_str(), m1->getName(), r1,
                  m2->getDeclaringType()->getFullName().c_str(), m2->getName(), r2);
        }

        // check arguments
        bool parmError = false;
        if (!primitiveTransform && (m1->getNumParameters() != m2->getNumParameters()))
        {
            parmError = true;
        }
        else if (primitiveTransform && (m1->getNumParameters() - 1 != m2->getNumParameters()))
        {
            parmError = true;
        }
        else
        {
            if (primitiveTransform)
            {
                if (m1->getNumParameters() < 1)
                {
                    error(m1, "Primitive Type Error: transformed method has 0 parameters and should take an instance of the primitive type in arg0:%s", m1->getStringSignature().c_str());
                }
                if (m1->getParameter(0)->getParameterType() != type)
                {
                    error(m1, "Primitive Type Error: transformed method has wrong parameter type in arg0: %s", m1->getStringSignature().c_str());
                }
            }

            for (int i = 0; i < m2->getNumParameters(); i++)
            {
                ParameterInfo *p1 = primitiveTransform ? m1->getParameter(i + 1) : m1->getParameter(i);
                ParameterInfo *p2 = m2->getParameter(i);

                if (p1->getParameterType() != p2->getParameterType())
                {
                    parmError = true;
                    break;
                }
            }
        }

        if (parmError)
        {
            utString sig1 = m1->getStringSignature();
            utString sig2 = m2->getStringSignature();

            error(m1, "Method Error: parameter mismatch on %s.%s and base type %s.%s",
                  type->getFullName().c_str(), sig1.c_str(),
                  m2->getDeclaringType()->getFullName().c_str(), sig2.c_str());
        }
    }

    void validateInheritance(Type *type)
    {
        Type *baseType = type->getBaseType();

        if (!baseType)
        {
            return;
        }

        // Check that we are not inheriting from a struct as this is not allowed
        if (baseType->isStruct())
        {
            error(NULL, "Inheriting from struct type %s : %s.  Structure types are implicitly final.", type->getFullName().c_str(), baseType->getFullName().c_str());
        }

        if (baseType->isFinal())
        {
            error(NULL, "Inheriting from final type %s : %s", type->getFullName().c_str(), baseType->getFullName().c_str());
        }

        // TODO: This should be a sealed class check
        // https://theengineco.atlassian.net/browse/LOOM-588
        if (baseType->isPrimitive())
        {
            error(NULL, "Inheriting from primitive type %s : %s", type->getFullName().c_str(), baseType->getFullName().c_str());
        }

        // first check member variables, which can't be overridden so
        // any duplicate is an error

        MemberTypes mtypes;
        mtypes.clear();
        mtypes.field = true;
        utArray<MemberInfo *> minfos;
        type->findMembers(mtypes, minfos, false);

        for (UTsize i = 0; i < minfos.size(); i++)
        {
            FieldInfo  *mi  = (FieldInfo *)minfos.at(i);
            MemberInfo *bmi = baseType->findMember(mi->getName(), true);

            if (bmi && bmi->isField())
            {
                // allow static members to have same names
                if (((FieldInfo *)bmi)->isStatic() && mi->isStatic())
                {
                    continue;
                }
            }

            if (bmi)
            {
                error(mi, "Field Error: %s:%s conflicts with base type %s:%s",
                      type->getFullName().c_str(), mi->getName(),
                      bmi->getDeclaringType()->getFullName().c_str(), bmi->getName());
            }
        }

        mtypes.clear();
        minfos.clear();

        // next up let's check properties

        mtypes.property = true;
        type->findMembers(mtypes, minfos, false);

        for (UTsize i = 0; i < minfos.size(); i++)
        {
            MemberInfo *mi  = minfos.at(i);
            MemberInfo *bmi = baseType->findMember(mi->getName(), true);

            if (!bmi)
            {
                continue;
            }

            if (!bmi->isProperty())
            {
                error(mi, "Property Override Error: %s:%s, base type %s:%s is not a property",
                      type->getFullName().c_str(), mi->getName(),
                      bmi->getDeclaringType()->getFullName().c_str(), bmi->getName());
            }

            PropertyInfo *p1 = (PropertyInfo *)mi;
            PropertyInfo *p2 = (PropertyInfo *)bmi;

            if (p1->getType() != p2->getType())
            {
                error(p1, "Property Override Error: type mismatch on property field %s.%s:%s, base type %s.%s:%s",
                      type->getFullName().c_str(), mi->getName(), p1->getType()->getFullName().c_str(),
                      bmi->getDeclaringType()->getFullName().c_str(), bmi->getName(), p2->getType()->getFullName().c_str());
            }
        }


        mtypes.clear();
        minfos.clear();

        // next up let's check function signatures

        mtypes.method = true;
        type->findMembers(mtypes, minfos, false);

        for (UTsize i = 0; i < minfos.size(); i++)
        {
            MemberInfo *mi  = minfos.at(i);
            MemberInfo *bmi = baseType->findMember(mi->getName(), true);

            if (!bmi)
            {
                continue;
            }

            if (mi->isMethod())
            {
                if (!bmi->isMethod())
                {
                    error(mi, "Method Override Error: %s:%s, base type %s:%s is not a method",
                          type->getFullName().c_str(), mi->getName(),
                          bmi->getDeclaringType()->getFullName().c_str(), bmi->getName());
                }

                if (mi->isStatic() != bmi->isStatic())
                {
                    error(mi, "Method Override Error: static/instance mismatch on %s:%s and base type %s:%s",
                          type->getFullName().c_str(), mi->getName(),
                          bmi->getDeclaringType()->getFullName().c_str(), bmi->getName());
                }

                // static methods may have different signatures
                // TODO: Look at how this affects super calls
                // https://theengineco.atlassian.net/browse/LOOM-591
                if (!mi->isStatic() && !bmi->isStatic())
                {
                    validateRelatedMethods((MethodInfo *)mi, (MethodInfo *)bmi);
                }
            }
        }
    }

    // validate native instance members are only on native types
    void validateNatives(Type *type)
    {
        // some types get a free pass
        if (type->isNative() || type->isPrimitive() ||
            (type->getFullName() == "system.BaseDelegate") || (type->getFullName() == "system.Object") ||
            (type->getFullName() == "system.Vector") || (type->getFullName() == "system.Dictionary"))
        {
            return;
        }

        utArray<MemberInfo *> tmembers;
        MemberTypes           mtypes;
        mtypes.property    = true;
        mtypes.method      = true;
        mtypes.field       = true;
        mtypes.constructor = true;
        type->findMembers(mtypes, tmembers, false);

        for (UTsize i = 0; i < tmembers.size(); i++)
        {
            MemberInfo *minfo = tmembers.at(i);
            if (minfo->isStatic())
            {
                continue;
            }

            if (minfo->isNative())
            {
                error(minfo, "Native member %s on non-native type: ", minfo->getName(), type->getFullName().c_str());
            }
        }
    }

    void validateInterfaces(Type *type)
    {
        // TODO: This should be hashy and not be
        // O(implementedCount * requiredCount), as that can be quite large!

        // The set of members that type and its bases implement.
        utArray<MemberInfo *> tmembers;
        MemberTypes           mtypes;
        mtypes.property = true;
        mtypes.method   = true;
        type->findMembers(mtypes, tmembers, true);

        // The set of members the interfaces require.
        utArray<MemberInfo *> imembers;
        type->getInterfaceMembers(imembers);

        UTsize i;
        for (i = 0; i < imembers.size(); i++)
        {
            MemberInfo *im = imembers.at(i);
            MemberInfo *tm = NULL;

            // find required member in list of implemented members.
            UTsize j;
            for (j = 0; j < tmembers.size(); j++)
            {
                if (!strcmp(tmembers[j]->getName(), im->getName()))
                {
                    tm = tmembers[j];
                    break;
                }
            }

            // Found it, consider next one.
            if (tm)
            {
                continue;
            }

            // Else log an error.
            for (UTsize j = 0; j < type->getNumInterfaces(); j++)
            {
                // See if this interface requires it.
                Type *interface = type->getInterface(j);
                if (interface->findMember(im->getName(), false))
                {
                    error(im, "Class %s does not implement member %s of interface %s",
                          type->getFullName().c_str(), im->getName(), interface->getFullName().c_str());
                }
            }
        }
    }

    void validateType(Type *type)
    {
        if (!type->isStruct() && !type->isDelegate() && (type->getFullName() != "system.BaseDelegate") && (type->getFullName() != "system.NativeDelegate"))
        {
            // Check that a non-struct class isn't overloading op assignent (these are always by reference)
            MemberInfo *minfo = type->findMember("__op_assignment");

            if (minfo)
            {
                error(minfo, "Type Error: non-struct type %s overloads the assignment operator", type->getFullName().c_str());
            }
        }
    }

    void validate()
    {
        Type *type = cls->type;

        validateType(type);

        validateStructType(type);

        validateInheritance(type);

        validatePrimitive(type);

        validateInterfaces(type);

        validateNatives(type);
    }

    void error(MemberInfo *memberInfo, const char *format, ...)
    {
        if (memberInfo)
        {
            LSLog(LSLogError, "ERROR: %s %i", memberInfo->getSource().c_str(), memberInfo->getLineNumber());
        }
        else
        {
            LSLog(LSLogError, "ERROR: %s", cunit->filename.c_str());
        }

        char    buff[2048];
        va_list args;
        va_start(args, format);
#ifdef _MSC_VER
        vsprintf_s(buff, 2046, format, args);
#else
        vsnprintf(buff, 2046, format, args);
#endif
        va_end(args);

        LSLog(LSLogError, buff);

        exit(EXIT_FAILURE);
    }

    void warning(MemberInfo *memberInfo, const char *format, ...)
    {
        if (memberInfo)
        {
            LSLog(LSLogWarn, "WARNING: %s %i", memberInfo->getSource().c_str(), memberInfo->getLineNumber());
        }
        else
        {
            LSLog(LSLogWarn, "WARNING: %s", cunit->filename.c_str());
        }


        char    buff[2048];
        va_list args;
        va_start(args, format);
#ifdef _MSC_VER
        vsprintf_s(buff, 2046, format, args);
#else
        vsnprintf(buff, 2046, format, args);
#endif
        va_end(args);

        LSLog(LSLogWarn, buff);
    }
};
}
#endif
