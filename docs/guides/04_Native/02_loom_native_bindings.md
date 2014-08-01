title: Script Bindings
description: Exposing C++ to LoomScript.
!------

LoomScript is designed to be a useful and effective part of a larger picture. Static typing, familiar syntax, rich language features, a fast compiler, debuggers, profilers, and the Lua VM all add up to a compelling picture. But without anything to control, LoomScript would feel a bit lifeless! To that end, LoomScript features a powerful native bridge to allow access to C/C++ classes and methods.

Native bindings in LoomScript require two matching pieces:

* On the C++ side, you register your classes and any methods, fields, or properties. This is done via a fluent API based on Vinnie Falco's LuaBridge. Types are automatically determined in most cases via C++ template magic.

* On the script side, you declare "native" classes with methods, fields, and properties matching the C++ side. This is done by prefixing the native keyword in front of the class definition as well as any native members.

* Together, these two pieces allow fast, type-safe access to native code from LoomScript, as well as giving the LoomScript compiler the information it needs in order to make sure that your code is valid.

That's really the high level you need to know. From here, let's get practical.

## Binding Example

Here's what LoomScript bindings look like:

**C++ Side**

~~~cpp
#include "loom/script/loomscript.h"

static int registerLoomAssets(lua_State* L) 
{
   // Every class has to be in a package.
   beginPackage(L, "Loom")
 
   // Map the class type to a string name.
   .beginClass <LoomTextAsset> ("LoomTextAsset")
 
   // In this case, we don't want to allow a constructor, we want
   // the user to call this static method instead.
   .addStaticFunction("create", &LoomTextAsset::create)
   .addFunction("getContents", &LoomTextAsset::getContents)
   .addFunction("load", &LoomTextAsset::load)
   .addProperty("updateDelegate", &LoomTextAsset::getUpdateDelegate)   

   .endClass()

   .endPackage();

   return 0;
}

// This function is called from installPackageLoom - each package has a 
// registration function that calls these various install functions.
// If you're adding a new install method, find an appropriate package to
// to call it from. These are the files matching with lmPackage*.cpp.
void installLoomAssets() 
{
   LOOM_DECLARE_NATIVETYPE(LoomTextAsset, registerLoomAssets);
}
~~~

**LoomScript Side**

~~~{as}
// Note that package matches the C++ definition.
package Loom
{
    // And the class matches too - and it has the native keyword.
    public native class LoomTextAsset
    {
        public native static function create(path:String):LoomTextAsset;
    
        public native function load():void;
        public native var updateDelegate:NativeDelegate;
    }
}
~~~

##Structs and Classes
In addition to classes, LoomScript supports structs. These are identical to classes except that they copy by value rather than by reference. On the C++, bind them as usual, and provide an assignment operator. On the script side, use the struct keyword instead of class. Examples follow:

~~~cpp
.beginClass<color3b> ("Color3B")

    .addConstructor <void (*)(void)>()
    .addData("r", &color3b::r)
    .addData("g", &color3b::g)
    .addData("b", &color3b::b)
    .addFunction("Color3B", &color3b::set)

    // Note the assignment operator.
    .addStaticFunction("__op_assignment", &color3b::opAssignment)

.endClass()

// The implementation of opAssignment:
static void opAssignment(_ccColor3B* a, _ccColor3B* b) 
{
  *a = *b;
}

// And the script bindings.
native struct Color3B {

   public native var r:Number;
   public native var g:Number;
   public native var b:Number;
   
   public native function Color3B(r:Number = 0, g:Number = 0, b:Number = 0);

   // Note the assignment operator.
   public static native operator function =(a:Color3B, b:Color3B):Color3B;
} 
~~~

##Pure Natives, Managed Natives, and Native Structs
LoomScript allows you to deal with native code via one of two paths: pure natives and managed natives.

Pure natives are the simplest case. You simply bind a class, get a reference to it (I like to use a static accessor if I want to get an instance allocated from C++), and go. LoomScript allows you to call methods and access properties. However, you cannot subclass it, nor add any non-native instance variables to the definition. You can add static variables, static methods, and instance methods. Pure natives also incur memory allocation overhead each time they are passed back from native code to LoomScript. Registering them looks like this:

