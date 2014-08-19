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
         *  Loads a text file from the given file path.
         *
         *  @param path The full path to the text file to load.
         *  @return A String with the contents of the text file or null if the file can't be loaded.
         */
        public static function loadTextFile(path:String):String 
        {
            return _loadTextFile(Path.normalizePath(path));
        }

        /**
         *  Loads a binary file from the given file path.
         *
         *  @param path The full path to the binary file to load.
         *  @return ByteArray with the contents of the binary file or null if the file can't be loaded.
         */
        public static function loadBinaryFile(path:String):ByteArray 
        {
            return _loadBinaryFile(Path.normalizePath(path));
        }

        /**
         *  Writes a text file to the given file path.
         *
         *  @param path The full path to the text file to save.
         *  @param text The text String to write to the file.
         *  @return True on success, false on failure.
         */
        public static function writeTextFile(path:String, text:String):Boolean 
        {
            return _writeTextFile(Path.normalizePath(path), text);
        }

        /**
         *  Writes a binary file to the given file path.
         *
         *  @param path The full path to the binary file to save.
         *  @param data The ByteArray containing the data to write to the file.
         *  @return True on success, false on failure.
         */
        public static function writeBinaryFile(path:String, data:ByteArray):Boolean
        {
            return _writeBinaryFile(Path.normalizePath(path), data);
        }

        /**
         *  Copies a file from pathSource to pathDestination
         *
         *  Please note that this implementation requires the file be loaded into memory.
         *  Therefore, it must fit into available memory.
         *  
         *  @param pathSource The source file to copy.
         *  @param pathDestination The destination file to write to.
         *  @return True on success, false on failure.
         */
        public static function copy(pathSource:String, pathDestination:String):Boolean
        {
            var bytes = loadBinaryFile(Path.normalizePath(pathSource));

            if (!bytes)
                return false;

            return writeBinaryFile(Path.normalizePath(pathDestination), bytes);
        }


        /**
         *  Checks whether a file exists at the given path.
         *
         *  @param path The full path to the file to check.
         *  @return True if the file exists, false if it doesn't.
         */
        public static function fileExists(path:String):Boolean
        {
            return _fileExists(Path.normalizePath(path));
        }

        /**
         *  Removes a file at the given path.
         *
         *  @param path The full path of the file to be removed.
         *  @return True on success, false on failure.
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

