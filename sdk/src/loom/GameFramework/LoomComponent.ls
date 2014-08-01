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
    * Base class for most game functionality. Contained in a LoomGameObject.
    * 
    * Dependency injection is fulfilled based on the LoomGroup containing the
    * owning LoomGameObject.
    * 
    * Provides a generic data binding system as well as callbacks when
    * the component is added to or removed from a LoomGameObject.
    */
   class LoomComponent
   {
      [Inject]
      /**
       * The property manager we'll use for lookups.
       */
      public var propertyManager:PropertyManager;

      // Make internal when LOOM-312 is fixed.
      public var _owner:LoomGameObject;

      /**
       * The game object we are attached to.
       */
      public function get owner():LoomGameObject
      {
         return _owner;
      }

      private var _safetyFlag:Boolean = false;
      private var _name:String;

      private var bindings:Vector.<String>;
      private var bindingsCache:Vector.<Object> = [];

      /**
       * Internal book-keeping flag for bindings.
       */
      public var bindingsDirty:Boolean;

      /**
       * The name of the component.
       */
      public function getName():String
      {
        return _name;
      }

      public function get name():String
      {
        return _name;
      }

      public function set name(value:String):void
      {
         Debug.assert(_owner == null, "Already added to a LoomGameObject, cannot change name!");
         _name = value;
      }

      public function doAdd():Boolean
      {
         _safetyFlag = false;
         var rvalue = onAdd();
         Debug.assert(_safetyFlag == true, "You forgot to call super.onAdd() in an onAdd override.");
         return rvalue;
      }

      public function doRemove():void
      {
         _safetyFlag = false;
         onRemove();
         Debug.assert(_safetyFlag == true, "You forgot to call super.onRemove() in an onRemove override.");
      }

      /**
       * Called when the component is added to a LoomGameObject; subclass with your own logic.
       */
      protected function onAdd():Boolean
      {
         _safetyFlag = true;
         return true;
      }

      /**
       * Called when the component is removed from a LoomGameObject; subclass with your own logic.
       */
      protected function onRemove():void
      {
         _safetyFlag = true;
      }

      /**
       * Add a binding - that is, a string defining a field elsewhere to draw data from.
       */
      public function addBinding(fieldName:String, propertyReference:String):void
      {
         if(!bindings)
            bindings = new Vector.<String>();

         var binding:String = fieldName + "||" + propertyReference;
         bindings.pushSingle(binding);

         bindingsDirty = true;
      }

      /**
       * Call with same args as prior call to addBinding to remove that binding.
       */
      public function removeBinding(fieldName:String, propertyReference:String):void
      {
         if(!bindings || !bindings.length)
            return;

          var binding:String = fieldName + "||" + propertyReference;

          bindings.remove(binding);

          bindingsDirty = true;
      }

      /**
       * Call whenever you need bindings propagated to your component. Ideally, 
       * not more than once a frame.
       */
      public function applyBindings():void
      {
         if(!bindings || !bindings.length || !_owner)
            return;

         Debug.assert(propertyManager, "Couldn't find a PropertyManager instance, is one available for injection?");

         if (bindingsDirty)
         {
            // our bindings are dirty, so clear them
            bindingsCache.clear();

            var invalid = false;

            // go through all the bindings generating an encoded property vector for them
            for each (var binding in bindings)
            {
               // first split out  the field/property we are setting
               var v:Vector.<String> = binding.split("||");

               var setProperty = false;
               var setType = this.getType();
               var setMember:MemberInfo;

               // first find it as a field
               setMember = setType.getFieldInfoByName(v[0]);

               if (!setMember)
               {   
                   // next see if it is a property
                   setMember = setType.getPropertyInfoByName(v[0]);
                   Debug.assert(setMember);
                   setMember = (setMember as PropertyInfo).getSetMethod();
                   Debug.assert(setMember);
                   setProperty = true;
               }

               // if we haven't found it at all, get out of here
               if (!setMember)
                   continue;

                // now split the property walking vector up
                v = v[1].split(".");

                // look up component in form @component
                var getComponent = _owner.lookupComponentByName(v[0].substr(1));

                // if we have no such component, this is a deal breaker
                if (!getComponent)
                {
                    invalid = true;
                    break;
                }

                // alright, start the encoding, first we 
                // add the component we are getting from
                bindingsCache.pushSingle(getComponent);    

                // remove the @component from property walker
                v.shift();

                // the getType tracks the type we are looking up fields
                // and properties from
                var getType = getComponent.getType();

                // push the number of properties in the walker
                bindingsCache.pushSingle(v.length);    

                // now, go through each and encode it
                for each (var member in v)
                {
                    var getProperty = false;
                    var getMember:MemberInfo;

                    // do the field vs getter dance
                    getMember = getType.getFieldInfoByName(member);

                    if (!getMember)
                    {
                        getMember = getType.getPropertyInfoByName(member);
                        Debug.assert(getMember);
                        getMember = (getMember as PropertyInfo).getGetMethod();
                        Debug.assert(getMember);
                        getProperty = true;
                    }

                    // if no such member, this is also a deal breaker
                    if (!getMember)
                    {
                        invalid = true;
                        break;
                    }

                    // get the type off the member
                    getType = getMember.getMemberType();

                    // if we're not a getter
                    if (!getProperty)
                        bindingsCache.pushSingle(getMember.getOrdinal());
                    else
                        bindingsCache.pushSingle(-getMember.getOrdinal());

                }

                // finally encode the setter property
                if (!setProperty)
                    bindingsCache.pushSingle(setMember.getOrdinal());
                else
                    bindingsCache.pushSingle(-setMember.getOrdinal());


                if (invalid)
                  break;

            }

            if (!invalid)
              bindingsDirty = false;

         } 

         // and apply         
         if (!bindingsDirty)
             PropertyManager.applyBindings(this, bindingsCache);

      }
   }
}
