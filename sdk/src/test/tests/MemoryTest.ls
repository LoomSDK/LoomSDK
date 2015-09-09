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

package tests {

    import unittest.Assert;

    class Memory
    {
        var someValue = 1;

        public function myfunction(...args)
        {
            var stype:Type = Type.getTypeByName("Memory");

            stype.setFieldOrPropertyValueByName(this, "someValue", 100);

            if (someValue != 100)
                trace("Error!");


        }
    }

    public class MemoryTest
    {
        [Test]
        function allocate()
        {
            var memory:Vector.<Memory> = [];

            var initialMem = GC.getAllocatedMemory();

            for (var i = 0; i < 100000; i++)
            {
                memory.push(new Memory);
                memory[memory.length - 1].myfunction();
            }

            var allocatedMem = GC.getAllocatedMemory();
            Assert.greater(allocatedMem, initialMem, "Allocated some data");

            memory.clear();

            GC.collect(GC.STEP, 2000);
            var allocatedMem2 = GC.getAllocatedMemory();
            Assert.less(allocatedMem2, allocatedMem, "Should free some memory");

            Assert.popResults();

            GC.fullCollect();
            // No way of guaranteeing that everything will be freed - internals
            Assert.less(GC.getAllocatedMemory(), allocatedMem2, "Should be the same as when we started the test");
        }

        [Test]
        function churn()
        {
            var memory:Vector.<Memory> = [];

            var initialMem = GC.getAllocatedMemory();

            for (var i = 0; i < 100000; i++)
            {
                var m = new Memory();
                m.myfunction();
            }

            var allocatedMem = GC.getAllocatedMemory();
            Assert.greater(allocatedMem, initialMem, "Allocated some data");

            memory.clear();

            GC.collect(GC.STEP, 2000);

            var allocatedMem2 = GC.getAllocatedMemory();
            Assert.less(allocatedMem2, allocatedMem, "Should free some memory");

            Assert.popResults();

            GC.fullCollect();
            // No way of guaranteeing that everything will be freed - internals
            Assert.less(GC.getAllocatedMemory(), allocatedMem2, "Should be the same as when we started the test");
        }
    }
}
