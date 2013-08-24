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

class TestPublicProtectedPrivate extends Test
{
    function test()
    {

        var i = 0;

        // static fields

        ///////////////////////////////
        // COMPILER ERRORS
        //-----------------------------
        /*
        i = TestEnforceA.sprivateA;
        i = TestEnforceA.sprotectedA;
        i = TestEnforceB.sprivateA;
        i = TestEnforceB.sprotectedA;
        i = TestEnforceB.sprivateB;
        i = TestEnforceB.sprotectedB;
        i = TestEnforceC.sprivateA;
        i = TestEnforceC.sprotectedA;
        i = TestEnforceC.sprivateB;
        i = TestEnforceC.sprotectedB;
        i = TestEnforceC.sprivateC;
        i = TestEnforceC.sprotectedC;
        */        
        ///////////////////////////////
        
        i = TestEnforceA.spublicA;
        i = TestEnforceB.spublicA;
        i = TestEnforceB.spublicB;
        i = TestEnforceC.spublicA;
        i = TestEnforceC.spublicB;
        i = TestEnforceC.spublicC;

        // static property getters

        ///////////////////////////////
        // COMPILER ERRORS
        //-----------------------------
        /*
        i = TestEnforceA.spprivateA;
        i = TestEnforceA.spprotectedA;
        i = TestEnforceB.spprivateA;
        i = TestEnforceB.spprotectedA;
        i = TestEnforceB.spprivateB;
        i = TestEnforceB.spprotectedB;
        i = TestEnforceC.spprivateA;
        i = TestEnforceC.spprotectedA;
        i = TestEnforceC.spprivateB;
        i = TestEnforceC.spprotectedB;
        i = TestEnforceC.spprivateC;
        i = TestEnforceC.spprotectedC;
        */        
        ///////////////////////////////
        
        i = TestEnforceA.sppublicA;        
        i = TestEnforceB.sppublicA;
        i = TestEnforceB.sppublicB;
        i = TestEnforceC.sppublicA;
        i = TestEnforceC.sppublicB;
        i = TestEnforceC.sppublicC;

        TestEnforceA.sppublicA = i;        
        TestEnforceB.sppublicA = i;
        TestEnforceB.sppublicB = i;
        TestEnforceC.sppublicA = i;
        TestEnforceC.sppublicB = i;
        TestEnforceC.sppublicC = i;

        /*
        // Errors
        TestEnforceA.spprivateA = i;
        TestEnforceA.spprotectedA = i;
        TestEnforceB.spprivateA = i;
        TestEnforceB.spprotectedA = i;
        TestEnforceB.spprivateB = i;
        TestEnforceB.spprotectedB = i;
        TestEnforceC.spprivateA = i;
        TestEnforceC.spprotectedA = i;
        TestEnforceC.spprivateB = i;
        TestEnforceC.spprotectedB = i;
        TestEnforceC.spprivateC = i;
        TestEnforceC.spprotectedC = i;
        */


        var ta = new TestEnforceA;
        var tb = new TestEnforceB;
        var tc = new TestEnforceC;

        ///////////////////////////////
        // COMPILER ERRORS
        //-----------------------------
        /*
        ta.fprotectedA();
        ta.fprivateA();
        tb.fprotectedA();
        tb.fprivateA();
        tb.fprotectedB();
        tb.fprivateB();
        tc.fprotectedA();
        tc.fprivateA();
        tc.fprotectedB();
        tc.fprivateB();
        tc.fprotectedC();
        tc.fprivateC();
        */

        ta.fpublicA();
        tb.fpublicA();
        tb.fpublicB();
        tc.fpublicA();
        tc.fpublicB();
        tc.fpublicC();        

        ta.fdpublicA = 1;
        tb.fdpublicA = 1;
        tb.fdpublicB = 1;
        tc.fdpublicA = 1;
        tc.fdpublicB = 1;
        tc.fdpublicC = 1;        

        // Errors
        /*
        ta.fdprotectedA = 1;
        tb.fdprotectedA = 1;
        tb.fdprotectedB = 1;
        tc.fdprotectedA = 1;
        tc.fdprotectedB = 1;
        tc.fdprotectedC = 1;        

        ta.fdprivateA = 1;
        tb.fdprivateA = 1;
        tb.fdprivateB = 1;
        tc.fdprivateA = 1;
        tc.fdprivateB = 1;
        tc.fdprivateC = 1;
        */  

        TestEnforceA.sfpublicA();
        TestEnforceB.sfpublicA();
        TestEnforceB.sfpublicB();
        TestEnforceC.sfpublicA();
        TestEnforceC.sfpublicB();
        TestEnforceC.sfpublicC();

        // Errors
        /*
        TestEnforceA.sfprotectedA();
        TestEnforceB.sfprotectedA();
        TestEnforceB.sfprotectedB();
        TestEnforceC.sfprotectedA();
        TestEnforceC.sfprotectedB();
        TestEnforceC.sfprotectedC();
        
        TestEnforceA.sfprivateA();
        TestEnforceB.sfprivateA();
        TestEnforceB.sfprivateB();
        TestEnforceC.sfprivateA();
        TestEnforceC.sfprivateB();
        TestEnforceC.sfprivateC();

        */
                
    }
    
