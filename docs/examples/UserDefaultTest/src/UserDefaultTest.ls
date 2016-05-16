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

package {

    import unittest.Assert;
    import loom.Application;
    import loom.platform.UserDefault;
    
    public class UserDefaultTest extends Application {
    
        function UserDefaultTest() {
            trace("\n    Please use 'loom test' to run this test!\n");
        }
        
        // /*
        [Test]
        function testBool() {
            var ud:UserDefault = UserDefault.sharedUserDefault();
            
            ud.purge();
            Assert.compare(true, ud.getBoolForKey("testBool", true));
            
            ud.purge();
            Assert.compare(false, ud.getBoolForKey("testBool", false));
            
            ud.setBoolForKey("testBool", true);
            Assert.compare(true, ud.getBoolForKey("testBool", false));
        }
        
        [Test]
        function testInteger() {
            var ud:UserDefault = UserDefault.sharedUserDefault();
            
            ud.purge();
            Assert.compare(123, ud.getIntegerForKey("testInteger", 123));
            
            ud.purge();
            Assert.compare(-456, ud.getIntegerForKey("testInteger", -456));
            
            ud.setIntegerForKey("testInteger", 789);
            Assert.compare(789, ud.getIntegerForKey("testInteger", 0));
            
            ud.setIntegerForKey("testInteger", -12345);
            Assert.compare(-12345, ud.getIntegerForKey("testInteger", 0));
        }
        
        [Test]
        function testFloat() {
            var ud:UserDefault = UserDefault.sharedUserDefault();
            
            ud.purge();
            Assert.compareNumber(123.456, ud.getFloatForKey("testFloat", 123.456));
            
            ud.purge();
            Assert.compareNumber(-987.654, ud.getFloatForKey("testFloat", -987.654));
            
            ud.setFloatForKey("testFloat", 321.123);
            Assert.compareNumber(321.123, ud.getFloatForKey("testFloat", 0));
            
            ud.setFloatForKey("testFloat", -123.321);
            Assert.compareNumber(-123.321, ud.getFloatForKey("testFloat", 0));
        }
        
        [Test]
        function testDouble() {
            var ud:UserDefault = UserDefault.sharedUserDefault();
            
            ud.purge();
            Assert.compareNumber(123.456789, ud.getDoubleForKey("testDouble", 123.456789));
            
            ud.purge();
            Assert.compareNumber(-987.654321, ud.getDoubleForKey("testDouble", -987.654321));
            
            ud.setDoubleForKey("testDouble", 654321.123);
            Assert.compareNumber(654321.123, ud.getDoubleForKey("testDouble", 0));
            
            ud.setDoubleForKey("testDouble", -123456.654);
            Assert.compareNumber(-123456.654, ud.getDoubleForKey("testDouble", 0));
        }
        
        [Test]
        function testString() {
            var ud:UserDefault = UserDefault.sharedUserDefault();
            
            ud.purge();
            Assert.compare("abc", ud.getStringForKey("testString", "abc"));
            
            ud.purge();
            Assert.compare("Hello World!", ud.getStringForKey("testString", "Hello World!"));
            
            ud.setStringForKey("testString", "Hi String!");
            Assert.compare("Hi String!", ud.getStringForKey("testString", ""));
            
            ud.setStringForKey("testString", "This is a different string!");
            Assert.compare("This is a different string!", ud.getStringForKey("testString", ""));
        }
        // */
        
    }
}
