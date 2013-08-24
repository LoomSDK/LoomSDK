title: Loom Overview
description: High level overview of Loom, LoomScript, and LoomCLI.
!------

This document gives an overview of key concepts and commands used when working with Loom.

## Development Philosophy
We believe that fast iteration times across multiple devices simultaneously lead to better, faster, cheaper app development.

Loom's design goal is to keep you on the fast development path as much as possible, while still preserving access to slower, more difficult, but still essential development paths. This gives a substantial benefit to development teams without blocking them.

Developing in LoomScript, using Loom CLI to deploy, run, and develop with live reload, is the fastest and cheapest path. Work here is the most malleable - that is, changes here to code and assets are very cheap, taking little time or effort.

However, LoomScript may not be suitable for all tasks, and at times, it may be desirable to avoid Loom CLI in favor of an IDE such as XCode or Visual Studio for debugging, profiling, or more convenient (but still relatively cumbersome) native development. 

In these situations, you can use the Loom Native SDK and work directly with Loom's C++ implementation. Of course, C++ development is not as agile as working in script. But if you need better insight into a crash, or want to fix a bug or extend Loom for your app with a new feature, it's worth the slow down. We recommend exposing new features or SDKs in LoomScript so that the bulk of integration and development work can be done with fast iteration times.

## System Architecture
Loom has three main components:

* Loom CLI. A command line tool that manages your Loom SDKs and packages, deploys, and runs your Loom projects. Simplifies the annoying parts of development so you can focus on the productive parts.
* Loom Engine. Written in C++, the Loom runtime runs on device and executes your app. You extend and modify it to add special features for your app.
* LoomScript. Familiar JS/AS3/C# syntax, but running on the proven Lua VM. Pragmatic and powerful; lets you do more in fewer lines of code.

Loom CLI and Loom Engine work together to support live reloading of assets and code. All together, these pieces form the foundation for app development with Loom.

On top of this, live the system libraries - like 2d and 3d rendering, sound playback, asset loading, XML parsing, file I/O, logging, memory management, input/touch handling, and so on. And on top of them lives your application code.

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
rake deploy:sdk

# You can also do this to name your SDK something else.
rake deploy:sdk[mySDK]
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