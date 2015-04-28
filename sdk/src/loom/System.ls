package loom
{
    import system.platform.Platform;
    import system.platform.PlatformType;
    
    public class System
    {
        private var _system:natSystem = new natSystem();
        
        /**
         * Run the provided command
         */
        public function cmd(path:String):void { _system.cmd(path); }
        
        public function multCmd(paths:Vector.<String>):void
        {
            if (!paths || paths.length == 0)
                return;
            
            if (paths.length == 1)
            {
                _system.cmd(paths[0]);
            }
            else
            {
                
                var finalPath:String = "";
                
                for (var i:int = 0; i < paths.length - 1; i++)
                {
                    if (Platform.getPlatform() == PlatformType.WINDOWS)
                    {
                        finalPath += paths[i];
                        finalPath += " & ";
                    }
                    else if (Platform.getPlatform() == PlatformType.OSX)
                    {
                        finalPath += paths[i];
                        finalPath += " && ";
                    }
                }
                
                finalPath += paths[i];
                
                _system.cmd(finalPath);
            }
        }
        
        public function addOnData(val:Function):void { _system.onData += val; }
        public function removeOnData(val:Function):void { _system.onData -= val; }

        public function addOnFinish(val:Function):void { _system.onFinish += val; }
        public function removeOnFinish(val:Function):void { _system.onFinish -= val; }
    }
    
    private native class natSystem
    {
        public native function cmd(path:String):Void;
        
        public native var onData:NativeDelegate;

        public native var onFinish:NativeDelegate;
    }
}
