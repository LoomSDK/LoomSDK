title: Evolving Your Game
description: Lifecycle of game projects.
!------

The needs of a game evolve over the course of its development. Let's discuss different stages of the development lifecycle, and look at how Loom fits into each.

Every game starts with a prototype. This is a small-scale, easily modified version of a game idea, often completed in a short period of time.

Next, the game goes into early stage production. The focus in this stage is on getting the team going, building core gameplay features, and implementing the game's look. There is little technical debt, performance is good, and few major bugs have been discovered or solved.

Finally, the game becomes mature. The game is basically built out, with most content complete. Performance, polish, and efficient creation of content become key issues at this point.

(Disclaimer: Loom has a lot of useful features, and there are a lot of different ways of making games. This document is meant to outline one way of working, based on our years of experience with game development, in order to help you use Loom more effectively. It is hardly the only effective way to work!)

## Awesome Prototyping with Loom

Prototypes live and die on how quickly and effectively they can sell the concept behind them. They often make big sacrifices to hit that goal - like incurring tons of technical debt or ignoring huge parts of the problem.

Because of its Flash heritage and efficient workflow, Loom is very effective for fast prototyping. `loom new` spits out a new project directly, and LoomScript, like AS3, is efficient in amount of functionality per line of code. Finally, live reloading of code and assets via `loom run` lets you iterate quickly on device or desktop.

## Starting Production with Loom

If your title makes it out of the prototyping stage, it must quickly grow features, team size, and level of polish. Dinosaurs are bigger than mice because they have bigger, stronger bones, and like them, your game can use frameworks in different ways to support its growth to different sizes.

We recommend an incremental approach when taking a prototype into production. It is vital to preserve whatever spark made the prototype successful! Additionally, long period where the game is in a broken state are bad for morale and cause managers stress.

Therefore, it's good to incrementally bring different frameworks and features into the codebase as you revisit each part of your game. For instance, recreating every hand-coded UI element with the `loom.ui` package could burn days. Taking a single screen or UI element and porting it over, however, is quick and efficient, and leads to better code, appearance, and behavior immediately.

Similarly, you could rip the whole game apart and change everything to use `loom.gameplay` - but it's often better to do it incrementally, on an as needed basis. Take a few pieces of particularly complicated game logic and componentize them to make it easier to add new functionality. Or use dependency injection to simplify initialization logic that is rapidly becoming unwieldy. Or make sure your levels reset cleanly by integrating into the lifecycle functionality.

Gradually introducing frameworks lets you pay as you go, using the parts that are most useful for your immediate needs. It keeps the team from being overwhelmed by changes or new complexity. Once a good structure is in place, it is much easier to grow development and know you aren't introducing systemic flaws in your game.

## Mature Games with Loom

Late production is all about taking a project that is 80% done and dragging it, kicking and screaming, through that last muddy 20%. The game is up and running and the major systems are in place, but it isn't truly finished yet. In our experience, this is the most challenging and demanding part of game development.

Loom has several features that are useful here. The technical issues encountered in this phase are fundamentally different than in previous phases. When you are adding new code you can often simply write it, test it, and move on. However, fixing a performance problem or solving a complex interaction between multiple subsystems requires awareness of what is happening at runtime. Here are the main options Loom provides to help:

First, Loom has tools to help with performance optimization. Often, performance doesn't become a problem until after final game levels and gameplay are present - imagine a game like Starcraft where 500 unit battles don't happen until you have experienced players facing off in finished levels. So, Loom provides a hierarchical profiler that tracks script and native code execution time, as well as integration with RAD's Telemetry (not included in the standard distribution to respect RAD's license, contact us for a code drop) and other tools.

Second, Loom has good logging/debugging tools. `loom run` gives an interactive debug console as well as log output. Although basic, this has been a standard and highly effective debug aid for twenty years of game development.

Third, Loom supports debugging. You can debug natively with your favorite IDE by opening the appropriate project file in the native SDK. Or you can debug script via `ldb`, our command line script debugger. You can launch this using `loom debug`.

Finally, the ease of deployment to actual hardware helps prevent obscure regressions and ensures the game experience is as intended across all targeted devices.

## Parting Thoughts

Games need different kinds of care and feeding as they go from prototype to early production to mature title. Loom provides the features you need at each point along the journey. Learn to use it to best advantage!
