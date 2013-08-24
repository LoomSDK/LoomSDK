title: Adding Classes
description: Extending Loom with your own C++ code.
!------

This section describes how to add new C++ source files to the Loom Native SDK and gives some basic information on how to expose new code to script. It assumes some knowledge of Loom. In particular, see the page `LoomScript Bindings` for further details on binding C++ to script, and the README at the root of the Native SDK for a full explanation of how to compile Loom using your favorite IDE. For the purposes this article, we will assume you are doing command line builds, not using an IDE.

## SDK Map

The Native SDK is laid out as follows:

~~~text
application/  - Entry points for your application on each supported platform.
   android/   - The Android entry point + support files.
   common/    - Code shared between different platforms. User code generally lives here.
   ios/       - The iOS entry point + support files.
   osx/       - The OSX entry point + support files.
   windows/   - The Windows entry point + support files.
build/        - Support files for CMake and build infrastructure.
certs/        - Certificates (.mobileprovision, Android certs, etc.)
docs/         - Documentation and support files.
    examples/ - The Loom example applications.
loom/         - C++ source code for the Loom engine.
    common/   - Foundational code for Loom.
    engine/   - Assets, rendering, script bindings, etc.
    graphics/ - Loom2D rendering library, bgfx.
    script/   - LoomScript implementation, compiler + runtime.
    vendor/   - Third party code.
sdk/          - SDK for LoomScript. This is itself a Loom Script SDK project.
    assets/   - Assets for the default project.
    src/      - LoomScript SDK source code for a variety of libraries and the default application.
tools/        - Assorted tools used in Loom development.
~~~

When you build the SDK, the output goes into an `artifacts/` folder. The default "application" for Loom is the LoomDemo app and this is what is created/run if you compile or debug the SDK via a project file.

## Making Yourself at Home

We highly recommend making a copy of the Loom Native SDK, then modifying it as needed to suit your game. Don't be scared to make modifications throughout the codebase! Put your application in `application/` and replace code as needed.

You will find most of the configuration details for the app name, package, etc. living in the root `CMakeLists.txt`.

As a matter of philosophy, we believe that it introduces needless complexity to have a single SDK with multiple C++ projects in it. Games inevitably require modifications of core code to ship - so it's much better to have a complete, clean snapshot of each project than to have them living alongside shared code. If this is desired, it's easy enough to copy the shared code back and forth as needed (at times least disruptive to each game team).

## Compiling, Packaging, and Using Loom SDKs

The Native SDK requires CMake and Rake. Make sure recent versions of these are installed before proceeding. You will also need developer tools for the platforms you want to target. This means XCode on OSX and MSVC on Windows. Run rake commands from the MSVC Command Prompt on Windows.

In the root of the Native SDK, run `rake deploy:sdk` to build an SDK including the current OS, iOS, and Android. This requires you have toolchains for all three available, so it only works on Mac. If you just want to build for just the current OS, run `rake deploy:free_sdk`.

Now, you can go to a Loom project of your choosing and run `loom use dev` to switch over to the Loom SDK that you built locally. 

You can also run `rake package:sdk` or `rake package:free_sdk` to produce a zip of the SDK. You can install this ZIP as an SDK with `loom install sdk --local path/to/the.zip`.

## Running Your Game Inside the Native SDK

Suppose you have added some new C++ code and are experiencing crashes. Wouldn't it be nice to run your game directly from the Native SDK so that you can use your IDE's debugger?

Normally you have to `deploy:sdk` (or `deploy:free_sdk`) and run your project via LoomCLI. However, you can bring your game's scripts and assets directly into the Native SDK. 

Simply copy your Loom project's assets into `sdk/assets/` and your Loom project's scripts into `sdk/src/demo`. Then, open your preferred IDE's project file (possibly generating it via rake first), and run your game.

You may need to manually compile your scripts via `rake utility:compileScripts`.
 
Notice that there is a `sdk/src/Main.build` config file for `lsc` which directs it to compile scripts from the `sdk/src/demo/` folder; you can move your script source code there or modify `sdk/src/Main.build` as appropriate to suit your needs.

## Adding Files to Loom

Loom uses CMake. Find where you want your source code to live (for instance, `application/common/MyClass.cpp` and `application/common/MyClass.h`). Walk up the directory hierarchy until you find a `CMakeLists.txt` file (in this example, `application/CMakeLists.txt`). Open it in your favorite text editor. You will see a block like the following, containing a list of .cpp and .h files. Add your files to the lists!

~~~text
set (APPLICATION_SRC
    common/AppDelegate.cpp
    common/myClass.cpp
)

set (APPLICATION_HDR
    common/AppDelegate.h
    common/myClass.h
)
~~~

Note that the lists are often organized by folder/alphabetical order to make maintenance easier.

There may also be a list of `.h` files (in this case, `APPLICATION_HDR`); if you have a header file, please add it there, too.

Now you can compile with `rake build:osx` or `rake build:windows` (depending on platform), or regenerate your IDE's project with CMake to see the new files.
