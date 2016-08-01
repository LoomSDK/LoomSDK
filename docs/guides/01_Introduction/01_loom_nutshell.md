title: Loom In a Nutshell
description: How Loom Works in One Short Page
!------

Loom provides a basic structure for your application built around the `Application` and `Stage` classes, as well as some conventions for project layout. LoomScript is Loom's powerful and easy to use scripting language.

## Project Structure

Loom's basic project structure is very simple:

   * `loom.config` - In the root of the project, this stores some basic information like application name, startup width/height, and other useful settings. You can also add your own data if you want and read it via `Application.loomConfigJSON`.
   * `src/` - This folder contains all the `.ls` LoomScript files for your project. You can edit them live if you run your app with `loom run`, changes will be pushed to your app automatically.
   * `assets/` - All images, sound files, levels, text data, etc. that should be packaged with your app are stored here. There will be a basic Bitmap font and some other starter data here by default.

You can run `loom new MyProject` to automatically create a new folder containing a default Loom project.

## The Application

Every Loom program subclasses Application or ConsoleApplication (if it is command line only). These classes set up and tear down commonly used resources and give you a starting point for your application logic: the `run()` method.

An empty Loom application looks like this:

~~~as3
class MyApp extends Application
{
   protected function run()
   {
      trace("Hello world!");
      
      // After this function finishes, Loom continues
      // rendering frames until the app is shut down.
   }
}
~~~

Code similar to the above is generated automatically when you use `loom new`.

`Application` has a lot of other very useful built in capabilities:
   * Methods you can override to get callbacks before each frame is rendered (`onFrame`) and at a fixed 60hz as time passes (`onTick`).
   * The `loom.config` file in JSON form stored in `loomConfigJSON`.
   * The current version of Loom in `version`.
   * The Stage stored in `stage`.
   * The console command manager, available via injection.

Check out the API docs for full details.

## The Stage and Display List

Loom has a hardware accelerated 2D rendering framework based on Starling. Rendering occurs on the `Stage` by adding `DisplayObject` subclasses to it and manipulating their properties. Collectively this system is called the display list. The display list allows you to position objects at pixel coordinates, rotate them, scale/skew them, and do other pretty things. For instance you have the following in the `run` method:

~~~as3
// Create a white 50x50px square.
var q = new Quad(50, 50);

// Position it at 20, 200.
q.x = 20;
q.y = 200;

// Rotate it about its center.
q.rotation = 10;

// And add it to the Stage so it is drawn.
stage.addChild(q);
~~~

Every frame, every object on the `Stage` is rendered using the GPU. Rendering occurs after LoomScript finishes executing for each frame, so only the last value you set for `x`, `y`, etc. takes effect. Having lots of `DisplayObject`s can slow down rendering, although Loom is heavily optimized for performance.

You can render from textures using `Image`, for instance, try dropping a transparent PNG in the `assets/` folder and modifying the above example so that the first line reads:

~~~as3
var q = new Image(Texture.fromAsset("assets/yourImage.png"));
~~~

You can override `onFrame` in your `Application` subclass to animate things:

~~~as3
class AnimationExample extends Application
{
    // Keep a reference to our quad so we can animate it.
    public var q:Quad;

   protected function run()
   {
        // Create a Quad as above.
        q = new Quad(50, 50);
        q.x = 20;
        q.y = 200;
        q.rotation = 10;
        stage.addChild(q);
   }
   
   public function onFrame()
   {
        // Add some motion.
        q.rotation += 0.1;
   }
}
~~~

## Feathers

Loom includes the [Feathers user interface library](http://www.feathersui.com). It's a full featured UI library with support for theming, layouts, lists, data sources, and a lot more. Because Feathers builds directly on top of the display list API, you can freely mix and match Feathers components with normal 2D elements.

The Feathers Component Explorer example app shows off a lot of what it can do. You can run it by executing the following commands:

~~~text
loom new FeathersComponents --example FeathersComponentExplorer
cd FeathersComponents
loom run
~~~

Browse the code in the `src/` folder to see thorough examples of all the major Feathers features.

## LoomScript

LoomScript is a simple language very similar to JavaScript, ActionScript, Java, or C#. A full language reference is available [here](http://docs.theengine.co/loom/1.1.3452/guides/02_LoomScript/02_syntax.html). We'll give some very short examples here to get you started.

LoomScript is strongly and implicitly typed. In other words, LoomScript knows the type of every variable and will give you an error if you try to do something invalid. Types are specified with a colon and the typename, although in many cases they are optional. For instance:

~~~as3
var foo = 100;  // Implicitly a Number.
var bar:Number; // Explicit typing.
function f(x:Number):String { return "Hello, " + x; }
~~~

LoomScript has standard friendly loops:

~~~as3
// Count up to 100 with a for loop.
for(var i:int=0; i<100; i++) trace(i);

// Count down from 100 with a while loop.
var i = 100;
while(i-- > 0) trace(i);

// Count to 3 with a for each loop referencing an Array.
for each(var i:int in [1, 2, 3]) trace(i);
~~~

Class definitions are also familiar:

~~~as3
public class MyClass extends Object implements SomeInterface
{
   public var myField = "Hello!"; // Implicitly typed as a String.
   
   public function MyClass()
   {
      trace("Constructor called!");
   }
   
   protected function myMethod():Number
   {
        trace("You can only call me from a subclass!");
        return Math.random();
   }
}
~~~

Classes are stored in packages and `import` is used to reference classes from packages other than current one. For instance:

~~~as3
package unittest
{

import system.xml.XMLDocument;

public class Test
{
   public var xml = new XMLDocument();
}
}
~~~