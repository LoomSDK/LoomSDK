title: Loom Editing
description: Edit code and assets in real time.
!------

Loom lets you modify assets and code on your desktop and see changes instantly in your game, wherever it is running.

One of the most frustrating and time consuming aspects of game development is tweaking art and game logic. When you have to deploy onto multiple devices to test the appearance and behavior of your changes, it becomes even worse. Loom reduces iteration time by streaming changed files to the device, where it can be hot reloaded to show your changes instantly.

NOTE: Live editing communicates with your device over Wifi. If your development system and your devices aren't on the same wifi network (ie, can ping one another) then live reload won't work.

## Using Live Editing
To live edit, just use the `loom run` command. It has live editing enabled by default. 

Go ahead and modify some of the files in the asset folder. Changes to .LML, .CSS, .PNG/.GIF/.JPEG/etc., and many other formats show up immediately. In the case where a change isn't visible in game right away, just type `reload` in the console and it will show up.

## Live Code Editing

You can simply do `loom run` to automatically recompile script when changes are detected.

Whenever code changes occur (ie a .ls file is modified), `Main.loom` is recompiled. Whenever a change to `Main.loom` is detected, the assembly is streamed to connected games. When games detect a new `Main.loom`, they restart the VM. Within a few seconds the game has restarted and your changes are visible.

## Edit And Continue?

We don't support edit and continue because it introduces a lot of complex issues for not very much benefit. 

What if you modify a class that is in use? When is the change applied? How does the VM deal with managing two different versions of the same class at the same time? When/how are statics initialized? How does it interact with the debugger?

Of course, all these issues can be solved. But since we are developing mobile games that need to be resilient against restart anyway, it is more pragmatic to heavily use the game's restart path during development. That way when you start using your game in the real world, and a phone call comes in and you get shut down mid-game, you know that the game will resume properly - because you've tested it thousands of times during development. 

## Technical Underpinnings
When `loom run` launches, it passes the host computer's IP and a port to `lsc`, which compiles the game's script. This IP and port is baked into the game's config information in `Main.loom`. When the game boots, it tries to connect to an instance of `assetAgent` listening at that IP and port.

At the same time, `loom run` launches an instance of `assetAgent`, which scans the files in your game project for changes several times a second. Whenever a file has changed, it sends the new version of the file to any connected game clients.

In general, you probably won't need to do anything to support hot reloading support; most of the time you'll use subsystems that already support it. However, if you do need to add support for a new asset type it is fairly straightforward.

Natively, game code uses the API defined in `assets/assets.h` to subscribe to changes on assets that they care about. They get a simple callback when it changes and can appropriately update their state. Please read this file for details on the API including usage examples.

`Loom.LoomTextAsset` provides a script-side API for working with assets. Although it says text in the name, strings in LoomScript are binary-safe so you can work with a wide variety of formats with this class. Please look at the `loom docs` entry for this class to see details of using it.