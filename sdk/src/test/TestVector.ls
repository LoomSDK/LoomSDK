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

import system.Vector;

class TestVector extends Test
{
    function makeAVectorForMePlease():Vector.<String> {
        return new Vector.<String> ["josh", "was", "here"];
    }
    
    public var aMemberVector:Vector.<String> = ["This", "is", "vector"];
    public var aMemberArray:Array = ["This", "is", "vector"];
    public var aMemberVectorArray:Vector.<Array> = [["hi"], ["there", "buddy"]];
    public var aNotherTest:Vector.<String> = new <String>["one", "2", "thr333"];

    public var aWhiteSpaceTest:Vector.<Object>=null;

    static function staticSortMethod(x:Number, y:Number):Number {
    
        if (x < y)  return -1;
        
        if (x > y)  return 1;
        
        return 0;
    }
    
    function instanceSortMethod(x:Number, y:Number):Number {
    
        if (x < y)  return -1;
        
        if (x > y)  return 1;
        
        return 0;
    }

    function test()
    {
        
        log(aMemberVector[0]);
        log(aMemberVector[1]);
        log(aMemberVector[2]);
    
        var v:Vector.<Number> = new Vector.<Number>();
        
        v.push(100, 101, 102);
        
        for (var i:Number = 0; i < v.length; i++)
            log(v[i]);
        
        log(v.length);
        
        var apples:Vector.<Apple> = new Vector.<Apple>();

        apples.push(new Apple());
        
        apples[0].eat("Yum!");
        
        var vv:Vector.<String> = new Vector.<String> ["one", "two", "three", "four"];
        
        var x:int;
        var s:String;
        for (x = 0; x < vv.length; x++)
            log(vv[x]);
            
        var av:Vector.<String> = ["apple", "orange", null, "cherry", "kiwi"];
        
        for (x = 0; x < av.length; x++)
            log(av[x]);
            
        for each (s in av) {
            log(s);
        }
        
        for (var n:Number in av) {
            log(n);
        }
        
        var thankyou:Vector.<String> = makeAVectorForMePlease();
        
        for each (s in thankyou) {
            log(s);
        }

        var o:Object;

        var newVector:Vector = av.concat(thankyou, 1, 2, 3, vv, "yes!");
                
        for each (o in newVector) {
            log(o);
        }
        
        var spliced:Vector.<Object> = av.splice(1, 3, "Hey!", "You!");
                
                        
        for each (o in spliced) {
            log(o);
        }
        
        for each (s in av) {
            log(s);
        }
        
        av = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        
        spliced = av.splice(-3, 2);
    
        // 8, 9    
        for each (o in spliced) {
            log(o);
        }

        // 1, 2, 3, 4, 5, 6, 7, 10
        for each (var xx:String in av) {
            log(xx);
        }
        
        av = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        
        spliced = av.splice(0, -1);
        
        // 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
        for each (o in spliced) {
            log(o);
        }

        // empty
        for each (o in av) {
            log(o);
        }
        
        av = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        
        spliced = av.splice(0, -1, "this", "is", "a", "test");
        
        // 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
        for each (var yy in spliced) {
            log(yy);
        }

        // this is a test
        for each (o in av) {
            log(o);
        }
        
        av = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        
        var sliced:Vector.<int> = av.slice(3, 6);
        
        for each (x in sliced) {
            log(x);
        }

        for each (o in av) {
            log(o);
        }
        
        av = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        
        sliced = av.slice(-2, -1);
        
        for each (x in sliced) {
            log(x);
        }        
        
        // test continue
        
        for each (s in thankyou) {
        
            if (s == "was")
                continue;
        
            log(s);
        }        
        
        for(x in thankyou) {
        
            if (x == 2)
                continue;
        
            log(x);
        }        
        
        assert(av.indexOf(3) == 2, "Vector.indexOf test 1 failure");
        assert(av.indexOf(3, 2) == 2, "Vector.indexOf test 2 failure");
        assert(av.indexOf(3, 3) == -1, "Vector.indexOf test 3 failure");
        assert(apples.indexOf(apples[0]) == 0, "Vector.indexOf test 4 failure");
        assert(apples.indexOf(null) == -1, "Vector.indexOf test 5 failure");
        
        var nv:Vector.<Number> = [34000, 77800, 12300, 11000, 21600, 33120, 18190, 43090];

        // test default splice args
        var vsplice:Vector.<Number> = nv.slice();

        assert(vsplice.length == nv.length);

        for (x in vsplice)
        {
            assert(nv[x] == vsplice[x]);
        }
        
        nv.sort(Vector.NUMERIC);

        assert(nv[0] == 11000);
        assert(nv[1] == 12300);
        assert(nv[2] == 18190);
        assert(nv[3] == 21600);
        assert(nv[4] == 33120);
        assert(nv[5] == 34000);
        assert(nv[6] == 43090);
        assert(nv[7] == 77800);
        
        nv.sort(Vector.NUMERIC | Vector.DESCENDING);
        
        assert(nv[7] == 11000);
        assert(nv[6] == 12300);
        assert(nv[5] == 18190);
        assert(nv[4] == 21600);
        assert(nv[3] == 33120);
        assert(nv[2] == 34000);
        assert(nv[1] == 43090);
        assert(nv[0] == 77800);
        
        nv = [10, 100, 99, -99, -100, 20, 1];
        nv.sort();
        
        assert(nv[0] == 1);
        assert(nv[1] == 10);
        assert(nv[2] == 20);
        assert(nv[3] == 99);
        assert(nv[4] == -99);
        assert(nv[5] == 100);
        assert(nv[6] == -100);
        
        av = ["apple", "orange", null, "Cherry", "kiwi"];
        
        av.sort();
        
        assert(av[0] == null);
        assert(av[1] == "Cherry");
        assert(av[2] == "apple");
        assert(av[3] == "kiwi");
        assert(av[4] == "orange");
        
        av.sort(Vector.CASEINSENSITIVE | Vector.DESCENDING);
        
        assert(av[4] == null);
        assert(av[3] == "apple");
        assert(av[2] == "Cherry");
        assert(av[1] == "kiwi");
        assert(av[0] == "orange");
        
        av = ["apple", "orange", null, "Cherry", "kiwi"];
        
        var iv:Vector.<Number> = av.sort(Vector.RETURNINDEXEDARRAY) as Vector;
        
        // check that original is unmodified
        assert(av[2] == null);
        assert(av[0] == "apple");
        assert(av[3] == "Cherry");
        assert(av[4] == "kiwi");
        assert(av[1] == "orange");

        assert(iv[0] == 2);
        assert(iv[1] == 3);
        assert(iv[2] == 0);
        assert(iv[3] == 4);
        assert(iv[4] == 1);
        
		
        av = ["apple", "orange", null, "Cherry", "apple"];
        
        // Returns 0 when unique sort fails
        assert(av.sort(Vector.UNIQUESORT) as Number == 0);
        
        // ensure that unique sort where not unique leaves vector unmodified
        assert(av[0] == "apple");
        assert(av[1] == "orange");
        assert(av[2] == null);
        assert(av[3] == "Cherry");
        assert(av[4] == "apple");
		
		
		av = ["apple", "orange", null, "Cherry", "kiwi"];
        
		// Returns the original Vector
		var rav = av.sort(Vector.UNIQUESORT);
        assert(av == rav);
        
        // ensure elements are sorted
        assert(av[0] == null);
        assert(av[1] == "Cherry");
        assert(av[2] == "apple");
        assert(av[3] == "kiwi");
        assert(av[4] == "orange");
        
		
        var functions:Vector.<Function> = [staticSortMethod, instanceSortMethod, function (x:Number, y:Number):Number { if (x < y)  return -1; if (x > y)  return 1; return 0;}];
        
        for each (var f:Function in functions) {
        
            nv = [10, 100, 99, -99, -100, 20, 1];
            nv.sort(f);
            assert(nv[0] == -100);
            assert(nv[1] == -99);
            assert(nv[2] == 1);
            assert(nv[3] == 10);
            assert(nv[4] == 20);
            assert(nv[5] == 99);        
            assert(nv[6] == 100);        
        }
        
        av = ["apple", "orange", null, "Cherry", "apple"];
        assert(av.join() == "apple,orange,null,Cherry,apple");
        
        var rv:Vector.<Object> = [1, "hello", av, true, null];
        assert(rv.join(";") == "1;hello;apple,orange,null,Cherry,apple;true;null");
        
        var spliceTest:Vector.<Number> = [1, 2, 3, 4];

        // splice once
        var spliceResult:Vector.<Number> = spliceTest.splice(0,1);
        
        assert(spliceTest.length == 3);
        assert(spliceTest[0] == 2 && spliceTest[1] == 3 && spliceTest[2] == 4);
        assert(spliceResult.length == 1);
        assert(spliceResult[0] == 1);

        // splice twice
        spliceResult = spliceTest.splice(0,1);
        
        assert(spliceTest.length == 2);
        assert(spliceTest[0] == 3 && spliceTest[1] == 4);
        assert(spliceResult.length == 1);
        assert(spliceResult[0] == 2);
        
        // splice thrice
        spliceResult = spliceTest.splice(0,1);
        
        
        assert(spliceTest.length == 1);
        assert(spliceTest[0] == 4);
        assert(spliceResult.length == 1);
        assert(spliceResult[0] == 3);

        // splice thrice
        
        spliceResult = spliceTest.splice(0,1);
        assert(spliceTest.length == 0);
        assert(spliceResult.length == 1);
        assert(spliceResult[0] == 4);
        
        // test specifying size at construction time
        var myVector = new Vector.<String>(100);
        myVector[50] = "Hey There!";
        var counter = 0;
        for (var idx in myVector) {
            if (idx == 50)
                assert (myVector[idx] == "Hey There!");
            else
                assert (myVector[idx] == null);
            counter++;
        }
        
        assert(counter == 100);
        
        assert(myVector.lastIndexOf("Hey There!") == 50);
        assert(myVector.lastIndexOf("Hey There!!") == -1);
        
        var everytest = [1, 2, 3, 4, 5];
        
        assert(everytest.every(function (item:Number, index:Number, v:Vector):Boolean { return item <= 5;}));
        assert(everytest.every(function (item:Number, index:Number, v:Vector):Boolean { return item > 5;}) == false);
        
        var filtertest = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        
        testInstanceMemberOnFilter = 1000;
        var filterResult:Vector.<Number> = filtertest.filter(filterTest, this);

        assert(filterResult.length == 5);
        assert(filterResult[0] == 1);
        assert(filterResult[1] == 2);
        assert(filterResult[2] == 3);
        assert(filterResult[3] == 4);
        assert(filterResult[4] == 5);
        
        var foreachtest = [1, 2, 3, 4, 5];
        
        var forEachResult = 0;
        foreachtest.forEach(function (item:Number, index:Number, v:Vector) { forEachResult += item; });
        
        assert(forEachResult == 15);
        
        var maptest = [1, 2, 3, 4, 5];
        var mapResult:Vector.<Number> = maptest.map(function (item:Number, index:Number, v:Vector):Number { return item + 1; });
        
        assert(mapResult.length == 5);
        assert(mapResult[0] == 2);
        assert(mapResult[1] == 3);
        assert(mapResult[2] == 4);
        assert(mapResult[3] == 5);
        assert(mapResult[4] == 6);
        
        var testreverse = [1, 2, 3, 4, 5];
        testreverse.reverse();
                
        assert(testreverse[0] == 5);
        assert(testreverse[1] == 4);
        assert(testreverse[2] == 3);
        assert(testreverse[3] == 2);
        assert(testreverse[4] == 1);
        
        testreverse = [1, 2, 3, 4];
        testreverse.reverse();

        assert(testreverse[0] == 4);
        assert(testreverse[1] == 3);
        assert(testreverse[2] == 2);
        assert(testreverse[3] == 1);

        testreverse = [1];
        testreverse.reverse();
        assert(testreverse[0] == 1);

        testreverse = [];
        testreverse.reverse();
        assert(testreverse.length == 0);

        var testunshift = [4, 5];
        assert(testunshift.unshift(1, 2, 3) == 5);
        assert(testunshift[0] == 1);
        assert(testunshift[1] == 2);
        assert(testunshift[2] == 3);
        assert(testunshift[3] == 4);
        assert(testunshift[4] == 5);
        
        assert(testunshift.toString() == "1,2,3,4,5");
        
        var ovector = new Vector(10);
        ovector[5] = 1000;
        assert(ovector.length == 10);
        
        var rangetest = [1, 2, 3, 4, 5];
        
        // will raise Vector indexed with negative number (write)
        //rangetest[-1] = 1;
        
        // will raise Vector index out of bounds (write)
        //rangetest[5] = 1;
        
        // will raise Vector indexed with negative number (read)
        // var oops = rangetest[-1];
        
        // will raise Vector index out of bounds (read)
        //var oops2 = rangetest[5];
        
        // will raise Vector indexed with non-number
        // rangetest["x"] = 1;
        
        // raises a compiler error, indexing with non-number
        // var oops3 = rangetest["x"];
        
        rangetest.clear();
        
        assert(rangetest.length == 0);        

        var setlength = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        assert(setlength.length == 10);
        setlength.length = 5;
        assert(setlength.length == 5);
        

        // Test nested vector type parse.
        var foo = new Vector.<Vector.<Vector.<Vector.<Object>>>>();
        foo.push(new Vector.<Vector.<Vector.<Object>>>());
        foo[0].push(new Vector.<Vector.<Object>>());
        foo[0][0].push(new Vector.<Object>());
        foo[0][0][0].push(new Object());

        var vpop = new Vector.<int>;
        
        vpop.pushSingle(1);

        var vp:int  = vpop.pop();

        assert(vp == 1 && vpop.length == 0);

        var foos = new Vector.<Vector.< String> >();
        foos.pushSingle(new Vector.<String>);
        foos[0].pushSingle("Hello");

        var vs:String = foos[0].pop();

        assert(vs == "Hello" && foos[0].length == 0);

        memberPop.pushSingle(new Vector.<String>);
        memberPop[0].pushSingle("Hello");

        vs = memberPop[0].pop();

        assert(vs == "Hello" && memberPop[0].length == 0);

        // Test that our Array worked properly.
        assert(aMemberArray.getTypeName() == "Vector");
        assert(aMemberArray[0] == "This");
        assert(aMemberArray[1] == "is");
        assert(aMemberArray[2] == "vector");
        assert(aMemberArray.length == 3);

        // And test that our Vector.<Array> worked properly.
        assert(aMemberVectorArray[0][0] == "hi");
        assert(aMemberVectorArray[1][0] == "there");
        assert(aMemberVectorArray[1][1] == "buddy");

        var dim = "100%";
        var numeric = dim.slice(0, dim.length);
        assert(("numeric " + numeric + "X") == "numeric 100%X");     

        // these generate indexing errors
        var vassign = new Vector.<int>;   
        //vassign[-1] = 100;
        //vp = vassign[100];

        //vassign[1000] = 1;



    }
    
    var memberPop:Vector.<Vector.< String> > = new Vector.<Vector.< String> >;

    var testInstanceMemberOnFilter = 100;

    function filterTest(item:Number, index:Number, v:Vector):Boolean 
    {
        // make sure we have the right instance
        assert(testInstanceMemberOnFilter == 1000);
    
        return item <= 5;
        
    }
    
    function TestVector()
    {
        name = "TestVector";   
        expected = EXPECTED_TEST_RESULT;

    }    
    
    var EXPECTED_TEST_RESULT:String = "
This
is
vector
100
101
102
3
Yum!
one
two
three
four
apple
orange
null
cherry
kiwi
apple
orange
null
cherry
kiwi
0
1
2
3
4
josh
was
here
apple
orange
null
cherry
kiwi
josh
was
here
1
2
3
one
two
three
four
yes!
orange
null
cherry
apple
Hey!
You!
kiwi
8
9
1
2
3
4
5
6
7
10
1
2
3
4
5
6
7
8
9
10
1
2
3
4
5
6
7
8
9
10
this
is
a
test
4
5
6
1
2
3
4
5
6
7
8
9
10
9
josh
here
0
1
";    
}

}



