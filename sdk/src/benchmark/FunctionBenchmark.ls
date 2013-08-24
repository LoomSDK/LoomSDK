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

package benchmark
{
    import system.platform.Platform;

    public class FunctionBenchmark extends Benchmark
    {
        function doIt():Number
        {
            var a = 1;
            var b = 2;
            return a + b;
        }

        public function run()
        {
            trace("Running - FunctionBenchmark");
            var start = Platform.getTime();

            var i = 0;

            while (i < 10000000)
            {
                doIt();
                i++;
            }

            trace("Completed in ", Platform.getTime() - start, "ms");

        }
    }
    
}