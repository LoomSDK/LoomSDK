package 
{
    import system.platform.Platform;

    class SomeFields
    {
        public var x = 1;
        public var y = 2;
        public var z = 3;
        public var w = 0;
    }

    /*
     * Benchmark for raw field access
     */
    public class BenchmarkFieldAccess
    {
        public function run()
        {
            trace("Running - BenchmarkFieldAccess");
            var start = Platform.getTime();

            var i = 0;

            var sf = new SomeFields;

            while (i < 10000000)
            {
                sf.w = sf.w + sf.x + sf.y + sf.z;
                i++;
            }

            trace("Completed in ", Platform.getTime() - start, "ms");

        }
    }
    
}