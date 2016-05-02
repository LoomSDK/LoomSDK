title: Loom Config File
description: Loom Configuration Options
!------

Each LoomScript project contains a file in the root project directory called 'loom.config'. This file contains a list of settings that can be used on the native side of things, or accessed via script.

## Setting Configuration Properties

To set a property in your loom.config, you can either modify your file directly, or use the 'loom config' command like so:

~~~console
$ loom config propertyName value
=> "value"
~~~

To set nested properties, use dot(.) syntax:

~~~console
$ loom config nested.property.name value
=> "value"
~~~

To add a global config value (such as an iOS signing identity), use the --global flag:

~~~console
$ loom config --global globalPropertyName value
=> "value"
~~~

## Built-In Configuration Properties

| Name                 | Valid Values             | Description                                                       |
| -------------------- | ------------------------ | ----------------------------------------------------------------- |
| android_sdk_path     |                          | The path to your android sdk. This can only be set globally using |
|                      |                          | the --global flag.                                                |
| app_id               |                          | the app's ID                                                      |
| app_type             | [ `"default"`,           | The type of app; this determines whether it is run in a window as |
|                      |   `"console"` ]          | a normal app, or as a console app using loomexec.                 |
| assetAgentHost       |                          | the host of the server running the asset agent                    |
| assetAgentPort       |                          | the asset agent server port number                                |
| debuggerHost         |                          | the host of the server running the LoomScript Debugger            |
| debuggerPort         |                          | the LoomScript Debugger server port number                        |
| display.x            | [ `<integer>`,           | The default horizontal position of the app in pixels from the     |
|                      |   `"center"` ]           | left edge of the screen.                                          |
|                      |                          | A string value of `"center"` positions the window so it appears   |
|                      |                          | horizontally centered on screen.                                  |
| display.y            | [ `<integer>`,           | The default vertical position of the app in pixels from the       |
|                      |   `"center"` ]           | top edge of the screen.                                           |
|                      |                          | A string value of `"center"` positions the window so it appears   |
|                      |                          | vertically centered on screen.                                    |
| display.width        | `<integer>`              | The default width of your app in pixels                           |
| display.height       | `<integer>`              | The default height of your app in pixels                          |
| display.maximized    | [ `true`, `false` ]      | If `true`, the app window opens maximized                         |
| display.minimized    | [ `true`, `false` ]      | If `true`, the app window opens minimized                         |
| display.resizable    | [ `true`, `false` ]      | If `false`, the app window is unable to be resized during runtime |
| display.borderless   | [ `true`, `false` ]      | If `true`, the app window has no borders. Note that on some       |
|                      |                          | platforms a small border might still appear if `resizable` is set |
|                      |                          | to `true` to allow resizing. Set `resizable` to `false` to hide   |
|                      |                          | that border as well.                                              |
| display.mode         | [ `"window"`,            | App window display mode. Set to `fullscreen` for                  |
|                      |   `"fullscreen"`,        | "true" fullscreen changing the screen resolution to the width and |
|                      |   `"fullscreenWindow"` ] | height as defined above. Set to `fullscreenWindow` to display the |
|                      |                          | app in a borderless fullscreen window taking up the whole screen. |
|                      |                          | This is similar to setting `maximized` and `borderless` to `true` |
|                      |                          | and `resizable` to `false`.                                       |
| display.orientation  | [ `"portrait"`,          | The orientation of your app. Set to 'auto' for auto-orientation.  |
|                      |   `"landscape"`,         |                                                                   |
|                      |   `"auto"` ]             |                                                                   |
| display.stats        | [ `0`, `1` ]             | Show stats. 0 = no stats, 1 = Report FPS to console,              |
| display.title        |                          | The title of your app                                             |
| ios_signing_identity |                          | The target iOS Developer certificate to use when creating an iOS  |
|                      |                          | app, in the format "iPhone Developer: John Doe (XXXX)". This can  |
|                      |                          |  be set locally, or globally using the --global flag.             |
| log                  |                          | See 'logging options' below                                       |
| mobile_provision     |                          | The path to the .mobileProvision file for your app. This can be   |
|                      |                          | set locally, or globally using the --global flag.                 |
| sdk_version          |                          | The target SDK used to compile your app. 'latest' will point to   |
|                      |                          | the latest stable release.                                        |
| version              |                          | the current version number of the application                     |
| telemetry            | [ `true`, `false` ]      | Enable or disable telemetry for the entire session. See the       |
|                      |                          | Profiling section in the LoomScript guide for more information.   |
| waitForAssetAgent    |                          | maximum number of milliseconds to pause execution while           |
|                      |                          | application attempts to connect to asset agent                    |
| waitForDebugger      |                          | number of milliseconds to wait for LoomScript debugger            |
| _wants51Audio        | [ `true`, `false` ]      | Set to true to initialize 5.1 audio                               |

