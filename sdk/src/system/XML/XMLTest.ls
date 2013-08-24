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

package system.xml {

/// @cond IGNORED    
    public class XMLTest {
    
        private static function testFive() {
        
            var xml1 =	"<xmlElement>
<![CDATA[
I am > the rules!
...since I make symbolic puns
]]>
</xmlElement>";

    		var xml2 =	"<xmlElement>
<![CDATA[
<b>I am > the rules!</b>
...since I make symbolic puns
]]>
</xmlElement>";

    		var doc = new XMLDocument;
    		doc.parse( xml1 );
    		doc.print();
    		doc.deleteNative();
    		
    		doc = new XMLDocument;
    		doc.parse( xml2 );
    		doc.print();
    		    		
    		doc.deleteNative();
            
        }
    
        private static function testFour() {
        
    		var xml = "<doc attr0='1' attr1='2.0' attr2='foo' />";
    
    		var doc = new XMLDocument;
    		doc.parse( xml );
    
    		var ele = doc.firstChildElement();
    
    		var value:Number;
    
    		value = ele.getNumberAttribute( "attr1");
    		Console.print(value);
    		
    		doc.deleteNative();
        
            
        }
    
    
        private static function testThree() {
        
            var xml = "<element>Text before.</element>";
            var doc = new XMLDocument();
            
            doc.parse(xml);
            var root = doc.firstChildElement();
            var newElement = doc.newElement("Subelement");
            root.insertEndChild(newElement);
            doc.print();
            Console.print("");
            doc.deleteNative();
        
            
        }
    
        private static function testTwo() {
        
    		var test:String  = "<!--hello world
line 2
line 3
line 4
line 5-->";

            var doc = new XMLDocument();
            doc.parse( test );
            doc.print();
            Console.print("");
            doc.deleteNative();
            
        }
    
        private static function testOne() {
        
                
            var testXML:Vector.<String> = new Vector.<String> [
                                        "<element />",
									    "<element></element>",
										"<element><subelement/></element>",
									    "<element><subelement></subelement></element>",
									    "<element><subelement><subsub/></subelement></element>",
									    "<!--comment beside elements--><element><subelement></subelement></element>",
									    "<!--comment beside elements, this time with spaces-->  \n <element>  <subelement> \n </subelement> </element>",
									    "<element attrib1='foo' attrib2=\"bar\" ></element>",
									    "<element attrib1='foo' attrib2=\"bar\" ><subelement attrib3='yeehaa' /></element>",
										"<element>Text inside element.</element>",
										"<element><b></b></element>",
										"<element>Text inside and <b>bolded</b> in the element.</element>",
										"<outer><element>Text inside and <b>bolded</b> in the element.</element></outer>",
										"<element>This &amp; That.</element>",
										"<element attrib='This&lt;That' />" ];
										
			
                for (var x:Number = 0; x < testXML.length; x++) {
                    var xml = testXML[x];
                    var doc = new XMLDocument();
                    var printer = new XMLPrinter();
                    doc.parse( xml );
                    doc.print(printer);
                    Console.print(printer.getString());
                    Console.print( "----------------------------------------------" );
                    printer.deleteNative();
                    doc.deleteNative();
    	        
	        }										
									
		}
        
        
        public static function runTest() {
            
            testOne();
            testTwo();
            testThree();
            testFour();
            testFive();
        }
        
    }
/// @endcond   
}