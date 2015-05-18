/*
===========================================================================
Loom SDK
Copyright 2011, 2012, 2013 
The Game Engine Company, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 
===========================================================================
*/

package system.reflection {

/**
 *  Represents the type of element that a member can be.
 *  @todo: Is this needed?
 */
native class MemberTypes {
    
    /**
     *  Indicates whether the Member is a constructor.
     */
    native var constructor:Boolean;
    
    /**
     *  Indicates whether the Member is a constructor.
     */
    native var field:Boolean;
    
    /**
     *  Indicates whether the Member is a method.
     */
    native var method:Boolean;
    
    /**
     *  Indicates whether the Member is a property.
     */
    native var property:Boolean;

    /**
     *  Sets all flags on MemberTypes to false.
     */
    public native function clear();

};

/**
 *  Represents information about the attributes of a member and provides access to member MetaInfo.
 *  MemberInfos can represent Member methods, fields, properties or constructors.
 *  
 *  @section examples Example
 *  @include MemberInfo.ls
 */
native class MemberInfo {

    /**
     *  Gets the name of the MemberInfo.
     *
     *  @return Name of the MemberInfo.
     */
    public native function getName():String;

    /**
     *  Returns the Type that represents the type that the member is or returns.
     *
     *  @return Type info for MemberInfos type.
     */
    public native function getTypeInfo():Type;

    /**
     *  Gets the MetaInfo for the specified Metadata tag name.
     *
     *  @param name Name of the metadata tag to lookup.
     *  @return MetaInfo for the specified Metadata tag name, null if the name does not exist on the MemberInfo.
     */
    public native function getMetaInfo(name:String):MetaInfo;

    /**
     *  Gets the Type that the MemberInfo belongs to.
     *
     *  @return Type that the member info belongs to.
     */
    public native function getDeclaringType():Type;

    /**
     *  Gets the native ordinal for a MemberInfo.
     *
     *  @return 0 for no native ordinal, otherwise the native ordinal.
     */
    public native function getOrdinal():Number;

    /**
     *  Gets the Type of the Member for example getMemberInfo on: 
     *  
     *  public var x:Number;
     *  
     *  would return the System.Number type
     *  @return Type of the member declaration
     */
    public native function getMemberType():Type;
    
}

/**
 *  Represents information about a metadata tag on a MemberInfo Object.
 */
[Native(managed)]   
native class MetaInfo {

    /**
     *  Name of the MetaData tag.
     */    
    public native var name:String;

    /**
     *  Gets the value of an attribute specified by the key.
     *
     *  @param key Attribute name.
     *  @return Attribute value, null if the attribute does not exist. 
     */
    public native function getAttribute(key:String):String;
}

/**
 *  Represents information about a field (variable) on a Type.
 */
[Native(managed)]   
native class FieldInfo extends MemberInfo {

    /**
     *  Sets the value on the Field on the specified object.
     *
     *  @param obj Target that contains the field represented in the FieldInfo.
     *  @param value The value that the obj field will be set to.
     */
    public native function setValue( obj:Object, value:Object );
    
    /**
     *  Gets the value from the Field on the specified object.
     *
     *  @param obj Target that contains the field represented in the FieldInfo.
     *  @return The value of the field on obj.
     */
    public native function getValue( obj:Object ):Object;
        
}

/**
 *  Represents information about a property (getter/setter) on a Type.
 */
[Native(managed)]   
native class PropertyInfo extends MemberInfo {

    /**
     *  Gets the setter method portion of the property.
     *
     *  @return The MethodInfo that represents the setter method of the property.
     */
    public native function getSetMethod():MethodInfo;

    /**
     *  Gets the getter method portion of the property.
     *
     *  @return The MethodInfo that represents the getter method of the property.
     */
    public native function getGetMethod():MethodInfo;
        
}

/**
 *  Represents a parameter in a MethodInfo or ConstructorInfo.
 */
[Native(managed)]   
native class ParameterInfo {

    /**
     *  Gets the name of the ParameterInfo.
     *
     *  @return Name of the parameter.
     */
    public native function getName():String;
    
    /**
     *  Gets the Type of the parameter as it is represented in the method or constructor.
     *
     *  @return Type of the parameter.
     */
    public native function getParameterType():Type;
    
}

/**
 *  Base class for representing Constructors or Methods on Types.
 */
native class MethodBase extends MemberInfo {
    
    /**
     *  Indicates whether the Method is a Constructor.
     */
    public native function isConstructor():Boolean;
    
    /**
     *  Indicates whether the Method is Public or not.
     */
    public native function isPublic():Boolean;

    /**
     *  Indicates whether the Method is Protected or not.
     */
    public native function isProtected():Boolean;

    /**
     *  Indicates whether the Method is Private or not.
     */
    public native function isPrivate():Boolean;

    /**
     *  Indicates whether the Method is an Operator.
     */
    public native function isOperator():Boolean;

    /**
     *  Indicates whether the Method is Native or not.
     */
    public native function isNative():Boolean;

    /**
     *  Indicates whether the Method is Static or not.
     */
    public native function isStatic():Boolean;

    /**
     *  Gets the number of parameters in the MethodBase.
     *
     *  @return Number of parameters in the MethodBase.
     */
    public native function getNumParameters():int;

    /**
     *  Gets the associated ParameterInfo at the specified index.
     *
     *  @param idx Index of associated ParameterInfo.
     *  @return Instance of the associated ParameterInfo.
     */
    public native function getParameter(idx:int):ParameterInfo;
    
}

/**
 *  Represents information about a Method on a Type.
 */
[Native(managed)]   
native class MethodInfo extends MethodBase {

    /**
     *  Calls the represented method on the specified object.
     *
     *  @param obj Target that contains the method represented in the MethodInfo.
     *  @param args Arbitrary list of values to take as the parameters in calling the method.
     */
    public native function invoke(obj:Object, ...args);

    /**
     *  Calls the represented method on the specified object.
     *
     *  @param obj Target that contains the method represented in the MethodInfo.
     *  @param arg A single argument which makes invokeSingle considerably faster to call as it doesn't 
     *             require a varargs Vector to be created.
     */
    public native function invokeSingle(obj:Object, arg:Object);
        
}

/**
 *  Represents information about a Constructor on a Type.
 */
[Native(managed)]   
native class ConstructorInfo extends MethodBase {

    // LOOM-293: support parameters in reflection instantiation (System.Reflection.ConstructorInfo:invoke)
    //public native function invoke(...args):Object;    
    
    /**
     *  Calls the represented constructor.
     *
     *  @return An instance of the object that was constructed.
     */
    public native function invoke():Object;    
}

/**
 *  Represents information about a Type that belongs to an assembly.
 *  Type is the root of System.Reflection functionality and is the entry point to obtaining data about
 *  Classes, Members, Methods, and other structures.
 */
[Native(managed)]   
public native class Type extends MemberInfo {

    /**
     *  Gets the Constructor for the Type.
     *
     *  @return The Constructor.
     */
    public native function getConstructor():ConstructorInfo;    
    
    /**
     *  Gets the fully qualified name for the Type, including the package for the type but not the Assembly.
     *
     *  @return Fully qualified name for the Type.
     */
    public native function getFullName():String;
    
    /**
     *  Indicates whether the Type is a Class or not.
     */
    public native function isClass():Boolean;
    
    /**
     *  Indicates whether the Type is a Struct or not.
     */
    public native function isStruct():Boolean;
    
    /**
     *  Indicates whether the Type is an Interface or not.
     */
    public native function isInterface():Boolean;
    
    /**
     *  Gets the Assembly that the Type belongs to.
     *
     *  @return The Type's Assembly.
     */
    public native function getAssembly():Assembly;
    
    /**
     *  Gets the Base Parent Type that the Type belongs to.
     *
     *  @return The Type's Base Parent Type.
     */
    public native function getParent():Type;
    
    /**
     *  Gets the number of Interfaces's associated with the Type.
     *
     *  @return Number of Interfaces's in the Type.
     */
    public native function getInterfaceCount():int;

    /**
     *  Gets the number of FieldInfo's associated with the Type and its inherited Fields.
     *
     *  @return Number of FieldInfo's in the Type.
     */
    public native function getFieldInfoCount():int;
    
    /**
     *  Gets the number of MethodInfo's associated with the Type and its inherited Methods.
     *
     *  @return Number of MethodInfo's in the Type.
     */
    public native function getMethodInfoCount():int;

    /**
     *  Gets the number of PropertyInfo's associated with the Type and its inherited Properties.
     *
     *  @return Number of PropertyInfo's in the Type.
     */
    public native function getPropertyInfoCount():int;
    
    /**
     *  Gets the Interface Type associated with the specified index.
     *
     *  @param index Index of associated Type.
     *  @return Type of the associated Interface.
     */
    public native function getInterface(index:int):Type;

    /**
     *  Gets the FieldInfo associated with the specified index.
     *
     *  @param index Index of associated FieldInfo.
     *  @return Instance of the associated FieldInfo.
     */
    public native function getFieldInfo(index:int):FieldInfo;
    
    /**
     *  Gets the MethodInfo associated with the specified index.
     *
     *  @param index Index of associated MethodInfo.
     *  @return Instance of the associated MethodInfo.
     */
    public native function getMethodInfo(index:int):MethodInfo;

    /**
     *  Gets the PropertyInfo associated with the specified index.
     *
     *  @param index Index of associated PropertyInfo.
     *  @return Instance of the associated PropertyInfo.
     */
    public native function getPropertyInfo(index:int):PropertyInfo;
    
    /**
     *  Gets a FieldInfo by its name.
     *
     *  @param name Name of the FieldInfo to match.
     *  @return FieldInfo that matches to the name, null if the FieldInfo does not exist.
     */
    public native function getFieldInfoByName(name:String):FieldInfo;

    /**
     *  Gets the MethodInfo associated with the specified name.
     *
     *  @param name Name of the MethodInfo.
     *  @return Instance of the associated FieldInfo, null if the method name does not exist.
     */
    public native function getMethodInfoByName(name:String):MethodInfo;

    /**
     *  Gets a PropertyInfo by its name.
     *
     *  @param name Name of the PropertyInfo to match.
     *  @return PropertyInfo that matches to the name, null if the PropertyInfo does not exist.
     */
    public native function getPropertyInfoByName(name:String):PropertyInfo;
    
    public native function isDerivedFrom(type:Type):Boolean;
    
    /**
     *  Gets a list of all FieldInfo and PropertyInfo names on the Type.
     *
     *  @return List of names for all the Fields and Properties.
     */
    public function getFieldAndPropertyList():Vector.<String>
    {
        var result:Vector.<String> = new Vector.<String>();

        var i:Number;
        for(i=0; i<getFieldInfoCount(); i++)
        {
            var fi = getFieldInfo(i);
            result.pushSingle(fi.getName());
        }

        for(i=0; i<getPropertyInfoCount(); i++)
        {
            var pi = getPropertyInfo(i);
            result.pushSingle(pi.getName());
        }

        return result;
    }

    /**
     *  Helper function to get a value of a field or a property on an object by name.
     *
     *  @param object The target object that contains the field/property.
     *  @param _name Name of the property/field.
     *  @param defaultValue Value that is returned if a field or property does not exist on the target object.
     *  @return Value of the property/field, default value if a field or property does not exist on the target object.
     */
    public function getFieldOrPropertyValueByName(object:Object, _name:String, defaultValue:Object = null):Object
    {
        Debug.assert(object, "Can't get a property or field without an object to get it from!");

        var field = getFieldInfoByName(_name);
        if(field)
            return field.getValue(object);

        var prop = getPropertyInfoByName(_name);
        if(prop)
        {
            var method = prop.getGetMethod();
            Debug.assert(method, "Property without getter!");
            return method.invoke(object);
        }

        return defaultValue;
    }

    /**
     *  Helper function to set a value of a field or a property on an object by name.
     *
     *  @param object The target object that contains the field/property.
     *  @param name Name of the property/field.
     *  @param value Value to apply to the field/property on the target object.
     */
    public function setFieldOrPropertyValueByName(object:Object, name:String, value:Object):Boolean
    {
        Debug.assert(object, "Must provide a non-null object!");
        
        var field = getFieldInfoByName(name);
        if(field)
        {
            field.setValue(object, value);
            return true;
        }

        var prop = getPropertyInfoByName(name);
        if(prop)
        {
            var method = prop.getSetMethod();
            if(!method)
                return false;

            method.invokeSingle(object, value);
            return true;
        }

        return false;
    }
    
    public function typeHasOwnProperty(object:Object, name:String):Boolean
    {
        var field = getFieldInfoByName(name);
        if(field)
            return true;
        var prop = getPropertyInfoByName(name);
        if(prop)
            return true;
        return false;
    }
    
    /**
     *  Gets a Type by its fully qualified name.
     *
     *  @param fullname Fully qualified name for the Type, including the package for the type but not the Assembly.
     *  @return Type that matches to the name, null if the Type does not exist.
     */
    public static native function getTypeByName(fullName:String):Type;

}

}