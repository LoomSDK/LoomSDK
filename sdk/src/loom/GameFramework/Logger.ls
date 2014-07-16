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
    * Helper class to handle log output.
    */
   class Logger
   {
      /**
       * Call to print warnings to the log.
       *
       * @param object Object initiating output.
       * @param method Method initiating output.
       * @param message Message to log.
       */
      public static function warn(object:Object, method:String, message:String):void
      {
         Console.print(object.toString() + " - WARN " + method + " - " + message);
      }

      /**
       * Call to print normal output to the log.
       *
       * @param object Object initiating output.
       * @param message Message to log.
       */
      public static function print(object:Object, message:String):void
      {
         Console.print(object.toString() + " - " + message);
      }
   }
}