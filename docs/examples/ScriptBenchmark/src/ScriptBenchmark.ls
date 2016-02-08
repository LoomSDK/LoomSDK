package
{
    import loom.Application;

    import loom2d.display.StageScaleMode;
    import loom2d.math.Point;
    import loom2d.ui.SimpleLabel;
    
    /*
     * Script benchmark for performance metrics on desktop/device via CLI
     */
    public class ScriptBenchmark extends Application
    {

        var label:SimpleLabel;

        var toRun = 0;

        override protected function onTick()
        {
            switch (toRun)
            {
                case 0:                    
                    new BenchmarkFieldAccess().run();
                    break;
                case 1:
                    new BenchmarkFunctionCall().run();
                    break; 

                case 2:
                    new BenchmarkAllocation().run();
                    break;

                default:
                    toRun = 0;
                    return; // done

            }

            toRun++;

            // Avoid running out of memory
            GC.fullCollect();
        }

        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX; 

            label = new SimpleLabel("assets/Curse-hd.fnt", 240, 24);
            label.text = "Benchmarking!";
            label.x = stage.stageWidth/2 - 120;
            label.y = 64;
            stage.addChild(label);

        }
    }
}