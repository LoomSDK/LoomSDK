package 
{
    import system.platform.Platform;

    class SimpleObject
    {
    }

    class SimpleObject2 extends SimpleObject
    {
    }

    class SimpleObject3 extends SimpleObject2
    {
        public var x = 1.0;
        public var y = 2.0;
        public var z = 3.0;
        public var w = 0.0;
    }

    /*
     * Benchmark for raw field access
     */
    public class BenchmarkAllocation
    {
        public function run()
        {
            trace("Running - BenchmarkAllocation");
            var start = Platform.getTime();

            var i = 0;
            while (i < 100000)
            {
                var sf = new SimpleObject3();
                i++;
            }

            trace("Completed in ", Platform.getTime() - start, "ms");

        }
    }
    
}