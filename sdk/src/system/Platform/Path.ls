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
    native class Path 
    {
        public static function folderFromPath(path:String):String
        {
            // Find the last folder delimiter.
            path = normalizePath(path);
            var delim = getFolderDelimiter();
            var lastSlash = path.lastIndexOf(delim);
           
            // No slash, who knows!
            if(lastSlash == -1)
                return path;

            return path.substring(0, lastSlash);
        }

        
        /**
         *  Get's a platform dependent path which may be written to 
         *  For example "Documents" on OSX and Windows or the local cache on iOS/Android.
         *  @return an absolute path to the writeable folder.
         */
        public static native function getWritablePath():String;

        /**
         *  Normalizes an input path to use the system folder delimiters.
         *  @param path the path to normalize.
         *  @return the normalized path with platform directory delimiters.
         */
        public static native function normalizePath(path:String):String;

        /**
         *  Recursively makes the full directory tree of the path provided.
         *  @param path the path to create.
         *  @return true on success, false on failure.
         */
        public static function makeDir(path:String):Boolean 
        {

            return _makeDir(normalizePath(path));

        }

        /**
         *  Checks whether a directory exists at the given path.
         *  @param path the path to check.
         *  @return true if the path exists, false if it doesn't.
         */
        public static function dirExists(path:String):Boolean
        {
            return _dirExists(Path.normalizePath(path));
        }

        /**
         *  Removes a directory (or directory tree) at the given path.
         *  @param path the path to remove.
         *  @param: recursive whether to delete all subfolders and files (note that if the directory is not empty
         *          and recursive is not specified the directory will not be removed).
         *  @return true if the directory was removed, false if it wasn't.
         */
        public static function removeDir(path:String, recursive:Boolean = false):Boolean
        {
            path = Path.normalizePath(path);

            if (recursive)
            {
                var files = new Vector.<String>;
                var dirs = new Vector.<String>;

                Path.walkFiles(path, removeDirCallback, files);

                dirs.pushSingle(path);

                for each (var filename in files) 
                {
                    var dirname = filename.substr(0, filename.lastIndexOf(Path.getFolderDelimiter()));

                    if (dirname != path)
                        if (!dirs.contains(dirname))
                            dirs.pushSingle(dirname);

                    if (!File.removeFile(filename))
                        return false;

                }

                // remove paths in reverse order

                for (var idx = dirs.length - 1; idx >= 0; idx--)
                {        
                    if (!removeDir(dirs[idx]))
                        return false;
                }

                return true;

            }

            return _removeDir(path);
        }

        /**
         *  Walks a given path calling the given callback function for every file in the directory and 
         *  its subdirectorys.
         *  @param path the path to walk.
         *  @param callback a function with the following signature function(fileName:String, payload:Object).
         *  @param payload an optional object to send to the callback function.
         */
        public static function walkFiles(path:String, callback:Function, payload:Object = null):void
        {
            return _walkFiles(Path.normalizePath(path), callback, payload);
        }

        /**
         *  Gets the system's folder delimiter "/" or "\".
\        *  @return returns the system folder delimiter string.
         */
        public static native function getFolderDelimiter():String;

        // privates
        private static function removeDirCallback(filename:String, files:Vector.<String>) 
        {
            files.pushSingle(filename);

        }

        private static native function _makeDir(path:String):Boolean;
        private static native function _dirExists(path:String):Boolean;
        private static native function _removeDir(path:String):Boolean;
        private static native function _walkFiles(path:String, callback:Function, payload:Object):void;


    }

}

