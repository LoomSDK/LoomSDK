title: Loom SDKs
description: The software development kits making up Loom.
!------

There are three software components used in Loom development. Depending on how you are using Loom, you might use one, two, or all three of them. They are:

* **The Native SDK.** This is the full source C++ (Java, ObjC, etc.) code for Loom along with a Ruby Rakefile, CMake files, and all the other bits required to build and package the second part, which is…

* **The Script SDK.** This is used for most Loom development. It is essentially a zip file containing compiled versions of the Loom engine and related tools for all supported platforms. Even when you are compiling the Native SDK locally and working with it, you'll often package it to a local SDK so that you can use the last part, which is…

* **The Loom CLI.** This is a special command, `loom`, which deals with running the right binaries from the selected Script SDK in order to run your game on desktop or device. It can download multiple Script SDK versions and run the right ones for different projects, so that developers can easily work with different versions of Loom. 

## SDK Versioning
Each of these components has its own version. This can be a little confusing, but you'll quickly find your way around. Here's what is important to know.

### Loom CLI Versions

First, you have some version of the Loom CLI installed (if you haven't, go follow the Getting Started guide!). You can check its version by running `loom -v`.

~~~ text
~/examples/WhackAMole$ loom -v
loom 0.0.113
~~~
   
You may need to download and run a new Loom CLI installer from time to time to support new features of Loom, but in general you won't need to update it very often.

### Loom Project & SDK Versons

Each Loom project has a `loom.config` file at the root. This file notes what version of the script SDK is used for that project. (If Loom CLI can't find that version locally, it will download it.)

You can use the `loom use` command to see or set the Script SDK version that is being used. For instance:

~~~ text
~/examples/WhackAMole$ loom use
Listing installed loom sdks...
  0.0.1
  0.0.118
  0.0.122
* 0.0.193
  0.0.205
~~~

You can see that for this project I am using the Loom Script SDK version 0.0.205. (Other projects might be using other versions!) I can select (and potentially download if I don't have it already) another version as follows:

~~~ text
~/examples/WhackAMole$ loom use 0.0.205
Configuring Project...
Checking for sdk 0.0.205
Preparing sdk files...
   Adding permissions to LoomDemo at /Users/beng/.loom/sdks/0.0.205/bin/LoomDemo.app/Contents/MacOS/LoomDemo
   Adding permissions to lsc at /Users/beng/.loom/sdks/0.0.205/tools/lsc
   Adding permissions to assetAgent at /Users/beng/.loom/sdks/0.0.205/tools/assetAgent
   Adding permissions to ldb at /Users/beng/.loom/sdks/0.0.205/tools/ldb
   Adding permissions to fruitstrap at /Users/beng/.loom/sdks/0.0.205/tools/fruitstrap
   Copying assets to /Users/beng/projects/EngineCo.git/sdk/examples/WhackAMole/assets
Now using loom version '0.0.205'
~~~

The last line is key; it shows that the version you requested has been selected succesfully. From this point on Loom CLI will use Loom tools and binaries from version 0.0.205 of the Script SDK.

### Loom Native Development
When you are working with the Native SDK, you will often want to run your locally built SDK against Loom projects on the same computer without putting the built script SDK up on a server somewhere!

You can do package and deploy an SDK locally by running the following command in the Native SDK:

~~~ text
rake deploy:sdk
~~~
   
This will build for all available platforms and put together a special SDK version called `dev`. (You can do `rake deploy:sdk['myDev']` to override the special version name that's set by default.)

Now you can run `loom use dev` (or whatever you called your version) to run your new native build of Loom. You can run the `rake deploy:sdk` command again and again without having to run `loom use dev` more than once - and don't forget you can type `loom use` in a Loom project to check the selected version.

### Installing Local Loom SDKs

You may want to share an SDK you have built with someone else or you may be on a system that does not have internet access. You can download a ZIP of the Loom SDK and install it with the following command:

~~~ bash
loom sdk install --local path/to/the.zip versionName
~~~

This will install the SDK for normal use under the version `versionName`. You can then use it by running `loom use versionName` in your Loom project.

## Complexity

Why do we introduce all of this complexity? Wouldn't it be simpler to just give people C++ source code and let them compile directly? Or, wouldn't it be simpler to just make zips of the Script SDK directly available and let developers run binaries from it directly as needed?

In fact, it turns out that running Loom projects requires many steps! First, you need to compile scripts. Assets may need to be processed or packaged. Then you need to launch both the game and the asset agent (for live reloading of assets). If you want to run on mobile devices, you may need to package the game multiple times for each device type, deploy it, and trigger a launch. If developers perform these steps manually, it is certain that they will do them out of order, forget to do them, or mistype and fail at doing some of them. (Certainly I would… maybe you are a perfect developer! ;) Thus, we want something to coordinate all these steps - simply running binaries directly is undesirable.

Why package Script SDKs instead of building Loom locally? Of course, we do support this (for advanced developers), but most of the time we think it's an inefficient choice. The reason is simple - setting up toolchains for each platform is a big commitment. Getting XCode all installed and proper is a complex process. So is getting set up for native Android development. And so is setting up OS X or Win32 or other development environments. For an experienced cross platform developer, getting all of these ready can take days; for a developer with less multiplatform experience, it can take longer.

With Loom, you can download a Script SDK with prepackaged binaries, or have just one or two of your team members tackle cross platform development and produce Script SDK builds themselves. Then 90% of your team's development in the fast, efficient script workflow, only requiring native development when you need it (which for some projects will be never - or only late in the project lifecycle).