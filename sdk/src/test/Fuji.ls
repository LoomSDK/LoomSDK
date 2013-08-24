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

import unittest.Test;

class Fuji extends Apple
{
    public var reallySpecific:String = "I'm a special kind of apple called a Fuji!";

    function Fuji() 
    {
        super();
        id = 103;
    }
    
    public function piddle(d:String)
    {
        Test.log("I am never called");
    }
    
    public function diddle(d:String)
    {
        super.piddle("diddle");
        Test.log(d);
    }
    
    public function eat(delicious:String)
    {
        super(delicious);
        super("munch");
        Test.log(delicious);
    }
    
    public function onAdd():Boolean
    {
        Test.log("In Fuji.onAdd");
    
        if(!super.onAdd())
            return false;
    
        return true;
    }    
    

    public function getAFujiSeed():String {
        return "Got a fuji seed";
    }
    
}


}




