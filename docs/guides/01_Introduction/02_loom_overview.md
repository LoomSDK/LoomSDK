title: Overview
description: High level overview of Loom, LoomScript, and LoomCLI.
!------

This document gives an overview of key concepts and commands used when working with Loom.

## Development Philosophy
We believe that fast iteration times across multiple devices simultaneously lead to better, faster, cheaper app development.

Loom's design goal is to keep you on the fast development path as much as possible, while still preserving access to slower, more difficult, but still essential development paths. This gives a substantial benefit to development teams without blocking them.

Developing in LoomScript, using Loom CLI to deploy, run, and develop with live reload, is the fastest and cheapest path. Work here is the most malleable - that is, changes here to code and assets are very cheap, taking little time or effort.

However, LoomScript may not be suitable for all tasks, and at times, it may be desirable to avoid Loom CLI in favor of an IDE such as XCode or Visual Studio for debugging, profiling, or more convenient (but still relatively cumbersome) native development. 

In these situations, you can use the Loom Native SDK and work directly with Loom's C++ implementation. Of course, C++ development is not as agile as working in script. But if you need better insight into a crash, or want to fix a bug or extend Loom for your app with a new feature, it's worth the effort. We recommend exposing new features or SDKs in LoomScript so that the bulk of integration and development work can be done with less setup and faster iteration times.

## System Architecture
Loom has three main components:

* Loom CLI. A command line tool that manages your Loom SDKs and packages, deploys, and runs your Loom projects. Simplifies the annoying parts of development so you can focus on the productive parts.
* Loom Engine. Written in C++, the Loom runtime runs on device and executes your app. You extend and modify it to add special features for your app.
* LoomScript. Familiar JS/AS3/C# syntax, but running on the proven Lua VM. Pragmatic and powerful; lets you do more in fewer lines of code.

Loom CLI and Loom Engine work together to support live reloading of assets and LoomScript code. Together, these pieces form the foundation for app development with Loom.

On top of this, live the system libraries - like 2d rendering, sound playback, asset loading, XML parsing, file I/O, logging, memory management, input/touch handling, and so on. On top of them lives your application code.

### Loom's Execution Model

Loom execution starts on the native side when the application is launched. Loom's standard entry point, `loom_appStart`, is called from the platform-specific entry point. The native subsystems like logging, assets, and rendering are initialized using values in `loom.config` (see section later in this chapter for details). LoomScript is initialized last when the main assembly (`Main.loom`) is loaded. From there, either a static `main` function (if present) or the application class is created; this is usually a subclass you created based on `Application`. 

If an application class is present, then the application class constructor is run, initializing key classes like `Stage`, `InputManager`, 'Juggler', and `TimeManager`, along with any user logic. Often, a lot of startup assets are loaded at this time although, to make the app more responsive, initialization may be deferred. (`TimeManager.callLater` will run code at the start of the next frame and is a useful tool for deferring startup code.)

From this point on, we enter the standard application loop. Most mobile devices want to render and process input at 60hz. Therefore, Loom takes frames as its fundamental unit of processing time. When the platform layer wants to render a frame, the native method `loom_tick` is called and frame execution begins. Every frame starts with the script processing step. The `ticks` delegate on the `Application` is fired; most system managers add callbacks to this delegate, so they get run on every frame. The `onTick` and `onFrame` callbacks on `Application` are run. Then, native systems are run, such as the asset manager (which handles debug logging and asset streaming) or sensor polling. Finally, rendering occurs.

A word on ticks vs. frames: the `Application.onTick` callback and the `Application.onFrame` callback have slightly different semantics. `onTick` is guaranteed to be run at 60hz even if the framerate is less than that, while `onFrame` is only called once for each rendered frame. Thus, `onTick` is useful for deterministic simulation logic, while `onFrame` is useful for visual display logic.

This process is repeated until application shutdown. At this time, depending on platform, the main loop is terminated, `loom_appShutdown` is called, resources are discarded, and the application terminates.

Be aware that mobile operating systems do not promise to keep inactive applications in memory, and may terminate the process at any point without warning if resources are needed elsewhere. Therefore, although the `Application.applicationActivated` and `Application.applicationDeactivated` delegates are useful, they cannot be relied on. Make sure to save any important application state intermittently so that if a user comes back after termination they won't be disappointed by lost progress!

## Workflow

Loom is designed to focus you on your app. To that end, Loom CLI deals with creating a Loom project and running it across multiple platforms:

~~~ text
# Create a new project called MyApp
loom new MyApp    

# Go into the newly created folder containing the project.
cd MyApp/

# Run the newly created app on iOS, Android, and OS X
# with live code reload. (Note: you may need to use 
# loom ios provision to set a .mobileprovision for the
# project.)
loom run --ios --android --desktop
~~~

At this point, while the app is running on multiple devices, you can freely modify art and code and see changes show up on device in just a few seconds.

## Native Development
You may need to modify the Loom C++ source code in order to fix a bug or add a feature. We are very active in monitoring the Loom forums at [http://theengine.co/forums](http://theengine.co/forums), so please let us know if you encounter any issues - that way we can fix them in the future.

If you have a copy of the Loom native source ([available online](http://theengine.co/downloads)), building is as simple as:

~~~ text
# Build SDK for all available platforms and deploy it locally as "dev"
rake deploy:sdk

# You can also do this to name your SDK something other than dev.
rake deploy:sdk[mySDKVersion]
~~~

This will trigger CMake for all available build targets, generate docs, and produce a packaged SDK on the local system called `dev` (by default). Then you can go to a Loom project and run:

~~~ text
loom use dev
~~~

Now you're running against the Loom SDK you just built! If you `rake deploy:sdk` again, your changes will take effect without having to run loom use.

~~~ text
# Some other useful commands:

rake         # List all available build commands!

rake deploy:free_sdk # Just build the desktop binaries.

rake update:sdk  # Only recompile and package scripts.

rake build:osx   # Only compile one platform (replace 
                # osx with other platforms).

rake generate:docs # Generate docs into the docs/ folder.

rake utility:run # Run the default demo app. Useful for 
                # getting things set up for debugging.
~~~