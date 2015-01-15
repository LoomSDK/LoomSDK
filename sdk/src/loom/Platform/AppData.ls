/*
===========================================================================
Loom SDK
Copyright 2011, 2012, 2013, 2014, 2015
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
    import loom.Application;
    import loom.gameframework.Logger;


   /**
    * AppData can be used as an ABSTRACT class to save app specific data 
    * locally on the system.  Data is saved as a JSON file in the system's 
    * writeable path for the application.  Multiple extended AppData objects 
    * can be created and accessed using the provided get/set functions as a 
    * standard JSON object.  Optionally, the save and load functions can be
    * overwritten, and the actual JSON object accessed, so that data storage 
    * and retrieval can be handled in a custom manner.
    * 
    * It supports the following base types: bool, int, float, string
    */
    public class AppData
    {
        /**
         * Constant subfolder for where all AppData files are stored off of 'Path.getWritablePath()'
         */
        private const   SubFolder:String      = "AppData";

        /**
         * Local JSON data object that stores the current state of the AppData at all time.  
         Set as protected so that child objects can access it for custom JSON controls.
         */
        protected var   jsonData:JSON = null;

        /**
         * Stores whether or not 'saveOnSet' was specified in the Constructor.
         */
        private var     _saveOnSet:Boolean = false;

        /**
         * Stores the full path, including filename, of the JSON AppData file to save/load.
         */
        private var     _writePath:String = null;



       /**
        Constructor for an AppData object.
         *
         *  @param filename Name of the AppData JSON file to save to the system
         *  @param appFolder Name of an optional containing folder for the JSON file to be saved to. 
                Can be null or ""
         *  @param saveOnSet Whether or not the JSON file should be written to the system after a call 
                to one of the 'set' fuctions
         *  @param saveOnDeactivated Whether or not the save() function should be called when the 
                'Application.applicationDeactivated' is triggered by the app
         */
        function AppData(filename:String, appFolder:String, saveOnSet:Boolean, saveOnDeactivated:Boolean)
        {
            //do we want to save out the JSON after every set*() call?
            _saveOnSet = saveOnSet;

            //set up write path for the data & create it if it doesn't exist yet
            appFolder = (!String.isNullOrEmpty(appFolder)) ? appFolder + Path.getFolderDelimiter() : "";
            _writePath = Path.normalizePath(Path.getWritablePath() + Path.getFolderDelimiter() + appFolder + SubFolder);
            if(!Path.dirExists(_writePath))
            {
                if(!Path.makeDir(_writePath))
                {
                    Logger.warn(this, "AppData", "Error creating directory for AppData to be written to: " + _writePath);
                }
            }

            //add filename to the path to have the full path including file now
            if(!String.isNullOrEmpty(filename))
            {
                _writePath += Path.normalizePath(Path.getFolderDelimiter() + filename);
            }
            else
            {
                Logger.warn(this, "AppData", "Null or Empty filename provided.");
            }

            //add auto-save on deactivation?
            if(saveOnDeactivated)
            {
                Application.applicationDeactivated += onAppDeactivated;
            }

            //clear and potentially load existing data to populate the JSON
            clear();

            //if file doesn't exist, call function that can be overwritten by users to initilaize their data
            if(!File.fileExists(_writePath))
            {
                init();
            }

            load();
        }


        /**
        Called when the before the JSON file is created for the first time
         * Designed to be overwritten by the child object to handle custom actions.
         */
        protected function init():void {}


        /**
        Saves the local JSON data object to the system as the AppData.
         * Designed to be optionally overwritten by the child object to handle custom actions.
         *
         *  @return Boolean Was the JSON data file saved successfully or not
         */
        protected function save():Boolean
        {
            //save the JSON
            if(!File.writeTextFile(_writePath, jsonData.serialize()))
            {
                Logger.warn(this, "save", "Error saving AppData JSON: " + _writePath);
                return false;
            }
            trace("App Data saved to: " + _writePath);            
            return true;
        }


        /**
        Loads the JSON file for the AppData from the system into a locally stored JSON data object.
         * Designed to be optionally overwritten by the child object to handle custom actions.
         *
         *  @return Boolean Was the JSON data file loaded successfully or not
         */
        protected function load():Boolean
        {
            //load the JSON into a text file
            if(!File.fileExists(_writePath))
            {
                Logger.print(this, "No AppData JSON found at: " + _writePath);
                return false;
            }
            var textFile:String = File.loadTextFile(_writePath);
            if((textFile == null) || (textFile == ""))
            {
                Logger.warn(this, "load", "Invalid contents of AppData JSON file: " + _writePath);
                return false;
            }
            trace("App Data loaded from: " + _writePath);            

            //create JSON from text file data
            jsonData = new JSON();
            return jsonData.loadString(textFile);
        }


        /**
        Clears the locally read in JSON data, but leave the file on the system as-is.  
         * Designed to be optionally overwritten by the child object to handle custom actions.
         */
        protected function clear():void
        {
            //clear the cached JSON data
            jsonData = new JSON();
            jsonData.loadString("{}");
        }


        /**
        Removes the JSON file storing the AppData from the system and clears the local data as well.
         */
        public function purge():void
        {
            //check for valid file
            if(!String.isNullOrEmpty(_writePath))
            {
                if(File.fileExists(_writePath))
                {
                    //delete the file
                    File.removeFile(_writePath);
                    trace("App Data file removed: " + _writePath);            
                }
            }

            //clear all local saved data as well
            clear();
        }


        /**
        Sets a Boolean value for the specified key from the AppData JSON file 
         * and optionally saves the file to disk afterwards.
         *
         *  @param key Key that marks the value provided
         *  @param val Value associated with the provided Key
         */
        public function setBoolean(key:String, val:Boolean)
        {
            if(jsonData != null)
            {
                jsonData.setBoolean(key, val);
                if(_saveOnSet)
                {
                    save();
                }
            }
        }


        /**
        Gets a Boolean value for the specified key from the AppData JSON file.
         *
         *  @param key Key that marks the value requested
         *  @return Boolean Value associated with the provided Key
         */
        public function getBoolean(key:String):Boolean
        {
            return (jsonData != null) ? jsonData.getBoolean(key) : false;
        }
      

        /**
        Sets an Integer value for the specified key from the AppData JSON file 
         * and optionally saves the file to disk afterwards.
         *
         *  @param key Key that marks the value provided
         *  @param val Value associated with the provided Key
         */
        public function setInteger(key:String, val:int)
        {
            if(jsonData != null)
            {
                jsonData.setInteger(key, val);
                if(_saveOnSet)
                {
                    save();
                }
            }
        }


        /**
        Gets an Integer value for the specified key from the AppData JSON file.
         *
         *  @param key Key that marks the value requested
         *  @return int Value associated with the provided Key
         */
        public function getInteger(key:String):int
        {
            return (jsonData != null) ? jsonData.getInteger(key) : 0;
        }
      

        /**
        Sets a float value for the specified key from the AppData JSON file 
         * and optionally saves the file to disk afterwards.
         *
         *  @param key Key that marks the value provided
         *  @param val Value associated with the provided Key
         */
        public function setFloat(key:String, val:float)
        {
            if(jsonData != null)
            {
                jsonData.setFloat(key, val);
                if(_saveOnSet)
                {
                    save();
                }
            }
        }


        /**
        Gets a Float value for the specified key from the AppData JSON file.
         *
         *  @param key Key that marks the value requested
         *  @return float Value associated with the provided Key
         */
        public function getFloat(key:String):float
        {
            return (jsonData != null) ? jsonData.getFloat(key) : 0.0;
        }
      

        /**
        Sets a String value for the specified key from the AppData JSON file 
         * and optionally saves the file to disk afterwards.
         *
         *  @param key Key that marks the value provided
         *  @param val Value associated with the provided Key
         */
        public function setString(key:String, val:String)
        {
            if(jsonData != null)
            {
                jsonData.setString(key, val);
                if(_saveOnSet)
                {
                    save();
                }
            }
        }


        /**
        Gets a String value for the specified key from the AppData JSON file.
         *
         *  @param key Key that marks the value requested
         *  @return String Value associated with the provided Key
         */
        public function getString(key:String):String
        {
            return (jsonData != null) ? jsonData.getString(key) : null;
        }


        /**
         * Delegate called when the application triggers the 'applicationDeactivated' 
         * event so that the AppData can be saved.  It is only hooked in if 'saveOnDeactivated'
         * is set as 'true' in the constructor.
         *
         */
        private function onAppDeactivated():void 
        {
            //auto-save data when the app is deactivated
           	save();
        }
    }
}