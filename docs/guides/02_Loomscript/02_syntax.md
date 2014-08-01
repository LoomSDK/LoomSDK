title: Language Reference
description: How to Write LoomScript
!------

Let's cover LoomScript syntax with a series of illustrations. This guide assumes a basic knowledge of OOP programming, and some familiarity with a language like ActionScript 3, C++, C#, Java, JavaScript, ALGOL, UnityScript, UnrealScript, or TorqueScript.

We highly recommend reading "Essential ActionScript 3" by Colin Moock to learn more about the basics of ActionScript 3 syntax. LoomScript does not support all the language features of ActionScript 3 (currently we do not support namespaces, E4X, or exceptions). But it does support most things that make AS3 pleasant to develop in (closures, static typing, effective inheritance model).

Note that this section is an overview of LoomScript language features, not a Loom tutorial.

## Basic Classes and Variables

LoomScript is object oriented, meaning that everything is defined in the context of a class. For instance, if we are working on a racing game we might define a Car class:

~~~as3
// First, boring version of our Car class.
public class Car
{
}
~~~

Even though right now it's empty, and therefore not very useful, we might instantiate it somewhere and store it in a variable:

~~~as3
var myCar = new Car();
~~~

We use JavaScript style, declaring a variable by giving `var` followed by the variable name `myCar`. Then, we assign using the `=` operator, and create the object using `new`. To summarize, we now have a variable called `myCar` which holds an instance of the `Car` class.

It's good practice to put each class definition in its own file named after the class, surrounded by a `package`. While everything has to be in a `package`, you can put multiple classes in a single file if you want. Here's what our Car class would look like in its own file:

~~~as3
Contents of Car.ls:

package com.myracinggame.example 
{
    public class Car
    {
    }    
}
~~~

It's also good practice to put LoomScript files in folders named after their package. For instance, this LoomScript file ought to be in `com/myracinggame/example/Car.ls` to make it easy to find. But this is also just a convention and you can break it if you want!

Let's modify the `Car` class to include some useful members:

~~~as3
// Second version of our Car class.
public class Car
{
    // The volume of the engine in cubic centimeters.
    public var engineVolumeCC = 100;

    // The manufacturer of the car ("Ferrari", "Volkswagen", etc.)
    public var manufacturer:String;

    public function Car()
    {
        manufacturer = "Generic";
    }
}
~~~

Now we have more going on. Specifically, our `Car` has some fields that store interesting data. We show two ways of initializing variables. First, you can do it inline - right in the definition, as seen with `engineVolumeCC`. This is good for simple values, and is nice because you can take in everything about the variable - its name, type, and initial value - at a glance.

`public` is a new keyword. It controls what code can access the item that comes after it. LoomScript has four access modifiers: `public` gives anyone access to the member, `protected` lets only the current class or subclasses have access, `private` allows only the current class have access, and `internal` denies any classes outside of the current package. Accessing a member you don't have permission for will result in a compiler error.

`manufacturer` is a little more complex; we see that we define it, and then we explicitly specify the type by adding a colon and the type name `String` after the variable name `manufacturer`. More on this in a second. Finally, we don't give it an initial value right away, but rather, set it in `Car`, a function defined a little later in the class. `Car`, of course, is named after the type holding it and is the constructor, called on creation of the object.

Specifying the type for `manufacturer` is necessary because LoomScript is statically typed. That is, it must know at compile time the type of every variable in your program. This allows the compiler to give you excellent error reports and also enables script to run faster. 

