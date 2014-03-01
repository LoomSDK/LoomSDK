title: Loom Config File
description: Loom Configuration Options
!------

Each LoomScript project contains a file in the root project directory called 'loom.config'. This file contains a list of settings that can be used on the native side of things, or accessed via script.

## Setting Configuration Properties

To set a property in your loom.config, you can either modify your file directly, or use the 'loom config' command like so:

~~~
loom config propertyName value
~~~

To set nested properties, use dot(.) syntax:

~~~
loom config nested.property.name value
~~~

To add a global config value (such as an iOS signing identity), use the --global flag:

~~~
loom config --global globalPropertyName value
~~~

## Built-In Configuration Properties

| Name                 | Available Flags      | Description                                                       |
| -------------------- | -------------------- | ----------------------------------------------------------------- |
| android_sdk_path     |                      | The path to your android sdk. This can only be set globally using |
|                      |                      | the --global flag.                                                |
| app_id               |                      | the app's ID                                                      |
| app_type             | [ default, console ] | The type of app; this determines whether it is run in a window as |
|                      |                      | a normal app, or as a console app using loomexec.                 |
| assetAgentHost       |                      | the host of the server running the asset agent                    |
| assetAgentPort       |                      | the asset agent server port number                                |
| debuggerHost         |                      | the host of the server running the LoomScript Debugger            |
| debuggerPort         |                      | the LoomScript Debugger server port number                        |
| display.height       |                      | the default height of your app                                    |
| display.orientation  | [ portrait,          | The orientation of your app. Set to 'auto' for auto-orientation.  |
|                      |   landscape,         |                                                                   |
|                      |   auto ]             |                                                                   |
| display.stats        | [ 0, 1, 2 ]          | Show stats. 0 = no stats, 1 = Report FPS to console,              |
|                      |                      | 2 = Show Debug Overlay                                            |
| display.title        |                      | The title of your app                                             |
| display.width        |                      | The default width of your app                                     |
| ios_signing_identity |                      | The target iOS Developer certificate to use when creating an iOS  |
|                      |                      | app, in the format "iPhone Developer: John Doe (XXXX)". This can  |
|                      |                      |  be set locally, or globally using the --global flag.             |
| log                  |                      | See 'logging options' below                                       |
| mobile_provision     |                      | The path to the .mobileProvision file for your app. This can be   |
|                      |                      | set locally, or globally using the --global flag.                 |
| sdk_version          |                      | The target SDK used to compile your app. 'latest' will point to   |
|                      |                      | the latest stable release.                                        |
| version              |                      | the current version number of the application                     |
| waitForAssetAgent    |                      | maximum number of milliseconds to pause execution while           |
|                      |                      | application attempts to connect to asset agent                    |
| waitForDebugger      |                      | number of milliseconds to wait for LoomScript debugger            |
| _wants51Audio        | [ true, false ]      | Set to true to initialize 5.1 audio                               |

## Logging Options

The Loom SDK includes a lightweight logging framework. All log output is associated with a log group. Log groups provide a name, an enabled, and a filter level (controlling what severity of log message is displayed).

You can set the logging settings for a particular group like so:

~~~
{
    "log": {
        "group.name": {
            "enabled": true,
            "level": 1
        }
    }
}
~~~

**Built-In Log Groups:**

Here is a list of the built-in logging groups used by the Loom SDK:

* asset.core - Logs related to local asset management
* asset.protocol - Logs related to the Asset Manager's asset protocol
* error - A log group for dumping platform errors
* GFX - Logs relating to native loom Graphics state
* GFXQuadRenderer - Logs coming from Loom's QuadRenderer
* GFXTexture - Logs specific to texture loading
* http.android - Logs relating to Android HTTP requests
* imageAsset - Logs related to the loading of image assets
* logger - Logs specific to Loom's logging system
* loom.application - Application-specific logs, including output from initialization and setup routines
* loom.asset - Logs specific to the Asset Agent
* loom.compiler - Basic log output from the LoomScript Compiler
* loom.compiler.verbose - More verbose output from the LoomScript Compiler
* loom.mobile.android - Logs specific to the Android platform
* Loom.NativeStore - Logs relating to the native cross-platform store API
* loom.script - 
* loom.sound - Logs coming from the native cross-platform sound API
* loom.store.apple - Logs related to the Apple app store API
* loom.store.googlePlay - Logs related to the Google Play store API
* loom.textAsset - Logs related to loading of Loom TextAssets
* Loom.Video - Logs relating to the native cross-platform video API
* loom.video.android - Logs related to Android native video states
* openal.android - Logs specific to the Android OpenAL implementation
* platform.network - Logs related to Loom's native networking implementation
* profiler - Logs coming from Loom's profiler
* script.LoomApplicationConfig - Log output related to the parsing of the loom.config file

