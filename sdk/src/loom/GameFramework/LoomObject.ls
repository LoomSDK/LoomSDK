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
    * Base class for things that have names, lifecycles, and exist in a LoomSet or
    * LoomGroup.
    * 
    * To use a LoomObject:
    * 
    * 1. Instantiate one. (var foo = new LoomGroup();)
    * 2. Set the owning group. (foo.owningGroup = rootGroup;)
    * 3. Call initialize(). (foo.initialize();) 
    * 4. Use the object!
    * 5. When you're done, call destroy(). (foo.destroy();)
    */
   class LoomObject
   {
      private var _name:String = null;
      private var _owningGroup:LoomGroup = null;
      protected var _sets:Vector.<LoomSet>;

      public function initialize(objectName:String = null):void
      {
         _name = objectName;

         if(_owningGroup == null)
         {
            owningGroup = LoomGroup.rootGroup;
            Debug.assert(_owningGroup != null, "Failed to get RootGroup in LoomObject.initialize!");
         }

         Debug.assert(owningGroup != null, "Can't initialize a LoomObject without a valid owningGroup!");

         if(owningGroup.getInjector())
            owningGroup.injectInto(this);
      }

      public function destroy():void
      {
         // Remove from sets.
         if(_sets)
         {
            while(_sets.length)
               _sets[_sets.length-1].remove(this);
         }

         // Remove from owning group.
         Debug.assert(_owningGroup != null, "Tried to destroy a " + this.getType().getFullName() + "(" + (name ? name : "null") + ") that does not have membership in a group. Probably you already called destroy() on it.");
         _owningGroup.remove_internal(this);
         _owningGroup = null;
      }

      /**
       * What LoomSets reference this LoomObject.
       */
      public function getSets():Object //Vector.<LoomSet>
      {
         return _sets;
      }

      public function get owningGroup():LoomGroup
      {
         return _owningGroup;
      }

      public function set owningGroup(value:LoomGroup):void
      {
         // Remove from previous owningGroup.
         if(_owningGroup != null)
         {
            _owningGroup.remove_internal(this);
         }

         // Add to new owningGroup.
         Debug.assert(value != null, "Can't set owningGroup of LoomObject to null. You probably want to call destroy() instead.");
         value.add_internal(this);
         _owningGroup = value;
      }

      public function noteSetAdd(_set:LoomSet):void
      {
         if(_sets == null)
             _sets = new Vector.<LoomSet>();
         _sets.pushSingle(_set);            
      }

      public function noteSetRemove(_set:LoomSet):void
      {
         _sets.remove(_set);
      }

      public function get name():String
      {
         return _name;
      }
   }
}