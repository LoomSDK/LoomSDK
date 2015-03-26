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

    public class JSONTest {
        
        private var objString:String = '{ "JSON_INTEGER" : 1, "JSON_REAL" : 0.2, "JSON_ARRAY" : [], "JSON_OBJECT" : {}, "JSON_FALSE" : false, "JSON_TRUE" : true, "JSON_STRING" : "string", "JSON_NULL" : null }';
        private var arrString:String = '[ 1, 0.2, [], {}, false, true, "string", null ]';
        
        private var jsonObj:JSON = new JSON();
        private var jsonArr:JSON = new JSON();
        
        public function JSONTest() {
            
            jsonObj.loadString(objString);
            jsonArr.loadString(arrString); 
        }
        
        [Test]
        function getInteger() {
            
            Assert.equal(jsonObj.getInteger("JSON_INTEGER"), 1, "Object Test");
            Assert.equal(jsonArr.getArrayInteger(0), 1, "Array Test");
        }
        
        [Test]
        function getReal() {
            
            Assert.equal(jsonObj.getNumber("JSON_REAL"), 0.2, "Object Test");
            Assert.equal(jsonArr.getArrayNumber(1), 0.2, "Aray Test");
        }
        
        [Test]
        function getArray() {
            
            Assert.isNotNull(jsonObj.getArray("JSON_ARRAY"), "Object Test");
            Assert.isNotNull(jsonArr.getArrayArray(2), "Array Test");
        }
        
        [Test]
        function getObject() {
            
            Assert.isNotNull(jsonObj.getObject("JSON_OBJECT"), "Object Test");
            Assert.isNotNull(jsonArr.getArrayObject(3), "Array Test");
        }
        
        [Test]
        function getBoolean() {
            
            Assert.equal(jsonObj.getBoolean("JSON_FALSE"), false, "Object Test");
            Assert.equal(jsonObj.getBoolean("JSON_TRUE"), true, "Object Test");
            
            Assert.equal(jsonArr.getArrayBoolean(4), false, "Array Test");
            Assert.equal(jsonArr.getArrayBoolean(5), true, "Array Test");
        }
        
        [Test]
        function getString() {
            
            Assert.equal(jsonObj.getString("JSON_STRING"), "string", "Object Test");
            Assert.equal(jsonArr.getArrayString(6), "string", "Array Test");
        }
        
        [Test]
        function nonSequentialArrayIndexes() {
            
            var testJson = new JSON();
            testJson.loadString("[]");
            testJson.setArrayString( 0, "First!" );
            testJson.setArrayString( 4, "The 5th Element" );

            Assert.equal(testJson.serialize(), "[\"First!\", null, null, null, \"The 5th Element\"]");
        }
        
        [Test]
        function setArray() {
            
            var testJson = new JSON();
            testJson.loadString("[ 1, 2, 3 ]");

            var jsonArrayTestObject = new JSON();
            jsonArrayTestObject.loadString("{}");
            jsonArrayTestObject.setArray("arrayValue", testJson);
            Assert.equal(jsonArrayTestObject.serialize(), "{\"arrayValue\": [1, 2, 3]}");
        }
        
        [Test]
        function getJSONType() {

            Assert.equal( jsonObj.getObjectJSONType("JSON_INTEGER"), JSONType.JSON_INTEGER, "Object: JSON_INTEGER test");
            Assert.equal( jsonObj.getObjectJSONType("JSON_REAL"), JSONType.JSON_REAL, "Object: JSON_REAL test");
            Assert.equal( jsonObj.getObjectJSONType("JSON_ARRAY"), JSONType.JSON_ARRAY, "Object: JSON_ARRAY test");
            Assert.equal( jsonObj.getObjectJSONType("JSON_OBJECT"), JSONType.JSON_OBJECT, "Object: JSON_OBJECT test");
            Assert.equal( jsonObj.getObjectJSONType("JSON_FALSE"), JSONType.JSON_FALSE, "Object: JSON_FALSE test");
            Assert.equal( jsonObj.getObjectJSONType("JSON_TRUE"), JSONType.JSON_TRUE, "Object: JSON_TRUE test");
            Assert.equal( jsonObj.getObjectJSONType("JSON_STRING"), JSONType.JSON_STRING, "Object:: JSON_STRING test");
            Assert.equal( jsonObj.getObjectJSONType("JSON_NULL"), JSONType.JSON_NULL, "Object: JSON_NULL test");

            Assert.equal( jsonObj.getObjectJSONType("InvalidKey"), JSONType.JSON_NULL, "Object: Invalid key test");
            Assert.equal( jsonObj.getArrayJSONType(0), JSONType.JSON_NULL, "Object: Treat as array test");

            Assert.equal( jsonArr.getArrayJSONType(0), JSONType.JSON_INTEGER, "Array: JSON_INTEGER test");
            Assert.equal( jsonArr.getArrayJSONType(1), JSONType.JSON_REAL, "Array: JSON_REAL test");
            Assert.equal( jsonArr.getArrayJSONType(2), JSONType.JSON_ARRAY, "Array: JSON_ARRAY test");
            Assert.equal( jsonArr.getArrayJSONType(3), JSONType.JSON_OBJECT, "Array: JSON_OBJECT test");
            Assert.equal( jsonArr.getArrayJSONType(4), JSONType.JSON_FALSE, "Array: JSON_FALSE test");
            Assert.equal( jsonArr.getArrayJSONType(5), JSONType.JSON_TRUE, "Array: JSON_TRUE test");
            Assert.equal( jsonArr.getArrayJSONType(6), JSONType.JSON_STRING, "Array: JSON_STRING test");
            Assert.equal( jsonArr.getArrayJSONType(7), JSONType.JSON_NULL, "Array: JSON_NULL test");
        }
        
        [Test]
        function getDictionary() {
            
            var jsonDictionary:Dictionary = jsonObj.getDictionary();
        
            Assert.equal(jsonObj.getVector(), null);
            
            Assert.equal(jsonDictionary["JSON_INTEGER"].getType().getFullName(), "system.Number");
            Assert.equal(jsonDictionary["JSON_INTEGER"], 1);
            Assert.equal(jsonDictionary["JSON_INTEGER"].getType().getFullName(), "system.Number");
            Assert.equal(jsonDictionary["JSON_REAL"], 0.2);
            Assert.equal(jsonDictionary["JSON_ARRAY"].getType().getFullName(), "system.JSON");
            Assert.equal(jsonDictionary["JSON_OBJECT"].getType().getFullName(), "system.JSON");
            Assert.equal(jsonDictionary["JSON_FALSE"].getType().getFullName(), "system.Boolean");
            Assert.equal(jsonDictionary["JSON_FALSE"], false);
            Assert.equal(jsonDictionary["JSON_TRUE"].getType().getFullName(), "system.Boolean");
            Assert.equal(jsonDictionary["JSON_TRUE"], true);
            Assert.equal(jsonDictionary["JSON_STRING"].getType().getFullName(), "system.String");
            Assert.equal(jsonDictionary["JSON_STRING"], "string");
            Assert.equal(jsonDictionary["JSON_NULL"], null);
        }
        
        [Test]
        function getVector() {
            
            var jsonVector:Vector = jsonArr.getVector();
        
            Assert.equal(jsonArr.getDictionary(), null);
            
            Assert.equal(jsonVector[0].getType().getFullName(), "system.Number");
            Assert.equal(jsonVector[0], 1);
            Assert.equal(jsonVector[1].getType().getFullName(), "system.Number");
            Assert.equal(jsonVector[1], 0.2);
            Assert.equal(jsonVector[2].getType().getFullName(), "system.JSON");
            Assert.equal(jsonVector[3].getType().getFullName(), "system.JSON");
            Assert.equal(jsonVector[4].getType().getFullName(), "system.Boolean");
            Assert.equal(jsonVector[4], false);
            Assert.equal(jsonVector[5].getType().getFullName(), "system.Boolean");
            Assert.equal(jsonVector[5], true);
            Assert.equal(jsonVector[6].getType().getFullName(), "system.String");
            Assert.equal(jsonVector[6], "string");
            Assert.equal(jsonVector[7], null);
        }
    }
}
