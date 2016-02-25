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
   import loom.utils.Injector;

   // This is optional per PBE2 standard
   interface ILoomManager
   {
      function initialize():void;
      function destroy():void;
   }

   /**
    * LoomGroup provides lifecycle functionality (LoomObjects in it are destroy()ed
    * when it is destroy()ed), as well as dependency injection (see
    * registerManager).
    * 
    * LoomGroups are unique because they don't require an owningGroup to 
    * be initialize()ed.
    */
   class LoomGroup extends LoomObject
   {
      private static var _rootGroup:LoomGroup = null;
      public static function get rootGroup():LoomGroup
      {
         if(_rootGroup == null)
         {
            _rootGroup = new LoomGroup();
            _rootGroup.initialize("RootGroup");          
         }

         Debug.assert(_rootGroup != null, "Failed to initialize rootGroup.");
         return _rootGroup;
      }

      private var _children:Vector.<LoomObject> = new Vector.<LoomObject>();
      private var _injector:Injector = new Injector();

      public function initialize(objectName:String):void
      {
         super.initialize(objectName);

         if(owningGroup)
            _injector.setParentInjector(owningGroup.getInjector());
      }

      public function destroy():void
      {
         super.destroy();

         // Destroy our children.
         while(length())
            at(length()-1).destroy();

         // De-initialize our managers.
         if(_injector)
         {
            var mappings:Dictionary.<String, Object> = _injector.getMappedValues();
            for(var key:String in mappings)
            {
               var instance = mappings[key];
               if(instance as ILoomManager)
                  (instance as ILoomManager).destroy();
            }
         }
      }

      // These are internal only.
      public function add_internal(object:LoomObject):void
      {
         _children.pushSingle(object);
      }

      public function remove_internal(object:LoomObject):void
      {
         _children.remove(object);
      }

      public function length():int
      {
         return _children.length;
      }

      public function at(i:int):LoomObject
      {
         return _children[i];
      }

      public function contains(object:LoomObject):Boolean
      {
         return (object.owningGroup == this);
      }

      public function indexOf(object:LoomObject):int
      {
         Debug.assert(false, "NYI");
         return -1;
      }

      public function getInjector():Injector
      {
         if(_injector)
            return _injector;
         else if(owningGroup)
            return owningGroup._injector;
         else 
            Debug.assert("Could not retrieve an injector!");
            
         return null;     
      }

      public function registerManager(instance:Object, clazz:Type = null, id:String = null):void
      {
         _injector.mapValue(instance, clazz, id);

         injectInto(instance);

         // See if we can initialize it.
         if(instance as ILoomManager)
            (instance as ILoomManager).initialize();
      }

      public function getManager(clazz:Type):Object
      {
         return getInjector().getValue(clazz);
      }

      public function injectInto(object:Object):void
      {
         Debug.assert(getInjector(), "Could not find an injector!");
         getInjector().apply(object);
      }

      public function lookup(name:String):LoomObject
      {
         Debug.assert(false, "NYI");
         return null;
      }
   }
}