## Logging Options

The Loom SDK includes a lightweight logging framework. All log output is associated with a log group. Log groups provide a name, an enabled toggle, and a filter level (controlling what severity of log message is displayed).

You can set the logging settings for a particular group like so:

~~~json
{
    "log": {
        // Global default filter level set to warning or higher
        "level": "warn",
        
        "sdl": {
            // Enables all log groups starting with 'sdl'
            "enabled": true,
            
             // Sets the filter level for 'sdl' groups to allow all debug messages and above
            "level": "debug",
            
            // Applies to 'sdl.error' specifically and overrides the above
            "error": {
                
                // Disable all 'sdl.error' messages
                "enabled": false
            }
        }
    }
}
~~~

Additionally, the command line switch `--verbose` overrides the global default level, setting it to `verbose`.

**Available Log Filter Levels:**

* `debug` or `verbose` - Debug level usually used for all kinds of usually not relevant information, but often useful when something doesn't work right and you want to figure out what's going on behind the scenes.
* `default` or `info` or empty string - Messages of informational nature - a quick overview of what is happening.
* `warn` or `warning` - Something happened that wasn't expected. It's usually not a big problem, but can be an indicator of one.
* `error` - A really bad thing happened and you should probably fix it.
* `quiet` or `none` - Disables output, no messages should use this level.

**Built-In Log Groups:**

Here is a list of the built-in logging groups used by the Loom SDK:

* `core` - Logs related to the main application entry point
* `app` - Application-specific logs, including output from initialization and setup routines
* `script` - Logs from core script runtime
* `config` - Logs related to parsing the loom.config configuration file


* `agent` - Logs specific to the state of the Asset Agent and any files it might be serving
* `asset` - General asset system logs
* `asset.prot` - Logs related to the Asset Manager's asset protocol
* `asset.txt` - Asset system logs related to text files
* `asset.bin` - Asset system logs related to binary files


* `profiler` - Runtime profiler output logs
* `lt` - Loom Telemetry logs
* `lts` - Loom Telemetry Server logs


* `compiler` - Diagnostic Loom compiler logs
* `debug` - Loom debugger logs


* `mobile` - Per-platform logs related to the `Mobile` class
* `store` - General logs about the native store API
* `googleplay` - Logs related to the Google Play Store API
* `applestore` - Logs related to the Apple App Store API
* `facebook` - Logs related to Facebook integration
* `teak` - Per-platform logs related to Teak integration
* `parse` - Parse integration logs


* `net` - Low level socket networking logs
* `http` - Per-platform logs related to HTTP requests
* `http.req` - Logs related to the `HTTPRequest` class
* `sqlite` - Logs related to SQLite integration


* `gfx` - Logs related to the internal graphics display
* `gfx.quad` - Logs related to the `QuadRenderer` graphics class
* `gfx.shader` - Logs related to compilation and usage of graphics shaders
* `gfx.tex` - Logs related to graphics texture creation, usage and disposal
* `gfx.vector` - Logs related to processing and rendering vector graphics
* `video` - Per-platform logs related to video playback
* `sound` - Logs coming from the native cross-platform sound API
* `controller` - Game controller diagnostic logs


* `sdl` - General logs from the SDL library
* `sdl.app` - Logs from the application SDL log category
* `sdl.error` - Logs from the error SDL log category
* `sdl.system` - Logs from the system SDL log category
* `sdl.audio` - Logs from the audio SDL log category
* `sdl.video` - Logs from the video SDL log category
* `sdl.render` - Logs from the render SDL log category
* `sdl.input` - Logs from the input SDL log category
* `sdl.custom` - Logs from the custom SDL log category
* `luastate` - Logs related to the Lua runtime
* `allocator` - Internal memory allocator logs 
* `error` - A log group for printing platform errors
* `delegate` - Internal native delegate logs
* `interface` - Internal native interface logs
* `logger` - Logging system logs


All the internal log group names are <= 10 characters long for consistency of output.