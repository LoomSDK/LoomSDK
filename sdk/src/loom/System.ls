package loom
{
    import system.platform.Platform;
    import system.platform.PlatformType;
    
    [Native(managed)]
    public native class System
    {
        /**
         * Run the provided command and get feedback from that command. The feedback will be returned using the onData
         * delegate. Data is automatically extracted from both STDOUT and STDERR.
         * 
         * NOTE: If you wish to run a synchronous multi-part command, it is reccomended that you use the runMult function because of
         * platform specific differences in command syntax.
         * 
         * @param command The command that will be run through the native command interface.
         * 
         * @see multCmd
         */
        public native function run(command:String):void;
        
        /**
         * Synchronously runs the provided commands in order and gets feedback from that command. Functionally simmilar to `run`, but 
         * this function takes into account platform specific syntax differences to run multiple commands. Data is automatically extracted
         * from both STDOUT and STDERR.
         * 
         * @param commands A vector of strings that contains all of the commands to be synchronously run. The commands in this vector will
         * be run in order, starting at index 0.
         */
        public function runMult(commands:Vector.<String>):void
        {
            if (!commands || commands.length == 0)
                return;
            
            if (commands.length == 1)
            {
                this.run(commands[0]);
            }
            else
            {
                var finalPath:String = "";
                
                for (var i:int = 0; i < commands.length - 1; i++)
                {
                    if (Platform.getPlatform() == PlatformType.WINDOWS)
                    {
                        finalPath += commands[i];
                        finalPath += " & ";
                    }
                    else if (Platform.getPlatform() == PlatformType.OSX)
                    {
                        finalPath += commands[i];
                        finalPath += " && ";
                    }
                }
                
                finalPath += commands[i];
                this.run(finalPath);
            }
        }
        
        public native function close():void;
        
        /**
        * Adds a function to the onData delegate that is fired off every time a full chunk of data is retrieved from the system.
        * A "full chunk" of data, in this case, is a string returned by the console that either ended with a
        * new line character, or was over 1024 characters long. In the case that the line was simply too long
        * the string will be broken up and returned over multiple calls of this delegate.
        *
        * NOTE: While a chunk of data is defined by end of line characters. The returned data will NOT contain
        * end of line characters.
        * 
        * @param val The function to be added to the onData delegate. It is expected that this function will have
        * the signature `function(String):void`.
        */
        //public function addOnData(val:Function):void { _system.onData += val; }
        /**
         * Removes a delegate function that was previously added with the addOnData function.
         * 
         * @param val The function to be removed from the onData function.
         */
        //public function removeOnData(val:Function):void { _system.onData -= val; }
        
        public native var onData:NativeDelegate;

        public native var onFinish:NativeDelegate;

        /**
         * Adds a function to the onFinish delegate that is fired off when a command is finished running.
         * 
         * @param val The function to be added to the onFinish delegate. It is expected that this function will have
         * the signature `function():void`.
         */
        //public function addOnFinish(val:Function):void { _system.onFinish += val; }
        /**
         * Removes a delegate function that was previously added with the addOnFinsh function.
         * 
         * @param val The function to be removed from the onFinish function.
         */
        //public function removeOnFinish(val:Function):void { _system.onFinish -= val; }
    }
}
