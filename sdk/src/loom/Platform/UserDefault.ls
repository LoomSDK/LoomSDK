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

package loom.platform
{
   /**
    * UserDefault acts as a tiny database for local settings. You can save and 
    * get base type values by it. For example, setBoolForKey("played", true) 
    * will add a bool value true into the database. Its key is "played". You
    * can get the value of the key by getBoolForKey("played").
    * 
    * It supports the following base types: bool, int, float, double, string
    */
   public native class UserDefault
   {
      /**
      Get bool value by key, if the key doesn't exist, a default value will return.
      You can set the default value, or it is false.
       */
      public native function getBoolForKey(key:String, def:Boolean = false):Boolean;
      
      /**
      Get integer value by key, if the key doesn't exist, a default value will return.
      You can set the default value, or it is 0.
       */
      public native function getIntegerForKey(key:String, def:int = 0):int;

      /**
      Get float value by key, if the key doesn't exist, a default value will return.
      You can set the default value, or it is 0.0f.
      */
      public native function getFloatForKey(key:String, def:Number = 0):Number;

      /**
      Get double value by key, if the key doesn't exist, a default value will return.
      You can set the default value, or it is 0.0.
      */
      public native function getStringForKey(key:String, def:String = ""):String;

      /**
      Get double value by key, if the key doesn't exist, a default value will return.
      You can set the default value, or it is 0.0.
      */
      public native function getDoubleForKey(key:String, def:Number = 0):Number;

      /**
      Set bool value by key.
      */
      public native function setBoolForKey(key:String, value:Boolean);

      /**
      Set integer value by key.
      */
      public native function setIntegerForKey(key:String, value:int);

      /**
      Set float value by key.
      */
      public native function setFloatForKey(key:String, value:Number);

      /**
      Set string value by key.
      */
      public native function setStringForKey(key:String, value:String);

      /**
      Set double value by key.
      */
      public native function setDoubleForKey(key:String, value:Number);

      /**
      Remove the user defaults from the file system.
      
      @return `true` if the file was removed, `false` if unable to remove or non-existent.
      */
      public native function purge():Boolean;

      /** 
      Get the singleton instance of UserDefault.
      */
      public static native function sharedUserDefault():UserDefault;

      /**
      Remove the shared user defaults from the filesystem
      */
      public static native function purgeSharedUserDefault():Boolean;
      
   }
}