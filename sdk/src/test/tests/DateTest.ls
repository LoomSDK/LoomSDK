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
    
    public class DateTest {
        
        var date:Date = new Date(); // Create a new date for things to be tested against
        
        // This date is populated with an integer representing a specific Unix Epoch to test against. 
        // The physical location this test is being made in is unreliable, therefore only UTC time aspects are tested
        var knownDate:Date = new Date(1441857747);
        
        [Test]
        function dateBounds() {
            
            if (date.date < 1 || date.date > 31) {
                Assert.fail("Date out of bounds! Value: " + date.date);
            }
            
            if (date.dateUTC < 1 || date.date > 31) {
                Assert.fail("Date UTC out of bounds! Value: " + date.dateUTC);
            }
        }
        
        [Test]
        function dayBounds() {
            
            if (date.day < 0 || date.day > 6) {
                Assert.fail("Day out of bounds! Value: " + date.day);
            }
            
            if (date.dayUTC < 0 || date.dayUTC > 6) {
                Assert.fail("Day UTC out of bounds! Value: " + date.dayUTC);
            }
        }
        
        [Test]
        function yearBounds() {
            
            // The year CAN be verified, it should be greater than or equal to 2015 (the year this file was first made!)
            if (date.year < 2015) {
                Assert.fail("Year is too low! Expected greater than or equal to 2015. Value: " + date.year);
            }
        }
        
        [Test]
        function hoursBounds() {
            
            if (date.hours < 0 || date.hours > 23) {
                Assert.fail("Hours out of bounds! Value: " + date.hours);
            }
            
            if (date.hoursUTC < 0 || date.hoursUTC > 23) { 
                Assert.fail("Hours UTC out of bounds! Value: " + date.hoursUTC);
            }
        }
        
        [Test]
        function minutesBounds() {
            
            if (date.minutes < 0 || date.minutes > 59) {
                Assert.fail("Minutes out of bounds! Value: " + date.minutes);
            }
            
            if (date.minutesUTC < 0 || date.minutesUTC > 59) {
                Assert.fail("Minutes UTC out of bounds! Value: " + date.minutesUTC);
            }
        }
        
        [Test]
        function monthBounds() {
            
            if (date.month < 0 || date.month > 11) {
                Assert.fail("Month out of bounds! Value: " + date.month);
            }
            
            if (date.monthUTC < 0 || date.monthUTC > 11) {
                Assert.fail("Month UTC out of bounds! Value: " + date.monthUTC);
            }
        }
        
        [Test]
        function secondsBounds() {
            
            if (date.seconds < 0 || date.seconds > 59) {
                Assert.fail("Seconds out of bounds! Value: " + date.seconds);
            }
            
            if (date.secondsUTC < 0 || date.secondsUTC > 59) {
                Assert.fail("Seconds UTC out of bounds! Value: " + date.secondsUTC);
            }
        }
        
        [Test]
        function dateCheck() {
            
            Assert.equal(knownDate.dateUTC, 10, "Date of " + knownDate.dateUTC + " did not match expected date of 10");
        }
        
        [Test]
        function dayCheck() {
            
            Assert.equal(knownDate.dayUTC, 4, "Day of " + knownDate.dayUTC + " did not match expected day of 4");
        }
        
        [Test]
        function yearCheck() {
            
            Assert.equal(knownDate.yearUTC, 2015, "Year of " + knownDate.yearUTC + " did not match expected year of 2014");
        }
        
        [Test]
        function hoursCheck() {
            
            Assert.equal(knownDate.hoursUTC, 4, "Hour of " + knownDate.hoursUTC + " did not match expected hour of 4");
        }
        
        [Test]
        function minutesCheck() {
            
            Assert.equal(knownDate.minutesUTC, 2, "Minute of " + knownDate.minutesUTC + " did not match expected minute of 2");
        }
        
        [Test]
        function monthCheck() {
            
            Assert.equal(knownDate.monthUTC, 8, "Month of " + knownDate.monthUTC + " did not match expected month of 8");
        }
        
        [Test]
        function secondCheck() {
            
            Assert.equal(knownDate.secondsUTC, 27, "Second of " + knownDate.secondsUTC + " did not match expected second of 27");
        }
    }
}
