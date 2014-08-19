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

package loom.gameframework
{
   /**
    * Abstract property lookups. Because properties can be fetched from a
    * variety of sources, having the full implementation in LoomGameObject is
    * unwieldy - and inflexible, since people will want to do lookups on other
    * kinds of objects.
    *
    * The PropertyManager allows easy addition of new functionality via plugins, 
    * and handles caching lookups for efficiency.
    */
   class PropertyManager
   {
      public function PropertyManager()
      {
         // Set up default plugins.
         registerPropertyType("@", new ComponentPlugin());
      }

      protected var propertyPlugins:Dictionary.<String, IPropertyPlugin> = new Dictionary.<String, IPropertyPlugin>();
      public function registerPropertyType(prefix:String, plugin:IPropertyPlugin):void
      {
         propertyPlugins[prefix] = plugin;
      }

      protected var parseCache:Dictionary.<String, Vector.<String> > = new Dictionary.<String, Vector.<String> >;
      protected var cachedPi:PropertyManagerInfo = new PropertyManagerInfo();
      public function findProperty(scope:Object, property:String, providedInfo:PropertyManagerInfo):PropertyManagerInfo
      {
         if(property == null || property.length == 0)
            return null;

         // See if it is cached...
         if(!parseCache[property])
         {
            // Parse and store it.
            parseCache[property] = new Vector.<String>();
            parseCache[property].pushSingle(property.charAt(0));

            var toAppend:Vector.<String> = property.substr(1).split(".");
            for(var i:int=0; i<toAppend.length; i++)
               parseCache[property].pushSingle(toAppend[i]);
         }

         // Either errored or cached at this point.

         // Awesome, switch off the type...
         const cached:Vector.<String> = parseCache[property];
         const plugin:IPropertyPlugin = propertyPlugins[cached[0]];
         Debug.assert(plugin, "Unknown prefix '" + cached[0] + "' in '" + property + "'.");

         // Let the plugin do its thing.
         plugin.resolve(scope, cached, providedInfo);

         return providedInfo;
      }

      protected var bindingCache:Dictionary.<String, Vector.<String> > = new Dictionary.<String, Vector.<String> >;

      public function applyBinding(scope:Object, binding:String):void
      {
         // Cache parsing if possible.
         if(bindingCache[binding] == null)
            bindingCache[binding] = binding.split("||");

         // Now do the mapping.
         var cachedBinding:Vector.<String> = bindingCache[binding];

         var propInfoToSet:PropertyManagerInfo = findProperty(scope, cachedBinding[1], cachedPi);
         var valueToSet = propInfoToSet.getValue();
         var scopeType = scope.getType();
         scopeType.setFieldOrPropertyValueByName(scope, cachedBinding[0], valueToSet);
      }

      public function getProperty(scope:Object, property:String, defaultValue:Object):Object
      {
         // Look it up.
         const resPi:PropertyManagerInfo = findProperty(scope, property, cachedPi);

         // Get value or return default.
         if(resPi)
            return resPi.getValue();
         else
            return defaultValue;
      }

      public function setProperty(scope:Object, property:String, value:Object):void
      {
         // Look it up.
         const resPi:PropertyManagerInfo = findProperty(scope, property, cachedPi);

         // Abort if not found, can't set nothing!
         if(resPi == null)
            return;

         resPi.setValue(value);
      }

     /**
      *  Applys an encoded property vector to the provided component 
      *
      *  This is an internal call and should not be called outside of LoomComponent  
      *
      *  @param component The component to apply the bindings to
      *  @param bindings the encoded property vector
      */
      static public native function applyBindings(component:LoomComponent, bindings:Vector.<Object>);

   }

   /**
    * Interface for plugins that implement property lookups. They shouldn't store much if any data.
    */
   public interface IPropertyPlugin
   {
      function resolve(context:Object, cached:Vector.<String>, propertyInfo:PropertyManagerInfo):void;
   }

   /**
    * Implement lookups of fields, ie "blah.foo.bar"
    */
   public class FieldPlugin implements IPropertyPlugin
   {
      public function resolve(context:Object, cached:Vector.<String>, propertyInfo:PropertyManagerInfo):void
      {
         var walk:Object = context;
         for(var i:int=0; i<cached.length - 1; i++)
         {
            var walkType = walk.getType();
            walk = walkType.getFieldOrPropertyValueByName(walk, cached[i], walk);
         }

         propertyInfo.object = walk;
         propertyInfo.field = cached[cached.length - 1];
      }

      public function resolveFull(context:Object, cached:Vector.<String>, propertyInfo:PropertyManagerInfo, arrayOffset:int = 0):void
      {
         var walk:Object = context;
         for(var i:int=arrayOffset; i<cached.length - 1; i++)
         {
            var walkType = walk.getType();
            walk = walkType.getFieldOrPropertyValueByName(walk, cached[i], walk);
         }

         propertyInfo.object = walk;
         propertyInfo.field = cached[cached.length - 1];
      }
   }

   /**
    * Implement lookups of "@foo" on a LoomGameObject ("@foo" means look up the component named foo).
    */
   public class ComponentPlugin implements IPropertyPlugin
   {
      protected var fieldResolver:FieldPlugin = new FieldPlugin();

      public function resolve(context:Object, cached:Vector.<String>, propertyInfo:PropertyManagerInfo):void
      {
         // Context had better be an entity.
         var entity:LoomGameObject;
         var contextAsGO:LoomGameObject = context as LoomGameObject;
         var contextAsLC:LoomComponent = context as LoomComponent;

         if(contextAsGO)
            entity = contextAsGO;
         else if(contextAsLC)
            entity = contextAsLC.owner;
         else
            Debug.assert(false, "Can't find entity to do lookup!");

         // Look up the component.
         var component:LoomComponent = entity.lookupComponentByName(cached[1]);

         if(cached.length > 2)
         {
            // Look further into the object. 
            fieldResolver.resolveFull(component, cached, propertyInfo, 2);
         }
         else
         {
            propertyInfo.object = component;
            propertyInfo.field = null;
         }
      }
   }

   /**
    * Internal class used by PropertyManager to service property lookups.
    * @private
    */
   class PropertyManagerInfo
   {
      public var object:Object = null;
      public var field:String = null;

      public function getValue():Object
      {
         if(!object)
            return null;

         if(!field)
            return object;
            
         var type = object.getType();
         Debug.assert(type, "Couldn't get type of object.");   

         // Do the field lookup.
         return type.getFieldOrPropertyValueByName(object, field);
      }

      public function setValue(value:Object):void
      {
         if (!object)
            Debug.assert(false, "Couldn't get type for object.");
         
         var type = object.getType();
         Debug.assert(type, "Couldn't get type of object.");   
         
         type.setFieldOrPropertyValueByName(object, field, value);
      }

      public function clear():void
      {
         object = null;
         field = null;
      }
   }
}