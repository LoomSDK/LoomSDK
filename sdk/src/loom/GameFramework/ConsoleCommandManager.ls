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
   import loom.Application;
   
   /**
    * Represent a conmmand in the console command manager.
    * @private
    */
   protected class ConsoleCommand
   {
      public var name:String;
      public var callback:Function;
      public var docs:String;
   }

   /**
    * Process and dispatch commands issued via the asset agent. You mostly care about registerCommand.
    */
   class ConsoleCommandManager implements ILoomManager
   {
      protected var commands:Dictionary.<String, ConsoleCommand> = new Dictionary.<String, ConsoleCommand>();
      protected var commandList:Vector.<ConsoleCommand> = new Vector.<ConsoleCommand>();
      protected var commandListOrdered:Boolean = false;

      /**
       * Start the console command manager.
       */
      public function initialize():void
      {
         Console.print("Command manager online.");
         Application.assetCommandDelegate += process;
      }

      /**
       * Stop the console command manager.
       */
      public function destroy():void
      {
         Console.print("Command manager offline.");
         Application.assetCommandDelegate -= process;
      }

      /**
       * Register a command which the user can execute via the console.
       * 
       * Arguments are parsed and cast to match the arguments in the user's
       * function. Command names must be alphanumeric plus underscore with no
       * spaces.
       *  
       * @param name The name of the command as it will be typed by the user. No spaces.
       * @param callback The function that will be called. Can be anonymous.
       * @param docs A description of what the command does, its arguments, etc.
       */
      public function registerCommand(name:String, cf:Function, docs:String = null):void
      {
         Debug.assert(name && name != "", "Tried to register a command with no name!");
         Debug.assert(cf != null, "Tried to register a command with no callback function!");

         // Allocate the command.
         var cc = new ConsoleCommand();
         cc.name = name;
         cc.callback = cf;
         cc.docs = docs;

         // Register it to all and sundry.
         Debug.assert(commands[name] == null, "Tried to register a command twice! Command with that name is already registered.");
         commands[name] = cc;
         commandList.push(cc);
         commandListOrdered = false;
      }

      protected function process(command:String):void
      {
         // Find a matching command.
         // TODO: Parse args and condition the command to be lower case + trimmed.
         var cc = commands[command];

         if(!cc)
         {
            Console.print("No such command '" + command +  "' found.");
            return;
         }

         // Call it!
         // TODO: Handle exceptions/errors.
         cc.callback.call();
      }
   }  
}