The previous examples (`var racecar = new Car()` and `public var engineVolumeCC = 100;`) work because LoomScript is able to infer the type. That is, it can determine the type based on clues around it, for instance, the type of the first value stored in it (Number, in the case of `engineVolumeCC`. However, LoomScript is pragmatic, and doesn't try to make type inference work in every case - so in cases like `manufacturer`, it's good practice to specify the type. It also makes the code self-documenting and self-correcting, which is an even better argument for the explicit type specification.

If you don't care about something's type, or want to program generically, you can specify `*` or `Object` and LoomScript will skip type checking for that variable.

## Functions And Access Modifiers

Of course, a car is still pretty boring when it can't do anything. Let's add some behavior:

~~~as3
// Second version of our Car class.
public class Car
{
    // The volume of the engine in cubic centimeters.
    public var engineVolumeCC = 100;

    // The manufacturer of the car ("Ferrari", "Volkswagen", etc.)
    public var manufacturer:String;

    // How fast is the engine revolving each minute?
    public var rpms:Number = 0;

    public function Car()
    {
        manufacturer = "Generic";
    }

    // Simulate starting the engine.
    public function start():void
    {
        trace("Starting the car!")
        rpms = 1000;
    }

    // Simulate revving the engine!
    public function revTheEngine(howMuch:Number):void
    {
        trace("Revving the engine by " + howMuch + " revs!");
        rpms += howMuch;
    }
}
~~~

We now add three members to `Car`: `rpms`, `start`, and `revTheEngine`. `rpms` is a public variable of type `Number`, which is acted on by two public functions: `start` and `revTheEngine`. `start` takes no arguments, while `revTheEngine` takes one argument, a number indicating by how much to rev the engine.

We also started using the `trace` method, which is a globally available utility method that prints a string to the Loom log. Anything you pass to it that isn't a `String` gets its `toString` method called, turning it into a `String` for display purposes!

Let's look at using our `Car`:

~~~as3
var car = new Car();
car.start();
car.revTheEngine(100);
car.revTheEngine(500);
trace(car.rpms);
~~~

If we ran the above code (perhaps in the constructor of our application's main class), we'd see the following output:

```
Starting the car!
Revving the engine by 100 revs!
Revving the engine by 500 revs!
1600
```

As you can see, we end up at 1000+100+500=1600 rpm!

### Anonymous Functions and Closures

Anonymous functions are handy and powerful:

~~~as3
var something = function(x:int, y:int):void { trace("sum " + (x+y)); };
something(1, 2); // Outputs 'sum 3'

var data = [1,2,3];
var count = 0;
data.forEach(function(val:int) { trace(" Item #" + (count++) + " = " + val); }); // Print a nice table of the values in data.
~~~

A closure is a function with its own local variables packaged with it. LoomScript allows this:

~~~as3
function closurizeCountUp():Function
{
	var counter:int = 100;
	return function() { trace(counter++); };
}

// Generate the closure.
var func = closurizeCountUp();

// Count up.
func();
func();
func();
func();
~~~

Would print:

~~~
101
102
103
104
~~~

### Default Arguments and Variable Arguments

Functions are powerful. They can take a lot of arguments if you so desire, although we think it's a bad idea to pass more than 10 arguments or so for readability reasons. They can have default arguments and return types:

~~~as3
public function showDefaultArgs(arg1:Number, anotherArg:String = "ThisIsADefault"):Object
~~~

Functions can also handle variable numbers of arguments:

~~~as3
    function doSomething(x:Number, s:String, ...args)
    {
        trace(x);
        trace(s);
        for (var i:Number = 0; i < args.length; i++)
            trace(args[i]);
    }
~~~

Notice that you specify variable arguments with `...`, and give them a name by putting the name right after the dots. Internally, the varargs type is an `Array` or `Vector.<Object>` (more on that later).

###

## Templated Types and Type Aliases

LoomScript supports a few templated types, specifically `Vector` and `Dictionary`. (Note that `Array` is treated the same as `Vector.<Object>` in LoomScript.) These types allow you to specify other types that they operate on. For instance:

~~~as3
var carList = new Vector.<Car>();
~~~

Above, `carList` is a `Vector` that only holds instances of `Car` or its subclasses. This is very helpful for keeping containers organized, as you can make sure at compile-time that you are writing and reading the right types. You can also specify a `Vector` with no type parameter (no `.<Car>` or equivalent) and it will default to holding anything, i.e., `.<Object>`.

`Dictionary` is similar; you might do `Dictionary.<String, Car>` to make a `Dictionary` that accepts `String` keys and `Car` values. `Dictionary` defaults to `.<Object,Object>` if you don't specify any parameter types.

LoomScript also provides a number of type aliases to simplify porting ActionScript 3 code and as shorthand. For instance, `Array` is actually `Vector.<Object>`, and the rest are implemented in `lsAlias.cpp`, reproduced here for convenience:

~~~as3
    // Each line rewrites the first type to the second.
    addAlias("byte", "Number");
    addAlias("char", "Number");
    addAlias("short", "Number");
    addAlias("ushort", "Number");
    addAlias("long", "Number");
    addAlias("double", "Number");
    addAlias("float", "Number");
    addAlias("int", "Number");
    addAlias("uint", "Number");
    addAlias("string", "String");
    addAlias("boolean", "Boolean");
    addAlias("*", "Object");
~~~

## Interfaces and Subclassing

LoomScript supports interfaces and subclassing, as seen below:

~~~as3
public interface ITowingVehicle
{
    function hitch(towable:Object):void;
    function tow():void;
}

public interface ITowable
{
    function dragAlong():void;
}

public class Truck extends Car implements ITowingVehicle
{
    protected towed:ITowable;

    function Truck()
    {
        // Call the base class' constructor. If it required arguments, you would
        // pass them here as in a normal function call.
        super();

        manufacturer = "Ford";
        engineVolumeCC = 3000;
    }

    public function hitch(towable:ITowable):void
    {
        trace("Now towing " + towable);
        towed = towable;
    }

    public function tow():void
    {
        if(towed)
        {
            trace("Dragged " + towed + " a bit.");
            towed.dragAlong();            
        }
    }

    public override function toString():String
    {
        return "[Truck manufacturer=" + manufacturer + ", engineVolumeCC=" + engineVolumeCC + "]";
    }
}
~~~

An interface defines one or more functions, getters, or setters that must be implemented by a class in order to be considered of that interface's type. In our example, we use it to indicate that a `Truck` is a `Car` that can do something extra - `hitch` and `tow`! We also override the `toString` function (which is present on every Object) in order to display some extra information.

Let's make something we can tow:

~~~as3
public class BoringTrailer implements ITowable
{
    public function dragAlong():void
    {
        trace(this + " got towed!");
    }

    public override function toString():String
    {
        return "[BoringTrailer]";
    }
}
~~~

And drive our `Truck`:

~~~as3
var bigRedTruck = new Truck();
var lilTrailer = new BoringTrailer();
bigRedTruck.hitch(lilTrailer);
bigRedTruck.tow();
~~~

We get the following output:

~~~as3
Now towing [BoringTrailer]
Dragged [BoringTrailer] a bit.
[BoringTrailer] got towed!
~~~

Let's modify Truck and make a more interesting example. First, let's make Truck an `ITowable`, omitting functions we already defined:

~~~as3
public class Truck extends Car implements ITowingVehicle, ITowable
{
    protected towed:ITowable;

    function Truck() ...
    public function hitch(towable:ITowable):void ...
    public function tow():void ...
    public override function toString():String ...

    public function dragAlong():void
    {
        trace(this + " comes along, rumbling and spinning its wheels!");

        // Also drag whatever we tow!
        if(towed)
            towed.dragAlong();
    }
}
~~~

Now we can tow our `Truck`, so let's have some fun:

~~~as3
var hugeRedTruck = new Truck();
var bigRedTruck = new Truck();
var lilTrailer = new BoringTrailer();
hugeRedTruck.hitch(bigRedTruck);
bigRedTruck.hitch(lilTrailer);
hugeRedTruck.tow();
~~~

We get the following output:

~~~
Now towing [Truck manufacturer=Ford engineVolumeCC=3000]
Now towing [Truck manufacturer=Ford engineVolumeCC=3000]
[Truck manufacturer=Ford engineVolumeCC=3000] comes along, rumbling and spinning its wheels!
Now towing [BoringTrailer]
Dragged [BoringTrailer] a bit.
[BoringTrailer] got towed!
~~~

## Casting

Notice that the compiler is smart enough to know that `Truck` and `BoringTrailer` are both `ITowable` and allow them to be passed to functions taking that type. LoomScript has full runtime typecasting abilities, embodied in the `is`, `instanceof`, and `as` keywords.

Let's declare a couple of classes and variables for reference in this section:

~~~as3
public interface I1
{
}

public class A
{
}

public class B extends A implements I1
{
	public function bMethod():void { trace("Called bMethod!"); }
}

var a = new A();
var b = new B();
var refToB:A = b;
~~~

### is

`X is Y` returns true if `X` is of class `Y`, and false if not. It's useful for checking if an object is of an expected type. For instance, if you want a function that takes an Object, and processes it one way if it is a `Number` and another if it is a `String`:

~~~as3
function doLogic(param:Object):void
{
	if(param is String)
		trace("I saw a string: " + param);
	
	if(param is Number)
	{
		param++;
		trace("I incremented the parameter: " + param);
	}
	
	if(param is A)
		trace("Saw an A!");

	if(param is B)
		trace("Saw a B!");
}

doLogic("Hello!");
doLogic(100);
doLogic(a);
doLogic(b);
~~~

Would give output:

```
I saw a string: Hello!
I incremented the parameter: 101
Saw an A!
Saw an A!
Saw a B!
```

Notice that when we passed `b` to `doLogic`, it appeared as both an `A` and a `B` - that's because `B` is a subclass of `A`, so `is` returns true for both classes.

### instanceof

`instanceof` is like `is`, but it requires an **exact** type match. That is, if we replaced `is` with `instanceof` in our above example, we'd see this output:

```
I saw a string: Hello!
I incremented the parameter: 101
Saw an A!
Saw a B!
```

Note that "Saw an A!" is not repeated - because `b` is `A` but it is NOT `instanceof` of `A`.

### as and the cast operator

`X as Y` tries to cast `X` to class `Y`. If this is possible, then it returns a reference to `X` using type `Y`. If it is not, it returns `null`. So we can do the following:

~~~as3
function tryIt(param:Object):void
{
	var possibly:B = param as B;
	if(possibly)
		possibly.bMethod();
	else
		trace("Couldn't cast!");
}

trace("Trying a:");
tryIt(a);
trace("Trying b:");
tryIt(b);
~~~

Giving us the following output:

```
Trying a:
Couldn't cast!
Trying b:
Called bMethod!
```

Another useful idiom with as is the following, if you're sure the cast will succeed!

~~~
(possibly as B).bMethod();
~~~

We also support a more concise cast syntax, which is equivalent to using `as`:

~~~as3
var definitely:B = B(param);
~~~

## Math and Operators

LoomScript supports a wide range of C-style math:

~~~as3
	var a = ((100 + 200) / 300) % 2;
	var b = 100 * 30;
	var c = (Math.random() > 0.5) ? true : false;
	var d = true && c;
	var e = 0x10 | 0x01;
	b++;
	a += 300;
~~~

All math is done at double precision; that is all, numeric types are Number. `NaN` is available, and fails all comparisons.

LoomScript supports operator overloads for +,-,/,*,+=,-=,/=,*=, and =, as seen below:

~~~as3
class OpClass {

    public function OpClass(x:Number = 0, y:Number = 0) {
        this.x = x;
        this.y = y;
    }

    public var x:Number;
    
    public var y:Number;
 
    // Addition overload
    public static operator function +(a:OpClass, b:OpClass):OpClass
    {
        return new OpClass(a.x + b.x, a.y + b.y);
    }    
    
    public static operator function -(a:OpClass, b:OpClass):OpClass
    {
        return new OpClass(a.x - b.x, a.y - b.y);
    }    

}
~~~

## Conditionals & Loops

LoomScript supports the usual conditionals:

~~~as3
if(true)
    trace("Always do this.");
else if(anotherCondition)
	trace("Won't actually ever do this.");
else
	trace("And definitely won't do this!")

true ? trace("Yes, we have ternary operator!") : trace("No, we do not.");
~~~

LoomScript supports a number of ways of iterating over data.

### For

For loops are alive and well:

~~~as3
for(var i=0; i<100; i++) 
	trace(i);

for(;;)
{
	// Loop forever until we explicitly break!
	if(Math.random() > 0.5) 
		break;
}
~~~

LoomScript also supports `for each`, which loops over each **value** in a `Vector` or a `Dictionary`:

~~~as3
var resolutions:Vector.<String> = ["1280x720", "1368x768", "1920x1080"];
for each (var r:String in resolutions)
{
    if (r == "1368x768")
        break;
}
~~~

`for in` allows you to iterate over keys in a `Dictionary` or `Vector`:

~~~as3
var values = { "hello": 1, "world": 2};
for (var x:String in values)
{
    if (x == "world")
        break;

}
~~~

### Do While

The venerable do/while loop requires no introduction:

~~~as3
while(i>0)
{
	i--;
}

do
{
	i++;
}
while(i < 100);
~~~

## Enum

You can use an `enum` to conveniently define multiple numeric constants:

~~~as3
enum Days 
{ 
	Saturday, // Default starts at zero. 
	Sunday, 
	Monday, 
	Tuesday, 
	Wednesday, 
	Thursday, 
	Friday 
};

enum Permissions 
{ 
    All = 3, // But you can override.
    Update = 2,
    Read = 1,
    None = 0 
};
~~~

Note that an `enum` is considered to be like a `class` and must be at the `package` level of your file.

## Packages and Importing

Every LoomScript file contains exactly one `package`, but it can have other file-scope classes defined after the `package` block:

~~~as3
package foo.bar
{
	class MyClass
	{
	}
}

class OnlyMyClassCanSeeMe
{
}
~~~

`import` allows you to specify classes that you want to use from elsewhere in your project, ie:

~~~as3
package tests 
{

	import unittest.Test;

	class MyTest extends Test
	{
	}
}	
~~~

You can specify classes by their fully specified name (e.g. `unittest.Test`) but this is more verbose and only recommended if you have imported two classes with the same short name.

## Delegates

LoomScript has first class delegate support, as seen in C#. A delegate is a type that looks like a function. You can call it like a function. But when you do so, it doesn't run any code - instead it calls any actual `Function`s that were added to it, and returns the result of the last one.

You can declare a delegate:

~~~as3
delegate MyDelegate(x:Number, y:Number):String;
~~~

And add some listeners to an instance of MyDelegate, then call it. Note that variables of delegate type are auto-instantiated. Also, note that only the return value of the last listener is used, so we don't have to match return types.

~~~as3
var d:MyDelegate;
d += function(x:Number, y:Number):Void { trace("Got " + x + " + " + y + "!"); };
d += function(x:Number, y:Number):String { return "Saw " + x + " + " + y; };
trace("D gave me: " + d(1,2));
~~~

Which would output:

```
Got 1 + 2!
D gave me: Saw 1 + 2
```

You can remove listeners from a delegate, but adding/removing is done by *instance* - that is, doing:

~~~as3
d -= function(x:Number, y:Number):String { return "Saw " + x + " + " + y; };
~~~

Would do nothing, because you are creating a new `Function` instance about which the delegate knows nothing. Instead you have to do:

~~~as3
var myFunc = function(x:Number, y:Number):String { return "Saw " + x + " + " + y; };
d += myFunc;
d -= myFunc;
~~~

You can also reset a delegate by assigning `null` to it:

~~~as3
var d:MyDelegate;
d += function(x:Number, y:Number):String { return "Saw " + x + " + " + y; };
trace("D gave me: " + d(1,2));
d = null;
trace("D gave me: " + d)
~~~

Giving output:

```
D gave me: Saw 1 + 2
D gave me: null
```

Delegates are a powerful building block, especially when working with composition, but they aren't always appropriate since you don't always have good control over the order of callbacks and it can be hard to clean them up. `EventDispatcher` is a good class if you find that `Delegate` is limiting you.

## Structs

Loom provides an alternative to the `class` keyword, `struct`. `struct` identical to `class`, except that variables of `struct` type are never null, and `struct` types assign by copy rather than by reference, using an assignment operator. For instance:

~~~as3
struct MyStruct {

    public function MyStruct(_x:Number = 1, _y:Number = 2) {
        this.x = _x;
        this.y = _y;
    }

    public var x:Number;
    
    public var y:Number;

    // assignment overload    
    public static operator function =(a:MyStruct, b:MyStruct):MyStruct
    {           
        a.x = b.x;
        a.y = b.y;
        
        return a;
    }    
 
    // Addition overload
    public static operator function +(a:MyStruct, b:MyStruct):MyStruct
    {
        return new MyStruct(a.x + b.x, a.y + b.y);
    }    
    
    // Addition overload
    public operator function +=(b:MyStruct)
    {
        x += b.x;
        y += b.y;
    }    
}
~~~

Which can be used as follows:

~~~as3
var ms:MyStruct;
trace(ms.x); // No need to initialize!
var ms2:MyStruct;
ms2.x = 100;
ms = ms2;
ms2.x = 20;
trace(ms.x); // x and y are copied by assignment overload so we get 100 here.
~~~

`struct`s can be useful when trying to avoid logic errors when working with complex math, and to reduce temporary object allocation.

## Getters and Setters

LoomScript supports getters and setters, functions which are run when a property is read to or written from:

~~~as3
public function get somefield():String
{
    trace("Read somefield!");
    return "Hello";
}

public function set somefield(value:String):void
{
    trace("Set somefield to " + value);
}
~~~

If you omit a getter or setter, then the field is treated as write or read only.

## Unsupported

Currently LoomScript has partial support for `try`/`catch` and `throw`. Specifically: `catch` blocks are ignored and `throw` blocks simply assert fatally.

E4X is not supported, but we do have a full XML library (see XMLNode and friends).

AS3 namespaces are not supported.