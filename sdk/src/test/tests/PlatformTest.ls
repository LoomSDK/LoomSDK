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
    
    import system.platform.Platform;
    
    public class PlatformTest {
        
        // This is the epoch at the time this test was created. The epoch gathered should always be greater than this!
        private const EPOCH_COMPARE:Number = 1442250586;
        
        // The amount of time we will sleep to test
        private const SLEEP_TIME:Number = 1000;
        
        // The bounds of the sleep time test
        private const SLEEP_TIME_BOUNDS:Number = SLEEP_TIME / 10;
        
        [Test]
        function getEpoch() {
            
            var epoch:Number = Platform.getEpochTime();
            Assert.greater(epoch, EPOCH_COMPARE, "Epoch time lower than expected! Expected greater than: " + EPOCH_COMPARE + " Actual: " + epoch);
        }
        
        [Test]
        function testSleep() {
            
            // Get the epoch time, pause, and compare the epoch to ensure the pause is good
            var startEpoch:Number = Platform.getEpochTime();
            
            Platform.sleep(SLEEP_TIME);
            
            
            var endEpoch:Number = Platform.getEpochTime();
            Assert.compareNumber(startEpoch + SLEEP_TIME, endEpoch, "Sleep time not within expected bounds. Expected: " + (startEpoch + SLEEP_TIME) + " Actual: " + endEpoch, SLEEP_TIME_BOUNDS);
        }
    }
}