~~~cpp
NativeInterface::registerNativeType<MyType>(myRegistrationFunc);
~~~

All you have to do on the script side is declare a class using the native keyword:

~~~as3
public native class MyClass { public native var myField:String; };
~~~
Managed natives allow subclassing and mixing script/native members. They require some support via the managed native API, and need to be registered via:

~~~cpp
NativeInterface::registerManagedNativeType<MyType>(myRegistrationFunc);
~~~

They also need to notify the script compiler, with this metadata:

~~~cpp
[Native(managed)] public native class MyType
~~~

You can provide your own native management API via `NativeInterface::pushNativeInterface` and `NativeInterface::popNativeInterface`. This can allow you to implement comprehensive safe pointers or other advanced features. A quick search in the source code for existing uses of these methods should get you on the right track - or ask on the forums if you have specific questions.

## Binding to a C++ Method (Not overloaded)
**Script Side (DisplayObject.ls)**

~~~{as}
public native function getTargetTransformationMatrix(targetSpace:DisplayObject, resultMatrix:Matrix):void;
~~~ 

**C++ Side (l2dScript.cpp)**

~~~cpp
.addMethod("getTargetTransformationMatrix", &DisplayObject::getTargetTransformationMatrix)
~~~

## Binding to an overloaded C++ Method
Sometimes you will need to add bindings for native methods that are overloaded. Take the following example:

`MyClass::addChild` is overloaded and has three possible overloads:

~~~cpp
virtual void addChild(MyClass *child);
virtual void addChild(MyClass *child, int zOrder);
virtual void addChild(MyClass *child, int zOrder, int tag);
~~~

Choose the method you want to bind to directly and use the following syntax to bind it.

**C++ Side**

~~~cpp
.addFunction("addChild", 
    (void (MyClass::*)(MyClass *, int, int))
    &MyClass::addChild)
~~~ 

Note the construction of the cast. First is the return type of the desired overload of of addChild. Second comes a method pointer - in this case the type is MyClass, so you slap ::* at the end and call it good. Finally, the arguments - note these are just the types of the desired addChild overload's parameters, without the argument names.

**Script Side (cocos2d.ls)**

~~~{as}
public native function addChild(child:MyClass, zOrder:int = 0, tag:int = 0):void;
~~~ 

Script side stays nice and simple.

## Dealing With Enums
Enums are fundamentally integer values. So from the binding system's perspective, you are passing integers back and forth. Of course, it's no fun typing 1, 2, 3, when you could be saying MODE_ON, MODE_OFF, MODE_AUTO. You can set up an enum in script as follows:

~~~cpp
enum MyEnum
{
  A = 1,
  B,
  C
}
~~~ 

Notice that you can set values explicitly just as you can in C++. In fact for the most part you can simply copy a C++ enum into LoomScript and it will work!

For reference, the default behavior in C++ and LoomScript is for the first item in the enum to be zero, and for values for each item to be assigned incrementally from the previous item. If you don't specify any values explicitly, then things will be assigned 0, 1, 2, 3, etc. - in this example MyEnum.A is 1, so MyEnum.B will be 2 and MyEnum.C will be 3.

If you are binding a property of enum type, you have to tell the binding layer to treat it as an int. This is done in the following way:

~~~cpp
.addData("type",(int b2BodyDef::*)&b2BodyDef::type)
~~~ 

Notice the added `(int b2BodyDef::*)` - the int is the type we want the field to appear as, and b2BodyDef is the type the field is on.

You can bind functions that have enum parameters by using the overload syntax as described above, casting the enum to an int.

Some enum parameters may not cast properly. The following is a useful idiom when this happens:

~~~cpp
// Normal binding for a class using an enum called MyClassEnum.
.addStaticFunction("create", 
    // But cast to make the enum an int so we don't get an error about a missing type.
    (MyClass * (*)(const char *, const char *, float, int, Point))
    // We also have a cast here to unambiguously select which override we want - so we have to specify the enum type
    // properly in order to get the function point.
    (MyClass * (*)(const char *, const char *, float, MyClassEnum, Point))
    &MyClass::create)
~~~ 