    function TestPublicProtectedPrivate()
    {
        name = "TestPublicProtectedPrivate";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = ""; 
    
}

class TestEnforceA
{
    private var privateA = 1;    
    protected var protectedA = 1;    
    public var publicA = 1;    

    static private var sprivateA = 1;    
    static protected var sprotectedA = 1;    
    static public var spublicA = 1;

    public function testAccessA() 
    {

        var i = 0;

        // static fields

        ///////////////////////////////
        // COMPILER ERRORS
        //-----------------------------
        /*
        i = TestEnforceB.sprivateB;        
        i = TestEnforceC.sprivateB;        
        i = TestEnforceC.sprivateC;
        i = TestEnforceC.sprotectedC;
        i = sprotectedC;
        */        
        ///////////////////////////////


        i = TestEnforceA.sprotectedA;
        i = TestEnforceB.sprotectedA;
        i = TestEnforceC.sprotectedA;

        i = sprotectedA;

        i = TestEnforceB.sprivateA;
        i = sprivateA;        

        // static properties
        ///////////////////////////////
        // COMPILER ERRORS
        //-----------------------------
        /*
        i = TestEnforceA.spprivateA;
        i = TestEnforceB.spprivateA;
        i = TestEnforceB.spprivateB;
        i = TestEnforceC.spprivateA;
        i = TestEnforceC.spprivateB;               

        i = TestEnforceC.spprotectedC;
        i = TestEnforceC.spprivateC;

        i = spprivateC;
        */

        i = TestEnforceA.spprotectedA;
        i = TestEnforceB.spprotectedA;
        i = TestEnforceC.spprotectedA;
                

        // publics
        i = TestEnforceA.spublicA;
        i = TestEnforceB.spublicA;
        i = TestEnforceB.spublicB;
        i = TestEnforceC.spublicA;
        i = TestEnforceC.spublicB;
        i = TestEnforceC.spublicC;

        i = spublicA;

        i = TestEnforceA.sppublicA;
        i = TestEnforceB.sppublicA;
        i = TestEnforceB.sppublicB;
        i = TestEnforceC.sppublicA;
        i = TestEnforceC.sppublicB;

        i = sppublicA;

        fpublicA();
        fprotectedA();
        fprivateA();

        sfpublicA();
        sfprotectedA();

        TestEnforceC.sppublicC = 1;
        

    }

    private function get pprivateA ():Number
    {
        return 1;
    }    

    private function set pprivateA (value:Number)
    {
    }    

    protected function get pprotectedA ():Number
    {
        return 1;
    }    

    protected function set pprotectedA (value:Number)
    {

    }    

    public function get ppublicA ():Number
    {
        return 1;
    }    

    public function set pppublicA (value:Number)
    {
    }    

/////

    private static function get spprivateA ():Number
    {
        return 1;
    }    

    private static function set spprivateA (value:Number)
    {
    }    

    protected static function get spprotectedA ():Number
    {
        return 1;
    }    

    protected static function set spprotectedA (value:Number)
    {

    }    

    public static function get sppublicA ():Number
    {
        return 1;
    }    

    public static function set sppublicA (value:Number)
    {
    }    

    public function fpublicA()
    {

    }

    protected function fprotectedA()
    {
        
    }

    private function fprivateA()
    {
        
    }

