package 
{
    import system.platform.Platform;

    class SimpleObject
    {
        function SimpleObject()
        {
            
        }
    }

    class SimpleObject2 extends SimpleObject
    {
        function SimpleObject2()
        {
            
        }
    }

    class SimpleObject3 extends SimpleObject2
    {
        function SimpleObject3()
        {

        }

        public var x = 1.0;
        public var y = 2.0;
        public var z = 3.0;
        public var w = 0.0;
    }

    /*
     * Benchmark for to test allocation of a representative script class with
     * some inheritance.
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

            trace("BenchmarkAllocation completed in ", Platform.getTime() - start, "ms");

        }
    }
    
}