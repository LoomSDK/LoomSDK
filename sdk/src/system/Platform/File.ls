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

package system.platform {

    /**
     * The File class provides many common file operations for text and binary files.
     */
    native class File 
    {
        /**
         *  Loads a text file at the given path.
         *
         *  @param path the full path to the text file to load.
         *  @return a string with the contents of the text file or null if the file can't be loaded.
         */
        public static function loadTextFile(path:String):String 
        {
            return _loadTextFile(Path.normalizePath(path));
        }

        /**
         *  Loads a binary file at the given path.
         *
         *  @param path the full path to the binary file to load.
         *  @return a ByteArray with the contents of the binary file or null if the file can't be loaded.
         */
        public static function loadBinaryFile(path:String):ByteArray 
        {
            return _loadBinaryFile(Path.normalizePath(path));
        }

        /**
         *  Writes a text file at the given path.
         *
         *  @param path the full path to the binary file to load.
         *  @param text the text to write to the file.
         *  @return true on success, false on failure.
         */
        public static function writeTextFile(path:String, text:String):Boolean 
        {
            return _writeTextFile(Path.normalizePath(path), text);
        }

        /**
         *  Writes a binary file at the given path.
         *
         *  @param path the full path to the binary file to load.
         *  @param data the ByteArray which contains the data to write to the file.
         *  @return true on success, false on failure.
         */
        public static function writeBinaryFile(path:String, data:ByteArray):Boolean
        {
            return _writeBinaryFile(Path.normalizePath(path), data);
        }

        /**
         *  Checks whether a file exists at the given path.
         *
         *  @param path the full path to the file to check.
         *  @result true if the file exists, false if it doesn't.
         */
        public static function fileExists(path:String):Boolean
        {
            return _fileExists(Path.normalizePath(path));
        }

        /**
         *  Removes a file at the given path.
         *
         *  @param path the full path to the file to remove.
         *  @result true on success, false on failure.
         */
        public static function removeFile(path:String):Boolean
        {
            return _removeFile(Path.normalizePath(path));
        }

        // private native backing methods
        private static native function _loadTextFile(path:String):String;

        private static native function _loadBinaryFile(path:String):ByteArray;

        private static native function _writeTextFile(path:String, text:String):Boolean; 

        private static native function _writeBinaryFile(path:String, data:ByteArray):Boolean; 

        private static native function _fileExists(path:String):Boolean;

        private static native function _removeFile(path:String):Boolean;

    }

}