    public var fdpublicA = 1;
    protected var fdprotectedA = 1;
    private var fdprivateA = 1;

    public static function sfpublicA()
    {

    }

    protected static function sfprotectedA()
    {

    }

    private static function sfprivateA()
    {

    }
    
}

class TestEnforceB extends TestEnforceA
{

    private var privateB = 1;    
    protected var protectedB = 1;    
    public var publicB = 1;    

    static private var sprivateB = 1;    
    static protected var sprotectedB = 1;    
    static public var spublicB = 1;    

    public function testAccessB() 
    {

        var i = 0;

        // static fields

        ///////////////////////////////
        // COMPILER ERRORS
        //-----------------------------
        /*
        i = TestEnforceA.sprivateA;        
        i = TestEnforceB.sprivateA;        
        i = TestEnforceC.sprivateA;        
        i = TestEnforceC.sprivateB;        
        i = TestEnforceC.sprivateC;

        i = TestEnforceC.sprotectedC;
        i = sprotectedC;
        */        
        ///////////////////////////////

        

        i = TestEnforceA.sprotectedA;
        i = TestEnforceB.sprotectedA;
        i = TestEnforceB.sprotectedB;
        i = TestEnforceC.sprotectedB;
        i = TestEnforceC.sprotectedA;

        i = sprotectedA;
        i = sprotectedB;

        i = TestEnforceB.sprivateB;
        i = sprivateB;        

        // static properties
        ///////////////////////////////
        // COMPILER ERRORS
        //-----------------------------
        /*
        i = TestEnforceA.spprivateA;
        i = TestEnforceB.spprivateA;
        i = TestEnforceB.spprivateB;
        i = TestEnforceC.spprivateA;
        i = TestEnforceC.spprivateB;               

        i = TestEnforceC.spprotectedC;
        i = TestEnforceC.spprivateC;

        i = spprivateC;
        */

        i = TestEnforceA.spprotectedA;
        i = TestEnforceB.spprotectedA;
        i = TestEnforceC.spprotectedA;
        i = TestEnforceB.spprotectedB;
        i = TestEnforceC.spprotectedB;
                
        i = TestEnforceB.spprivateB;
        i = spprivateB;

        // publics
        i = TestEnforceA.spublicA;
        i = TestEnforceB.spublicA;
        i = TestEnforceB.spublicB;
        i = TestEnforceC.spublicA;
        i = TestEnforceC.spublicB;
        i = TestEnforceC.spublicC;

        i = spublicA;
        i = spublicB;        

        i = TestEnforceA.sppublicA;
        i = TestEnforceB.sppublicA;
        i = TestEnforceB.sppublicB;
        i = TestEnforceC.sppublicA;
        i = TestEnforceC.sppublicB;

        i = sppublicA;
        i = sppublicB;


        fpublicA();
        fpublicB();
        fprotectedA();
        fprotectedB();
        //fprivateA();
        fprivateB();

        sfpublicA();
        sfpublicB();

        sfprotectedA();
        sfprotectedB();
        
        //sfprivateA();
        sfprivateB();

        TestEnforceC.sppublicC = 1;

 
    }

    private function get pprivateB ():Number
    {
        return 1;
    }    

    private function set pprivateB (value:Number)
    {
    }    

    protected function get pprotectedB ():Number
    {
        return 1;
    }    

    protected function set pprotectedB (value:Number)
    {

    }    

    public function get ppublicB ():Number
    {
        return 1;
    }    

    public function set pppublicB (value:Number)
    {
    }    
/////

    private static function get spprivateB ():Number
    {
        return 1;
    }    

    private static function set spprivateB (value:Number)
    {
    }    

    protected static function get spprotectedB ():Number
    {
        return 1;
    }    

    protected static function set spprotectedB (value:Number)
    {

    }    

    public static function get sppublicB ():Number
    {
        return 1;
    }    

    public static function set sppublicB (value:Number)
    {
    }

    public function fpublicB()
    {

    }

    protected function fprotectedB()
    {
        
    }

    private function fprivateB()
    {
        
    }

    public var fdpublicB = 1;
    protected var fdprotectedB = 1;
    private var fdprivateB = 1;

    public static function sfpublicB()
    {

    }

    protected static function sfprotectedB()
    {

    }

