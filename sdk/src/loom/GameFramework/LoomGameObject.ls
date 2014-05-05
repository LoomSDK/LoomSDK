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
    * A delegate used to broadcast LoomGameObject notifications to components that register with it
    */
   delegate BroadCastDelegate( type:String, data:Object );

   /**
    * Container class for LoomComponent. Most game objects are made by 
    * instantiating LoomGameObject and filling it with one or more LoomComponent
    * instances.
    */
   class LoomGameObject extends LoomObject
   {
      public var broadcast:BroadCastDelegate;

      private var _deferring:Boolean = true;
      private var _components:Dictionary.<String, LoomComponent> = new Dictionary.<String, LoomComponent>();

      public function get deferring():Boolean
      {
         return _deferring;
      }

      public function set deferring(value:Boolean):void
      {
         if(_deferring && value == false)
         {
            var foundDeferred:Boolean = true;
            while(foundDeferred == true)
            {
               foundDeferred = false;

               for(var key:String in _components)
               {
                  // Deferred entries are marked with !.
                  if(!key || key.charAt(0) != "!")
                     continue;

                  // It's a deferral, so init it...
                  doInitialize(_components[key]);

                  // ... and nuke the entry.
                  _components[key] = null;
                  _components.deleteKey(key);

                  // Keep looking, so that we don't lose
                  // anything due to dictionary reorder.
                  foundDeferred = true;                     
               }
            }

         }

         _deferring = value;
      }

      protected function doInitialize(component:LoomComponent):void
      {
         Debug.assert(component != null, "Can't initialize a null component!");
         Debug.assert(owningGroup != null, "Can't initialize without an owning group!");
         component._owner = this;
         owningGroup.injectInto(component);
         component.doAdd();         
      }

      public override function initialize(objectName:String = null):void
      {
         super.initialize(objectName);

         // Look for un-added members.
         var thisType:Type = this.getType();
         var fieldList:Vector.<String> = thisType.getFieldAndPropertyList();
         for each(var key:String in fieldList)
         {
            // Only consider components.
            var fieldComponent:LoomComponent = thisType.getFieldOrPropertyValueByName(this, key) as LoomComponent;
            if(!fieldComponent)
               continue;

            // Don't double initialize.
            if(fieldComponent.owner != null)
               continue;

            // OK, add the component.
            if(fieldComponent.name != null && fieldComponent.name != "" && fieldComponent.name != key)
               Debug.assert(false, "LoomComponent has name '" + fieldComponent.name + "' but is set into field named '" + key + "', these need to match!");

            fieldComponent.name = key;
            addComponent(fieldComponent);
         } 
         
         // Inject ourselves.
         owningGroup.injectInto(this);
         
         // Stop deferring and let init happen.
         this.deferring = false;
         
         // Propagate bindings on everything.
         for(var key2:String in _components)
         {
             //if(!_components[key2].propertyManager)
             //    throw new Error("Failed to inject component properly.");
             _components[key2].applyBindings();
         }     
      }

      public override function destroy():void
      {
        // Remove all the components.
         for(var key:String in _components)
            removeComponent(_components[key]);

        super.destroy();
      }

      public function addComponent(component:LoomComponent, name:String = null):Boolean
      {
         if(name)
            component.name = name;

         if(component.name == null || component.name == "")
            Debug.assert(false, "Can't add component with no name!");

         // Stuff in dictionary.
         _components[component.getName()] = component;

         // Set component owner.
         component._owner = this;

         // Directly set field of same name if present.
         var mappedField = this.getType().getFieldInfoByName(component.name);
         if(mappedField)
            mappedField.setValue(this, component);

         // Defer or add now.
         if(_deferring)
            _components["!" + component.name] = component;
         else
            doInitialize(component);

         // mark all the bindings as dirty as we have added a component
         for each (var c in _components)
            c.bindingsDirty = true;
            
         return true;
      }

      public function removeComponent(component:LoomComponent):void
      {
         // Sanity.
         Debug.assert(component.owner == this, "Tried to remove a component that we do not own!");

         // Clear out mapped field of same name.
         var mappedField = this.getType().getFieldInfoByName(component.name);
         if(mappedField && mappedField.getValue(this) == component)
            mappedField.setValue(this, null);

         _components[component.name] = null;
         _components.deleteKey(component.name);

         component.doRemove();
         component._owner = null;

         // mark all the bindings as dirty as we have removed a component
         for each (var c in _components)
            c.bindingsDirty = true;
         
      }

      // TODO: Explicit templated downcast would be nice here.
      public function lookupComponentByName(name:String):LoomComponent
      {
         return _components[name];
      }
      
      var pm:PropertyManager;

      /**
       * Get a value from this game object in a data driven way. 
       * @param property Property string to look up, ie "@componentName.fieldName"
       * @param defaultValue A default value to return if the desired property is absent.
       */
      public function getProperty(property:String, defaultValue:Object = null):Object
      {
         Debug.assert(owningGroup, "Owning group required to get a property." );
         if (!pm)
            pm = owningGroup.getManager(PropertyManager) as PropertyManager;
         return pm.getProperty(this, property, defaultValue);
      }

      /**
       * Set a value on this game object in a data driven way. 
       * @param property Property string to look up, ie "@componentName.fieldName"
       * @param value Value to set if the property is found.
       */
      public function setProperty(property:String, value:Object):void
      {
         Debug.assert(owningGroup, "Owning group required to set a property." );
         if (!pm)
            pm = owningGroup.getManager(PropertyManager) as PropertyManager;
         pm.setProperty(this, property, value);            
      }
   }
}