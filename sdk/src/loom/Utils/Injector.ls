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

package loom.utils {
/*
Injector is an interface that provides a minimalist dependency 
injection API.
*/
class Injector 
{
    public function Injector():void
    {
        mappedValues = new Dictionary.<Type, Object>();
    }

    /*
    Maps a value to a certain class type, so when apply()
    is called, the value will be injected into any property with the
    [Inject] tag over it and that matches the class definition specified
    in the type parameter.

    If type is not specified, it will be inferred from value.
    */
    public function mapValue(value:Object, type:Type=null, id:String=null):void
    {
        if(!type)
            type = value.getType();

        Debug.assert(type != null, "You must provide a type when mapping a value!");
        Debug.assert(type.getFullName() != null, "Type somehow lacks a valid type name.");
        Debug.assert(value != null, "You must provide a value to map!");

        var key:String = type.getFullName();
        if(id != null)
            key += "!!" + id;

        mappedValues[key] = value;
    }

    protected static var recursionProtection:int = 0;

    public function getValue(type:Type, id:String = null):Object
    {
        Debug.assert(type != null, "You must provide a type when retrieving a value!");

        // Generate the key to look up.
        var key:String = type.getFullName();

        // try to find it based off the id first
        var res:Object;

        recursionProtection++;

        if(recursionProtection > 64)
        {
            trace("INFINITE RECURSION IN INJECTOR FOR (" + type.getName() + ", " + id + ")");
            return null;
        }

        // try with an ID
        if(id != null)
            res = mappedValues[key + "!!" + id];

        // Check our mapped values,
        if(res == null)
            res = mappedValues[key];

        // If we can't find it, check the parent...
        if(res == null && parent)
            res = parent.getValue(type, id);

        // If we still can't find it, then warn.
        if(res == null)
            warnCouldNotGetValue(type, id);

        recursionProtection--;

        return res;
    }

    /*
    Applies the injection to the specified object. If you wish to have a
    property injected into the specified object, make sure that an [Inject]
    metadata tag is added to the desired target property and the value is
    mapped in this injector using the mapValue() method.
    */
    public function apply(target:Object, tagName:String="Inject"):void
    {
        var type = target.getType();
        var targets:Vector.<InjectionTarget> = injectionTargetCache[type];

        if(!targets)
        {
            targets = new Vector.<InjectionTarget>();
            injectionTargetCache[type] = targets;

            // otherwise we need to create injection targets
            for(var i = 0; i<type.getFieldInfoCount(); i++)
            {
                var fieldInfo = type.getFieldInfo(i);
                var inject = fieldInfo.getMetaInfo(tagName);
                if(inject) {
                    var t = new InjectionTarget();
                    t.type = fieldInfo.getTypeInfo();
                    t.property = fieldInfo.getName();
                    t.fieldInfo = fieldInfo;
                    t.id = inject.getAttribute("id");

                    if(t.id == null)
                        t.id = fieldInfo.getName();

                    targets.push(t);
                }
            }
        }
     
        // loop over the targets and inject into them
        for(var j = 0; j < targets.length; j++)
        {
            var injectionTarget = targets[j];

            // Should dictioary keys be compared strictly or looseley?
            // This problem is outlined in Jira Issue: LOOM-10
            var injectedValue:Object;

            injectedValue = getValue(injectionTarget.type, injectionTarget.id);
            if(injectedValue) 
            {
                injectionTarget.fieldInfo.setValue(target,injectedValue);
            }
        }
    }

    public function getMappedValues():Dictionary.<String, Object>
    {
        return mappedValues;
    }

    public function setParentInjector(i:Injector):void
    {
        parent = i;
    }

    // called when the injector could not get value for the type and ID
    protected function warnCouldNotGetValue(type:Type, id:String)
    {
        Console.print("WARNING: Injector - could not get a value for " + type.getFullName() + " id=" + id.toString());
    }

    protected var parent:Injector = null;

    protected var mappedValues:Dictionary.<String, Object>;

    protected static var injectionTargetCache:Dictionary.<Type,Vector.<InjectionTarget> > = new Dictionary.<Type,Vector.<InjectionTarget> >();

}

protected class InjectionTarget
{
    public var type:Type;
    public var property:String;
    public var fieldInfo:FieldInfo;
    public var id:String;
}

}