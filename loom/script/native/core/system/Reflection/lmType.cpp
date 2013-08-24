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

#include "loom/script/native/lsLuaBridge.h"
#include "loom/script/reflection/lsType.h"
#include "loom/script/reflection/lsMemberInfo.h"
#include "loom/script/reflection/lsFieldInfo.h"
#include "loom/script/reflection/lsMethodInfo.h"


using namespace LS;


static int registerSystemReflectionType(lua_State *L)
{
    beginPackage(L, "system.reflection")

       .beginClass<MemberTypes>("MemberTypes")

       .addConstructor<void (*)(void)>()

       .addVar("field", &MemberTypes::field)
       .addVar("constructor", &MemberTypes::constructor)
       .addVar("method", &MemberTypes::method)
       .addVar("property", &MemberTypes::property)

       .addMethod("clear", &MemberTypes::clear)

       .endClass()

       .beginClass<MemberInfo>("MemberInfo")
       .addMethod("getName", &MemberInfo::getName)
       .addMethod("getTypeInfo", &MemberInfo::getType)
       .addMethod("getMetaInfo", &MemberInfo::getMetaInfo)
       .addMethod("getDeclaringType", &MemberInfo::getDeclaringType)
       .addMethod("getOrdinal", &MemberInfo::getOrdinal)
       .addMethod("getMemberType", &MemberInfo::getType)
       .endClass()

       .beginClass<MetaInfo>("MetaInfo")
       .addVar("name", &MetaInfo::name)
       .addMethod("getAttribute", &MetaInfo::getAttribute)
       .endClass()

       .deriveClass<PropertyInfo, MemberInfo>("PropertyInfo")
       .addMethod("getSetMethod", &PropertyInfo::getSetMethod)
       .addMethod("getGetMethod", &PropertyInfo::getGetMethod)
       .endClass()

       .deriveClass<FieldInfo, MemberInfo>("FieldInfo")
       .addLuaFunction("getValue", &FieldInfo::getValue)
       .addLuaFunction("setValue", &FieldInfo::setValue)
       .endClass()

       .beginClass<ParameterInfo>("ParameterInfo")
       .addMethod("getName", &ParameterInfo::getName)
       .addMethod("getParameterType", &ParameterInfo::getParameterType)
       .endClass()

       .deriveClass<MethodBase, MemberInfo>("MethodBase")
       .addMethod("isConstructor", &MethodBase::isConstructor)
       .addMethod("isPublic", &MethodBase::isPublic)
       .addMethod("isProtected", &MethodBase::isProtected)
       .addMethod("isPrivate", &MethodBase::isPrivate)
       .addMethod("isOperator", &MethodBase::isOperator)
       .addMethod("isNative", &MethodBase::isNative)
       .addMethod("isStatic", &MethodBase::isStatic)
       .addMethod("getNumParameters", &MethodBase::getNumParameters)
       .addMethod("getParameter", &MethodBase::getParameter)
       .endClass()

       .deriveClass<MethodInfo, MethodBase>("MethodInfo")
       .addLuaFunction("invoke", &MethodInfo::_invoke)
       .addLuaFunction("invokeSingle", &MethodInfo::_invokeSingle)
       .endClass()

       .deriveClass<ConstructorInfo, MethodBase>("ConstructorInfo")
       .addLuaFunction("invoke", &ConstructorInfo::_invoke)
       .endClass()

       .deriveClass<Type, MemberInfo>("Type")

       .addStaticMethod("getTypeByName", &Type::getType)

       .addMethod("getFullName", &Type::getFullName)
       .addMethod("isInterface", &Type::isInterface)
       .addMethod("isClass", &Type::isClass)
       .addMethod("isStruct", &Type::isStruct)

       .addMethod("getAssembly", &Type::getAssembly)

       .addMethod("getFieldInfoCount", &Type::getFieldInfoCount)
       .addMethod("getFieldInfo", &Type::getFieldInfo)

       .addMethod("getPropertyInfoCount", &Type::getPropertyInfoCount)

       .addMethod("getMethodInfo", &Type::getMethodInfo)
       .addMethod("getPropertyInfo", &Type::getPropertyInfo)

       .addMethod("getConstructor", &Type::getConstructor)

       .addMethod("getPropertyInfoByName", &Type::findPropertyInfoByName)
       .addMethod("getFieldInfoByName", &Type::findFieldInfoByName)

       .endClass()


       .endPackage();

    return 0;
}


void installSystemReflectionType()
{
    NativeInterface::registerNativeType<MemberTypes>(registerSystemReflectionType);
    NativeInterface::registerManagedNativeType<Type>(registerSystemReflectionType);
    NativeInterface::registerManagedNativeType<MetaInfo>(registerSystemReflectionType);
    NativeInterface::registerNativeType<MemberInfo>(registerSystemReflectionType);
    NativeInterface::registerManagedNativeType<FieldInfo>(registerSystemReflectionType);
    NativeInterface::registerManagedNativeType<PropertyInfo>(registerSystemReflectionType);
    NativeInterface::registerManagedNativeType<ParameterInfo>(registerSystemReflectionType);
    NativeInterface::registerNativeType<MethodBase>(registerSystemReflectionType);
    NativeInterface::registerManagedNativeType<MethodInfo>(registerSystemReflectionType);
    NativeInterface::registerManagedNativeType<ConstructorInfo>(registerSystemReflectionType);
}
