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
    * LoomSet provides safe references to one or more LoomObjects. When the
    * referenced LoomObjects are destroy()ed, then they are automatically removed
    * from any LoomSets. 
    */
   class LoomSet extends LoomObject
   {
      protected var items:Vector.<LoomObject> = new Vector.<LoomObject>();

      public function LoomSet(_name:String = null)
      {
         initialize(_name);
      }

      /**
      * Add a LoomObject to the set. 
      */
      public function add(object:LoomObject):void
      {
         items.pushSingle(object);
         object.noteSetAdd(this);
      }

      /**
       * Remove a LoomObject from the set.
       */
      public function remove(object:LoomObject):void 
      {
         Debug.assert(items.contains(object), "Tried to remove object from set that it was not a member of.");
         items.remove(object);
         object.noteSetRemove(this);
      }

      /**
       * Returns true if this LoomSet contains the specified object.
       */
      public function contains(object:LoomObject):Boolean
      {
         return items.contains(object);
      }

      /**
       * Returns the number of objects in the set.
       */
      public function get length():int
      {
         return items.length;
      }

      /**
       * Return the object at the specified index of the set.
       */
      public function at(index:int):LoomObject
      {
         return items[index];
      }
   }
}