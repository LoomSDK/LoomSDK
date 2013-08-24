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

    [Native(managed)]
    native class BenchmarkNativeClass
    {
        public native var a = 0;
        public native var b = 0;
        public native var c = 0;

        public native function get x():float; 
        public native function set x(value:float);      
        public native function get y():float;
        public native function set y(value:float);
        public native function get rotation():float;
        public native function set rotation(value:float);

        public function doIt():Number
        {
            a = 1;
            b = 2;
            c = a + b;
            return c;
        }

    }

    public class NativeClassBenchmark extends Benchmark
    {

        public function run()
        {
            trace("Running - NativeClassBenchmark");
            var start = Platform.getTime();

            var i = 0;

            var instance = new BenchmarkNativeClass;
            
            //while ( true)
            while ( i < 10000000)
            {
                instance.x += 1;

                i++;
            }

            trace("Completed in ", Platform.getTime() - start, "ms");

        }
    }


}