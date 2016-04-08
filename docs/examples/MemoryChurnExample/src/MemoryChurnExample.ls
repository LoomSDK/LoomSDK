package
{
    import loom.Application;
    import loom2d.Loom2D;
    import loom2d.animation.IAnimatable;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.math.Point;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    import system.Number;
    import system.Void;
    import system.metrics.Metrics;
    import system.platform.File;
    import system.platform.Platform;

    public class MemoryChurnExample extends Application implements IAnimatable
    {
        private var counter = 0;
        private var filename:String;
        private var output:String;
        
        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;
            
            filename = "data/newest/memstat-" + CommandLine.getArg(0) + ".tsv";
            
            //beginChurn();
            Loom2D.juggler.delayCall(beginChurn, 1);
            
            output = "";
        }
        
        private function write(line:String)
        {
            trace(line);
            output += line + "\n";
        }
        
        private function beginChurn() 
        {
            //trace("Churning...");
            
            //Loom2D.juggler.add(this);
            //advanceTime(0);
            
            /*
            var nums = [
                1e2, 2e2, 3e2, 4e2, 5e2, 6e2, 7e2, 8e2, 9e2,
                1e3, 2e3, 3e3, 4e3, 5e3, 6e3, 7e3, 8e3, 9e3,
                1e4, 2.5e4, 5e4, 7.5e4,
                1e5, 2.5e5, 5e5, 7.5e5,
                1e6
            ];
            */
            
            /* used for: 4
            var nums = [
                1e2, 2e2, 3e2, 4e2, 5e2, 6e2, 7e2, 8e2, 9e2,
                1e3, 2e3, 3e3, 4e3, 5e3, 6e3, 7e3, 8e3, 9e3,
                1e4, 2e4, 3e4, 4e4, 5e4, 6e4, 7e4, 8e4, 9e4,
                1e5, 2e5, 3e5, 4e5, 5e5, 6e5, 7e5, 8e5, 9e5,
                1e6
            ];
            */
            
            var nums = [
                1e2, 2e2, 3e2, 4e2, 5e2, 6e2, 7e2, 8e2, 9e2,
                1e3, 2e3, 3e3, 4e3, 5e3, 6e3, 7e3, 8e3, 9e3,
                1e4, 2.5e4, 5e4, 7.5e4,
                1e5, 2.5e5, 5e5
            ];
            
            var samples = 5;
            
            write("allocNum\tsampleNum\tallocTime\tgcTime\tbeforeMem\tafterMem\tbeforeProcMem\tafterProcMem");
            
            for (var ni:int = 0; ni < nums.length; ni++)
            {
                var n = nums[ni];
                for (var s:int = 0; s < samples; s++) 
                {
                    var allocTime = Platform.getTime();
                    for (var i:int = 0; i < n; i++) 
                    {
                        var p = new Point(i, -i);
                        p.scale(5);
                        p.normalize(1);
                    }
                    allocTime = Platform.getTime() - allocTime;
                    var beforeMem = GC.getAllocatedMemory();
                    var beforeProcMem = Metrics.getProcessMemoryUsage();
                    
                    var gcTime = Platform.getTime();
                    GC.fullCollect();
                    GC.collect(GC.STOP, 0);
                    gcTime = Platform.getTime() - gcTime;
                    
                    var afterMem = GC.getAllocatedMemory();
                    var afterProcMem = Metrics.getProcessMemoryUsage();
                    
                    write(n + "\t" + s + "\t" + allocTime + "\t" + gcTime + "\t" + beforeMem + "\t" + afterMem + "\t" + beforeProcMem + "\t" + afterProcMem);
                }
            }
            
            File.writeTextFile(filename, output);
            
            Process.exit(0);
            
        }
        
        /* INTERFACE loom2d.animation.IAnimatable */
        
        public function advanceTime(time:Number)
        {
            if (counter % 1 == 0) {
                var n = 1e3;
                
                for (var i:int = 0; i < n; i++) 
                {
                    new Point(i, i * 2);
                }
                
                //trace("Created " + n + " objects...");
            }
            
            counter++;
        }
    }
}