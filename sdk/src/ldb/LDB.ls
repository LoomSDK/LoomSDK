package ldb {

    import system.debugger.Server;
    import system.debugger.DebuggerClient;
    import system.CommandLine;

    // LDB is be the script side of the LoomScript debugger server program
    // It should remain simple as we'll want to implement this under a variety of
    // programs/languages (for instance, Eclipse/Java)
    public class LDB {

        public static function main() {

            var isServer = false;
            for (var i = 0; i < CommandLine.getArgCount(); i++) {
                if (CommandLine.getArg(i) == "--server") {
                    isServer = true;
                }
            }

            var server:Server;

            if (isServer)
            {

                trace("LDB Remote Debugger");
                trace("Awaiting debug client connection");

                // bind to local host and wait for client to connect
                server = Server.listen("*", 8171);

                trace("Debug client connected");

                var lastLine = "s";
                while (true) {
                    IO.write("LDB> ");

                    var line = IO.read("*line");

                    if (!line)
                        line = lastLine;
                    else
                        lastLine = line;

                    server.handleCommand(line);

                    var msg = server.receiveFromClient();

                    if (msg == "### Client VM Reload ###")
                    {
                        // shutdown the server
                        server.shutdown();

                        trace("LDB Remote Debugger");
                        trace("Awaiting debug client connection");

                        // bind to local host and wait for client to connect
                        server = Server.listen("*", 8171);

                        trace("Debug client connected");

                    }
                    else if (msg != null)
                        trace(msg);


                }

            }

            else {

                DebuggerClient.connect("127.0.0.1", 8171);
                DebuggerClient.cmdSTEP();

                while(true) {

                    DebuggerClient.update();

                }
            }


            trace("Debugging session ended");

        }

    }

    class InstanceTest {

        public function doSomething() {
            trace("hi");
        }

    }


}