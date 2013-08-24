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

    
interface IAwesome 
{
    function foo():Number;
}

class XFoo {}

class XBar extends XFoo implements IAwesome
{
    public function foo():Number
    {
        return 42;
    }
}

class XX1 {}
class XX2 extends XX1 {}
class XX3 extends XX2 {}

class TestCoercion extends Test
{

    function test()
    {
        
        // create some fruit
        var apple:Apple = new Apple();
        var fuji:Fuji = new Fuji();
        var orange:Orange = new Orange();
        
        assert(fuji is Apple);
        assert(fuji is Fuji);

        assert(fuji instanceof Fuji);
        assert (fuji as Apple instanceof Fuji);
        
        // this is now caught by compiler as invalid
        // log(fuji as Orange);

        assert(Apple(apple) && Apple(fuji));

        // true
        assert((fuji as Fruit) != null);

        assert(Apple(fuji));

        assert(!(Apple(orange) && Apple(fuji)));

        assert(!Apple(orange));

        assert(Orange(orange));

        assert(!Orange(fuji));   

        var fapple:Apple = Apple(fuji);

        assert(Fuji(fapple).getAFujiSeed() == "Got a fuji seed");
        
        assert (orange is Fruit);
        assert ((orange instanceof Fruit));
        
        // this is now caught by compiler as invalid
        // log (orange as Apple);
        
        assert (orange as Orange is Fruit);
        assert (orange as Orange instanceof Orange);

        var a:XFoo = new XBar();
        var b:XBar = new XBar();
        var c:XFoo = new XFoo();
        
        assert(a is IAwesome);
        assert((a as IAwesome).foo() == 42);
        assert(b.foo() == 42);

        assert(!(c is IAwesome));
        assert(c as IAwesome == null);

        var d:XX3 = new XX3();
        var e:XX1 = d;
        var f:XX1 = new XX1();

        assert(e as XX1);
        assert(e as XX2);
        assert(e as XX3);

        assert(e is XX1);
        assert(e is XX2);
        assert(e is XX3); 

        assert(e instanceof XX1 == true);
        assert(e instanceof XX2 == true);
        assert(e instanceof XX3 == true);

        assert(f as XX1);
        assert(f as XX2 == null);
        assert(f as XX3 == null);

        assert(f is XX1 == true);
        assert(f is XX2 == false);
        assert(f is XX3 == false); 

        assert(f instanceof XX1 == true);
        assert(f instanceof XX2 == false);
        assert(f instanceof XX3 == false);

        // Examples of exact type match.
        assert(e.getType() == XX3);
        assert(f.getType() == XX1);

    }
    
    function TestCoercion()
    {
        name = "TestCoercion";   
        expected = EXPECTED_TEST_RESULT;
    }    
    
    var EXPECTED_TEST_RESULT:String = "";
}

}



