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

import unittest.LegacyTest;

public class Apple extends Fruit
{
    public function Apple() 
    {
        id = 101;
        specific = "I'm an apple!";
    }
    
    public function piddle(p:String) 
    {
        LegacyTest.log(p);
    }
    
    public function eat(delicious:String)
    {
        LegacyTest.log(delicious);
    }
    
    public function onAdd():Boolean
    {
        LegacyTest.log("In Apple.onAdd");
        
        if(!super.onAdd())
            return false;
    
        return true;
    }    
}

}
