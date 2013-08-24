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

package loom.lml {

import loom.LoomTextAsset;

/*
    Contains static methods for creating/applying a LML document to a target ILMLParent
*/
class LML 
{
    //_________________________________________________
    //  Static Methods
    //_________________________________________________
    public static function apply(path:String, target:ILMLParent):LMLDocument
    {
        var lmlNode = nodeCache[path];
        if(!lmlNode) 
        {
            // load the xml file
            var asset = LoomTextAsset.create(path);
            // listen to asset change notification
            asset.updateDelegate += onAssetChange;
            asset.load();

            lmlNode = nodeCache[path];
        }
           

        var doc = new LMLDocument(path, target);
        doc.root = lmlNode;

        return doc;
    }

    public static function bind(path:String, target:ILMLParent):LMLDocument
    {
        // add binding method here
        if(!boundLML[path])
            boundLML[path] = new Vector.<LMLDocument>();

        var doc = apply(path, target);
        boundLML[path].push(doc);

        return doc;
    }

    public static function unbind(value:LMLDocument):void
    {
        boundLML[value.path].remove(value);
    }

    //_________________________________________________
    //  Protected Static Properties
    //_________________________________________________
    protected static var nodeCache:Dictionary.<String,LMLNode> = new Dictionary.<String,LMLNode>();
    protected static var boundLML:Dictionary.<String,Vector.<LMLDocument> > = new Dictionary.<String,Vector.<LMLDocument> >();

    //_________________________________________________
    //  Protected Static Methods
    //_________________________________________________
    protected static function parseLML(path:String, contents:String):LMLNode
    {
        var document:XMLDocument = new XMLDocument();   
        var lml:LMLNode = null;

        if(!contents)
        {
            Console.print("WARNING: LML content is empty at '", path, "'");
            return lml;
        }

        var code = document.parse(contents);

        if(code != 0)
        {
            Console.print("WARNING: Failed to parse lml at '", path, "'. ", XMLErrorMessages.buildErrorMessage(code, document));
            return lml;
        }

        var root:XMLElement = document.rootElement();
        lml = new LMLNode(root, path);

        // Store a reference to the XMLDocument so it doesn't get GC'ed under us
        // causing the various nodes and strings under it to be nuked.
        // LOOM-551 tracks this.
        lml.owningDocument = document;

        return lml;
    }

    protected static function onAssetChange(path:String, contents:String):void
    {
        // TODO: Re-add this in verbose mode.
        //Console.print("LML file changed: " + path);

        // refresh the contents
        var lmlNode = parseLML(path, contents);

        if(lmlNode)
        {
            nodeCache[path] = lmlNode;

            // refresh any bound objects
            var boundObjects:Vector.<LMLDocument> = boundLML[path];
            if(boundObjects) {

                for(var i = 0; i<boundObjects.length; i++) {
                    boundObjects[i].root = lmlNode;
                }

            }
        }       
    }
}



}