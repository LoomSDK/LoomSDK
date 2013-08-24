package 
{
    import system.platform.Platform;

    class SomeCalls
    {
        public function doIt(z:Number):Number
        {
            var x = 1;
            var y = 2;
            return x + y + z;
        }

        static public function staticDoIt(z:Number):Number
        {
            var x = 1;
            var y = 2;
            return x + y + z;
        }

    }

    /*
     * Benchmark for script instance and static function calls
     */
    public class BenchmarkFunctionCall
    {
        public function run()
        {
            trace("Running - BenchmarkFunctionCall");
            

            var i = 0;

            var sc = new SomeCalls;

            var start = Platform.getTime();

            while (i < 10000000)
            {
                sc.doIt(i);
                i++;
            }

            var now =  Platform.getTime();

            trace("Instance functions ", now - start, "ms");

            i = 0;

            while (i < 10000000)
            {
                var b = SomeCalls.staticDoIt(i);
                i++;
            }

            trace("Static functions ", Platform.getTime() - now, "ms");

            trace("Completed in ", Platform.getTime() - start, "ms");

        }
    }
    
}