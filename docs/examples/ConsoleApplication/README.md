title: Console Application
description: A basic console application.
source: src/Main.ls
!------

## Overview
A basic console application.

To setup your project to run as a Console Application, set the app_type to "console" in your loom config.

You can simply do this by running the following command:
`loom config app_type console`

## Try It
@cli_usage

## Output

~~~bash
$: loom run
"/Users/loomsdk/.loom/sdks/1.1.2670/tools/lsc" -DassetAgentPort=12340 -DassetAgentHost=localhost
-DwaitForAssetAgent=150 -DdebuggerPort=8171 -DdebuggerHost=192.168.10.65 -DwaitForDebugger=0
LSC - JIT Compiler
[loom.compiler] SDK Path: /Users/loomsdk/.loom/sdks/1.1.2670/
Building Main.loom with default settings
[loom.compiler] Compiling: Main
[loom.compiler] Compile Successful: ./bin/Main.loom

Hello
~~~

## Code
@insert_source
