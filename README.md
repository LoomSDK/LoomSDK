### Loom Native SDK - Mobile App and Game Development

The Loom SDK is a great mobile game and application framework (www.loomsdk.com). 

This is the "Loom Native SDK" - our term for the C, C++, Java, and Objective C source code for the Loom runtime, compilers, etc. It is for power users and confident native developers.

The Native SDK is a complement to the workflow available through Loom Turbo. It can be used by itself but be prepared to suffer through a frustrating and complex workflow that is greatly improved when combined with Loom Turbo and the CLI. Cross platform native development is hard!

### [Loom Turbo](http://www.loomsdk.com/plans) 

The Loom official maintainers, The Engine Company, actively build Loom on our build farm, with the binaries available in [Loom Turbo](http://www.loomsdk.com/plans)'s firehose builds within minutes!

We realize not everyone is an experienced C/C++ programmer with working native toolchains and a need to extend Loom at a low level.  We also use Loom to create applications, so we built Loom Turbo.

##### If you're interested in accelerated development using industry standard scripting and amazing live reload workflow, you want [Loom Turbo](http://www.loomsdk.com/plans).

### Platforms

Loom currently runs on Android, iOS, Windows, OSX, Linux, and Ouya

### License

The Loom SDK is licensed under the [Apache License, Version 2](http://www.apache.org/licenses/LICENSE-2.0.html) 

There are a number of other licenses used which can be viewed in the LICENSE_THIRDPARTY file.  We have been very careful in selecting no-nonsense licenses and the Loom Native SDK contains no traces of proprietary or copyleft licenses.  

### Community

http://www.loomsdk.com/community 

### Build Instructions

The build system is setup to generate a "dev" sdk for use with the Loom command line interface (Loom CLI) available from [LoomSDK.com](http://www.loomsdk.com)

Firstly, building Loom from the native source code requires having [Rake](https://github.com/jimweirich/rake) & [CMake](http://www.cmake.org) installed and on your path.

There are 2 important rake commands

**rake deploy:free_sdk** 

This will build and deploy a **OSX** or **Windows** dev sdk based on your host OS.

**rake deploy:sdk** 

This will build and deploy a full dev sdk with support for **Windows/Android** or **OSX/iOS/Android** depending on your host OS.

Once successfuly compiled and deployed, change directory to your project and issue this Loom CLI command:

**loom use dev**

You'll now be developing with your custom Loom build!

For more information, please see the individual Readme files for platform specific setup instructions.