    private static function sfprivateB()
    {

    }


    
}

class TestEnforceC extends TestEnforceB
{

    private var privateC = 1;    
    protected var protectedC = 1;    
    public var publicC = 1;   

    static private var sprivateC = 1;    
    static protected var sprotectedC = 1;    
    static public var spublicC = 1;   

    public function testAccessC() 
    {
        var i = 0;

        // static fields

        ///////////////////////////////
        // COMPILER ERRORS
        //-----------------------------
        /*
        i = TestEnforceA.sprivateA;        
        i = TestEnforceB.sprivateA;
        i = TestEnforceB.sprivateB;        
        i = TestEnforceC.sprivateA;        
        i = TestEnforceC.sprivateB;        
        
        */        
        ///////////////////////////////        

        i = TestEnforceA.sprotectedA;
        i = TestEnforceB.sprotectedA;
        i = TestEnforceB.sprotectedB;
        i = TestEnforceC.sprotectedB;
        i = TestEnforceC.sprotectedA;
        i = TestEnforceC.sprotectedC;

        i = sprotectedA;
        i = sprotectedB;
        i = sprotectedC;

        i = TestEnforceC.sprivateC;
        i = sprivateC;

        // static properties
        ///////////////////////////////
        // COMPILER ERRORS
        //-----------------------------
        /*
        i = TestEnforceA.spprivateA;
        i = TestEnforceB.spprivateA;
        i = TestEnforceB.spprivateB;
        i = TestEnforceC.spprivateA;
        i = TestEnforceC.spprivateB;       

        i = spprivateB;        
        */

        i = TestEnforceA.spprotectedA;
        i = TestEnforceB.spprotectedA;
        i = TestEnforceC.spprotectedA;
        i = TestEnforceB.spprotectedB;
        i = TestEnforceC.spprotectedB;
        i = TestEnforceC.spprotectedC;

        i = TestEnforceC.spprivateC;        
        i = spprivateC;

        // publics
        i = TestEnforceA.spublicA;
        i = TestEnforceB.spublicA;
        i = TestEnforceB.spublicB;
        i = TestEnforceC.spublicA;
        i = TestEnforceC.spublicB;
        i = TestEnforceC.spublicC;

        i = spublicA;
        i = spublicB;
        i = spublicC;

        i = TestEnforceA.sppublicA;
        i = TestEnforceB.sppublicA;
        i = TestEnforceB.sppublicB;
        i = TestEnforceC.sppublicA;
        i = TestEnforceC.sppublicB;
        i = TestEnforceC.sppublicC;

        i = sppublicA;
        i = sppublicB;
        i = sppublicC;

        fpublicA();
        fpublicB();
        fpublicC();        
        fprotectedA();
        fprotectedB();
        fprotectedC();
        //fprivateA();
        //fprivateB();
        fprivateC();

        sfpublicA();
        sfpublicB();
        sfpublicC();

        sfprotectedA();
        sfprotectedB();
        sfprotectedC();
        
        //sfprivateA();
        //sfprivateB();
        sfprivateC();

        sppublicC = 1;
        TestEnforceC.sppublicC = 1;

    }


    private function get pprivateC ():Number
    {
        return 1;
    }    

    private function set pprivateC (value:Number)
    {
    }    

    protected function get pprotectedC ():Number
    {
        return 1;
    }    

    protected function set pprotectedC (value:Number)
    {

    }    

    public function get ppublicC ():Number
    {
        return 1;
    }    

    public function set pppublicC (value:Number)
    {
    }    

/////

    private static function get spprivateC ():Number
    {
        return 1;
    }    

    private static function set spprivateC (value:Number)
    {
    }    

    protected static function get spprotectedC ():Number
    {
        return 1;
    }    

    protected static function set spprotectedC (value:Number)
    {

    }    

    public static function get sppublicC ():Number
    {
        return 1;
    }    

    public static function set sppublicC (value:Number)
    {
        
    } 
 
    public function fpublicC()
    {

    }

    protected function fprotectedC()
    {
        
    }

    private function fprivateC()
    {
        
    }

    public var fdpublicC = 1;
    protected var fdprotectedC = 1;
    private var fdprivateC = 1;

    public static function sfpublicC()
    {

    }

    protected static function sfprotectedC()
    {

    }

    private static function sfprivateC()
    {

    }



}

}



