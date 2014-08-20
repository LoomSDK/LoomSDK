title: The Console
description: The powerful debug console.
!------

When you run your game with `loom run`, you have access to a powerful debug console and logging toolkit along with live editing.

The Loom Console shows you all the log output from any connected games. Games deployed to mobile devices or desktop via `loom run --ios` or `loom run --android` or `loom run --desktop` will have the right IP/port in their configuration data and connect automatically. If mobile builds of your game exit or crash, just relaunch them on device to reconnect.

If you hit enter, you can send commands to games or to the console itself. Note that while you have the command prompt up, output is paused. Just hit enter again to go back to live log output.

## Log Output Format

Log output from the console looks like the following:

~~~ text
[loom.asset] Starting file watcher thread...
~~~

The part in square brackets ("[loom.asset]") is the log group with which this log line is associated. You can set filtering rules in `loom.config` to show/hide log output from different groups.

Log output from the game looks like this:

~~~ text
[asset.protocol] LOG: loading assets/PolyUI.png
~~~

Notice it has `[asset.protocol] LOG:` in front of it, showing that it came through the asset agent's logging.

Log entries have a severity level, but it is not currently shown in the Loom console.

You can emit log output from script using `trace` and from C++ using `lmLog`.

## Console Comands

There are two kinds of console commands, local and remote commands.

Local commands start with a . (period) and are run locally, in the loom console process. They do certain special functions it wouldn't make sense to do on the game end, and they are:

*.run* - This runs the desktop version of your game. If a copy is already running, it restarts it.

*.compile* - Launch `lsc` to compile scripts, then push those changes to clients.

*.sendall* - Send all known assets to all connected clients. This is useful for testing or if you have a client that is out of sync due to a crash.

You can add more commands by registering them with the `ConsoleCommandManager`:

~~~as3
	var commandManager = Application.group.getManager(ConsoleCommandManager);
    commandManager.registerCommand("myCommand", function():void {
    	trace("You ran my command!");
    });
~~~