title: LoomScript
description: A general overview of LoomScript.
!------

LoomScript is the proprietary scripting language for Loom. It is a simple and effective tool for building game logic. It features an ActionScript3-like syntax extended with some C#-esque capabilities, and runs on an unmodified Lua or LuaJIT VM. Compiler, debugger, and profiler source code is included with Loom, and can be readily modified for your project's specific needs.

## Syntax
We highly recommend reading "Essential ActionScript 3" by Colin Moock to learn more about the basics of ActionScript 3 syntax. LoomScript does not support all the language features of ActionScript 3 (currently we do not support namespaces, E4X, or exceptions). But it does support most that make AS3 pleasant to develop in (closures, static typing, effective inheritance model).

In practice, existing ActionScript 3 code can be ported quickly and easily - for instance, we were able to port PushButton Engine 2, a large AS3 project, to run on Loom with only a few modifications.

## LoomScript Extensions
The major language features we've added to LoomScript are:

* Delegates. LoomScript has C#-esque delegates for binding to script or native code.

    ~~~
    delegate LMLDelegate():void;
    public var lmlChildRemoved:LMLDelegate;
    ~~~

* Implicit typing. When you declare something as `var foo = new Point();` the compiler automatically determines that the type of foo is `Point` and statically checks your code for you.

* C# reflection API. AS3 has an anemic reflection API, so we have introduced one based on C#'s API. See the System.Reflection package.

* The `struct` keyword. `struct` works just like class, with two differences. First, all variables of type struct are pre-initialized and are never null. Second, assignment is treated as copy, so `=` copies by value rather than assigning by reference. This prevents a wide class of issues related to inadvertantly sharing Points (for instance).

* Operator overloads. You can overload +, -, /, =, and other operators by declaring functions named after the operators.

* Enums. [Enumerated Types](http://en.wikipedia.org/wiki/Enumerated_type) provide type-safe keys, symbols and configuration valuables. 

    ~~~
    public enum GameState
    {
      MAIN_MENU,
      IN-GAME,
      PAUSED,
      VICTORY,
      DEFEAT
    }

## Why LoomScript?
Why not use JavaScript or Lua directly? Why develop our own language?

Simply, because we feel that JS and Lua aren't great choices for game development. They can certainly work - but they don't have good support for [Programming in the Large](http://en.wikipedia.org/wiki/Programming_in_the_large). As a result, they become painful for larger teams and/or more complicated games. Even small teams benefit from having good frameworks and abstractions, since we provide those things with Loom and they can leverage them in their games.

As far as ""developing our own language"", we have tried very hard to follow the [principle of least astonishment](http://en.wikipedia.org/wiki/Principle_of_least_astonishment). In practice, LoomScript is highly familiar to any developer who has worked with ActionScript 3, C#, Java, C++, PHP, or JavaScript. Where we have added features, we have modelled them closely off of existing major languages implementations. For instance, we have added delegates, assemblies, and implicit typing that are very similar to C#'s. 

We have aggressively avoided trying to innovate in our language design. We feel there are some very good options if you want an innovative language for your project, such as Erlang, Haxe, Clojure, etc. LoomScript is meant to be a practical tool to let you and your team write compelling interactive experiences quickly.

Because Loom includes the full source code for the full language stack, you are never at the mercy of outside forces for bugfixes or features. We have worked hard to keep LoomScript's compiler and runtime implementation small and understandable for this reason.
