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

package system.debugger {

    import system.socket.Socket;
    
    /**
     *  Extremely simple %Server class for communication with the client debugger
     *  This class is purposefully simple as it may be implemented in a number of different
     *  scenarios/languages
     */
    class Server {
    
        private var socket:Socket;
        private var client:Socket;
        
        /**
         *  Creates an instance of Server that is configured to accept client connections against the specified host/port.
         *  
         *  @param host The host to bind the debugging Socket to. Defaults to "*"
         *  @param port The port to binf the debugging Socket to. Defaults to 8171
         *
         *  @return The configured server instance.
         */
        public static function listen(host:String = "*", port:Number = 8171):Server 
        {
        
            var server = new Server();
            server.socket = Socket.bind(host, port, 32);
            server.client = server.socket.accept();            
            server.client.setTimeout(250);
            
            return server;
            
        }

        /**
         *  Shutdown an instance of the debugger server, closing ports.
         *
         */
        public function shutdown() 
        {
        
            if (client)
                client.close();

            if (socket)
                socket.close();

            socket = client = null;
            
        }

        
        /**
         *  Sends a message to the connected debugging client
         *  
         *  @param msg The message to send to the client
         */
        public function sendToClient(msg:String) 
        {
            
            client.send(msg);
            
        }
        
        /**
         *  Gets the latest message from the client
         *
         *  @return Message from the client
         */
        public function receiveFromClient():String 
        {
            
            var lines = [];        
            var s = client.receive();
            
            while (s && s != "") {
            
                if (s != "200 OK") {
                    lines.pushSingle(s);
                }
                
                s = client.receive();
            } 
            
            var rbuffer = lines.join("\n");
            if (!rbuffer.length)
                rbuffer = "OK";
            
            return rbuffer;
            
        }
        
        /**
         *  Handles a specific command either sent from the client or invoked by
         *  the Server instance owning program.
         *
         *  @param line The command to handle/execute.
         */
        public function handleCommand(line:String) 
        {
            
            var commandv:Vector.<String> = line.find("^([a-z]+)");
            var elements:Vector.<String>;
            var command = commandv[0];
            var cmd:String;
            var found:Vector.<String>;
            var file:String;
            var bline:String;
            
            switch(command) {
    
                case "b":
                case "break":
                case "breakpoint":
                
                    found = line.find("^([a-z]+)%s+(.-)%s+(%d+)%s*$");
                    
                    if (found.length == 3) {
                        
                        file = found[1];
                        bline = found[2];
                        
                        sendToClient("BREAK " + file + " " + bline + "\n");
                        Console.print(receiveFromClient());
                        
                    }
                    
                    break;
                
                // remove a breakpoint by source line    
                case "c":
                case "clear":
                
                    found = line.find("^([a-z]+)%s+(.-)%s+(%d+)%s*$");
                    
                    if (found.length == 3) {
                        
                        file = found[1];
                        bline = found[2];
                        
                        sendToClient("CLEAR " + file + " " + bline + "\n");
                        Console.print(receiveFromClient());
                        
                    }
                    
                    break;
                    
                    
                case "bt":
                case "backtrace":
                    sendToClient("BACKTRACE\n");
                    break;
                    
                case "s":
                case "step":
                    sendToClient("STEP\n");
                    break;
                                    
                case "n":    
                case "next":
                    sendToClient("OVER\n");
                    break;
                    
                case "d":    
                case "delete":
                    elements = line.split(" ");
                    cmd = "DELETE" + (elements.length == 2 ? " " + elements[1] : "") + "\n";
                    sendToClient(cmd);
                    break;
                                        
                case "finish":
                    sendToClient("FINISH\n");
                    break;
                    
                case "frame":
                    elements = line.split(" ");
                    cmd = "FRAME" + (elements.length == 2 ? " " + elements[1] : "") + "\n";
                    sendToClient(cmd);
                    break;
                    
                case "p":
                case "print":
                    elements = line.split(" ");
                    cmd = "PRINT" + (elements.length == 2 ? " " + elements[1] : "") + "\n";
                    sendToClient(cmd);
                    break;
                    
                case "info":
                    elements = line.split(" ");
                    elements.shift();
                    cmd = "INFO " + elements.join(" ") + "\n";
                    sendToClient(cmd);
                    break;
                    
                case "k":                    
                case "kill":
                    sendToClient("KILL");
                    break;

                case "q":                    
                case "quit":
                    Process.exit(1);
                    break;

                case "r":    
                case "run":
                    sendToClient("RUN\n");
                    break;
                    
                case "c":    
                case "continue":
                    sendToClient("RUN\n");
                    break;

                case "reload":    
                    sendToClient("RELOAD\n");
                    break;
                    
                case "help":    
                    printHelp();
                    break;
                    
                default:
                    Console.print("Unknown command: " + command.toString());
                    break;
                 
            }
            
        }
        
        /*
         * Prints ldb help.
         */
        function printHelp() 
        {
            
            var help = "LDB Commands:\n";
            help += "r, run : Starts program execution\n\n";
            help += "s, step : Steps a line of execution, stepping into method calls\n\n";
            help += "n, next : Steps a line of execution, stepping over method calls\n\n";
            help += "finish : Finish the current method\n\n";
            help += "bt, backtrace : Prints the current callstack\n\n";
            help += "b, break, breakpoint sourcefile line: Sets a breakpoint in the given source at the specified line. (Ex. break src/demo/Main.ls 100)\n\n";
            help += "clear sourcefile line: Clears a breakpoint in the given source at the specified line. (Ex. clear src/demo/Main.ls 100)\n\n";
            help += "info locals: Prints the name and values of local variables (including arguments)\n\n";
            help += "info break: Prints a numbers list of all current breakpoints\n\n";
            help += "frame <#> : Displays the current stack as a numbered list.  If the optional number is supplied, switches to that stack frame\n\n";            
            help += "q, quit: quits the LDB session\n\n";
            help += "k, kill: kills the LDB client\n\n";
            help += "d, delete <#> : Deletes all breakpoints or if a number is given just the breakpoint in the list given by the \"info break\" command\n\n";
            help += "p, print <variable name> : Prints the value of the specified local variable, if no variables are specified prints all locals\n\n";
            help += "reload : Restarts the client VM\n\n";
            help += "help : Display this help\n";
            
            Console.print(help);
            
        }
        
        
    }
    
    
}