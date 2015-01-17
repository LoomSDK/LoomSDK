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

/**
 * Injector provides a minimalist dependency injection API.
 *
 * Dependency injection sets member variables and properties on an object
 * automatically based on mappings. A field that should be set is marked
 * with metadata, ie, [Inject]. Then when the Injector.apply method is 
 * called on the object, it applies values specified with mapValue().
 *
 * Please see the guide under LoomScript -> Dependency Injection for 
 * a fuller description of how dependency injection can help you
 * structure your programs more cleanly.
 */
class Injector 
{
    public function Injector():void
    {
        mappedValues = new Dictionary.<Type, Object>();
    }

    /**
        Remove all mappings from the injector. Useful to ensure no lingering
        references are kept.
    */
    public function clear()
    {
        mappedValues.clear();
    }

    /**
    Maps a value to a certain class type, so when apply()
    is called, the value will be injected into any property with the
    [Inject] tag over it and that matches the class definition specified
    in the type parameter.

    If type is not specified, it will be inferred from value.

    If value is null and type is specified, then the mapping is removed.
    */
    public function mapValue(value:Object, type:Type=null, id:String=null):void
    {
        if(!type)
        {
            if(value)
            {
                type = value.getType();
            }
            else
            {
                Debug.assert(false, "Unable to map null value with no type specified! Please specify a type or value!");
                return;
            }
        }

        Debug.assert(type != null, "You must provide a type when mapping a value!");
        Debug.assert(type.getFullName() != null, "Type somehow lacks a valid type name.");

        // Generate the key.
        var key:String = type.getFullName();
        if(id != null)
            key += "!!" + id;

        // Assign to dictionary.
        mappedValues[key] = value;
    }

    protected static var recursionProtection:int = 0;

    /**
     * Get the value that would be injected for a given type/id.
     */
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
            recursionProtection--;
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

    /**
    Applies the injection to the specified object. If you wish to have a
    property injected into the specified object, make sure that an [Inject]
    metadata tag is added to the desired target property and the value is
    mapped in this injector using the mapValue() method.
    */
    public function apply(target:Object, tagName:String="Inject"):void
    {
        var type = target.getType();

        // Get all potential targets from the cache.
        var targets:Vector.<InjectionTarget> = injectionTargetCache[type];
        if(!targets)
        {
            // Cache miss, create entry.
            targets = new Vector.<InjectionTarget>();
            injectionTargetCache[type] = targets;

            // We need to create injection targets...

            // ...for fields...
            for(var i = 0; i<type.getFieldInfoCount(); i++)
            {
                // Look up the field.
                var fieldInfo = type.getFieldInfo(i);

                // Get the metadata if present.
                var inject = fieldInfo.getMetaInfo(tagName);
                if(!inject)
                    continue;

                // Create the injection target.
                var t = new InjectionTarget();
                t.type = fieldInfo.getTypeInfo();
                t.property = fieldInfo.getName();
                t.fieldInfo = fieldInfo;
                t.id = inject.getAttribute("id");

                if(t.id == null)
                    t.id = fieldInfo.getName();

                targets.push(t);
            }

            // ...for properties...
            for(i = 0; i<type.getPropertyInfoCount(); i++)
            {
                // Look up the property.
                var propInfo = type.getPropertyInfo(i);

                // Get first of getter, setter for the metadata.
                inject = null;
                if(propInfo.getGetMethod())
                    inject = propInfo.getGetMethod().getMetaInfo(tagName);
                if(!inject && propInfo.getSetMethod())
                    inject = propInfo.getSetMethod().getMetaInfo(tagName);
                if(!inject)
                    continue;

                // Register the target.
                t = new InjectionTarget();
                t.type = propInfo.getTypeInfo();
                t.property = propInfo.getName();
                t.propInfo = propInfo;
                t.id = inject.getAttribute("id");

                if(t.id == null)
                    t.id = propInfo.getName();

                targets.push(t);
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
            if(!injectedValue) 
                continue;

            if(injectionTarget.fieldInfo)
            {
                // Handle fields.
                injectionTarget.fieldInfo.setValue(target,injectedValue);
            }
            else if(injectionTarget.propInfo)
            {
                // Handle properties.
                var method = injectionTarget.propInfo.getSetMethod();
                if(method)
                {
                    method.invoke(target, injectedValue);
                }
                else
                {
                    Console.print("WARNING: Injector tried to inject to property " + injectionTarget.property + " that has no setter on class " + target.getTypeName());
                }
            }
            else
            {
                Debug.assert(false, "Got an injection target with no field or property info!");
            }
        }
    }

    /**
     * Helper to get direct access to the mappings. Advanced users only.
     */
    public function getMappedValues():Dictionary.<String, Object>
    {
        return mappedValues;
    }

    /**
     * If a parent injector is set, then any mappings we can't fulfill are 
     * referred to the parent injector.
     */
    public function setParentInjector(i:Injector):void
    {
        parent = i;
    }

    /**
     * Called when the injector could not get value for the type and ID. You
     * can override this to provide alternate behaviors.
     */
    protected function warnCouldNotGetValue(type:Type, id:String)
    {
        Console.print("WARNING: Injector - could not get a value for " + type.getFullName() + " id=" + id.toString());
    }

    protected var parent:Injector = null;

    protected var mappedValues:Dictionary.<String, Object>;

    protected static var injectionTargetCache:Dictionary.<Type,Vector.<InjectionTarget> > = new Dictionary.<Type,Vector.<InjectionTarget> >();

}

/**
 * Internal cache for info about injection sites.
 * @private
 */
protected class InjectionTarget
{
    public var type:Type;
    public var property:String;
    public var fieldInfo:FieldInfo;
    public var propInfo:PropertyInfo;
    public var id:String;
}

}
