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

package loom.css 
{    
    public class DocumentBlock implements IParserNode
    {
        public var styles:Vector.<StyleBlock> = new Vector.<StyleBlock>();

        public function parse(p:CSSParser)
        {
            while(!p.end()) 
            {
                var style:StyleBlock = new StyleBlock();
                style.parse(p);

                styles.push(style);

                p.skipCommentsAndWS();
            }
        }
    }

    public class StyleBlock implements IParserNode 
    {
        public var name:String;
        public var properties:StylePropertyBlock;
        public var attributes:Vector.<String> = new Vector.<String>;

        public function parse(p:CSSParser)
        {
            p.skipCommentsAndWS();
            name = p.readUntil("[","\n","\t"," ","{");

            if(p.peek() == "[")
                parseStyleAttributes(p);

            p.skipCommentsAndWS();

            // skip the {
            p.next();

            // read the property block
            var props:StylePropertyBlock = new StylePropertyBlock();
            props.parse(p);
            properties = props;
        }

        public function parseStyleAttributes(p:CSSParser):void
        {
            // skip [
            p.next();

            while(p.peek() != "]")
            {
                var attr = p.readUntil(" ", ",","]");
                if(p.peek() == ",")
                    p.next();

                p.skipCommentsAndWS();

                attributes.push(attr);
            }

            // skip ]
            p.next();
        }
    }

    public class StylePropertyBlock implements IParserNode 
    {
        public var properties:Dictionary.<String,String> = new Dictionary.<String,String>();

        public function parse(p:CSSParser)
        {
            p.skipCommentsAndWS();

             // read the property block
            while(p.peek() != "}")
            {
                parseProperty(p);

                if(p.end()) return;

                p.skipCommentsAndWS();
            }

            // skip the }
            p.next();
        }

        public function parseProperty(p:CSSParser):void
        {
            var key = "";
            var value = "";

            //____________________________________________
            //  Reading the key
            //____________________________________________
            p.skipCommentsAndWS();

            // we need to read until some whitespace or
            // a colon
            key += p.readUntil(" ",":");
            p.skipCommentsAndWS();

            // if there is no colon here, throw an error
            if(p.peek() != ":") {
                p.error("Expected ':'");
                p.goToEnd();
                return;
            }
                

            // skip ':'
            p.next();

            //____________________________________________
            //  Reading the value
            //____________________________________________
            p.skipCommentsAndWS();

            if(p.peek() == "\"")
                value = parseStringValue(p, "\"");
            else if(p.peek() == "'")
                value = parseStringValue(p, "'");
            else
                value = parseValue(p);

            // skip ';'
            p.next();

            properties[key] = value;
        }

        public function parseStringValue(p:CSSParser,quote:String):String
        {
            // skip the first quote
            p.next();
            var result = p.readUntil(quote);

            // skip the second quote
            p.next();

            p.skipCommentsAndWS();

            if(p.peek() != ";")
                p.error("Expected ';'");

            return result;
        }

        public function parseValue(p:CSSParser):String
        {
            var result = p.readUntil(";");
            p.skipCommentsAndWS();

            if(p.peek() != ";")
                p.error("Expected ';'");

            return result;
        }
    }

    public interface IParserNode
    {
        function parse(p:CSSParser);
    }

    public class CSSParser 
    {
        //____________________________________________
        //  Public
        //____________________________________________
        public function parse(value:String):DocumentBlock
        {
            source = value;
            position = 0;

            var doc = new DocumentBlock();
            doc.parse(this);

            return doc;
        }

        public function peek(offset:Number=0):String
        {
            return source.charAt(position+offset);
        }

        public function next():void
        {
            // lookup line number
            if(peek() == "\n")
                line++;

            position++;
        }

        public function isWs():Boolean
        {
            var c = peek();
            return c==" " || c=="\n" || c=="\t" || c=="\r";
        }

        public function skipWS():void
        {
            while(isWs()) next();
        }

        public function skipCommentsAndWS()
        {
            skipWS();
            if(peek() == "/" && peek(1) == "*")
            {
                do {
                    readUntil("*");
                    next();
                } while(peek() != "/")
                next();
            }
            skipWS();
        }

        public function end():Boolean
        {
            return position >= source.length-1;
        }

        public function goToEnd()
        {
            position = source.length;
        }

        // does a peek and next
        public function readChar():String
        {
            var c = peek();
            next();
            return c;
        }

        // TODO, pass in a custom error message here if we reach an EOF
        public function readUntil(... args):String
        {
            var result = "";

            var matched = peekCmp(args);
            while(!matched)
            {
                result += readChar();
                matched = peekCmp(args);

                if(end()) {
                    error("EOF Reached, perhaps a string or brace is not closed?");
                    matched = true;
                }

            }

            return result;
        }

        public function get lineNumber():Number
        {
            return line;
        }

        public function error(msg:String):void
        {
            Console.print("WARNING: Error in parsing CSS line " + lineNumber + " char " + peek() + ": " + msg);
        }

        //____________________________________________
        //  Protected
        //____________________________________________
        protected var source:String;
        protected var position:Number = 0;
        protected var line:Number = 1;

        protected function peekCmp(args:Vector.<String>):Boolean
        {
            for(var i=0; i<args.length; i++)
            {
                if(peek() == args[i])
                    return true;
            }

            return false;
        }

    }

}