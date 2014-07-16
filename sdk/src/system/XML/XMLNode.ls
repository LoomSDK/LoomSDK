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

    /**
     *  Represents Error codes used by the XML API.
     *
     *  @see XMLDocument.parse
     */
    enum XMLError {
    	XML_NO_ERROR = 0,
    	XML_SUCCESS = 0,
    
    	XML_NO_ATTRIBUTE,
    	XML_WRONG_ATTRIBUTE_TYPE,
    
    	XML_ERROR_FILE_NOT_FOUND,
    	XML_ERROR_FILE_COULD_NOT_BE_OPENED,
    	XML_ERROR_ELEMENT_MISMATCH,
    	XML_ERROR_PARSING_ELEMENT,
    	XML_ERROR_PARSING_ATTRIBUTE,
    	XML_ERROR_IDENTIFYING_TAG,
    	XML_ERROR_PARSING_TEXT,
    	XML_ERROR_PARSING_CDATA,
    	XML_ERROR_PARSING_COMMENT,
    	XML_ERROR_PARSING_DECLARATION,
    	XML_ERROR_PARSING_UNKNOWN,
    	XML_ERROR_EMPTY_DOCUMENT,
    	XML_ERROR_MISMATCHED_ELEMENT,
    	XML_ERROR_PARSING
    };

    /**
     * Helper class for working with XML error messages.
     */
    class XMLErrorMessages
    {
        /**
         * Convert an XMLError to an English string.
         *
         * @see buildErrorMessage for more complete functionality.
         */
        public static function lookup(error:XMLError):String
        {
            return messages[error];
        }

        /**
         * Return a nice error message given an error code and the document that
         * just generated it.
         */
        public static function buildErrorMessage(error:XMLError, document:XMLDocument):String
        {
            var message = lookup(error);

            var val1 = document.getErrorStr1();
            var val2 = document.getErrorStr2();

            if(val1 && val2)
                message += " (" + val1 + ", " + val2 + ")"; 
            else if(val1)
                message += " (" + val1 + ")";


            return message;
        }

        private static var messages:Dictionary.<XMLError, String> = { 
            XMLError.XML_NO_ERROR: "",
            XMLError.XML_SUCCESS: "",
            XMLError.XML_NO_ATTRIBUTE: "No attribute found",
            XMLError.XML_WRONG_ATTRIBUTE_TYPE: "Wrong attribute type",
            XMLError.XML_ERROR_FILE_NOT_FOUND: "File not found",
            XMLError.XML_ERROR_FILE_COULD_NOT_BE_OPENED: "File could not be opened",
            XMLError.XML_ERROR_ELEMENT_MISMATCH: "Element mismatch",
            XMLError.XML_ERROR_PARSING_ELEMENT: "Error parsing element",
            XMLError.XML_ERROR_PARSING_ATTRIBUTE: "Error parsing attribute",
            XMLError.XML_ERROR_IDENTIFYING_TAG: "Error identifying tag",
            XMLError.XML_ERROR_PARSING_TEXT: "Error parrsing text",
            XMLError.XML_ERROR_PARSING_CDATA: "Error parsing CData",
            XMLError.XML_ERROR_PARSING_COMMENT: "Error parsing comment",
            XMLError.XML_ERROR_PARSING_DECLARATION: "Error parsing xml declaration",
            XMLError.XML_ERROR_PARSING_UNKNOWN: "Error parsing unknown",
            XMLError.XML_ERROR_EMPTY_DOCUMENT: "Empty xml document",
            XMLError.XML_ERROR_MISMATCHED_ELEMENT: "Error mismatched element",
            XMLError.XML_ERROR_PARSING: "Error parsing xml"
        };
    }

    /**
     *  XMLNode is a base class for every object that is in the XML Document Object Model (DOM), except XMLAttributes. 
     *  Nodes have siblings, a parent, and children which can be navigated. A node is always in a XMLDocument. 
     *  The type of a XMLNode can be queried, and it can be cast to its more defined type.
     *
     *  @attention Looms XML Library is based on TinyXML 2. If you see something in TinyXML 2 that you do not see in this API, please contact The Engine Co.
     */
    native public class XMLNode {
        
        /**
         *  Gets the value of the XMLNode.
         *  The meaning of 'value' changes for the specific type.
         *  
         *  ~~~text
         *  Document:   empty
         *  Element:    name of the element
         *  Comment:    the comment text
         *  Unknown:    the tag contents
         *  Text:       the text string
         *  ~~~
         *
         *  @return Te value of the XMLNode.
         */
        public native function getValue():String;

        /**
         *  Set the Value of the XMLNode.
         *  
         *  @param v The value to set.
         *
         *  @see getValue
         */
        public native function setValue(v:String, staticMem:Boolean = false);
        
        /**
         *  Gets the XMLDocument that owns the XMLNode.
         *
         *  @return The owning XMLDocument.
         */
    	public native function getDocument():XMLDocument;
    
        /**
         *  Safely cast to an XMLElement.
         *
         *  @return The casted XMLElement, Null if cast was unsuccessful.
         */
    	public native function toElement():XMLElement;

        /**
         *  Safely cast to an XMLText.
         *
         *  @return The casted XMLText, Null if cast was unsuccessful.
         */
    	public native function toText():XMLText;

        /**
         *  Safely cast to an XMLComment.
         *
         *  @return The casted XMLComment, Null if cast was unsuccessful.
         */
    	public native function toComment():XMLComment;

        /**
         *  Safely cast to an XMLDocument.
         *
         *  @return The casted XMLDocument, Null if cast was unsuccessful.
         */
    	public native function toDocument():XMLDocument;

        /**
         *  Safely cast to an XMLDeclaration.
         *
         *  @return The casted XMLDeclaration, Null if cast was unsuccessful.
         */
    	public native function toDeclaration():XMLDeclaration;
    	//public native function ToUnknown():XMLUnknown;
    	
        /**
         *  Gets the parent of this node on the DOM. 
         *  
         *  @return The parent of this XMLNode, Null if the XMLNode has no parent.
         */
    	public native function getParent():XMLNode;

        /**
         *  Returns true if this node has no children. 
         */
    	public native function noChildren():Boolean;
    	
        /**
         *  Gets the first child XMLNode.
         *
         *  @return The first child XMLNode, Null if none exist.  
         */
        public native function firstChild():XMLNode;

        /**
         *  Get the first child XMLElement, or optionally the first child element with the specified name.
         *
         *  @param name Optional name for finding first child element by name.
         *  @return First child XMLElement, Null if none exist or if name does not match any child XMLElements.
         */
        public native function firstChildElement(name:String = null):XMLElement;
        
        /**
         *  Gets the lasr child XMLNode.
         *
         *  @return The last child XMLNode, Null if none exist.  
         */
        public native function lastChild():XMLNode;

        /**
         *  Get the last child XMLElement, or optionally the last child element with the specified name.
         *
         *  @param name Optional name for finding last child element by name.
         *  @return First child XMLElement, Null if none exist or if name does not match any child XMLElements.
         */
        public native function lastChildElement(name:String = null):XMLElement;
        
        /**
         *  Gets the previous (left) sibling XMLNode of this node.
         *
         *  @return previous sibling XMLNode, Null if none exist.
         */
        public native function previousSibling():XMLNode;

        /**
         *  Get the previous (left) sibling XMLElement of this node.
         *
         *  @param name Optional name for finding previous sibling element by name.
         *  @return previous sibling XMLNode, Null if none exist.
         */
        public native function previousSiblingElement(name:String = null):XMLElement;

        /**
         *  Gets the next (right) sibling XMLNode of this node.
         *
         *  @return next sibling XMLNode, Null if none exist.
         */
        public native function nextSibling():XMLNode;

        /**
         *  Get the next (right) sibling XMLElement of this node.
         *
         *  @param name Optional name for finding next sibling element by name.
         *  @return next sibling XMLNode, Null if none exist.
         */
        public native function nextSiblingElement(name:String = null):XMLElement;
        
        /**
         *  Add a child XMLNode as the last (right) child.
         *
         *  @param addThis The XMLNode to add.
         *  @return The added XMLNode.
         */
        public native function insertEndChild( addThis:XMLNode ):XMLNode;
    	
        /// @cond IGNORED
        // What does this do?
        public native function linkEndChild( addThis:XMLNode ):XMLNode;
	    /// @endcond

        /**
         *  Add a child node as the first (left) child.
         *
         *  @param addThis The XMLNode to add.
         *  @return The added XMLNode.
         */
        public native function insertFirstChild( addThis:XMLNode ):XMLNode;
    	
        /**
         *  Add an XMLNode after the specified child node.
         *
         *  @param afterThis The relative XMLNode.
         *  @param addThis The XMLNode to add.
         *  @return The added XMLNode.
         */
        public native function insertAfterChild( afterThis:XMLNode, addThis:XMLNode ):XMLNode;
    	
        /**
         *  Delete all the children of the XMLNode.
         */
        public native function deleteChildren();
    	
        /**
         *  Delete a child belonging to the XMLNode.
         *
         *  @param node The XMLNode to delete.
         */
        public native function deleteChild(node:XMLNode);
    	
        /**
         *  Make a copy of this XMLNode, but not its children. You may pass in a Document pointer that will be the owner of the new Node. 
         *  If the 'document' is null, then the node returned will be allocated from the current Document. (this.getDocument())
         *
         *  @note If called on a XMLDocument, this will return Null.
         *  @param doc The owner of the new XMLNode.
         *  @return shallow copy of the XMLNode, Null if called on a XMLDocument.
         */
    	public native function shallowClone(doc:XMLDocument):XMLNode;
    	
        /**
         *  Test if 2 XMLNode%s are the same, but don't test children. The 2 nodes do not need to be in the same XMLDocument.
         *  
         *  @note If called on a XMLDocument, this will return false.
         *  @param compare The XMLNode to compare to.
         *  @return Whether or not the XMLNode%s are shallow equals.
         */
        public native function shallowEqual(compare:XMLNode):Boolean;
    	
    	
    }
    
    /**
     *  The element is a container class. It has a value, the element name, and can contain other elements, text, comments, and unknowns. 
     *  Elements also contain an arbitrary number of attributes.
     */
    native public class XMLElement extends XMLNode {

        public native function value():String;
    
        /**
         *  Convenience function for easy access to the text inside an element. Although easy and concise, getText() is limited compared to getting the XMLText child and accessing it directly.
         *  
         * @return String if first child is XMLText, Null otherwise. 
         */
        public native function getText():String;
        
        /**
         *  Looks up a String attribute matched by name and (optional) value.
         *
         *  @param name The name of the attribute to look up.
         *  @param value Optional value to match the name against.
         *  @return The String value of the attribute.
         */
        public native function getAttribute( name:String, value:String = null ):String;        
        
        /**
         *  Looks up a Number attribute matched by name.
         *
         *  @param name The name of the attribute to look up.
         *  @return The Number value of the attribute.
         */
        public native function getNumberAttribute( name:String ):Number;        
        
        /**
         *  Looks up a Boolean attribute matched by name.
         *
         *  @param name The name of the attribute to look up.
         *  @return The Boolean value of the attribute.
         */
        public native function getBoolAttribute( name:String ):Boolean;        
        
        /**
         *  Sets a String Attribute onthe XMLElement.
         *  
         *  @param name The name of the attribute to be set.
         *  @patam value The value to set for the attribute.
         */
        public native function setAttribute( name:String, value:String); 

        /**
         *  Sets a Number Attribute onthe XMLElement.
         *  
         *  @param name The name of the attribute to be set.
         *  @patam value The value to set for the attribute.
         */       
        public native function setNumberAttribute( name:String, value:Number);  

        /**
         *  Sets a Boolean Attribute onthe XMLElement.
         *  
         *  @param name The name of the attribute to be set.
         *  @patam value The value to set for the attribute.
         */      
        public native function setBoolAttribute( name:String, value:Boolean);   
        
        /**
         *  Removes an attribute from the XMLElement%s list of attributes.
         */
        public native function deleteAttribute( name:String);
        
        /**
         *  Gets the first attribute in the list of attibutes.
         *
         *  @return First XMLAttribute, Null of none exist.
         */
        public native function firstAttribute( ):XMLAttribute;        
        
        /**
         *  Looks up an XMLAttribute by name.
         *
         *  @return Matched XMlAttribute, Null if none exist.
         */
        public native function findAttribute(name:String ):XMLAttribute;        
        
        
    }
    
    /**
     *  XML text.
     *  Note that a text node can have child element nodes, for example:
     *
     *  ~~~xml
     *  <root>This is <b>bold</b></root>
     *  ~~~
     *  
     * A text node can have 2 ways to output the next. "normal" output and CDATA. It will default to the mode it was parsed from the XML file and you generally want to leave it alone, but you can change the output mode with SetCDATA() and query it with CDATA().
     */
    native public class XMLText extends XMLNode {
    
        /**
         *  Declare whether this should be CDATA or standard text. 
         */
        public native function set cdata(value:Boolean);

        /**
         *  True if this is a CDATA text element. 
         */
        public native function get cdata():Boolean;
        
    }
    
    /**
     *  An XML Comment.
     */
    native public class XMLComment extends XMLNode {
        
    }
    
    /**
     *  An XML Declaration.
     */
    native public class XMLDeclaration extends XMLNode {
        
    }
    
    /**
     *  A Document binds together all the functionality. It can be saved, loaded, and printed to the screen. All Nodes are connected and allocated to a Document. 
     *  If the Document is deleted, all its Nodes are also deleted.
     */
    native public class XMLDocument extends XMLNode {
        
        /**
         *  Load an XML file from disk.
         *
         *  @param filename The file to load.
         *  @return XMLError.XML_NO_ERROR (0) on success, or an XMLError.
         */
        public native function loadFile(filename:String):Number;

        /**
         *  Save an XML file to disk.
         *
         *  @param filename The file to save.
         *  @return XMLError.XML_NO_ERROR (0) on success, or an XMLError.
         */
        public native function saveFile(filename:String):Number;

        /**
         *  Parse an XML file from a character string.
         *
         *  @param xml The xml to parse.
         *  @return XMLError.XML_NO_ERROR (0) on success, or an XMLError.
         */
        public native function parse(xml:String):Number;

        /**
         *  Returns the root XMLElement of the DOM. Equivalent to firstChildElement(). To get the first node, use firstChild().
         *
         *  @return The root XMLElement of the DOM.
         */
        public native function rootElement():XMLElement;

        /**
         *  Print the Document. If the XMLPrinter is not provided, it will print to stdout. If you provide XMLPrinter, this can print to a file:
         *
         *  @param printer XMLPrinter to print to a file.
         */
        public native function print(printer:XMLPrinter = null);
        
        /**
         *  Create a new XMLElement associated with this XMLDocument. The memory for the XMLElement is managed by the XMLDocument.
         *
         *  @param name The name of the new XMLElement.
         *  @return The new XMLElement.
         */
        public native function newElement(name:String):XMLElement;

        /**
         *  Create a new XMLComment associated with this XMLDocument. The memory for the XMLComment is managed by the XMLDocument.
         *
         *  @param comment The text of the comment.
         *  @return The new XMLComment.
         */
        public native function newComment(comment:String):XMLComment;

        /**
         *  Create a new XMLText associated with this XMLDocument. The memory for the XMLText is managed by the XMLDocument.
         *
         *  @param text The new xml text.
         *  @return The new XMLText.
         */
        public native function newText(text:String):XMLText;

        /**
         *  Create a new XMLDeclaration associated with this XMLDocument. The memory for the XMLDeclaration is managed by the XMLDocument.
         *
         *  @param decl Text of the new declaration.
         *  @return The new XMLDeclaration.
         */
        public native function newDeclaration(decl:String):XMLDeclaration;
        
        /**
         *  Delete a node associated with this document. It will be unlinked from the DOM.
         *
         *  @param node XMLNode to unlink from the DOM. 
         */
        public native function deleteNode(node:XMLNode);

        public native function getErrorStr1():String;
        public native function getErrorStr2():String;
        
    }    
    
    /**
     *  An XMLAttribute is a name-value pair. Elements have an arbitrary number of attributes, each with a unique name.
     *  
     *  @note The attributes are not XMLNodes. You may only query the next() attribute in a list.
     */
    native public class XMLAttribute  {
    
        /**
         *  The name of the XMLAttribute. 
         */
        public native function get name():String;

        /**
         *  The String value of the XMLAttribute.
         */
        public native function get value():String;

        /**
         *  Gets the Next XMLAttribute in the list.
         */
        public native function get next():XMLAttribute;
        
        /**
         *  The Number value of the XMLAttribute.
         */
        public native function get numberValue():Number;

        /**
         *  The Boolean value of the XMLAttribute.
         */
        public native function get boolValue():Boolean;
        
        /**
         *  Sets the String value of the XMLAttribute.
         */
        public native function set stringValue(value:String);

        /**
         *  Sets the Number value of the XMLAttribute.
         */
        public native function set numberValue(value:Number);

        /**
         *  Sets the Boolean value of the XMLAttribute.
         */
        public native function set boolValue(value:Boolean);        
        
    }
    
    /**
     * Provides extra methods for printing XML other than stdout.
     */
    native public class XMLPrinter  {
    
        /**
         *  Gets the String value of the printed XMLDocument.
         *
         *  @see XMLDocument.print 
         */
        public native function getString():String;
    
    }
    
    
}