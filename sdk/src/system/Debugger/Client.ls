/*
===========================================================================
Loom SDK
Copyright 2011, 2012, 2013
The Game Engine Company, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
===========================================================================
*/

package system.debugger
{

    import system.socket.Socket;
    import system.reflection.Type;
    import system.reflection.MethodBase;
    import system.reflection.MethodInfo;
    import system.CallStackInfo;

    /**
     *  Delegate to call for the reload command.
     */
    delegate ReloadDelegate():void;

    /**
     *  A low level interface to Looms Debugging API.
     *  It contains standard features for connecting to the debugger and executing debug commands.
     */
    static class DebuggerClient {

        /**
         *  Matches "<command> <source> <line>" i.e. "break ./src/Main.ls 35".
         */
        static private var sourceAndLineRegex:String = "^([A-Z]+)%s+(.-)%s+(%d+)%s*$";

        /**
         *  Delegate to call when given the reload command.
         */
        static public var reloaded:ReloadDelegate;


        /**
         *  Enable the debugger client's VM reload command.
         *  Reload starts disabled to give the application a
         *  chance to do base initialization and get to a valid
         *  reload state.
         */
        static public function enableReload(value:Boolean)
        {
            reloadEnabled = value;
        }

        /**
         *  Connects to the Debugger Server service either locally or over TCP/IP.
         *
         *  @param host The socket host of the Debugger Server.
         *  @param port The socket port of the Debugger Server.
         */
        static public function connect(host:String, port:Number) {

            socket = Socket.connect(host, port);

            // start not blocking
            socket.setTimeout(1);

            // The main debug loop is a coroutine which does not interfere with the client's code
            mainDebugLoop = Coroutine.create(mainLoop);
            mainDebugLoop.resume();

            // Set the debug hook which is implemented in native C code
            Debug.setDebugHook();

            Debug.lineEventDelegate += lineEventHook;
            Debug.returnEventDelegate += returnEventHook;
            Debug.callEventDelegate += callEventHook;
            Debug.assertEventDelegate += assertEventHook;

            Debug.blocking = true;

        }

        /**
         *  Sends a generic OK response code to the Debugger Server.
         */
        static function responseOK() {

            sendToServer("200 OK\n");
        }

        /**
         *  This is generally called from the C++ application code with no need for the client code to be
         *  aware of it. However, it is possible to drive the DebuggerClient from script.
         */
        public static function update() {

            mainDebugLoop.resume();

        }

        // BEGIN COMMNADS

        /**
         *  Reloads the client VM and initializes a new debug session
         *  Please note that reload must be enabled first, this is generally done
         *  at an initialized state in the application.  Debugging commands such as
         *  stepping and object inspecting do work before reloading is enabled.
         *
         *  Returns true on success and false otherwise
         */
        static function cmdRELOAD():Boolean {

            if (!reloadEnabled)
            {
                sendToServer("Client VM is currently initializing and not in a valid reload state, please continue execution\n");
                return false;
            }

            curFrameIdx = 0;
            Debug.blocking = false;
            Debug.stepping = false;
            Debug.stepOver = false;
            Debug.finishMethod = null;

            sendToServer("### Client VM Reload ###\n");

            if (socket)
                socket.close();

            reloaded();

            return true;
        }

        /**
         *  Executes the program until the next breakpoint (if any).
         *
         *  Returns true on success and false otherwise
         */
        static function cmdRUN():Boolean {

            if (checkAssertionState())
                return false;

            curFrameIdx = 0;
            Debug.blocking = false;
            Debug.stepping = false;
            Debug.stepOver = false;
            Debug.finishMethod = null;

            return true;
        }

        /**
         *  Sets a breakpoint at a given source file + line, example: setb src/demo/Program.ls 112.
         *
         *  Returns true on success and false otherwise
         */
        static function cmdBREAK(line:String):Boolean {

            if (checkAssertionState())
                return false;

            var commandv:Vector.<String> = line.find(sourceAndLineRegex);

            var result:String;
            if(commandv.length > 2 && (result = Debug.addBreakpoint(commandv[1], commandv[2].toNumber())) != null)
            {
                sendToServer("Setting breakpoint: " + result + " : " + commandv[2].toNumber() + "\n");
                return true;
            }
            else
            {
                return false;
            }
        }

        /**
         *  Clear command.
         *
         *  Returns true on success and false otherwise
         */
        static function cmdCLEAR(line:String):Boolean {

            if (checkAssertionState())
                return false;

            var commandv:Vector.<String> = line.find(sourceAndLineRegex);
            var result:String;

            if (commandv.length > 2 && (result = Debug.removeBreakpoint(commandv[1], commandv[2].toNumber())) != null)
            {
                sendToServer("Cleared breakpoint: " + result + " : " + commandv[2].toNumber() + "\n");
                return true;
            }
            else
            {
                return false;
            }
        }

        /**
         *  Step command, for now please use "over".
         *
         *  Returns true on success and false otherwise
         */
        public static function cmdSTEP():Boolean {

            if (checkAssertionState())
                return false;

            curFrameIdx = 0;
            Debug.blocking = false;
            Debug.stepping = true;
            Debug.stepOver = false;

            return true;
        }

        /**
         *  Steps over code (please note that this is currently stepping into methods, we have followup debugger tasks).
         *
         *  Returns true on success and false otherwise
         */
        static function cmdOVER():Boolean {

            if (checkAssertionState())
                return false;

            curFrameIdx = 0;
            Debug.blocking = false;
            Debug.stepping = true;
            Debug.stepOver = true;

            return true;
        }

        /**
         *  Finish command.
         *
         *  Returns true on success and false otherwise
         */
        static function cmdFINISH():Boolean {

            if (checkAssertionState())
                return false;

            if (!stackSnapshot || stackSnapshot.length < 1)
                return false;

            curFrameIdx = 0;
            Debug.stepping = false;
            Debug.stepOver = false;
            Debug.blocking = false;

            Debug.finishMethod = stackSnapshot[0].method;

            //Console.print("cmdFINISH", " ", finishMethod.getName());

            return true;
        }

        /**
         *  BT command.
         *
         *  Returns true on success and false otherwise
         */
        static function cmdBACKTRACE():Boolean {

            if (!stackSnapshot || stackSnapshot.length < 1)
                return false;

            var sframe:String = "";

            for (var i in stackSnapshot) {
                var info = stackSnapshot[i];
                var method = info.method;
                sframe += "#" + i + " " + method.getDeclaringType().getFullName() + ":" + info.method.getName() + "() " + ": " + info.source + " : " + info.line + "\n";
            }

            sendToServer(sframe);

            return true;
        }

        /**
         *  Info command.
         *
         *  Returns true on success and false otherwise
         */
        static function cmdINFO(line:String):Boolean {

            var elements = line.split(" ");

            if (elements.length < 2)
                return false;

            // info breakpoints
            if (elements[1].toLowerCase() == "break" || elements[1].toLowerCase() == "breakpoints") {

                var breakpoints:Vector.<Breakpoint> = Debug.getBreakpoints();

                var bps = "";
                for (var idx in breakpoints) {
                    bps += "#" + idx + ": " + breakpoints[idx].source + " : " + breakpoints[idx].line + "\n";
                }
                if (!bps)
                    bps = "No Breakpoints Defined\n";

                sendToServer(bps);
            }

            // info locals
            if (elements[1].toLowerCase() == "locals") {

                if (!stackSnapshot || stackSnapshot.length < 1)
                    return false;

                    var locals:Dictionary.<String, Object> = Debug.getLocals(stackSnapshot, curFrameIdx);

                    if (!locals) {
                        sendToServer("NULL LOCALS\n");
                        return false;
                    } else {

                    if (!locals.length) {
                        sendToServer("EMPTY LOCALS\n");
                        return false;
                    }

                    var ls = "";
                    for (var name:String in locals) {
                        ls += name + " : " + locals[name] + "\n";
                    }

                    sendToServer(ls);

                }

            }

            return true;
        }

        /**
         *  Print command.
         *
         *  Returns true on success and false otherwise
         */
        static function cmdPRINT(line:String):Boolean {

            if (!stackSnapshot || stackSnapshot.length < 1)
                return false;

            var elements = line.split(" ");

            if (elements.length == 2)
            {
                var locals:Dictionary.<String, Object> = Debug.getLocals(stackSnapshot, curFrameIdx);

                for (var name:String in locals)
                {
                    var path = elements[1].split(".");
                    var localname = path[0];
                    path.shift();

                    if (name == localname)
                    {
                        var o = locals[name];

                        if (o)
                        {
                            for each(var p in path)
                            {
                                var type = o.getType();

                                o = type.getFieldOrPropertyValueByName(o, p);

                                if (!o)
                                    break;

                            }
                        }

                        if(ideMode)
                            sendToServer("Print: " + inspectObjectIDE(o) + "\n");
                        else
                            sendToServer(name + " : " + ObjectInspector.inspect(o) + "\n");

                        return true;

                    }
                }
            }

            return cmdINFO("INFO locals");
        }

        static function inspectObjectIDE(o:Object):String
        {
            var json = new JSON();
            json.loadString("{}");

            var type = o.getType();

            var fields = type.getFieldAndPropertyList();
            for(var i=0; i<fields.length; i++)
            {
                var field = fields[i];
                var fieldJSON = new JSON();
                fieldJSON.loadString("{}");
                fieldJSON.setString("name", field);

                var val = type.getFieldOrPropertyValueByName(o, field);
                fieldJSON.setString("value", val.toString());
                fieldJSON.setString("numvars", val.getType().getFieldAndPropertyList().length.toString());
                json.setObject(i.toString(), fieldJSON);
            }

            return json.serialize();
        }


        /**
         *  Frame command.
         *
         *  Returns true on success and false otherwise
         */
        static function cmdFRAME(line:String):Boolean {

            if (!stackSnapshot || stackSnapshot.length < 1)
                return false;

            var elements = line.split(" ");
            if (elements.length == 2) {
                var frameIdx = int(elements[1]);
                if (frameIdx < 0 || frameIdx >= stackSnapshot.length) {
                    sendToServer("WARNING: frame selection out of bounds\n");
                    return false;
                }

                curFrameIdx = frameIdx;
                return true;
            }

            var sframe:String = "";

            for (var i in stackSnapshot) {
                var info = stackSnapshot[i];
                var method = info.method;
                sframe += "#" + i + " " + method.getDeclaringType().getFullName() + ":" + info.method.getName() + "() " + ": " + info.source + " : " + info.line + "\n";
            }

            sendToServer(sframe);

            return true;
        }

        /**
         *  Delete command.
         *
         *  Returns true on success and false otherwise
         */
        static function cmdDELETE(line:String):Boolean {

            var elements = line.split(" ");

            if (elements.length == 2) {

                var result:String;
                if ((Debug.removeBreakpointAtIndex(int(elements[1]))))
                {
                    sendToServer("Breakpoint #" + elements[1] + " deleted\n");
                    return true;
                }
                else
                {
                    return false;
                }
            }

            Debug.removeAllBreakpoints();

            sendToServer("All breakpoints deleted\n");

            return true;
        }

        static function cmdIDE() {
            ideMode = true;
        }



        /**
         *  Retrives a server commad from the server network connection
         *  commands are line based.
         */
        static function getServerCommand():String {

            var line = receiveFromServer();

            if (line == null) {

                var error = getError();

                if (error == "timeout") {
                    return line;
                }

                if (error == "closed")
                    Debug.assert(false, "closed");

                if (error) {
                    Console.print("Unhandled socket error: " + error);
                    Debug.assert(false, "error");
                }
            }

            return line;
        }

        /**
         *  Main command handling methd, this is called from the main debugger coroutine
         *  both when blocking and not blocking (note, that we use unblocking sockets
         *  for the client, so in this context blocking means that only the debugger loop
         *  is running (and receiving commands).
         */
        static function handleCommand() {

            var line = getServerCommand();
            if (!line)
                return;

            var commandv:Vector.<String> = line.find("^([A-Z]+)");

            var cmd = commandv[0];

            switch (cmd) {

                case "STEP":
                    if (cmdSTEP())
                        responseOK();
                    else
                        sendToServer("Failed to step\n");
                    break;

                case "BREAK":
                    if (cmdBREAK(line))
                        responseOK();
                    else
                        sendToServer("Failed to set breakpoint\n");
                    break;

                case "CLEAR":
                    if (cmdCLEAR(line))
                        responseOK();
                    else
                        sendToServer("Failed to clear breakpoint\n");
                    break;

                case "RUN":
                    if (cmdRUN())
                        responseOK();
                    else
                        sendToServer("Failed to run\n");
                    break;

                case "OVER":
                    if (cmdOVER())
                        responseOK();
                    else
                        sendToServer("Failed to do over\n");
                    break;

                case "FINISH":
                    if (cmdFINISH())
                        responseOK();
                    else
                        sendToServer("Failed to finish\n");
                    break;

                case "INFO":
                    if (cmdINFO(line))
                        responseOK();
                    else
                        sendToServer("Failed to get info\n");
                    break;

                case "BACKTRACE":
                    if (cmdBACKTRACE())
                        responseOK();
                    else
                        sendToServer("Failed to get a backtrace\n");
                    break;

                case "FRAME":
                    if (cmdFRAME(line))
                        responseOK();
                    else
                        sendToServer("Failed to set frame\n");
                    break;

                case "PRINT":
                    if (cmdPRINT(line))
                        responseOK();
                    else
                        sendToServer("Failed to print\n");
                    break;

                case "DELETE":
                    if (cmdDELETE(line))
                        responseOK();
                    else
                        sendToServer("Failed to delete\n");
                    break;

                case "RELOAD":
                    if (cmdRELOAD())
                        responseOK();
                    else
                        sendToServer("Failed to reload\n");
                    break;

                case "KILL":
                    Process.exit(1);
                    break;

                case "IDE":
                    cmdIDE();
                    responseOK();
                    break;
            }

        }

        /**
         *  Simple main loop of debugger coroutine, it processes commands and
         *  when not blocking returns control to the application code via a yield.
         */
        static function mainLoop():Boolean {

            while (true) {

                handleCommand();

                if(!Debug.blocking)
                    yield(true);

            }

            return true;

        }

        /**
         *  This wrappers around socket error detection, handling, and messaging.
         */
        static public function getError(clear:Boolean = true):String {

            return socket.getError(clear);

        }

        /**
         *  Clears the Error on the socket.
         */
        static public function clearError() {

            socket.clearError();
        }

        /**
         *  Send a message to the connected debug Server.
         */
        static public function sendToServer(msg:String) {
            socket.send(msg);
        }

        /**
         *  Gets a message from the debug Server.
         */
        static public function receiveFromServer():String {

            var msg = socket.receive();
            var error = socket.getError();
            if (error && error != "timeout") {
                Console.print("Socket closed exiting: ", error);
                Process.exit(1);
            }

            return msg;
        }

        /**
         *  Callback for call events.
         */
        static function callEventHook(callstack:Vector.<CallStackInfo>) {


            if (Debug.blocking && Debug.stepping && Debug.stepOver) {
                cmdFINISH();
                Debug.finishMethod = callstack[0].method; // fix up with this method
            }

        }

        /**
         *  Callback for return events.
         */
        static function returnEventHook(callstack:Vector.<CallStackInfo>) {

            if (Debug.assertion)
                return;

            //Console.print("returnEventHook", " ", callstack[0].method.getName());

            if (Debug.finishMethod == callstack[0].method) {
                Debug.finishMethod = null;
                cmdOVER();
            }

        }

        /**
         *  Callback for assertion events.
         */
        static function assertEventHook(callstack:Vector.<CallStackInfo>) {

            stackSnapshot = callstack;

            var source = callstack[0].source;
            var line = callstack[0].line;

            evtHitBreakpoint(source, line);

            // breakpoints block until we get a new command
            while(Debug.blocking) {

                handleCommand();

            }

        }

        /**
         *  The script based debug hook (the actual VM debug hook is implemented in native code
         *  for speed (see: engine/src/bindings/system/lmDebug.cpp Debug::debugHook)
         *  The script hook is called by the native hook handler with callstack information.
         */
        static function lineEventHook(callstack:Vector.<CallStackInfo>) {

            stackSnapshot = callstack;

            var source = callstack[0].source;
            var line = callstack[0].line;

            // Normalize path separators
            var pathParts = source.split("\\");
            source = pathParts.join("/");

            // check whether we have a breakpoint set for this source/line
            if (Debug.debugBreak || Debug.hasBreakpoint(source, line) ) {

                Debug.debugBreak = false;

                // and process it
                evtHitBreakpoint(source, line);

                // breakpoints block until we get a new command
                while(Debug.blocking) {

                    handleCommand();

                }

                // we're done here!
                return;
            }

            // If we're in step over mode
            if (Debug.stepping) {

                // process it
                evtStep(source, line);

                // we block until we get a new command
                while(Debug.blocking) {

                    handleCommand();

                }

                // if we're still stepping over lines, make sure we're still blocking
                // main application code
                if (Debug.stepping)
                    Debug.blocking = true;

                return;
            }

        }

        /**
         *  Processing for a DebugEventType.STEP.
         */
        static function evtStep(source:String, line:Number) {

            Debug.blocking = true;
            if(ideMode)
                sendToServer("Step: " + getBreakInfo(source, line) + "\n");
            else
                sendToServer("Step: " + source + " : " + line + "\n");
        }

        /**
         *  Processing for a DebugEventType.BREAKPOINT.
         */
        static function evtHitBreakpoint(source:String, line:Number) {

            Debug.blocking = true;
            if(ideMode)
                sendToServer("Hit breakpoint: " + getBreakInfo(source, line) + "\n");
            else
                sendToServer("Hit breakpoint: " + source + " : " + line + "\n");
        }

        static function getBreakInfo(source:String, line:Number):String {
            var tmp = curFrameIdx;

            var json = new JSON();
            json.loadString("{}");
            json.setString("source", source);
            json.setString("line", line.toString());

            var frames = new JSON();
            frames.loadString("{}");
            json.setObject("frames", frames);

            for (var i in stackSnapshot) {
                var frame = new JSON();
                frame.loadString("{}");
                var info = stackSnapshot[i];
                var method = info.method;

                frame.setString("type", method.getDeclaringType().getFullName());
                frame.setString("method", info.method.getName());
                frame.setString("source", info.source);
                frame.setString("line", info.line.toString());

                var locals = new JSON();
                locals.loadString("{}");
                frame.setObject("locals", locals);

                // set locals
                curFrameIdx = i;
                var localsDict:Dictionary.<String, Object> = Debug.getLocals(stackSnapshot, i);
                var j = 0;
                for (var name:String in localsDict) {
                    var local = new JSON();
                    local.loadString("{}");
                    local.setString("name", name);
                    local.setString("value", localsDict[name].toString());

                    var type:Type = localsDict[name].getType();
                    local.setString("numvars", type.getFieldAndPropertyList().length.toString());
                    locals.setObject(j.toString(), local);
                    j++;
                }

                frames.setObject(i.toString(), frame);
            }

            curFrameIdx = tmp;

            return json.serialize();
        }

        /**
         *  Checks whether we have hit an assertion state.
         */
        static function checkAssertionState():Boolean {

            if (Debug.assertion)
                sendToServer("Command is invalid in assertion state\n");
            return Debug.assertion;

        }

        /**
         *  The current stack snapshot, when we are stepping, have hit an assertion, etc.
         */
        static var stackSnapshot:Vector.<CallStackInfo> = [];

        /**
         *  The current frame index we have selected with the frame command.
         */
        static var curFrameIdx:int = 0;

        /**
         *  Our socket for communicating with server.
         */
        static var socket:Socket;

        /**
         *  The main debugger loop is a coroutine.
         */
        static var mainDebugLoop:Coroutine;

        /**
          * If reloadEnabled is true, the reload command will be allowed to
          * reload the main assembly.
          */
        static var reloadEnabled = false;

        /**
         *  If true, will output messages in JSON objects.
         */
        static var ideMode = false;


    }


}
