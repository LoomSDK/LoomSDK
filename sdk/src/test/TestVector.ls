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

        assertEqual(av.indexOf(3), 2, "Vector.indexOf test 1 failure");
        assertEqual(av.indexOf(3, 2), 2, "Vector.indexOf test 2 failure");
        assertEqual(av.indexOf(3, 3), -1, "Vector.indexOf test 3 failure");
        assertEqual(apples.indexOf(apples[0]), 0, "Vector.indexOf test 4 failure");
        assertEqual(apples.indexOf(null), -1, "Vector.indexOf test 5 failure");

        var nv:Vector.<Number> = [34000, 77800, 12300, 11000, 21600, 33120, 18190, 43090];

        // test default slice args
        var nvslice:Vector.<Number> = nv.slice();
        testVectorEqual(nvslice, nv, "slice should match original");

        nv.sort(Vector.NUMERIC);

        testVectorEqual(nv, [11000, 12300, 18190, 21600, 33120, 34000, 43090, 77800], "numeric flag should order numbers numerically");

        nv.sort(Vector.NUMERIC | Vector.DESCENDING);

        testVectorEqual(nv, [77800, 43090, 34000, 33120, 21600, 18190, 12300, 11000], "numeric and descending flags should work correctly");

        nv = [10, 100, 99, -99, -100, 20, 1];
        nv.sort();

        testVectorEqual(nv, [-100, -99, 1, 10, 100, 20, 99], "default sort should order numbers alphabetically");

        av = ["apple", "orange", null, "Cherry", "kiwi"];
        av.sort();

        testVectorEqual(av, [null, "Cherry", "apple", "kiwi", "orange"], "default sort should work correctly with null and mixed case");

        av.sort(Vector.CASEINSENSITIVE | Vector.DESCENDING);

        testVectorEqual(av, ["orange", "kiwi", "Cherry", "apple", null], "case-insensitive and descending flags should work correctly");

        av = ["apple", "orange", null, "Cherry", "kiwi"];

        var iv:Vector.<Number> = av.sort(Vector.RETURNINDEXEDARRAY) as Vector;

        // check that original is unmodified
        testVectorEqual(av, ["apple", "orange", null, "Cherry", "kiwi"], "index sort should not modify the vector");
        testVectorEqual(iv, [2, 3, 0, 4, 1], "index sort should return a new array of indices in sort order");

        av = ["apple", "orange", null, "Cherry", "apple"];

        // Returns 0 when unique sort fails, and leaves vector unmodified
        assertEqual(av.sort(Vector.UNIQUESORT) as Number, 0, "unique sort should return 0 when items are not unique");
        testVectorEqual(av, ["apple", "orange", null, "Cherry", "apple"], "unique sort should not modify the vector when items are not unique");

        av = ["apple", "orange", null, "Cherry", "kiwi"];

        // Returns the original Vector when unique, and sorts it
        var vr:Object = av.sort(Vector.UNIQUESORT);
        assertEqual(av, vr, "unique sort should return the original vector when items are unique");
        testVectorEqual(av, [null, "Cherry", "apple", "kiwi", "orange"], "unique sort should sort the vector in place when items are unique");

        // ensure consistency with as3 sorting behavior

        /// alpha vs numeric
        var msg = "plain sort should order elements alphabetically";
        av = ["22", "111", "3"];
        var av2:Vector.<String> = ["111", "22", "3"];
        av.sort();
        testVectorEqual(av, av2, msg);

        msg = "numeric sort should order elements numerically";
        av = ["111", "22", "3"];
        av2 = ["3", "22", "111"];
        av.sort(Vector.NUMERIC);
        testVectorEqual(av, av2, msg);

        /// allowing dupes
        msg = "case-insensitive sort should allow dupes in Vector.<String>";
        av = ["a", "a", "a"];
        var avslice:Vector.<String> = av.slice();
        vr = av.sort(Vector.CASEINSENSITIVE);
        testVectorEqual(vr, avslice, msg);

        msg = "case-insensitive sort should allow dupes in Vector.<Number>";
        nv = [1, 1, 1];
        nvslice = nv.slice();
        vr = nv.sort(Vector.CASEINSENSITIVE);
        testVectorEqual(vr, nvslice, msg);

        msg = "descending sort should allow dupes in Vector.<String>";
        av = ["b", "b", "b"];
        avslice = av.slice();
        vr = av.sort(Vector.DESCENDING);
        testVectorEqual(vr, avslice, msg);

        msg = "descending sort should allow dupes in Vector.<Number>";
        nv = [1, 1, 1];
        nvslice = nv.slice();
        vr = nv.sort(Vector.DESCENDING);
        testVectorEqual(vr, nvslice, msg);

        msg = "indexed array sort should allow dupes in Vector.<String>";
        av = ["c", "c", "c"];
        nvslice = [0, 1, 2];
        vr = av.sort(Vector.RETURNINDEXEDARRAY);
        assertEqual(([]).getFullTypeName(), vr.getFullTypeName(), msg);

        msg = "indexed array sort should allow dupes in Vector.<Number>";
        nv = [1, 1, 1];
        nvslice = [0, 1, 2];
        vr = nv.sort(Vector.RETURNINDEXEDARRAY);
        assertEqual(([]).getFullTypeName(), vr.getFullTypeName(), msg);

        msg = "numeric sort should allow dupes in Vector.<String>";
        av = ["d", "d", "d"];
        avslice = av.slice();
        vr = av.sort(Vector.NUMERIC);
        testVectorEqual(vr, avslice, msg);

        msg = "numeric sort should allow dupes in Vector.<Number>";
        nv = [1, 1, 1];
        nvslice = nv.slice();
        vr = nv.sort(Vector.NUMERIC);
        testVectorEqual(vr, nvslice, msg);

        var functions:Vector.<Function> = [staticSortMethod, instanceSortMethod, function (x:Number, y:Number):Number { if (x < y)  return -1; if (x > y)  return 1; return 0;}];

        for each (var f:Function in functions) {
            nv = [10, 100, 99, -99, -100, 20, 1];
            nv.sort(f);
            testVectorEqual(nv, [-100, -99, 1, 10, 20, 99, 100], "custom sort should work with static, instance, and closure methods");
        }

        av = ["apple", "orange", null, "Cherry", "apple"];
        assertEqual(av.join(), "apple,orange,null,Cherry,apple", "default join should comma-separate");

        var rv:Vector.<Object> = [1, "hello", av, true, null];
        assertEqual(rv.join(";"), "1;hello;apple,orange,null,Cherry,apple;true;null", "join should use given separator and handle nested joins");

        var spliceTest:Vector.<Number> = [1, 2, 3, 4];

        // splice once
        var spliceResult:Vector.<Number> = spliceTest.splice(0,1);

        testVectorEqual(spliceTest, [2, 3, 4], "splice(0, 1) should remove one element at position zero");
        testVectorEqual(spliceResult, [1], "splice should return removed elements in new array");

        // splice twice
        spliceResult = spliceTest.splice(0,1);

        testVectorEqual(spliceTest, [3, 4], "splice(0, 1) should remove one element at position zero");
        testVectorEqual(spliceResult, [2], "splice should return removed elements in new array");

        // splice thrice
        spliceResult = spliceTest.splice(0,1);

        testVectorEqual(spliceTest, [4], "splice(0, 1) should remove one element at position zero");
        testVectorEqual(spliceResult, [3], "splice should return removed elements in new array");

        // splice frice
        spliceResult = spliceTest.splice(0,1);

        testVectorEqual(spliceTest, [], "splice(0, 1) should remove one element at position zero");
        testVectorEqual(spliceResult, [4], "splice should return removed elements in new array");

        // test specifying size at construction time
        var myVector = new Vector.<String>(100);
        myVector[50] = "Hey There!";
        var counter = 0;
        for (var idx in myVector) {
            if (idx == 50)
                assertEqual(myVector[idx], "Hey There!");
            else
                assertEqual(myVector[idx], null);
            counter++;
        }

        assertEqual(counter, 100, "for..in should visit every index in vector");

        assertEqual(myVector.lastIndexOf("Hey There!"), 50, "token element should be found");
        assertEqual(myVector.lastIndexOf("Hey There!!"), -1, "near match to token element should not be found");

        var everytest = [1, 2, 3, 4, 5];

        assertEqual(everytest.every(function (item:Number, index:Number, v:Vector):Boolean { return item <= 5;}), true, "every with truthy test should return true");
        assertEqual(everytest.every(function (item:Number, index:Number, v:Vector):Boolean { return item > 5;}), false, "every with falsey test should return false");

        var filtertest = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

        testInstanceMemberOnFilter = 1000;
        var filterResult:Vector.<Number> = filtertest.filter(filterTest, this);

        testVectorEqual(filterResult, [1, 2, 3, 4, 5], "filter should remove items that don't pass the filter callback");

        var foreachtest = [1, 2, 3, 4, 5];

        var forEachResult = 0;
        foreachtest.forEach(function (item:Number, index:Number, v:Vector) { forEachResult += item; });

        assertEqual(forEachResult, 15, "forEach should execute the callback for each item");

        var maptest = [1, 2, 3, 4, 5];
        var mapResult:Vector.<Number> = maptest.map(function (item:Number, index:Number, v:Vector):Number { return item + 1; });

        testVectorEqual(mapResult, [2, 3, 4, 5, 6], "map should generate a new vector containing the result of the callback for each item");
        testVectorEqual(maptest, [1, 2, 3, 4, 5], "map should leave the original vector unmodified");

        var testreverse = [1, 2, 3, 4, 5];
        testVectorEqual(testreverse.reverse(), [5, 4, 3, 2, 1], "reverse should invert order for odd number of elements");
        testVectorEqual(testreverse.reverse(), [1, 2, 3, 4, 5], "double reverse should equal original order for odd number of elements");

        testreverse = [1, 2, 3, 4];
        testVectorEqual(testreverse.reverse(), [4, 3, 2, 1], "reverse should invert order for even number of elements");
        testVectorEqual(testreverse.reverse(), [1, 2, 3, 4], "double reverse should equal original order for even number of elements");

        testreverse = [1];
        testreverse.reverse();
        assertEqual(testreverse[0], 1, "reversal of a single item should equal that item");

        testreverse = [];
        testreverse.reverse();
        assertEqual(testreverse.length, 0, "reversal of an empty vector should remain empty");

        var testunshift = [4, 5];
        assertEqual(testunshift.unshift(1, 2, 3), 5, "unshift should return the new length");
        testVectorEqual(testunshift, [1, 2, 3, 4, 5], "unshift should insert multiple items to front of vector");

        assertEqual(testunshift.toString(), "1,2,3,4,5");

        var ovector = new Vector(10);
        ovector[5] = 1000;
        assertEqual(ovector.length, 10);

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

        assertEqual(rangetest.length, 0, "clear should remove all elements");

        var setlength = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        assertEqual(setlength.length, 10);

        setlength.length = 5;

        assertEqual(setlength.length, 5, "setting length shorter should truncate vector");

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
        assertEqual(aMemberArray.getTypeName(), "Vector", "Array type should alias to Vector");
        testVectorEqual(aMemberArray, ["This", "is", "vector"], "Arrays should equate to Vectors");

        // And test that our Vector.<Array> worked properly.
        msg = "Arrays should be a valid Vector element type";
        assertEqual(aMemberVectorArray[0][0], "hi", msg);
        assertEqual(aMemberVectorArray[1][0], "there", msg);
        assertEqual(aMemberVectorArray[1][1], "buddy", msg);

        var dim = "100%";
        var numeric = dim.slice(0, dim.length);
        assertEqual(("numeric " + numeric + "X"), "numeric 100%X");

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

    function testVectorEqual(a:Object, b:Object, msg:String):void
    {
        var vectorType:String = ([]).getFullTypeName();
        var aType:String = a.getFullTypeName();
        var bType:String = b.getFullTypeName();

        assertEqual(aType, vectorType, (msg + "; object is not a vector"));
        assertEqual(bType, vectorType, (msg + "; object is not a vector"));

        if (aType == vectorType && bType == vectorType)
        {
            var va:Vector.<Object> = a as Vector.<Object>;
            var vb:Vector.<Object> = b as Vector.<Object>;

            assertEqual(va.length, vb.length, (msg + "; lengths do not match"));

            for (var i:Number in va)
                assertEqual(va[i], vb[i], (msg + "; mismatch at index " + i));
        }
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



