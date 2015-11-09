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

import loom.utils.Injector;

/**
 * Called when certain LML events occur.
 */
delegate LMLDelegate():void;

/* 
    Represents an instance of an LML document 
*/
class LMLDocument 
{
    //_________________________________________________
    //  Public Properties
    //_________________________________________________
    public function get path():String
    {
        return _path;
    }

    public function get target():ILMLParent 
    {
        return _target;
    }

    public function get root():LMLNode 
    {
        return _root;
    }

    public function set root(value:LMLNode):void
    {
        // revert the target
        if(_root) {
            onRemoveLMLChildren();
            target.removeLMLChildren();
        }

        _root = value;
        _injector = new LMLInjector();
        if(_root)
        {
            // reapply to the target
            var rootType = _root.type.getFullName();
            var targetType = (target as Object).getType().getFullName();
            _root.apply(target as Object);

            // apply the lml nodes to the target
            for(var i = 0; i<_root.children.length; i++)
            {
                var child:LMLNode = _root.children[i];
                if(child)
                    target.addLMLChild(child.id, child.construct(injector));
            }

            injector.apply(target, "Bind");
        }

        onLMLCreated();
    }

    public function get injector():Injector
    {
        return _injector;
    }

    public function apply()
    {
        injector.apply(target, "Bind");
        onLMLCreated();
    }

    //_________________________________________________
    //  Public Function
    //_________________________________________________
    
    /* 
        Called right before the ILMLParent.removeLMLChildren()
        is called on the target during an asset refresh. This
        can be called multiple times as the LML is reloaded
        Through the asset manager.
    */
    public var onRemoveLMLChildren:LMLDelegate;

    /* 
        Called when the LML has finished loading and
        has been applied to it's target. This can be 
        called multiple times as the LML is reloaded
        Through the asset manager.
    */
    public var onLMLCreated:LMLDelegate;

    //_________________________________________________
    //  Constructor
    //_________________________________________________
    public function LMLDocument(path:String, target:ILMLParent)
    {
        _path = path;
        _target = target;
    }

    //_________________________________________________
    //  Protected Properties
    //_________________________________________________
    protected var _path:String;
    protected var _target:ILMLParent;
    protected var _root:LMLNode;
    protected var _injector:Injector;

    //_________________________________________________
    //  Protected Functions
    //_________________________________________________


}

}