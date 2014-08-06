title: Dependency Injection
description: Modularize your code.
!------

Code often has dependencies on other code, and dependency injection is a technique for managing these dependencies. Loom's script frameworks use dependency injection heavily. If you are confused by the `[Inject]` tags through Loom, this is the document for you!

## Creating a Problem

For instance, suppose a class `Animal` in a zoo game. `Animal` needs access to information about different kinds of food, so that when you call `myAnimal.eat("pineapple")` it knows how many calories a pineapple has, and how shiny its coat should be as a result of eating it. In order to model this, you need some sort of `FoodManager` which you can load with data about different kinds of food.

Suppose also that `Animal` wants to have access to the `ScoreManager` so it can reward the player with points for feeding it a `"pineapple"`, the `SoundManager` so it can trigger a pineapple-eating sound, and the `FurAppearanceManager` so it can get the right sprite to show for its current level of fatness and fur appearance.

These are all considered "dependencies" of the Animal class. In addition, if we had created a UI to show the qualities of different kinds of food, we would find that the UI code "depended" on the `FoodManager` as well.

Note that we will mostly speak of "managers" here, but a dependency could be anything - small things like a `Vector`, `Number`, or `String`, or bigger things like a `WorldMap` or `EnglishLanguageDictionary`.

## Possible Solutions

The quickest and easiest option is to use static members and make the state global:

~~~as3
var foodItem = FoodManager.getByName("pineapple");
~~~

This works, and in some cases it can be a perfectly adequate solution. However, it is of limited use. In code using this style, dependencies are implicit -  you have to read all the code in a module to understand what else it touches. In addition, it is unaware of context. If we have different `Animal`s that want to use different `FoodManager`s, or we want to create and destroy `FoodManager` instances depending on the current level, this approach quickly becomes unwieldy.

The next option is to stay away from statics and simply store a reference to the `FoodManager` on the `Animal`:

~~~as3
public class Animal
{
   public var foodManager:FoodManager;

   public function eat(food:String):void
   {
      var foodItem = foodManager.getByName("pineapple");
   }
}
~~~

This allows us to control which `FoodManager` an `Animal` uses. However, it pushes the problem out to the allocator of the `Animal`:

~~~as3
var kitty = new Animal();
kitty.foodManager = theKittyFoodManager;
~~~

This introduces an annoying detail that must be attended to every time we create a new `Animal`. You will also notice that if we forget to set `foodManager`, no error occurs until much later when `eat()` is called. This approach is fragile. But it does give us full control over which `FoodManager` any given `Animal` is using.

How can we avoid the fragility while keeping the flexibility? There are two main idioms. First, you can require that dependencies get passed to the constructor, e.g., `new Animal(theKittyFoodManager)`. This works nicely until you start having a lot of managers, e.g., `new Animal(theKittyFoodManager, theSoundManager, theScoreManager, theFurAppearanceManager)`, at which point it becomes cumbersome. It also incurs a lot of type coupling - the allocating code has to know about every single class involved, including subclasses, where to find the right instance, and so on.

The second idiom is to create a `GlobalContext` class and pass it around instead. It might look like this:

~~~as3
public class GlobalZooContext
{
   public var foodManager:FoodManager;
   public var scoreManager:ScoreManager;
   public var furAppearanceManager:FurAppearanceManager;
   public var soundManager:SoundManager;
}
~~~

`GlobalZooContext` helps reduce verbosity, but now we have lost visibility into what a given class' dependencies are, because it has access to all of them all the time! It also has type coupling problems similar to the constructor idiom. Overall, this is not a big step forward.

What can we do?

## Dependency Injection to the Rescue

From the preceding discussion, we know that our goals are:

1. Control which instance of a dependency code uses. We want to use different instances of managers in different contexts.
2. Make dependencies explicit. It should be easy to look at a class and know what managers it wants to use. This makes code understandable/maintainable, and helps avoid overly coupled code (if a class has 52 dependencies, it might be a good idea to refactor it).
3. Reduce coupling. If I am allocating something, I shouldn't have to know every single detail about it, and if I add a dependency, I shouldn't have to touch every allocation site.

Dependency injection is an elegant solution to these constraints. There are two parts to dependency injection, the injector and the target. Loom's injector is `loom.utils.injector`, and the target is any class on which you wish to fulfill dependencies. Here is what it looks like:

~~~as3
// Animal has dependencies:
public class Animal
{
   [Inject]
   protected var foodManager:FoodManager;  

   public function eat(food:String):void
   {
      var foodItem = foodManager.getByName(food);
   }
}

// Set up the injector to give an instance of FoodManager when requested.
var injector = new Injector();
injector.mapValue(FoodManager, new FoodManager());

// To allocate a new Animal:
var kitty = new Animal();
injector.apply(kitty);

// At this point, kitty has its dependencies and is ready to eat!
kitty.eat("pineapple");
~~~

`Injector` will error if a dependency cannot be fulfilled at `apply` time, simplifying debugging. You will also notice that the allocator doesn't need any knowledge of the rest of the system; it just needs an injector with the right mappings. As a result, there is no type coupling. Adding a new dependency can happen without the knowledge of the rest of the system. And it's extremely obvious what the dependencies are for a class; they are the members marked with [Inject].

Dependency injection combines the best attributes of all the approaches we described above.

## Advanced Injection Tricks

`Injector`s can be arranged in a hierarchy by calling `setParentInjector` - this tells the `Injector` that if it cannot fulfill a dependency, it should let the parent try. This is useful when you have a base context with a bunch of "global" managers, but want to add or override managers for certain specific contexts. `loom.gameplay.LoomGroup` does this, so that most dependencies are fulfilled by the root group, but child groups can add their own managers.

Sometimes you need to distinguish between dependencies more specifically than simply by their type. `Injector` lets you specify a string id when mapping and injecting values:

~~~as3
injector.mapValue(FoodManager, new FoodManager(), "kittyFood");
injector.mapValue(FoodManager, new FoodManager(), "doggyFood");

public class DoubleAnimal
{
   [Inject(id="kittyFood")]
   public var kittyFoodManager:FoodManager;

   [Inject(id="doggyFood")]
   public var doggyFoodManager:FoodManager;
}
~~~
